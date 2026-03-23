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
@onready var back_button = $BackButton

func _ready():
	# Подключаем сигналы
	terminal_input.text_submitted.connect(_on_input_submitted)
	help_button.pressed.connect(_show_help)
	back_button.pressed.connect(_on_back_pressed)
	
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
		terminal_input.grab_focus()
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
	
	# ⭐ Ждём следующий кадр и возвращаем фокус
	await get_tree().process_frame
	terminal_input.grab_focus()
		
func _focus_input():
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
		# Проверяем, нет ли ORDER BY или GROUP BY после WHERE
		var order_index = query.to_upper().find("ORDER BY", where_index)
		var group_index = query.to_upper().find("GROUP BY", where_index)
		
		var end_index = query.length()
		if order_index != -1 and order_index < end_index:
			end_index = order_index
		if group_index != -1 and group_index < end_index:
			end_index = group_index
		
		where_clause = query.substr(where_index + 6, end_index - where_index - 6).strip_edges()
	
	# Фильтруем если есть WHERE
	if not where_clause.is_empty():
		data = apply_where_filter(data, where_clause)
	
	# Проверяем GROUP BY
	var group_clause = ""
	var group_index = query.to_upper().find("GROUP BY")
	if group_index != -1:
		var order_index = query.to_upper().find("ORDER BY", group_index)
		if order_index != -1:
			group_clause = query.substr(group_index + 9, order_index - group_index - 9).strip_edges()
		else:
			group_clause = query.substr(group_index + 9).strip_edges()
		group_clause = group_clause.replace(";", "")
		data = apply_group_by(data, group_clause)
	
	# Проверяем ORDER BY
	var order_clause = ""
	var order_index = query.to_upper().find("ORDER BY")
	if order_index != -1:
		order_clause = query.substr(order_index + 9).strip_edges()
		order_clause = order_clause.replace(";", "")
		data = apply_order_by(data, order_clause)
	
	# Проверяем агрегатные функции
	if is_aggregate_query(query):
		execute_aggregate(data, query)
		return
	
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
	append_output("SELECT * FROM table ORDER BY col  - сортировка")
	append_output("SELECT COUNT(*) FROM table        - количество")
	append_output("SELECT SUM(salary) FROM table    - сумма")
	append_output("SELECT AVG(salary) FROM table    - среднее")
	append_output("SELECT MAX(salary) FROM table    - максимум")
	append_output("SELECT MIN(salary) FROM table    - минимум")
	append_output("SELECT DISTINCT col FROM table   - уникальные")
	append_output("GROUP BY column                  - группировка")
	append_output("═══════════════════════════════════════════════════")
	append_output("")

func append_output(text: String, color: Color = Color.WHITE):
	terminal_output.append_text("[color=" + color.to_html() + "]" + text + "[/color]\n")
	# Автопрокрутка вниз
	scroll_to_bottom()
	# Возвращаем фокус
	terminal_input.grab_focus()
	
func scroll_to_bottom():
	# Прокручиваем к последней строке
	var line_count = terminal_output.get_line_count()
	terminal_output.scroll_to_line(line_count - 1)
	
func pad_string(text: String, length: int) -> String:
	"""Дополняет строку пробелами до нужной длины"""
	while text.length() < length:
		text += " "
	return text

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/desktop/desktop.tscn")
	
func apply_order_by(data: Array, order_clause: String) -> Array:
	var parts = order_clause.split(" ")
	if parts.size() < 1:
		return data
	
	var column = parts[0].to_lower()
	var ascending = true
	
	if parts.size() > 1:
		if parts[1].to_upper() == "DESC":
			ascending = false
		elif parts[1].to_upper() == "ASC":
			ascending = true
	
	# Сортировка
	var sorted = data.duplicate(true)
	sorted.sort_custom(func(a, b):
		var val_a = a[column]
		var val_b = b[column]
		
		if ascending:
			return val_a < val_b
		else:
			return val_a > val_b
	)
	
	return sorted
	
func is_aggregate_query(query: String) -> bool:
	var upper_query = query.to_upper()
	return upper_query.contains("COUNT(") or \
		   upper_query.contains("SUM(") or \
		   upper_query.contains("AVG(") or \
		   upper_query.contains("MIN(") or \
		   upper_query.contains("MAX(")
		
func execute_aggregate(data: Array, query: String):
	var upper_query = query.to_upper()
	
	# COUNT(*)
	if upper_query.contains("COUNT(*)"):
		append_output("╔════════════════════╗", Color.CYAN)
		append_output("║ COUNT              ║", Color.CYAN)
		append_output("╠════════════════════╣", Color.CYAN)
		append_output("║ %-18d ║" % data.size(), Color.GREEN)
		append_output("╚════════════════════╝", Color.CYAN)
		append_output("")
		return
	
	# SUM(column)
	var sum_start = upper_query.find("SUM(")
	if sum_start != -1:
		var sum_end = upper_query.find(")", sum_start)
		var column = query.substr(sum_start + 5, sum_end - sum_start - 5).to_lower()
		var total = 0.0
		for row in data:
			if row.has(column):
				total += float(row[column])
		append_output("SUM: %.2f" % total, Color.GREEN)
		append_output("")
		return
	
	# AVG(column)
	var avg_start = upper_query.find("AVG(")
	if avg_start != -1:
		var avg_end = upper_query.find(")", avg_start)
		var column = query.substr(avg_start + 5, avg_end - avg_start - 5).to_lower()
		if data.size() > 0:
			var total = 0.0
			for row in data:
				if row.has(column):
					total += float(row[column])
			append_output("AVG: %.2f" % (total / data.size()), Color.GREEN)
		else:
			append_output("AVG: 0", Color.YELLOW)
		append_output("")
		return
	
	# MAX(column)
	var max_start = upper_query.find("MAX(")
	if max_start != -1:
		var max_end = upper_query.find(")", max_start)
		var column = query.substr(max_start + 5, max_end - max_start - 5).to_lower()
		var max_val = -999999999.0
		for row in data:
			if row.has(column):
				max_val = max(max_val, float(row[column]))
		append_output("MAX: %.2f" % max_val, Color.GREEN)
		append_output("")
		return
	
	# MIN(column)
	var min_start = upper_query.find("MIN(")
	if min_start != -1:
		var min_end = upper_query.find(")", min_start)
		var column = query.substr(min_start + 5, min_end - min_start - 5).to_lower()
		var min_val = 999999999.0
		for row in data:
			if row.has(column):
				min_val = min(min_val, float(row[column]))
		append_output("MIN: %.2f" % min_val, Color.GREEN)
		append_output("")
		return
		
func apply_group_by(data: Array, group_clause: String) -> Array:
	var grouped = {}
	
	for row in data:
		if row.has(group_clause):
			var key = str(row[group_clause])
			if not grouped.has(key):
				grouped[key] = []
			grouped[key].append(row)
	
	# Возвращаем по одной записи на группу
	var result = []
	for key in grouped.keys():
		result.append(grouped[key][0])
	
	return result
	
func apply_distinct(data: Array) -> Array:
	var seen = {}
	var result = []
	
	for row in data:
		var key = str(row)
		if not seen.has(key):
			seen[key] = true
			result.append(row)
	
	return result
	
