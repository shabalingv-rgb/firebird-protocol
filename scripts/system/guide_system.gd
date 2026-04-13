extends Node

var unlocked_topics: Array[String] = []
var read_articles: Array[String] = []

# Кэш тем из БД
var guide_topics_db_cache: Array = []

# Текущий день игрока (обновляется из QuestManager)
var current_day: int = 1

# Все темы загружаются ТОЛЬКО из БД
var guide_database: Dictionary = {}

func _ready():
	print("📖 Guide System загружен!")

	# Загружаем темы из БД (обязательно)
	_load_topics_from_database()

	# Подписываемся на завершение загрузки прогресса
	if QuestManager:
		QuestManager.progress_loaded.connect(_on_quest_progress_loaded)

	# Если БД ещё не готова — подписываемся на сигнал готовности
	if DatabaseManager and not DatabaseManager.IsInitialized:
		DatabaseManager.DatabaseReady.connect(_on_database_ready)

func _on_database_ready():
	print("📖 БД стала готова — перезагружаем темы справки...")
	_load_topics_from_database()
	# Разблокировка будет вызвана после загрузки прогресса QuestManager

func _on_quest_progress_loaded(day: int):
	print("📖 Прогресс квестов загружен (день ", day, ") — обновляем разблокировку тем...")
	_unlock_topics_for_current_day()

# === ЗАГРУЗКА ТЕМ ИЗ БАЗЫ ДАННЫХ ===
func _load_topics_from_database():
	if not DatabaseManager or not DatabaseManager.IsInitialized:
		print("⚠️ БД не готова, темы не загружены!")
		return

	print("📚 Загрузка тем справки из Firebird...")

	# Загружаем все темы (без фильтрации по дню — фильтрация будет при разблокировке)
	guide_topics_db_cache = DatabaseManager.call("GetAvailableGuideTopics", 999)

	if guide_topics_db_cache.is_empty():
		print("⚠️ Тем в БД не найдено! Справочник будет пуст.")
		return

	# Заменяем guide_database данными из БД
	guide_database.clear()

	for topic_data in guide_topics_db_cache:
		var topic = topic_data as Dictionary
		var topic_key = str(topic.get("TOPIC_KEY", topic.get("topic_key", "")))
		var title = str(topic.get("TITLE", topic.get("title", "")))
		var content = str(topic.get("CONTENT", topic.get("content", "")))
		var example = str(topic.get("SQL_EXAMPLE", topic.get("sql_example", "")))
		var category = _map_category(str(topic.get("CATEGORY", topic.get("category", "sql"))))
		var min_day = int(topic.get("MIN_DAY", topic.get("min_day", 1)))

		if topic_key.is_empty():
			continue

		guide_database[topic_key] = {
			"title": title,
			"category": category,
			"content": content,
			"example": example if example != "" else "",
			"firebird_specific": false,
			"unlock_condition": "day_" + str(min_day) + "_start",
			"min_day": min_day
		}

	print("✅ Загружено тем из БД: ", guide_topics_db_cache.size())

func _map_category(cat: String) -> String:
	match cat:
		"sql": return "basics"
		"tables": return "filtering"
		"game": return "game_mechanics"
		_: return "advanced"

# === РАЗБЛОКИРОВКА ТЕМ ПО ДНЯМ ===
func _unlock_topics_for_current_day():
	# Обновляем текущий день из QuestManager
	if QuestManager:
		current_day = QuestManager.current_day

	print("🔓 Разблокировка тем: current_day=", current_day)

	var unlocked_count = 0

	for topic_id in guide_database.keys():
		var topic = guide_database[topic_id]
		var min_day = topic.get("min_day", 1)

		# Разблокируем если день позволяет
		if current_day >= min_day:
			if not unlocked_topics.has(topic_id):
				unlocked_topics.append(topic_id)
				unlocked_count += 1
				print("  ✅ ", topic_id, " (min_day=", min_day, ")")
		else:
			print("  🔒 ", topic_id, " (min_day=", min_day, ", day=", current_day, ")")

	print("🔓 Разблокировано тем: ", unlocked_count, " (всего в базе: ", guide_database.size(), ")")

# Публичный метод для обновления разблокировок при смене дня
func refresh_unlocked_topics():
	unlocked_topics.clear()
	_unlock_topics_for_current_day()

func unlock_topic(topic_id: String):
	if not unlocked_topics.has(topic_id):
		unlocked_topics.append(topic_id)
		if guide_database.has(topic_id):
			print("📖 Открыта тема: ", guide_database[topic_id].title)

func is_topic_unlocked(topic_id: String) -> bool:
	return unlocked_topics.has(topic_id)

func mark_as_read(article_id: String):
	if not read_articles.has(article_id):
		read_articles.append(article_id)
		print("📚 Прочитано: ", article_id)

func load_topic(topic_key: String):
	"""Загрузка темы из БД"""
	# В полной версии: DatabaseManager.GetGuideTopic(topic_key, current_day)

	# Проверка разблокировки
	if not is_topic_unlocked(topic_key):
		show_locked_message(topic_key)
		return

	# Загрузка контента
	#... код загрузки...

func show_locked_message(topic_key: String):
	"""Показ сообщения что тема заблокирована"""
	print("🔒 Тема заблокирована: ", topic_key)
	# Здесь можно показать UI с сообщением
