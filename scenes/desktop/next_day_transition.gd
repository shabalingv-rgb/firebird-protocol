extends Control

var target_day: int = 1
var _mode: String = "workday"  # "intro" или "workday"

# ──────────── Публичные методы ────────────

func set_day(day: int) -> void:
	"""Обычная смена дня (1-30). Показывает «НИИ Файербёрд / сотрудник / дата»."""
	_mode = "workday"
	target_day = day
	_update_display()


func show_intro_date() -> void:
	"""Начальная заставка: «Кафе ФайрБёрд / безработный / 24 июня 1990»."""
	_mode = "intro"
	target_day = 0
	_update_display()


# ──────────── Отображение ────────────

func _update_display() -> void:
	var date_label = $DayLabel

	# Вычисляем реальную дату: День 0 = 24 июня 1990
	var day_of_month = 24 + target_day
	var month = 6  # июнь
	var year = 1990

	# Коррекция для июля
	if day_of_month > 30:
		day_of_month -= 30
		month = 7  # июль

	var months = ["января", "февраля", "марта", "апреля", "мая", "июня",
		"июля", "августа", "сентября", "октября", "ноября", "декабря"]
	var month_name = months[month - 1]
	var date_text = "%d %s %d" % [day_of_month, month_name, year]

	match _mode:
		"intro":
			# ┌─────────────────────────┐
			# │   Кафе «ФайрБёрд»      │
			# │                         │
			# │       безработный       │
			# │                         │
			# │     24 июня 1990        │
			# └─────────────────────────┘
			date_label.text = "Кафе «ФайрБёрд»\n\nбезработный\n\n%s" % date_text

		"workday":
			# ┌─────────────────────────┐
			# │   НИИ «ФАЙЕРБЁРД»      │
			# │                         │
			# │        сотрудник        │
			# │                         │
			# │     День 1              │
			# │     25 июня 1990        │
			# └─────────────────────────┘
			date_label.text = "НИИ «ФАЙЕРБЁРД»\n\nсотрудник\n\nДень %d\n%s" % [target_day, date_text]


# ──────────── Анимация ────────────

func _ready() -> void:
	var date_label = $DayLabel
	date_label.modulate.a = 0.0

	var tween = create_tween()
	tween.tween_property(date_label, "modulate:a", 1.0, 1.5)
	tween.set_ease(Tween.EASE_OUT)

	# Через 3 секунды — переход на рабочий стол
	await get_tree().create_timer(3.0).timeout

	var fade_tween = create_tween()
	fade_tween.tween_property($Bg, "modulate:a", 0.0, 0.5)
	fade_tween.tween_property(date_label, "modulate:a", 0.0, 0.5)

	await fade_tween.finished

	get_tree().change_scene_to_file("res://scenes/desktop/desktop.tscn")
