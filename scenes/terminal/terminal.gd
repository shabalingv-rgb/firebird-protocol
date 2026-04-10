extends Control

# Переменные для отслеживания состояния
var current_day: int = 1
var current_quest: Dictionary = {}
var active_quest: Dictionary = {}  # ✅ ДОБАВЬ ЭТУ СТРОКУ
var sql_command_history: Array = []
var is_quest_active: bool = false

# Ссылки на узлы UI
@onready var terminal_output = $TerminalScroll/TerminalOutput
@onready var terminal_input = $TerminalInput
@onready var terminal_scroll = $TerminalScroll

func _ready():
	# Подключаемся к сигналам БД
	if DatabaseManager:
		DatabaseManager.DatabaseReady.connect(_on_database_ready)
	
	# Настройка терминала
	terminal_input.text = ""
	terminal_input.focus_mode = Control.FOCUS_ALL
	terminal_input.grab_focus()
	terminal_output.scroll_following = true

	welcome_message()

	$BackButton.pressed.connect(_on_back_pressed)
	$HelpButton.pressed.connect(_on_help_pressed)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/desktop/desktop.tscn") 
	
func  _on_help_pressed():
	get_tree().change_scene_to_file("res://scenes/guide/guide_client.tscn")

func _on_database_ready():
	print("💻 Terminal: БД готова")
	# Можно загрузить активное задание
	load_active_quest()


func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER and terminal_input.has_focus():
			execute_command(terminal_input.text)
			terminal_input.text = ""
		
		# Ctrl+L для очистки
		elif event.keycode == KEY_L and (event.ctrl_pressed or event.meta_pressed):
			terminal_output.text = ""

func welcome_message():
	"""Приветственное сообщение"""
	var welcome = """
╔══════════════════════════════════════════════════╗
║     FIREBIRD SQL TERMINAL v5.0                   ║
║     Образовательная система НИИ "Файербёрд"      ║
╚══════════════════════════════════════════════════╝

Введите 'TABLES' для списка доступных таблиц
Введите 'HELP' для списка команд

"""
	terminal_output.text += welcome


func show_tables():
	"""Показ реальных таблиц из Firebird"""
	var result = DatabaseManager.call("ExecuteQuery",
		"SELECT TRIM(RDB$RELATION_NAME) AS TABLE_NAME FROM RDB$RELATIONS WHERE RDB$SYSTEM_FLAG = 0 ORDER BY RDB$RELATION_NAME")

	var tables_text = "\n[color=cyan]ДОСТУПНЫЕ ТАБЛИЦЫ:[/color]\n"

	if result == null or result.is_empty():
		tables_text += "  [color=gray]Таблицы не найдены[/color]\n"
	else:
		for row in result:
			var table_name = str(row.get("TABLE_NAME", "")).strip_edges()
			if not table_name.is_empty():
				tables_text += "  - " + table_name + "\n"

	terminal_output.text += tables_text + "\n"


func scroll_to_bottom():
	#ДАём движку время пересчитать размер текста
	await  get_tree().process_frame
	await  get_tree().process_frame
	await  get_tree().process_frame
	terminal_output.scroll_to_line(terminal_output.get_line_count())
	

func load_active_quest():
	"""Синхронизация с QuestManager (там уже выбрано обязательное задание дня) или загрузка из БД."""
	if QuestManager and not QuestManager.active_quest.is_empty():
		active_quest = QuestManager.active_quest
		current_quest = active_quest
		is_quest_active = true
		show_quest_notification(active_quest)
		return
	if not DatabaseManager:
		return
	var emails = DatabaseManager.call("GetEmailsForDay", current_day)
	for email in emails:
		var eid = email.get("ID", email.get("id", -1))
		var quest = DatabaseManager.call("GetQuestForEmail", int(eid))
		if quest and not quest.is_empty():
			current_quest = quest
			active_quest = quest
			if QuestManager:
				QuestManager.active_quest = quest
			is_quest_active = true
			var qt = quest.get("TITLE", quest.get("title", ""))
			print("🎯 Активное задание: ", qt)
			show_quest_notification(quest)
			break


func show_quest_notification(quest: Dictionary):
	"""Показ уведомления о задании"""
	var title = quest.get("TITLE", quest.get("title", ""))
	var desc = quest.get("DESCRIPTION", quest.get("description", ""))
	var exp_rows = quest.get("EXPECTED_ROWS", quest.get("expected_rows", -1))
	terminal_output.text += "\n[color=yellow]📋 НОВОЕ ЗАДАНИЕ[/color]\n"
	terminal_output.text += "[color=yellow]Название:[/color] " + str(title) + "\n"
	terminal_output.text += "[color=yellow]Описание:[/color] " + str(desc) + "\n"
	terminal_output.text += "[color=yellow]Ожидаемый результат:[/color] " + str(exp_rows) + " строк\n\n"


func execute_command(command: String):
	var cmd_raw = command.strip_edges()
	if cmd_raw.is_empty(): return
	
	terminal_output.text += "\nSQL> " + cmd_raw + "\n"
	
	# Разбиваем команду на части для умного HELP
	var parts = cmd_raw.split(" ", false) # false значит "не убирать пустые", но при этом лучше true
	var first_word = parts[0].to_upper() if parts.size() > 0 else ""
	
	if first_word == "HELP":
		if parts.size() > 1:
			var subject = parts[1].strip_edges().to_upper()
			show_help_for_subject(subject)
		else :
			show_help()
		terminal_input.text = "" # Очищаем ввод
		scroll_to_bottom() # Вызываем прокрутку здесь
		return
		
	if command.strip_edges().is_empty():
		return

	sql_command_history.append(command)

	# Обработка специальных команд
	if command.to_upper().begins_with("HELP"):
		show_help()
		return
	elif command.to_upper().begins_with("CLEAR"):
		terminal_output.text = ""
		return
	elif command.to_upper().begins_with("TABLES"):
		show_tables()
		return
	
	# Выполнение SQL запроса
	var result = execute_sql(cmd_raw)
	if result.success:
		display_result(result.data)
		if cmd_raw.to_upper().strip_edges().begins_with("SELECT"):
			check_quest_completion(result.data)
	else:
		terminal_output.text += "[color=red]⚠️ ОШИБКА:[/color] " + str(result.error) + "\n"
		
	terminal_input.text = ""
		
	scroll_to_bottom() # Вызываем прокрутку здесь


func show_help_for_subject(subject: String):
	terminal_output.text += "\n [color=cyan] 🔍 СПРАВКА ПО ОБЪЕКТУ: " + subject + "[/color]\n"
	
	match subject:
		"EMPLOYEES":
			terminal_output.text += "Таблица сотрудников НИИ.\nКолонки: ID (int), NAME (str), DEPARTMENT (str), SALARY (int)\n"
		"EMAILS":
			terminal_output.text += "Архив входящей почты.\nКолонки: ID, SENDER, SUBJECT, BODY, DAY_ID\n"
		"SELECT":
			terminal_output.text += "Синтаксис: SELECT [колонки] FROM [таблица] WHERE [условие]\nПример: SELECT * FROM employees WHERE salary > 50000\n"
		_:
			# Проверка имени таблицы в системном каталоге Firebird (экранируем кавычки в имени)
			var safe = str(subject).replace("'", "''")
			var check_db = DatabaseManager.call("ExecuteQuery",
				"SELECT 1 FROM RDB$RELATIONS WHERE RDB$RELATION_NAME = '" + safe + "'")
			if check_db != null and check_db.size() > 0:
				terminal_output.text += "Это существующая таблица в базе данных.\n"
			else:
				terminal_output.text += "Информация по запросу '" + str(subject) + "' не найдена.\n"
				
		# Прокрутка вниз
	scroll_to_bottom()

	

func show_help():
	"""Показ справки по командам"""
	var help_text = """
[color=cyan]ДОСТУПНЫЕ КОМАНДЫ:[/color]
  HELP          - Показать эту справку
  CLEAR         - Очистить терминал
  TABLES        - Показать доступные таблицы
  
[color=cyan]SQL КОМАНДЫ:[/color]
  SELECT        - Выборка данных
  INSERT        - Добавление записей
  UPDATE        - Обновление записей
  DELETE        - Удаление записей
  
[color=cyan]ПРИМЕРЫ:[/color]
  SELECT * FROM employees
  SELECT name, salary FROM employees WHERE salary > 70000
  SELECT department, COUNT(*) FROM employees GROUP BY department

"""
	terminal_output.text += help_text


func execute_sql(command: String) -> Dictionary:
	"""Выполнение реального SQL запроса через Firebird"""
	var cmd_upper = command.to_upper().strip_edges()
	
	# Сначала записываем использованные команды для статистики/ачивок
	for word in ["SELECT", "INSERT", "UPDATE", "DELETE", "CREATE", "DROP"]:
		if cmd_upper.begins_with(word):
			track_sql_usage(word)
			break

	#Отправляем запрос в настоящий Firebird через наш С# менеджер
	var result_data = DatabaseManager.call("ExecuteQuery", command)

	#Если результат null значит в C# произошла ошибка (исключение)
	if result_data == null:
		var err_text = DatabaseManager.call("GetLastError")
		return {"success": false, "error": err_text}
	
	return {"success": true, "data": result_data}


func display_result(data: Array):
	if data.is_empty():
		terminal_output.append_text("[color=gray]Запрос выполнен. Строк: 0[/color]\n")
		return
	
	# 1. Получаем колонки правильно (из первого элемента массива)
	var columns = data[0].keys()
	
	# 2. Считаем ширину колонок
	var col_widths = {}
	for col in columns:
		var max_w = str(col).length()
		for row in data:
			var val_text = str(row.get(col, "NULL"))
			if val_text.length() > max_w:
				max_w = val_text.length()
		col_widths[col] = max_w

	# 3. Рисуем шапку
	var header = " "
	var separator = "+"
	for col in columns:
		header += str(col).to_upper().rpad(col_widths[col]) + " | "
		separator += "-".repeat(col_widths[col] + 1) + "+"
	
	terminal_output.append_text("[color=cyan]" + separator + "[/color]\n")
	terminal_output.append_text("[color=cyan]" + header + "[/color]\n")
	terminal_output.append_text("[color=cyan]" + separator + "[/color]\n")
	
	# 4. Выводим данные
	for row in data:
		var line = " "
		for col in columns:
			var value = str(row.get(col, "NULL"))
			line += value.rpad(col_widths[col]) + " | "
		terminal_output.append_text(line + "\n")
		
	terminal_output.append_text("[color=cyan]" + separator + "[/color]\n")
	terminal_output.append_text("[color=yellow]Всего строк: " + str(data.size()) + "[/color]\n")
	
func check_quest_completion(result_data: Array):
	"""Проверка выполнения задания"""
	if active_quest.is_empty():
		return
	
	var expected_rows = active_quest.get("EXPECTED_ROWS", active_quest.get("expected_rows", -1))
	
	# 1. Простейшая проверка по количеству строк
	if expected_rows >= 0 and result_data.size() == expected_rows:
		terminal_output.text += "\n[color=green]✅ СИСТЕМА: Запрос принят. Данные соответствуют ожидаемым.[/color]\n"
		QuestManager.complete_quest(true)
		active_quest = {}
		if QuestManager:
			QuestManager.active_quest = {}
		is_quest_active = false
	else:
		terminal_output.text += "\n[color=yellow]⚠️ СИСТЕМА: Получено " + str(result_data.size()) + " строк. Ожидалось " + str(expected_rows) + ".[/color]\n"
		
func track_sql_usage(command_name: String):
	"""Отслеживание использования SQL команды"""
	if DatabaseManager:
		DatabaseManager.call("TrackSqlUsage", command_name, current_day)


func set_day(day: int):
	"""Установка текущего дня"""
	current_day = day
	load_active_quest()
