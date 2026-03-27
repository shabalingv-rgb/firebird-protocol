extends Node

var game_time: Dictionary = {"hour": 9, "minute": 0, "day": 1}
var violations: int = 0
var flags: Dictionary = {}
var current_quest: Dictionary = {}

# Сигналы для обновления UI (например, счетчика нарушений)
signal security_violation_changed(count)
signal day_changed(day)
signal story_flag_changed(flag_name, value)

# Конфигурация безопасности
const MAX_VIOLATIONS := 3

# Переменные состояния
var current_campaign: int = 1 # 1, 2 или 3
var current_day: int = 0
var security_violations: int = 0
var is_game_over: bool = false

# Флаги сюжета (ключ: значение)
# Пример: "day_zero_passed": true, "journalist_contacted": false
var story_flags: Dictionary = {}

# Сохранение прогресса (флаги, которые влияют на следующие кампании)
var persistent_flags: Dictionary = {}

# ⭐ ДОБАВЬ ЭТО:
var terminal_preset_query: String = ""

func _ready():
	# Инициализация при старте игры
	load_game_state()

func add_violation():
	security_violations += 1
	security_violation_changed.emit(security_violations)
	if security_violations >= MAX_VIOLATIONS:
		trigger_game_over("security")

func reset_violations():
	security_violations = 0
	security_violation_changed.emit(0)

func set_flag(flag_name: String, value: bool):
	story_flags[flag_name] = value
	story_flag_changed.emit(flag_name, value)
	# Если флаг важен для будущих кампаний, копируем его в постоянные
	if flag_name.begins_with("persistent_"):
		persistent_flags[flag_name] = value

func get_flag(flag_name: String, default: bool = false) -> bool:
	return story_flags.get(flag_name, default)

func get_persistent_flag(flag_name: String, default: bool = false) -> bool:
	return persistent_flags.get(flag_name, default)

func next_day():
	current_day += 1
	day_changed.emit(current_day)
	# Здесь можно добавить логику автосохранения в БД

func trigger_game_over(reason: String):
	is_game_over = true
	# Запуск сцены концовки
	# get_tree().change_scene_to_file("res://scenes/endings/" + reason + ".tscn")
	print("GAME OVER: Reason - ", reason)

func save_game_state():
	# Временное сохранение в JSON, позже заменим на Firebird
	var file = FileAccess.open("user://save_state.json", FileAccess.WRITE)
	var data = {
		"campaign": current_campaign,
		"day": current_day,
		"violations": security_violations,
		"flags": story_flags,
		"persistent": persistent_flags
	}
	file.store_string(JSON.stringify(data))
	file.close()

func load_game_state():
	if FileAccess.file_exists("user://save_state.json"):
		var file = FileAccess.open("user://save_state.json", FileAccess.READ)
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		file.close()
		if parse_result == OK:
			var data = json.get_data()
			current_campaign = data.get("campaign", 1)
			current_day = data.get("day", 0)
			security_violations = data.get("violations", 0)
			story_flags = data.get("flags", {})
			persistent_flags = data.get("persistent", {})
			security_violation_changed.emit(security_violations)

func advance_game_time(hours: int):
	"""Продвинуть игровое время на N часов"""
	game_time.hour += hours
	while game_time.hour >= 24:
		game_time.hour -= 24
		game_time.day += 1
		on_new_day()
	
	print("⏰ Время продвинуто на ", hours, " часов")
	print("   Текущее время: ", game_time.hour, ":", game_time.minute)

func on_new_day():
	print("📅 Начался новый день: ", game_time.day)
