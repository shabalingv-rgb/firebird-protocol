extends Node

const DB_PATH := "user://game_content.db"
const SQL_IMPORT_PATH := "res://scripts/database/game_content_sqlite.sql"

var db: SQLite
var db_connected: bool = false
var is_initialized: bool = false
# Кэшированные данные
var cached_days: Array = []
var cached_emails: Array = []
var cached_quests: Array = []
var cached_news: Array = []
var cached_dossiers: Array = []
var cached_events: Array = []
var cached_endings: Array = []
var cached_sql_commands: Array = []

signal database_ready()


func _ready():
	print("🗄️ Database Manager загружен")
	connect_database()


func connect_database() -> bool:
	db = SQLite.new()
	db.path = DB_PATH
	
	var result = db.open_db()
	db_connected = result
	
	if result:
		print("✅ Подключение к БД успешно")
		initialize_database()
		return true
	else:
		print("❌ Ошибка подключения")
		return false


func initialize_database():
	print("📋 Инициализация БД...")
	
	# ⭐ ДОБАВЬ ЭТО - очистка старой БД
	var dir = DirAccess.open("user://")
	if dir.file_exists("game_content.db"):
		print("🗑️ Удаляю старую БД...")
		dir.remove("game_content.db")
	
	# Переподключаемся к чистой БД
	db.close_db()
	db = SQLite.new()
	db.path = DB_PATH
	db.open_db()
	
	create_tables()
	import_content_from_sql()
	
	is_initialized = true
	database_ready.emit()
	print("✅ БД готова к работе")


func create_tables():
	print("📋 Создание таблиц...")
	
	var tables = [
		"CREATE TABLE IF NOT EXISTS game_days (id INTEGER PRIMARY KEY AUTOINCREMENT, role TEXT, day_number INTEGER, title TEXT, description TEXT, is_playable INTEGER DEFAULT 1, alternative_activity TEXT, UNIQUE(role, day_number))",
		"CREATE TABLE IF NOT EXISTS emails (id INTEGER PRIMARY KEY AUTOINCREMENT, day_id INTEGER, sender TEXT, sender_email TEXT, subject TEXT, body TEXT, email_type TEXT, is_required INTEGER DEFAULT 1, sort_order INTEGER DEFAULT 0, unlock_condition TEXT)",
		"CREATE TABLE IF NOT EXISTS quests (id INTEGER PRIMARY KEY AUTOINCREMENT, email_id INTEGER, title TEXT, description TEXT, sql_template TEXT, expected_rows INTEGER, expected_columns TEXT, difficulty TEXT, time_limit_minutes INTEGER DEFAULT 0, sql_skills_required TEXT, story_flags_set TEXT, story_flags_required TEXT, moral_choice INTEGER DEFAULT 0, consequences TEXT)",
		"CREATE TABLE IF NOT EXISTS sql_commands (id INTEGER PRIMARY KEY AUTOINCREMENT, command_name TEXT, category TEXT, firebird_specific INTEGER DEFAULT 0, introduced_day INTEGER, times_used INTEGER DEFAULT 0, last_used_day INTEGER DEFAULT 0)",
		"CREATE TABLE IF NOT EXISTS player_progress (id INTEGER PRIMARY KEY AUTOINCREMENT, save_slot INTEGER DEFAULT 1, current_role TEXT, current_day INTEGER DEFAULT 1, violations INTEGER DEFAULT 0, trust_level INTEGER DEFAULT 50, flags_unlocked TEXT, quests_completed TEXT, endings_unlocked TEXT, total_playtime_minutes INTEGER DEFAULT 0, last_saved DATETIME DEFAULT CURRENT_TIMESTAMP)",
		"CREATE TABLE IF NOT EXISTS player_choices (id INTEGER PRIMARY KEY AUTOINCREMENT, quest_id INTEGER, choice_type TEXT, choice_value TEXT, day_id INTEGER, consequences_applied INTEGER DEFAULT 0, choice_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)",
		"CREATE TABLE IF NOT EXISTS news_articles (id INTEGER PRIMARY KEY AUTOINCREMENT, day_id INTEGER, title TEXT, content TEXT, category TEXT, is_visible INTEGER DEFAULT 1, visibility_condition TEXT, publish_date DATE)",
		"CREATE TABLE IF NOT EXISTS employee_dossiers (id INTEGER PRIMARY KEY AUTOINCREMENT, employee_name TEXT, position TEXT, department TEXT, hire_date DATE, status TEXT, dossier_text TEXT, unlock_condition TEXT, is_mysterious INTEGER DEFAULT 0)",
		"CREATE TABLE IF NOT EXISTS random_events (id INTEGER PRIMARY KEY AUTOINCREMENT, event_name TEXT, event_type TEXT, min_day INTEGER, max_day INTEGER, trigger_chance REAL, effect_description TEXT, can_occur_multiple INTEGER DEFAULT 0)",
		"CREATE TABLE IF NOT EXISTS endings (id INTEGER PRIMARY KEY AUTOINCREMENT, ending_name TEXT, ending_type TEXT, role_required TEXT, conditions_required TEXT, description TEXT, is_secret INTEGER DEFAULT 0)"
	]
	
	for table_sql in tables:
		db.query(table_sql)
	
	print("✅ Таблицы созданы")


func import_content_from_sql():
	print("📥 Импорт контента...")
	
	if not FileAccess.file_exists(SQL_IMPORT_PATH):
		print("❌ Файл не найден: ", SQL_IMPORT_PATH)
		return
	
	var file = FileAccess.open(SQL_IMPORT_PATH, FileAccess.READ)
	if not file:
		print("❌ Не удалось открыть файл")
		return
	
	var sql_content = file.get_as_text()
	file.close()
	
	print("📄 Файл прочитан: ", sql_content.length(), " символов")
	
	var commands = parse_sql_commands(sql_content)
	print("🔧 Найдено команд: ", commands.size())
	
	# Считаем INSERT в emails
	var email_inserts = 0
	for cmd in commands:
		if "INSERT INTO emails" in cmd:
			email_inserts += 1
	print("📧 INSERT в emails: ", email_inserts)
	
	var success_count = 0
	var error_count = 0
	var error_commands: Array[String] = []
	
	for command in commands:
		var result = db.query(command)
		if result:
			success_count += 1
		else:
			error_count += 1
			if command.length() > 100:
				error_commands.append(command.substr(0, 100) + "...")
			else:
				error_commands.append(command)
	
	print("✅ Импорт завершён: ", success_count, " успешно, ", error_count, " ошибок")
	
	if error_count > 0:
		print("\n❌ Ошибочные команды:")
		for i in range(min(5, error_commands.size())):  # Показываем первые 5
			print("  ", i+1, ". ", error_commands[i])
		print("")
	
	# ✅ Загружаем в кэш после импорта
	print("📦 Начинаем загрузку в кэш...")
	load_content_to_cache()
	
func parse_sql_commands(sql_content: String) -> Array[String]:
	var commands: Array[String] = []
	var current_command = ""
	
	var lines = sql_content.split("\n")
	
	for line in lines:
		if line.strip_edges().begins_with("--"):
			continue
		
		current_command += line + "\n"
		
		if line.strip_edges().ends_with(";"):
			var cmd = current_command.strip_edges().trim_suffix(";")
			if not cmd.is_empty():
				commands.append(cmd)
			current_command = ""
	
	return commands


func close_database():
	if db:
		db.close_db()
		db_connected = false
		print("🔒 БД закрыта")

# ============================================
# МЕТОДЫ ДЛЯ ПОЛУЧЕНИЯ ДАННЫХ
# ============================================

func get_emails_for_day(day_id: int) -> Array:
	"""Получить письма для дня из кэша"""
	var result: Array = []
	for email in cached_emails:
		if email.day_id == day_id:
			result.append(email)
	return result
	
func get_quest_for_email(email_id: int) -> Dictionary:
	"""Получить задание для письма из кэша"""
	for quest in cached_quests:
		if quest.email_id == email_id:
			return quest
	return {}
	
func get_random_event_for_day(day: int) -> Dictionary:
	"""Получить случайное событие из кэша"""
	for event in cached_events:
		if day >= event.min_day and day <= event.max_day:
			if randf() < event.trigger_chance:
				return event
	return {}

func load_content_to_cache():
	"""Загрузка данных в кэш"""
	print("📦 Загрузка в кэш...")
	
	# Проверяем что БД подключена
	if not db or not db_connected:
		print("❌ БД не подключена!")
		return
	
	# Дни
	print("   📅 Загрузка дней...")
	var days_result = db.query("SELECT * FROM game_days ORDER BY day_number")
	print("   📅 Результат: ", days_result, " тип: ", typeof(days_result))
	if days_result and typeof(days_result) == TYPE_ARRAY:
		cached_days = days_result
		print("   📅 Дней: ", cached_days.size())
	else:
		print("   ⚠️ Дней не загружено")
	
	# Письма
	print("   📧 Загрузка писем...")
	var emails_result = db.query("SELECT * FROM emails ORDER BY day_id, sort_order")
	print("   📧 Результат: ", emails_result, " тип: ", typeof(emails_result))
	if emails_result and typeof(emails_result) == TYPE_ARRAY:
		cached_emails = emails_result
		print("   📧 Писем: ", cached_emails.size())
		
		# Проверяем письма для дня 1
		var day1_emails = 0
		for email in cached_emails:
			if email.day_id == 1:
				day1_emails += 1
		print("   📧 Писем для дня 1: ", day1_emails)
	else:
		print("   ⚠️ Писем не загружено")
	
	# Задания
	print("   🎯 Загрузка заданий...")
	var quests_result = db.query("SELECT * FROM quests ORDER BY id")
	if quests_result and typeof(quests_result) == TYPE_ARRAY:
		cached_quests = quests_result
		print("   🎯 Заданий: ", cached_quests.size())
	else:
		print("   ⚠️ Заданий не загружено")
	
	print("✅ Кэш загружен")
