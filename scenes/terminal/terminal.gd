extends Control

# Переменные для отслеживания состояния
var current_day: int = 1
var current_quest: Dictionary = {}
var active_quest: Dictionary = {}  # ✅ ДОБАВЬ ЭТУ СТРОКУ
var sql_command_history: Array = []
var is_quest_active: bool = false

# Ссылки на узлы UI
@onready var terminal_output = $TerminalOutput
@onready var terminal_input = $TerminalInput
#@onready var timer_label = $TimerLabel  # Если есть таймер

# Эмуляция таблиц Firebird SQL
var mock_tables: Dictionary = {}


func _ready():
	# Подключаемся к сигналам БД
	if DatabaseManager:
		DatabaseManager.database_ready.connect(_on_database_ready)
	
	# Настройка терминала
	terminal_input.text = ""
	terminal_input.grab_focus()
	
	welcome_message()
	load_mock_tables()


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
	"""Выполнение SQL команды"""
	if command.strip_edges().is_empty():
		return
	
	# Добавляем в историю
	sql_command_history.append(command)
	
	# Отображаем команду
	terminal_output.text += "\nSQL> " + command + "\n"
	
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
	var result = execute_sql(command)
	
	if result.success:
		display_result(result.data)
		
		# Проверяем если это задание
		if is_quest_active:
			check_quest_completion(result.data)
	else:
		terminal_output.text += "[color=red]⚠️ ОШИБКА:[/color] " + result.error + "\n"
	
	# Прокрутка вниз
	terminal_output.scroll_vertical = terminal_output.get_line_count()


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
	"""Выполнение SQL запроса (эмуляция)"""
	var cmd_upper = command.to_upper().strip_edges()
	
	# Простая эмуляция SELECT
	if cmd_upper.begins_with("SELECT"):
		return execute_select(command)
	elif cmd_upper.begins_with("INSERT"):
		return execute_insert(command)
	elif cmd_upper.begins_with("UPDATE"):
		return execute_update(command)
	elif cmd_upper.begins_with("DELETE"):
		return execute_delete(command)
	else:
		return {"success": false, "error": "Неподдерживаемая команда"}


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
	"""Отображение результатов запроса"""
	if data.is_empty():
		terminal_output.text += "[color=yellow]Строк: 0[/color]\n"
		return
	
	# Получаем колонки
	var columns = data[0].keys()
	
	# Заголовок
	var header = ""
	for col in columns:
		header += str(col) + " | "
	terminal_output.text += "[color=green]" + header + "[/color]\n"
	
	# Данные
	for row in data:
		var line = ""
		for col in columns:
			line += str(row.get(col, "")) + " | "
		terminal_output.text += line + "\n"
	
	terminal_output.text += "[color=yellow]Строк: " + str(data.size()) + "[/color]\n"
		
func check_quest_completion(result_data: Array):
	"""Проверка выполнения задания"""
	if active_quest.is_empty():
		return
	
	var expected_rows = active_quest.get("expected_rows", -1)
	
	if expected_rows >= 0 and result_data.size() == expected_rows:
		terminal_output.text += "\n[color=green]✅ ЗАДАНИЕ ВЫПОЛНЕНО![/color]\n"
		
		# ✅ ИСПРАВЛЕНО - передаём true (bool)
		QuestManager.complete_quest(true)
		
		is_quest_active = false
	else:
		terminal_output.text += "\n[color=red]⚠️ Ожидается " + str(expected_rows) + " строк, получено " + str(result_data.size()) + "[/color]\n"
		
func track_sql_usage(command_name: String):
	"""Отслеживание использования SQL команды"""
	if DatabaseManager:
		DatabaseManager.track_sql_usage(command_name, current_day)


func set_day(day: int):
	"""Установка текущего дня"""
	current_day = day
	load_active_quest()
