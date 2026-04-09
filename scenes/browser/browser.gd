extends Control

@onready var site_buttons = $SiteButtons #Container с кнопками
@onready var content_view = $ContentView/Text
@onready var title_label = $ContentView/Title

var current_day: int = 1
var available_sites: Dictionary = {}
var articles_cache: Array = []

func _ready():
	print("🌐 Browser загружен")
	
	# Подключаемся к сигналам
	if QuestManager:
		QuestManager.day_completed.connect(_on_day_changed)
	
	load_available_sites()
	load_articles_for_day(1)

func _on_day_changed(day: int):
	current_day = day
	load_articles_for_day(day)
	update_site_availability()

func load_available_sites():
	# Загрузка доступных сайтов из БД
	# В полной версии: DatabaseManager.GetSitesForDay(current_day)
	# Сейчас - заглушка:
	available_sites = {
		"news": {"name": "📰 Новости НИИ", "unlocked": true},
		"wiki": {"name": "📚 Википедия", "unlocked": true},
		"board": {"name": "📌 Доска объявлений", "unlocked": current_day >= 3},
		"humor": {"name": "😂 Юмор", "unlocked": current_day >= 5}
	}
	
	render_site_buttons()

func render_site_buttons():
	# Создание кнопок сайтов
	# Очистка
	for child in site_buttons.get_children():
		child.queue_free()
	
	# Создание кнопок
	for site_id in available_sites:
		var site = available_sites[site_id]
		if not site.unlocked:
			continue
		
		var btn = Button.new()
		btn.text = site.name
		btn.name = site_id
		btn.connect("pressed", Callable(self, "_on_site_button_pressed").bind(site_id))
		site_buttons.add_child(btn)


func _on_site_button_pressed(site_id: String):
	# При клике на сайт
	title_label.text = available_sites[site_id].name
	load_available_site(site_id)

func load_articles_for_site(site_id: String):
	# Загрузка статей для сайта
	# Фильтруем статьи по сайту и дню
	var relevant = []
	for article in articles_cache:
		if article.get("site_name") == site_id and article.get("day_id", 1) <= current_day:
			relevant.append(article)
	
	if relevant.is_empty():
		content_view.text = "[i]Нет материалов для отображения[/i]"
		return
	
	# Показываем первую статью (можно сделать список)
	var article = relevant[0]
	content_view.text = "[b]" + article.get("title", "") + "[/b]\n\n" + article.get("content", "")

func load_articles_for_day(day: int):
	# Загрузка статей из БД для дня
	# В полной версии: DatabaseManager.GetArticlesForDay(day)
	articles_cache = [
		{"site_name": "news", "day_id": 1, "title": "Планёрка", "content": "Сегодня в 09:00..."},
		{"site_name": "wiki", "day_id": 1, "title": "Что такое SQL?", "content": "SQL - язык запросов...", "is_permanent": true},
		{"site_name": "board", "day_id": 3, "title": "Пропуск", "content": "Найден пропуск на 3 этаж..."},
		{"site_name": "humor", "day_id": 5, "title": "Анекдот", "content": "Программист и заба данных..."}
	]

func update_site_availability():
	# Обновление доступности сайтов при смене дня
	# Перегружаем список сайтов с учетом новых условий
	load_available_sites()

func load_available_site(site_id: String):
	# Загрузка контента конкретного сайта
	load_articles_for_site(site_id)
