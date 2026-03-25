extends Node

# Текущие активные задания
var active_quests: Array[Dictionary] = []
var completed_quests: Array[String] = []

# База всех заданий
var quest_database: Array[Dictionary] = [
	{
		"id": "day1_find_high_salary",
		"title": "Найти высокооплачиваемых сотрудников",
		"description": "Найдите всех сотрудников с зарплатой выше 80000",
		"sql_template": "SELECT * FROM employees WHERE salary > 80000",
		"expected_rows": 1,
		"difficulty": "easy",
		"day": 1,
		"story_flags": {
			"day1_completed": true
		}
	},
	{
		"id": "day2_count_by_department",
		"title": "Статистика по отделам",
		"description": "Посчитайте количество сотрудников в каждом отделе",
		"sql_template": "SELECT department, COUNT(*) FROM employees GROUP BY department",
		"expected_rows": 3,
		"difficulty": "medium",
		"day": 2,
		"story_flags": {
			"day2_completed": true
		}
	},
	{
		"id": "day3_find_suspicious",
		"title": "Подозрительные записи",
		"description": "Найдите всех сотрудников IT отдела с зарплатой выше 75000",
		"sql_template": "SELECT * FROM employees WHERE department = 'IT' AND salary > 75000",
		"expected_rows": 2,
		"difficulty": "hard",
		"day": 3,
		"moral_choice": true,
		"story_flags": {
			"found_anomalies": true,
			"reported_anomalies": false
		}
	}
]

func _ready():
	print(" Quest Manager загружен!")
	print("Активных заданий: ", quest_database.size())
	# Загружаем задания для текущего дня
	load_quests_for_day(GameState.current_day)

func load_quests_for_day(day: int):
	print("📅 Загружаем задания для дня: ", day)
	active_quests.clear()
	
	for quest in quest_database:
		print("  Проверяем задание: ", quest.id, " (день ", quest.day, ")")
		if quest.day == day and not completed_quests.has(quest.id):
			active_quests.append(quest)
			print("    ✅ Добавлено активное задание: ", quest.title)
	
	print("  Всего активных заданий: ", active_quests.size())
	
func check_quest_completion(query_data: Array, query: String) -> Dictionary:
	var result = {
		"completed": false,
		"quest_id": null,
		"message": ""
	}
	
	print("🔍 Проверяем задание...")
	print("  Активных заданий: ", active_quests.size())
	print("  Запрос игрока: ", query)
	
	for quest in active_quests:
		print("  Проверяем шаблон: ", quest.sql_template)
		
		if is_query_similar(query, quest.sql_template):
			print("  ✅ Запрос похож на шаблон!")
			if validate_result(query_data, quest):
				print("  ✅ Результат валиден!")
				complete_quest(quest.id)
				result.completed = true
				result.quest_id = quest.id
				result.message = "✅ Задание выполнено: " + quest.title
				
				# Устанавливаем флаги сюжета
				for flag in quest.story_flags.keys():
					GameState.set_flag(flag, quest.story_flags[flag])
	
	return result
	
	
func is_query_similar(user_query: String, template: String) -> bool:
	# Нормализуем: убираем точку с запятой, пробелы, приводим к верхнему регистру
	var norm_user = user_query.to_upper().replace(";", "").strip_edges()
	var norm_template = template.to_upper().replace(";", "").strip_edges()
	
	# Убираем множественные пробелы
	while norm_user.contains("  "):
		norm_user = norm_user.replace("  ", " ")
	while norm_template.contains("  "):
		norm_template = norm_template.replace("  ", " ")
	
	print("  Нормализованный запрос: '", norm_user, "'")
	print("  Нормализованный шаблон: '", norm_template, "'")
	print("  Совпадение: ", norm_user == norm_template)
	
	return norm_user == norm_template
	
func validate_result(query_data: Array, quest: Dictionary) -> bool:
	print("  🔍 Валидация результата...")
	print("  Получено строк: ", query_data.size())
	print("  Ожидаемо строк: ", quest.expected_rows)
	
	# Проверяем количество строк
	var result = query_data.size() >= quest.expected_rows
	print("  Результат валидации: ", result)
	
	return result

func complete_quest(quest_id: String):
	if completed_quests.has(quest_id):
		return  # Уже выполнено
	
	completed_quests.append(quest_id)
	
	# Удаляем из активных
	for i in range(active_quests.size()):
		if active_quests[i].id == quest_id:
			active_quests.remove_at(i)
			break
	
	print("✅ Задание выполнено: ", quest_id)
	
	# ⭐ ПРОВЕРЯЕМ все ли задания дня выполнены
	if is_day_completed():
		on_day_completed()
		
func is_day_completed() -> bool:
	# Проверяем, есть ли ещё невыполненные задания для текущего дня
	for quest in quest_database:
		if quest.day == GameState.current_day and not completed_quests.has(quest.id):
			return false
	return true
	

		
func on_day_completed():
	print("🎉 День ", GameState.current_day, " завершён!")
	
	# ⭐ УБЕРИ advance_game_time() отсюда - это отдельная функция
	# GameState.advance_game_time(8)
	
	# Переходим к следующему дню
	GameState.current_day += 1
	print("📅 Начался новый день: ", GameState.current_day)
	
	# Выдаём новые задания
	if GameState.current_day <= 3:
		issue_quests_for_day(GameState.current_day)

func issue_quests_for_day(day: int):
	print("📬 Выдаём задания на день ", day)
	
	# Очищаем старые активные задания
	active_quests.clear()
	
	var quests_issued = 0
	
	for quest in quest_database:
		if quest.day == day and not completed_quests.has(quest.id):
			create_quest_email(quest)
			active_quests.append(quest)
			quests_issued += 1
			print("  ✅ Задание: ", quest.title)
			
	if quests_issued == 0:
		print("  ℹ️ Нет новых заданий для дня ", day)

func create_quest_email(quest: Dictionary):
	# Создаём письмо с заданием
	var email = {
		"from": "manager@nii-firebird.gov",
		"subject": "Задание: " + quest.title,
		"body": """
Уважаемый сотрудник,

Ваше задание на сегодня:

{description}

Требования:
- Выполните SQL-запрос в терминале
- Убедитесь в корректности результатов
- Отправьте отчёт после выполнения

С уважением,
Ваш руководитель

---
ID задания: {id}
Сложность: {difficulty}
		""".format({
			"description": quest.description,
			"id": quest.id,
			"difficulty": quest.difficulty
		}),
		"quest_id": quest.id,
		"read": false
	}
	
	# Добавляем в систему почты
	EmailSystem.add_email(email)
	print("  📧 Создано письмо с заданием: ", quest.title)
	
func is_quest_completed(_quest_id: String) -> bool:
	# Проверяем, выполнял ли игрок правильный SQL запрос
	# Для этого можно хранить историю запросов
	# Пока просто возвращаем true для теста
	return true

func get_quest_by_id(quest_id: String) -> Dictionary:
	for quest in quest_database:
		if quest.id == quest_id:
			return quest
	return {}
