extends Control

@onready var search_bar = $Header/SearchBar
@onready var categories_tree = $ContentContainer/Sidebar/CategoriesTree
@onready var progress_label = $ContentContainer/Sidebar/ProgressLabel
@onready var content_label = $MainContent/ArticleContent
@onready var code_example = $CodeExample
@onready var prev_button = $NavigationButtons/PrevButton
@onready var next_button = $NavigationButtons/NextButton
@onready var try_button = $TryItButton

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
	
	load_guide()
	update_progress()
	update_navigation_buttons()

func load_guide():
	categories_tree.clear()
	
	# Создаём корневые категории
	var basics_root = categories_tree.create_item()
	basics_root.set_text(0, "📚 Основы SQL")
	basics_root.set_selectable(0, false)
	
	var firebird_root = categories_tree.create_item()
	firebird_root.set_text(0, "🔥 Firebird SQL")
	firebird_root.set_selectable(0, false)
	
	var mechanics_root = categories_tree.create_item()
	mechanics_root.set_text(0, "🎮 Игровые механики")
	mechanics_root.set_selectable(0, false)
	
	# Заполняем
	for topic_id in GuideSystem.guide_database:
		if GuideSystem.is_topic_unlocked(topic_id):
			var topic = GuideSystem.guide_database[topic_id]
			var parent = basics_root
			
			if topic.category == "firebird_specific":
				parent = firebird_root
			elif topic.category == "game_mechanics":
				parent = mechanics_root
			elif topic.category == "filtering" or topic.category == "aggregates":
				parent = basics_root
			elif topic.category == "advanced":
				parent = basics_root
			
			var item = categories_tree.create_item(parent)
			item.set_text(0, topic.title)
			item.set_metadata(0, topic_id)
			
			# Цвет для Firebird-специфики
			if topic.firebird_specific:
				item.set_custom_color(0, Color(0, 0.8, 1))

func _on_category_selected():
	var selected = categories_tree.get_selected()
	if selected:
		var topic_id = selected.get_metadata(0)
		if topic_id:
			show_article(topic_id)
			GuideSystem.mark_as_read(topic_id)

func show_article(topic_id: String):
	# Сохраняем историю
	if current_topic_id != topic_id:
		if history_index < topic_history.size() - 1:
			topic_history = topic_history.slice(0, history_index + 1)
		topic_history.append(topic_id)
		history_index = topic_history.size() - 1
	
	current_topic_id = topic_id
	
	# Показываем статью
	var topic = GuideSystem.guide_database[topic_id]
	content_label.text = topic.content
	code_example.text = topic.get("example", "")
	
	update_navigation_buttons()
	update_progress()

func update_navigation_buttons():
	prev_button.disabled = history_index <= 0
	next_button.disabled = history_index >= topic_history.size() - 1
	
	# Меняем текст кнопки для визуальной обратной связи
	if prev_button.disabled:
		prev_button.text = "← Назад"
		prev_button.disabled = true
	else:
		prev_button.text = "← Назад"
		prev_button.disabled = false
	
	if next_button.disabled:
		next_button.text = "Вперёд →"
		next_button.disabled = true
	else:
		next_button.text = "Вперёд →"
		next_button.disabled = false
	
	# ИЛИ меняем цвет через theme_override
	if prev_button.disabled:
		prev_button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.5))
	else:
		prev_button.remove_theme_color_override("font_color")
	
	if next_button.disabled:
		next_button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.5))
	else:
		next_button.remove_theme_color_override("font_color")
				
func _on_prev_pressed():
	if history_index > 0:
		history_index -= 1
		var prev_topic = topic_history[history_index]
		current_topic_id = prev_topic
		
		var topic = GuideSystem.guide_database[prev_topic]
		content_label.text = topic.content
		code_example.text = topic.get("example", "")
		
		update_navigation_buttons()
		categories_tree.deselect_all()

func _on_next_pressed():
	if history_index < topic_history.size() - 1:
		history_index += 1
		var next_topic = topic_history[history_index]
		current_topic_id = next_topic
		
		var topic = GuideSystem.guide_database[next_topic]
		content_label.text = topic.content
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
	var total = GuideSystem.guide_database.size()
	var unlocked = GuideSystem.unlocked_topics.size()
	progress_label.text = "Изучено: %d/%d тем" % [unlocked, total]

func _on_search_changed(new_text: String):
	if new_text.is_empty():
		load_guide()
		return
	
	categories_tree.clear()
	
	# Поиск по статьям
	for topic_id in GuideSystem.guide_database:
		if GuideSystem.is_topic_unlocked(topic_id):
			var topic = GuideSystem.guide_database[topic_id]
			if topic.title.to_lower().contains(new_text.to_lower()) or \
			   topic.content.to_lower().contains(new_text.to_lower()):
				
				var item = categories_tree.create_item()
				item.set_text(0, topic.title)
				item.set_metadata(0, topic_id)
