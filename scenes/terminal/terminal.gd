extends Control

# Виртуальная база данных
var database: Dictionary = {
	"employees": [
		{"id": 1, "name": "Иванов Иван", "department": "IT", "salary": 75000},
		{"id": 2, "name": "Петрова Мария", "department": "HR", "salary": 65000},
		{"id": 3, "name": "Сидоров Алексей", "department": "IT", "salary": 80000},
		{"id": 4, "name": "Козлова Елена", "department": "Finance", "salary": 70000},
		{"id": 5, "name": "Новиков Дмитрий", "department": "IT", "salary": 90000}
	],
	"departments": [
		{"id": 1, "name": "IT", "budget": 500000},
		{"id": 2, "name": "HR", "budget": 200000},
		{"id": 3, "name": "Finance", "budget": 300000}
	],
	"projects": [
		{"id": 1, "name": "Firebird DB", "lead_id": 1, "budget": 1000000},
		{"id": 2, "name": "HR System", "lead_id": 2, "budget": 500000},
		{"id": 3, "name": "Analytics", "lead_id": 3, "budget": 750000}
	]
}

# История команд
var command_history: Array[String] = []
var history_index: int = 0

@onready var terminal_output = $TerminalOutput
@onready var terminal_input = $TerminalInput
@onready var help_button = $HelpButton

func _ready():
	# Подключаем сигналы
	terminal_input.text_submitted.connect(_on_input_submitted)
	help_button.pressed.connect(_show_help)
	
	# Приветственное сообщение
	welcome_message()
	terminal_input.grab_focus()

func welcome_message():
	append_output("╔══════════════════════════════════════════════════════╗")
	append_output("║  FIREBIRD SQL TERMINAL v5.0                          ║")
	append_output("║  Образовательная система НИИ                         ║")
	append_output("╚══════════════════════════════════════════════════════╝")
	append_output("")
	append_output("Доступные таблицы: employees, departments, projects")
	append_output("Введите 'HELP' для списка команд")
	append_output("")
	append_output("SQL> ", Color.GREEN)

func _on_input_submitted(query: String):
	if query.is_empty():
		terminal_input.clear()
		return
	
	# Добавляем в историю
	command_history.append(query)
	history_index = command_history.size()
	
	# Показываем введенную команду
	append_output("SQL> " + query, Color.GREEN)
	
	# Обрабатываем команду
	process_query(query)
	
	# Очищаем ввод
	terminal_input.clear()
	terminal_input.grab_focus()

func process_query(query: String):
	var normalized = query.strip_edges().to_upper()
	
	# Проверяем на запрещенные команды
	if is_forbidden_command(normalized):
		append_output("⚠️ ОШИБКА: Несанкционированный доступ!", Color.RED)
		append_output("Эта команда запрещена для вашего уровня доступа.")
		GameState.add_violation()
		return
	
	# Обрабатываем команды
	if normalized == "HELP" or normalized == "?":
		_show_help()
	elif normalized.begins_with("SELECT"):
		execute_select(query)
	elif normalized.begins_with("INSERT"):
		execute_insert(query)
	elif normalized.begins_with("UPDATE"):
		execute_update(query)
	elif normalized.begins_with("DELETE"):
		execute_delete(query)
	elif normalized == "CLEAR" or normalized == "CLS":
		terminal_output.clear()
		welcome_message()
	elif normalized == "TABLES":
		show_tables()
	else:
		append_output("⚠️ ОШИБКА: Неизвестная команда", Color.RED)
		append_output("Введите HELP для списка доступных команд")

func is_forbidden_command(query: String) -> bool:
	var forbidden = ["DROP", "TRUNCATE", "ALTER", "CREATE", "GRANT", "REVOKE"]
	for cmd in forbidden:
		if query.begins_with(cmd):
			return true
	return false

func execute_select(query: String):
	# Простой парсер SELECT
	var parts = query.split(" ")
	if parts.size() < 4:
		append_output("⚠️ ОШИБКА: Неверный синтаксис SELECT", Color.RED)
		append_output("Пример: SELECT * FROM employees")
		return
	
	# Извлекаем таблицу
	var from_index = parts.find("FROM")
	if from_index == -1 or from_index + 1 >= parts.size():
		append_output("⚠️ ОШИБКА: Укажите таблицу после FROM", Color.RED)
		return
	
	var table_name = parts[from_index + 1].to_lower()
	
	# Убираем точку с запятой если есть
	table_name = table_name.replace(";", "")
	
	# Проверяем существование таблицы
	if not database.has(table_name):
		append_output("⚠️ ОШИБКА: Таблица '%s' не найдена" % table_name, Color.RED)
		append_output("Доступные таблицы: employees, departments, projects")
		return
	
	# Получаем данные
	var data = database[table_name]
	
	# Проверяем WHERE
	var where_clause = ""
	var where_index = query.to_upper().find("WHERE")
	if where_index != -1:
		where_clause = query.substr(where_index + 6).strip_edges()
	
	# Фильтруем если есть WHERE
	if not where_clause.is_empty():
		data = apply_where_filter(data, where_clause)
	
	# Показываем результаты
	display_results(data)
	append_output("")
	append_output("Строк: %d" % data.size(), Color.YELLOW)

func apply_where_filter(data: Array, where_clause: String) -> Array:
	var filtered: Array = []
	
	# Простой парсер WHERE (поддерживает = и >, <)
	var parts = where_clause.split(" ")
	if parts.size() < 3:
		return data
	
	var column = parts[0].to_lower()
	var operator = parts[1]
	var value = parts[2].replace(";", "").replace("'", "").replace('"', '')
	
	for row in data:
		if not row.has(column):
			continue
		
		var cell_value = row[column]
		var match_result = false
		
		if operator == "=":
			match_result = str(cell_value).to_upper() == value.to_upper()
		elif operator == ">":
			match_result = float(cell_value) > float(value)
		elif operator == "<":
			match_result = float(cell_value) < float(value)
		elif operator == ">=":
			match_result = float(cell_value) >= float(value)
		elif operator == "<=":
			match_result = float(cell_value) <= float(value)
		elif operator == "LIKE":
			match_result = str(cell_value).find(value) != -1
		
		if match_result:
			filtered.append(row)
	
	return filtered
	
func display_results(data: Array):
	if data.is_empty():
		append_output("Пустой результат", Color.YELLOW)
		return
	
	# Получаем заголовки
	var headers = data[0].keys()
	
	# Вычисляем ширину колонок
	var col_widths = {}
	for header in headers:
		col_widths[header] = header.length()
		for row in data:
			col_widths[header] = max(col_widths[header], str(row[header]).length())
	
	# Рисуем таблицу
	draw_table_line(col_widths, headers)
	
	# Заголовки
	var header_line = "|"
	for header in headers:
		header_line += " " + pad_string(header, col_widths[header]) + " |"
	append_output(header_line)
	
	draw_table_line(col_widths, headers)
	
	# Данные
	for row in data:
		var line = "|"
		for header in headers:
			line += " " + pad_string(str(row[header]), col_widths[header]) + " |"
		append_output(line)
	
	draw_table_line(col_widths, headers)

func draw_table_line(col_widths: Dictionary, headers: Array):
	var line = "+"
	for header in headers:
		line += "-" + "-".repeat(col_widths[header]) + "-+"
	append_output(line)

func execute_insert(query: String):
	append_output("⚠️ Команда INSERT пока не реализована", Color.YELLOW)

func execute_update(query: String):
	append_output("⚠️ Команда UPDATE пока не реализована", Color.YELLOW)

func execute_delete(query: String):
	append_output("⚠️ Команда DELETE пока не реализована", Color.YELLOW)

func show_tables():
	append_output("Доступные таблицы:", Color.CYAN)
	for table_name in database.keys():
		append_output("  - " + table_name, Color.GREEN)

func _show_help():
	append_output("═══════════════════════════════════════════════════", Color.CYAN)
	append_output("ДОСТУПНЫЕ КОМАНДЫ:", Color.CYAN)
	append_output("═══════════════════════════════════════════════════")
	append_output("SELECT * FROM table          - выбрать все записи")
	append_output("SELECT col FROM table        - выбрать колонку")
	append_output("SELECT * FROM table WHERE    - с условием")
	append_output("TABLES                       - показать таблицы")
	append_output("CLEAR                        - очистить экран")
	append_output("HELP                         - эта справка")
	append_output("═══════════════════════════════════════════════════")
	append_output("")

func append_output(text: String, color: Color = Color.WHITE):
	terminal_output.append_text("[color=" + color.to_html() + "]" + text + "[/color]\n")
	
func pad_string(text: String, length: int) -> String:
	"""Дополняет строку пробелами до нужной длины"""
	while text.length() < length:
		text += " "
	return text
