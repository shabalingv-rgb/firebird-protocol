extends Node

signal database_ready()
signal content_loaded()

var is_initialized: bool = false
var cached_days: Array = []
var cached_emails: Array = []
var cached_quests: Array = []

func _ready():
	print("🗄️ Database Manager загружен (временная версия)")
	# Имитируем загрузку
	await get_tree().create_timer(0.5).timeout
	is_initialized = true
	database_ready.emit()
	print("✅ БД готова (заглушка)")


func get_emails_for_day(day_id: int) -> Array:
	print("📧 Запрос писем для дня ", day_id)
	# ВРЕМЕННО: возвращаем пустой массив
	# Потом подключим к C#
	return []


func get_quest_for_email(email_id: int) -> Dictionary:
	# ВРЕМЕННО: возвращаем пустой словарь
	return {}


func load_player_progress(save_slot: int = 1) -> Dictionary:
	return {
		"current_day": 1,
		"violations": 0,
		"trust_level": 50,
		"flags_unlocked": {},
		"quests_completed": []
	}


func save_player_progress(role: String, day: int, violations: int, flags: Dictionary, quests: Array):
	print("💾 Прогресс сохранён (заглушка): день=", day)


func track_sql_usage(command_name: String, day: int):
	print("📊 SQL команда: ", command_name)


func get_random_event_for_day(day: int) -> Dictionary:
	return {}
