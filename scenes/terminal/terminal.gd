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
#@onready var timer_label = $TimerLabel  # Если есть таймер

# Эмуляция таблиц Firebird SQL
var mock_tables: Dictionary = {}


func _ready():
	# Подключаемся к сигналам БД
	if DatabaseManager:
		DatabaseManager.DatabaseReady.connect(_on_database_ready)
	
	# Настройка терминала
	terminal_input.text = ""
	terminal_input.grab_focus()
	terminal_output.scroll_following = true
	
	welcome_message()
	load_mock_tables()
	
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

Доступные таблицы: employees, departments, projects
Введите 'HELP' для списка команд

"""
	terminal_output.text += welcome


func load_mock_tables():
	"""Загрузка тестовых данных для эмуляции БД"""
	# Таблица employees
	mock_tables["employees"] = [
		{"id": 1, "name": "Иванов Иван", "department": "IT", "salary": 75000},
		{"id": 2, "name": "Петрова Мария", "department": "HR", "salary": 65000},
		{"id": 3, "name": "Сидоров Алексей", "department": "IT", "salary": 80000},
		{"id": 4, "name": "Козлова Елена", "department": "Finance", "salary": 70000},
		{"id": 5, "name": "Новиков Дмитрий", "department": "IT", "salary": 90000}
	]
	
	# Таблица departments
	mock_tables["departments"] = [
		{"id": 1, "name": "IT", "budget": 1000000},
		{"id": 2, "name": "HR", "budget": 500000},
		{"id": 3, "name": "Finance", "budget": 750000}
	]
	
	# Таблица projects
	mock_tables["projects"] = [
		{"id": 1, "name": "Протокол Феникс", "budget": 5000000, "status": "secret"},
		{"id": 2, "name": "Аналитика данных", "budget": 200000, "status": "active"}
	]

func scroll_to_bottom():
	#ДАём движку время пересчитать размер текста
	await  get_tree().process_frame
	await  get_tree().process_frame
	await  get_tree().process_frame
	terminal_output.scroll_to_line(terminal_output.get_line_count())
	

func load_active_quest():
	"""Загрузка активного задания из БД"""
	# Получаем задание для текущего дня
	var emails = DatabaseManager.get_emails_for_day(current_day)
	
	for email in emails:
		var quest = DatabaseManager.get_quest_for_email(email.id)
		if quest and not quest.is_empty():
			current_quest = quest
			is_quest_active = true
			print("🎯 Активное задание: ", quest.title)
			show_quest_notification(quest)
			break


func show_quest_notification(quest: Dictionary):
	"""Показ уведомления о задании"""
	terminal_output.text += "\n[color=yellow]📋 НОВОЕ ЗАДАНИЕ[/color]\n"
	terminal_output.text += "[color=yellow]Название:[/color] " + quest.title + "\n"
	terminal_output.text += "[color=yellow]Описание:[/color] " + quest.description + "\n"
	terminal_output.text += "[color=yellow]Ожидаемый результат:[/color] " + str(quest.expected_rows) + " строк\n\n"


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
	
	#Добавляем в историю
		sql_command_history.append(command)
	
	 #Обработка специальных команд
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
			#Если игрок ввел что-то неизвестное, пробуем поискать это в БД
			var check_db = DatabaseManager.ExecuteQuery("SELECT 1 FROM RDB$RELATIONS_NAME = '" + subject + "'")
			if check_db and check_db.size() >0:
				terminal_output.text += "Это существующая таблица в базе данных.\n"
			else:
				terminal_output.text += "Информация по запросу '" + subject + "' не найдена.\n"
				
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


func show_tables():
	"""Показ доступных таблиц"""
	var tables_text = "\n[color=cyan]ДОСТУПНЫЕ ТАБЛИЦЫ:[/color]\n"
	for table_name in mock_tables.keys():
		tables_text += "  - " + table_name + "\n"
	terminal_output.text += tables_text + "\n"


func execute_sql(command: String) -> Dictionary:
	"""Выполнение реального SQL запроса через Firebird"""
	var cmd_upper = command.to_upper().strip_edges()
	
	# Сначала записываем использованные команды для статистики/ачивок
	for word in ["SELECT", "INSERT", "UPDATE", "DELETE", "CREATE", "DROP"]:
		if cmd_upper.begins_with(word):
			track_sql_usage(word)
			break

	#Отправляем запрос в настоящий Firebird через наш С# менеджер
	var result_data = DatabaseManager.ExecuteQuery(command)

	#Если результат null значит в C# произошла ошибка (исключение)
	if result_data == null:
		# Получаем тектс ошибки прямо из движка Firebird через наш новый метод
		var err_text = DatabaseManager.GetLastError()
		return {"success": false, "error": err_text}
	
	return {"success": true, "data": result_data}


func execute_select(command: String) -> Dictionary:
	"""Выполнение SELECT запроса"""
	# Очень простая эмуляция - для демо
	# В полной версии нужно парсить SQL
	
	var result_data: Array = []
	
	# Ищем имя таблицы
	var table_name = ""
	if "FROM" in command.to_upper():
		var parts = command.split("FROM", 1, false)
		if parts.size() > 1:
			var after_from = parts[1].strip_edges()
			var table_parts = after_from.split(" ")
			if table_parts.size() > 0:
				table_name = table_parts[0].strip_edges().to_lower()
	
	# Проверяем существует ли таблица
	if not mock_tables.has(table_name):
		return {"success": false, "error": "Таблица '" + table_name + "' не найдена"}
	
	# Возвращаем все данные таблицы (упрощённо)
	result_data = mock_tables[table_name]
	
	# Отслеживаем использование SQL команд
	track_sql_usage("SELECT")
	
	return {"success": true, "data": result_data}


func execute_insert(_command: String) -> Dictionary:
	"""Выполнение INSERT запроса"""
	track_sql_usage("INSERT")
	return {"success": true, "data": [], "message": "Запись добавлена (эмуляция)"}


func execute_update(_command: String) -> Dictionary:
	"""Выполнение UPDATE запроса"""
	track_sql_usage("UPDATE")
	return {"success": true, "data": [], "message": "Записи обновлены (эмуляция)"}


func execute_delete(_command: String) -> Dictionary:
	"""Выполнение DELETE запроса"""
	track_sql_usage("DELETE")
	return {"success": true, "data": [], "message": "Записи удалены (эмуляция)"}


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
		terminal_output.text += "\n[color=green]✅ СИСТЕМА: Зпрос принят. Данные соответсвуют ожидаемым.[/color]\n"
		
		# 2. Передаём сигнал в QuestManager
		QuestManager.complete_quest(true)
		
		# 3. Деактивируем задание, что бы не срабатывало на каждый SELECT
		active_quest = {}
		is_quest_active = false
	else:
		terminal_output.text += "\n[color=yellow]⚠️ СИСТЕМА: Получено " + str(result_data.size()) + " строк. Ожидалось " + str(expected_rows) + ".[/color]\n"
		
func track_sql_usage(command_name: String):
	"""Отслеживание использования SQL команды"""
	if DatabaseManager:
		# Используем TrackSqlUsage (с большой буквы)
		DatabaseManager.TrackSqlUsage(command_name, current_day)


func set_day(day: int):
	"""Установка текущего дня"""
	current_day = day
	load_active_quest()
