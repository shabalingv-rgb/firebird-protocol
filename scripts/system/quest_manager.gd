extends Node
## Менеджер заданий - управляет квестами, прогрессом и нарушениями

# Сигналы
signal quest_started(quest: Dictionary)
signal quest_completed(quest: Dictionary, success: bool)
signal day_completed(day_number: int)
signal violation_added(count: int, reason: String)
#signal role_completed(role: String)

# Autoload DatabaseManager = C# FirebirdDatabase (см. project.godot → Autoload)
# Текущее состояние
var player_role: String = "employee"
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
	
	# Временно убираем проверку is_initialized
	# Загружаем прогресс если есть
	if DatabaseManager:
		# Ждём немного пока БД инициализируется
		await get_tree().create_timer(0.5).timeout
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
	var emails = DatabaseManager.GetEmailsForDay(day_number)
	
	for email in emails:
		# Пытаемся взять ID или id (Firebird любит заглавные)
		var email_id = email.get("ID", email.get("id", -1))
		
		#Внимание: Тут должен вызываться метод получения ЗАДАНИЯ
		var quest = DatabaseManager.GetQuestForEmail(email_id)
		
		if quest and not quest.is_empty():
			#Проверяем заголовок задания (опять же учиытваем регистр)
			var is_required = quest.get("IS_REQUIRED", quest.get("is_required", true))
			var title = quest.get("TITLE", quest.get("title", "Без названия"))
			
			if is_required:
				active_quest = quest
				quest_started.emit(quest)
				print("🎯 Активное задание: ", title)
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
	if active_quest.is_empty():
		return

	if success:
		var qtitle = active_quest.get("TITLE", active_quest.get("title", ""))
		print("✅ Задание выполнено: ", qtitle)
		var qid = active_quest.get("ID", active_quest.get("id", -1))
		completed_quests.append(qid)
		
		# Сохраняем story flags
		var raw_sf = active_quest.get("STORY_FLAGS_SET", active_quest.get("story_flags_set", ""))
		if str(raw_sf).length() > 0:
			var flags = str(raw_sf).split(",")
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
	var emails = DatabaseManager.GetEmailsForDay(current_day)
	var required_quests = []
	
	for email in emails:
		var eid = email.get("ID", email.get("id", -1))
		var quest = DatabaseManager.GetQuestForEmail(int(eid))
		if quest == null or quest.is_empty():
			continue
		var req = quest.get("IS_REQUIRED", quest.get("is_required", true))
		if req:
			var qid = quest.get("ID", quest.get("id", -1))
			required_quests.append(qid)
	
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
	
	DatabaseManager.SavePlayerProgress(
		player_role,
		current_day,
		violations,
		story_flags,
		completed_quests
	)
	
	print("💾 Прогресс сохранён")



func load_progress():
	"""Загрузка прогресса из C# (столбцы БД могут быть в разном регистре)."""
	if not DatabaseManager:
		print("❌ DatabaseManager не найден!")
		return

	var progress = DatabaseManager.LoadPlayerProgress(1)

	if progress == null:
		print("⚠️ База вернула пустой результат")
		return

	player_role = str(progress.get("USER_ROLE", progress.get("player_role", "employee")))
	current_day = int(progress.get("CURRENT_DAY", progress.get("current_day", 1)))
	violations = int(progress.get("VIOLATIONS", progress.get("violations", 0)))
	trust_level = int(progress.get("TRUST_LEVEL", progress.get("trust_level", 50)))
	
	var raw_flags = progress.get("FLAGS_UNLOCKED", progress.get("flags_unlocked", "{}"))
	var parsed_flags = JSON.parse_string(str(raw_flags))
	if parsed_flags is Dictionary:
		story_flags = parsed_flags
	else:
		story_flags = {}

	var raw_quests = progress.get("QUESTS_COMPLETED", progress.get("quests_completed", "[]"))
	var parsed_quests = JSON.parse_string(str(raw_quests))
	if parsed_quests is Array:
		completed_quests = parsed_quests
	else:
		completed_quests = []
	
	print("💾 Прогресс загружен: День ", current_day, ", Нарушения: ", violations)

func reset_progress():
	"""Сброс прогресса"""
	player_role = "employee"
	current_day = 1
	active_quest = {}
	violations = 0
	trust_level = 50
	completed_quests = []
	story_flags = {}
	
	print("🗑️ Прогресс сброшен")


func check_random_events():
	"""Проверка случайных событий"""
	var event = DatabaseManager.GetRandomEventForDay(current_day)
	
	if event and not event.is_empty():
		var ename = event.get("EVENT_NAME", event.get("event_name", ""))
		print("🎲 Случайное событие: ", ename)
		# Здесь будет обработка события
		# show_event_dialog(event)


func get_quest_status() -> Dictionary:
	"""Получение статуса заданий"""
	return {
		"current_day": current_day,
		"player_role": player_role,
		"active_quest": active_quest,
		"violations": violations,
		"trust_level": trust_level,
		"completed_quests": completed_quests.size(),
		"story_flags": story_flags.size()
	}


func is_quest_completed(quest_id: Variant) -> bool:
	"""Проверка, отмечено ли задание выполненным (для кнопки отчёта в почте)."""
	var want = str(quest_id)
	for q in completed_quests:
		if str(q) == want:
			return true
	return false


func has_story_flag(flag_name: String) -> bool:
	"""Проверка наличия story flag"""
	return story_flags.get(flag_name, false)


func set_story_flag(flag_name: String, value: bool = true):
	"""Установка story flag"""
	story_flags[flag_name] = value
	print("🚩 Story flag установлен: ", flag_name)
