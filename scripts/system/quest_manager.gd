extends Node
## Менеджер заданий - управляет квестами, прогрессом и нарушениями

# Сигналы
signal quest_started(quest: Dictionary)
signal quest_completed(quest: Dictionary, success: bool)
signal day_completed(day_number: int)
signal violation_added(count: int, reason: String)
#signal role_completed(role: String)

# Текущее состояние
var current_role: String = "employee"
var current_day: int = 1
var active_quest: Dictionary = {}
var violations: int = 0
var trust_level: int = 50
var completed_quests: Array = []
var story_flags: Dictionary = {}

# Константы
const MAX_VIOLATIONS := 5
const TRUST_DECREASE_PER_VIOLATION := 10


func _ready():
	print("📋 Quest Manager загружен")
	
	# Загружаем прогресс если есть
	if DatabaseManager and DatabaseManager.is_initialized:
		load_progress()


func start_day(day_number: int):
	"""Начало нового дня"""
	current_day = day_number
	print("📅 Начало дня ", day_number)
	
	# Загружаем задания на этот день
	load_quests_for_day(day_number)
	
	# Проверяем случайные события
	check_random_events()


func load_quests_for_day(day_number: int):
	"""Загрузка заданий для дня"""
	var emails = DatabaseManager.get_emails_for_day(day_number)
	
	for email in emails:
		var quest = DatabaseManager.get_quest_for_email(email.id)
		if quest and not quest.is_empty():
			if quest.get("is_required", true):
				active_quest = quest
				quest_started.emit(quest)
				print("🎯 Активное задание: ", quest.title)
				return
	
	print("ℹ️ Нет обязательных заданий на день ", day_number)


func check_quest_completion(sql_result: Array, expected_rows: int) -> bool:
	"""Проверка выполнения задания"""
	if active_quest.is_empty():
		return false
	
	var success = (sql_result.size() == expected_rows)
	
	if success:
		complete_quest(true)
	else:
		print("⚠️ Ожидается ", expected_rows, " строк, получено ", sql_result.size())
	
	return success


func complete_quest(success: bool):
	"""Завершение задания"""
	if active_quest.is_empty():
		return
	
	if success:
		print("✅ Задание выполнено: ", active_quest.title)
		
		# Добавляем в completed
		completed_quests.append(active_quest.id)
		
		# Сохраняем story flags
		if active_quest.has("story_flags_set"):
			var flags = active_quest.story_flags_set.split(",")
			for flag in flags:
				story_flags[flag.strip_edges()] = true
		
		# Проверяем завершение дня
		check_day_completion()
		
		quest_completed.emit(active_quest, true)
	else:
		print("❌ Задание провалено")
		quest_completed.emit(active_quest, false)


func check_day_completion():
	"""Проверка завершены ли все задания дня"""
	# Получаем все обязательные задания дня
	var emails = DatabaseManager.get_emails_for_day(current_day)
	var required_quests = []
	
	for email in emails:
		var quest = DatabaseManager.get_quest_for_email(email.id)
		if quest and quest.get("is_required", true):
			required_quests.append(quest.id)
	
	# Проверяем все ли выполнены
	var all_completed = true
	for quest_id in required_quests:
		if not completed_quests.has(quest_id):
			all_completed = false
			break
	
	if all_completed:
		print("✅ День ", current_day, " завершён!")
		day_completed.emit(current_day)
		
		# Сохраняем прогресс
		save_progress()


func next_day():
	"""Переход к следующему дню"""
	if current_day >= 20:
		print("🏁 Конец игры!")
		return
	
	current_day += 1
	start_day(current_day)


func add_violation(reason: String):
	"""Добавление нарушения"""
	violations += 1
	trust_level = max(0, trust_level - TRUST_DECREASE_PER_VIOLATION)
	
	print("⚠️ Нарушение! ", reason)
	print("   Всего нарушений: ", violations)
	print("   Уровень доверия: ", trust_level)
	
	violation_added.emit(violations, reason)
	
	# Проверяем Game Over
	if violations >= MAX_VIOLATIONS:
		trigger_game_over()


func trigger_game_over():
	"""Game Over - слишком много нарушений"""
	print("💀 GAME OVER - Слишком много нарушений!")
	
	# Здесь будет показ экрана Game Over
	# get_tree().change_scene_to_file("res://scenes/game_over.tscn")


func save_progress():
	"""Сохранение прогресса"""
	if not DatabaseManager:
		return
	
	DatabaseManager.save_player_progress(
		current_role,
		current_day,
		violations,
		story_flags,
		completed_quests
	)
	
	print("💾 Прогресс сохранён")


func load_progress():
	"""Загрузка прогресса"""
	if not DatabaseManager:
		return
	
	var progress = DatabaseManager.load_player_progress()
	
	current_role = progress.get("current_role", "employee")
	current_day = progress.get("current_day", 1)
	violations = progress.get("violations", 0)
	trust_level = progress.get("trust_level", 50)
	story_flags = progress.get("flags_unlocked", {})
	completed_quests = progress.get("quests_completed", [])
	
	print("💾 Прогресс загружен: День ", current_day, ", Нарушения: ", violations)


func reset_progress():
	"""Сброс прогресса"""
	current_role = "employee"
	current_day = 1
	active_quest = {}
	violations = 0
	trust_level = 50
	completed_quests = []
	story_flags = {}
	
	print("🗑️ Прогресс сброшен")


func check_random_events():
	"""Проверка случайных событий"""
	var event = DatabaseManager.get_random_event_for_day(current_day)
	
	if event and not event.is_empty():
		print("🎲 Случайное событие: ", event.event_name)
		# Здесь будет обработка события
		# show_event_dialog(event)


func get_quest_status() -> Dictionary:
	"""Получение статуса заданий"""
	return {
		"current_day": current_day,
		"current_role": current_role,
		"active_quest": active_quest,
		"violations": violations,
		"trust_level": trust_level,
		"completed_quests": completed_quests.size(),
		"story_flags": story_flags.size()
	}


func has_story_flag(flag_name: String) -> bool:
	"""Проверка наличия story flag"""
	return story_flags.get(flag_name, false)


func set_story_flag(flag_name: String, value: bool = true):
	"""Установка story flag"""
	story_flags[flag_name] = value
	print("🚩 Story flag установлен: ", flag_name)
