extends Control

# Шрифт для элементов
var quest_font: FontFile = preload("res://assets/fonts/PressStart2P-Regular.ttf")

# Ссылки на узлы
@onready var site_buttons_container = $SiteButtons
@onready var article_list = $ArticleList
@onready var article_text = $ContentView/ArticleText
@onready var back_button = $BackButton

var current_day: int = 1
var current_site: String = ""
var available_sites: Array = []
var articles_cache: Array = []


func _ready():
	print("🌐 Browser загружен")
	
	# Подключаем сигналы
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	if article_list:
		article_list.item_selected.connect(_on_article_selected)
		article_list.add_theme_font_override("font", quest_font)
	
	# Получаем текущий день
	if QuestManager:
		current_day = QuestManager.current_day
	
	# Подписываемся на смену дня
	if GameState:
		if not GameState.day_changed.is_connected(_on_day_changed):
			GameState.day_changed.connect(_on_day_changed)
			print("🌐 Подписан на GameState.day_changed")
		else:
			print("🌐 Уже подписан на day_changed")
		print("🌐 GameState.current_day=", GameState.current_day)
	else:
		print("⚠️ GameState не доступен!")
	
	# Все кнопки видны всегда, но статьи загружаются по доступности
	_setup_site_buttons()


func _on_day_changed(day: int):
	"""Реакция на смену дня"""
	print("🌐 Браузер: день изменён на ", day)
	current_day = day
	# Перезагружаем текущий сайт
	if not current_site.is_empty():
		print("🌐 Перезагружаю статьи для: ", current_site, " day=", day)
		load_articles_for_site(current_site)


func _setup_site_buttons():
	"""Создаёт кнопки для всех сайтов (видны всегда)"""
	print("🌐 _setup_site_buttons: current_day=", current_day)
	# Очищаем старые кнопки
	for child in site_buttons_container.get_children():
		child.queue_free()
	
	var all_sites = [
		{"id": "news", "name": "📰 Новости НИИ"},
		{"id": "wiki", "name": "📚 Википедия"},
		{"id": "board", "name": "📌 Доска объявлений"},
		{"id": "humor", "name": "😄 Юмор"}
	]
	
	for site in all_sites:
		var btn = Button.new()
		btn.text = site["name"]
		btn.name = "btn_" + site["id"]
		btn.custom_minimum_size = Vector2(150, 32)
		btn.add_theme_font_override("font", quest_font)
		var site_id = site["id"]
		btn.pressed.connect(func(): _on_site_pressed(site_id))
		site_buttons_container.add_child(btn)
	
	# Загружаем первый доступный сайт
	load_articles_for_site("news")


func _on_site_pressed(site_id: String):
	"""При клике на сайт"""
	print("🌐 Открыт сайт: ", site_id)
	current_site = site_id
	load_articles_for_site(site_id)


func load_articles_for_site(site_id: String):
	"""Загрузка статей для сайта"""
	print("📰 Загрузка статей для ", site_id, " day=", current_day, "...")
	
	# Проверяем доступность сайта по дню
	var min_day = 1
	if site_id == "board":
		min_day = 3
	elif site_id == "humor":
		min_day = 5
	
	print("📰 min_day=", min_day, " current_day=", current_day)
	
	if current_day < min_day:
		article_text.text = "Раздел в разработке."
		article_list.clear()
		print("📰 Раздел заблокирован до дня ", min_day)
		return
	
	if not DatabaseManager:
		print("📰 DatabaseManager не доступен!")
		return
	
	articles_cache = DatabaseManager.GetArticlesForSite(site_id, current_day)
	print("📰 Найдено статей: ", articles_cache.size())
	
	# Очищаем список статей
	article_list.clear()
	
	# Показываем статьи
	for article_data in articles_cache:
		var article = article_data as Dictionary
		var title = str(article.get("TITLE", article.get("title", "Без названия")))
		var author = str(article.get("AUTHOR", article.get("author", "")))
		
		var display_text = title
		if not author.is_empty():
			display_text += " — " + author
		
		article_list.add_item(display_text)
	
	# Показываем первую статью если есть
	if articles_cache.size() > 0:
		article_list.select(0)
		_show_article(0)
	else:
		article_text.text = "Статей пока нет."


func _on_article_selected(index: int):
	"""При выборе статьи"""
	_show_article(index)


func _show_article(index: int):
	"""Показать содержимое статьи"""
	if index < 0 or index >= articles_cache.size():
		return
	
	var article = articles_cache[index] as Dictionary
	var title = str(article.get("TITLE", article.get("title", "")))
	var content = str(article.get("CONTENT", article.get("content", "")))
	var author = str(article.get("AUTHOR", article.get("author", "")))
	
	article_text.text = "[b]" + title + "[/b]"
	if not author.is_empty():
		article_text.text += "\n\n" + author
	article_text.text += "\n\n" + content
	
	print("📖 Открыта статья: ", title)


func _on_back_pressed():
	"""Кнопка Назад"""
	get_tree().change_scene_to_file("res://scenes/desktop/desktop.tscn")


func update_for_day(new_day: int):
	"""Обновление при смене дня"""
	current_day = new_day
	# Перезагружаем текущий сайт
	if not current_site.is_empty():
		load_articles_for_site(current_site)
