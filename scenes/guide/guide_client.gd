extends Control

@onready var search_bar = $Header/SearchBar
@onready var categories_tree = $ContentContainer/Sidebar/CategoriesTree
@onready var progress_label = $ContentContainer/Sidebar/ProgressLabel
@onready var article_title = $MainContent/ContentMargin/VBox/ArticleTitle
@onready var content_label = $MainContent/ContentMargin/VBox/ArticleContent
@onready var code_example = $CodeExample
@onready var prev_button = $NavigationButtons/PrevButton
@onready var next_button = $NavigationButtons/NextButton
@onready var try_button = $TryItButton
@onready var close_button = $Header/CloseButton

var quest_font: FontFile = preload("res://assets/fonts/PressStart2P-Regular.ttf")

# Навигация
var current_topic_id: String = ""
var topic_history: Array[String] = []
var history_index: int = -1

func _ready():
	search_bar.text_changed.connect(_on_search_changed)
	categories_tree.item_selected.connect(_on_category_selected)
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	try_button.pressed.connect(_on_try_it_pressed)
	close_button.pressed.connect(_on_close_pressed)

	# Фокус на поиск при открытии
	search_bar.grab_focus()

	# Обновляем разблокировки из БД при каждом открытии
	if GuideSystem:
		GuideSystem.refresh_unlocked_topics()

	load_guide()
	update_progress()
	update_navigation_buttons()

	search_bar.placeholder_text = "🔍 Поиск по справке..."

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F and (event.ctrl_pressed or event.meta_pressed):
			search_bar.grab_focus()
			search_bar.select_all()
		elif event.keycode == KEY_ESCAPE:
			# Esc → пауз-меню (вместо прямого выхода на рабочий стол)
			var pause_menu = get_node_or_null("/root/PauseMenu")
			if pause_menu and not pause_menu.is_open:
				pause_menu.show_menu()
				get_viewport().set_input_as_handled()  # чтобы PauseMenu не поймал тот же Esc
			else:
				_on_close_pressed()

func load_guide():
	categories_tree.clear()

	# Словарь для групп
	var categories = {}

	# Собираем все разблокированные темы по категориям
	for topic_id in GuideSystem.guide_database:
		if GuideSystem.is_topic_unlocked(topic_id):
			var topic = GuideSystem.guide_database[topic_id]
			var cat = topic.category

			if not categories.has(cat):
				categories[cat] = []
			categories[cat].append(topic_id)

	# Создаём дерево с категориями
	for cat in categories.keys():
		# Корневой элемент категории
		var cat_root = categories_tree.create_item()
		cat_root.set_text(0, get_category_text(cat))
		cat_root.set_selectable(0, false)
		cat_root.set_custom_color(0, Color(0.8, 0.8, 0.8))

		# Элементы категории
		for topic_id in categories[cat]:
			var topic = GuideSystem.guide_database[topic_id]
			var item = categories_tree.create_item(cat_root)
			item.set_text(0, topic.title)
			item.set_metadata(0, topic_id)

			# Подсветка Firebird-специфики
			if topic.get("firebird_specific", false):
				item.set_custom_color(0, Color(0, 0.8, 1))
				
func _on_category_selected():
	var selected = categories_tree.get_selected()
	if selected:
		var topic_id = selected.get_metadata(0)
		if topic_id:
			show_article(topic_id)
			GuideSystem.mark_as_read(topic_id)
			
			# ⭐ НЕ вызываем load_guide() здесь!
			# Просто сбрасываем поиск
			if not search_bar.text.is_empty():
				#search_bar.text = ""
				search_bar.placeholder_text = "🔍 Поиск по справке..."
			
			
func show_article(topic_id: String):
	# Сохраняем историю
	if current_topic_id != topic_id:
		if history_index < topic_history.size() - 1:
			topic_history = topic_history.slice(0, history_index + 1)
		topic_history.append(topic_id)
		history_index = topic_history.size() - 1

	current_topic_id = topic_id

	var topic = GuideSystem.guide_database[topic_id]
	article_title.text = topic.title

	# Очищаем и устанавливаем контент (предотвращает наложение)
	content_label.clear()
	content_label.bbcode_enabled = true
	content_label.text = topic.content

	var example = topic.get("example", "")
	code_example.clear()
	code_example.bbcode_enabled = true
	code_example.text = example

	update_navigation_buttons()
	update_progress()

func update_navigation_buttons():
	prev_button.disabled = history_index <= 0
	next_button.disabled = history_index >= topic_history.size() - 1
				
func _on_prev_pressed():
	if history_index > 0:
		history_index -= 1
		var prev_topic = topic_history[history_index]
		current_topic_id = prev_topic
		var topic = GuideSystem.guide_database[prev_topic]
		article_title.text = topic.title
		content_label.clear()
		content_label.bbcode_enabled = true
		content_label.text = topic.content
		code_example.clear()
		code_example.bbcode_enabled = true
		code_example.text = topic.get("example", "")
		update_navigation_buttons()
		categories_tree.deselect_all()

func _on_next_pressed():
	if history_index < topic_history.size() - 1:
		history_index += 1
		var next_topic = topic_history[history_index]
		current_topic_id = next_topic
		var topic = GuideSystem.guide_database[next_topic]
		article_title.text = topic.title
		content_label.clear()
		content_label.bbcode_enabled = true
		content_label.text = topic.content
		code_example.clear()
		code_example.bbcode_enabled = true
		code_example.text = topic.get("example", "")
		update_navigation_buttons()
		categories_tree.deselect_all()

func _on_try_it_pressed():
	if current_topic_id.is_empty():
		print("⚠️ Нет открытой статьи")
		return
	
	var topic = GuideSystem.guide_database[current_topic_id]
	if topic.has("example") and not topic.example.is_empty():
		# Извлекаем чистый SQL из BBCode
		var sql_example = extract_sql_from_bbcode(topic.example)
		
		if not sql_example.is_empty():
			# Передаём в терминал через GameState
			GameState.terminal_preset_query = sql_example
			
			# Открываем терминал
			get_tree().change_scene_to_file("res://scenes/terminal/terminal.tscn")
			
			print("🔧 Пример отправлен в терминал: ", sql_example)
	else:
		print("⚠️ Для этой статьи нет примера кода")
		# Всё равно открываем терминал
		get_tree().change_scene_to_file("res://scenes/terminal/terminal.tscn")

func extract_sql_from_bbcode(text: String) -> String:
	# Удаляем BBCode теги
	var clean = text.replace("[code]", "").replace("[/code]", "")
	clean = clean.replace("[color=00ff00]", "").replace("[/color]", "")
	clean = clean.replace("[b]", "").replace("[/b]", "")
	clean = clean.replace("[i]", "").replace("[/i]", "")
	
	# Разбиваем на строки
	var lines = clean.split("\n")
	var sql_keywords = ["SELECT", "INSERT", "UPDATE", "DELETE", "CREATE", "ALTER", "DROP"]
	
	# Ищем первую SQL команду
	for line in lines:
		line = line.strip_edges()
		line = line.to_upper()
		
		# Пропускаем комментарии и пустые строки
		if line.is_empty() or line.begins_with("--"):
			continue
		
		# Проверяем, начинается ли с SQL ключевого слова
		for keyword in sql_keywords:
			if line.begins_with(keyword):
				return line.strip_edges()
	
	# Если не нашли, возвращаем первую непустую строку
	for line in lines:
		line = line.strip_edges()
		if not line.is_empty():
			return line
	
	return ""
	
func update_progress():
	var unlocked = GuideSystem.unlocked_topics.size()
	var read = GuideSystem.read_articles.size()
	progress_label.text = "Изучено: %d/%d тем" % [read, unlocked]

func _on_search_changed(new_text: String):
	if new_text.is_empty():
		load_guide()
		return

	categories_tree.clear()

	var search_results_count = 0
	
	# Обновляем разблокировки перед поиском
	if GuideSystem:
		GuideSystem.refresh_unlocked_topics()

	# Поиск по статьям (включая темы из БД)
	for topic_id in GuideSystem.guide_database:
		if GuideSystem.is_topic_unlocked(topic_id):
			var topic = GuideSystem.guide_database[topic_id]

			# Ищем в заголовке, содержании и примере
			var title_match = topic.title.to_lower().contains(new_text.to_lower())
			var content_match = topic.content.to_lower().contains(new_text.to_lower())
			var example_match = false

			if topic.has("example"):
				example_match = topic.example.to_lower().contains(new_text.to_lower())

			if title_match or content_match or example_match:
				# Создаём элемент с иконкой
				var item = categories_tree.create_item()
				var category_icon = get_category_icon(topic.category)
				item.set_text(0, category_icon + " " + topic.title)
				item.set_metadata(0, topic_id)

				# Подсветка Firebird-специфики
				if topic.get("firebird_specific", false):
					item.set_custom_color(0, Color(0, 0.8, 1))

				search_results_count += 1

	# Показываем количество результатов
	if search_results_count > 0:
		search_bar.placeholder_text = "Найдено: %d статей" % search_results_count
	else:
		search_bar.placeholder_text = "Ничего не найдено..."
		
func get_category_icon(category: String) -> String:
	match category:
		"basics":
			return "📚"
		"filtering":
			return "🔍"
		"aggregates":
			return "📊"
		"firebird_specific":
			return "🔥"
		"advanced":
			return "🎓"
		"game_mechanics":
			return "🎮"
		_:
			return "📄"

func get_category_text(category: String) -> String:
	match category:
		"basics":
			return "📚 Основы SQL"
		"filtering":
			return "🔍 Фильтрация"
		"aggregates":
			return "📊 Агрегаты"
		"firebird_specific":
			return "🔥 Firebird"
		"advanced":
			return "🎓 Продвинутый"
		"game_mechanics":
			return "🎮 Игра"
		_:
			return "📄 Другое"
			
func _on_close_pressed():
	print("📖 Закрытие справки...")
	get_tree().change_scene_to_file("res://scenes/desktop/desktop.tscn")
