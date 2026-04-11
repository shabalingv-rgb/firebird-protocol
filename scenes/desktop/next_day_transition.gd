extends Control

var target_day: int = 1

func set_day(day: int):
	target_day = day
	_update_display()

func _update_display():
	var date_label = $DayLabel

	# Вычисляем реальную дату: День 0 = 24 июня
	var day_of_month = 24 + target_day
	var month = 6  # июнь
	var year = 2026

	# Коррекция для июля
	if day_of_month > 30:
		day_of_month -= 30
		month = 7  # июль

	var months = ["января", "февраля", "марта", "апреля", "мая", "июня",
		"июля", "августа", "сентября", "октября", "ноября", "декабря"]
	var month_name = months[month - 1]

	var day_text = "День %d" % target_day
	var date_text = "%d %s %d" % [day_of_month, month_name, year]

	date_label.text = day_text + "\n" + date_text

func _ready():
	# Анимация появления
	var date_label = $DayLabel
	date_label.modulate.a = 0.0

	var tween = create_tween()
	tween.tween_property(date_label, "modulate:a", 1.0, 1.5)
	tween.set_ease(Tween.EASE_OUT)

	# Через 3 секунды — возврат на рабочий стол
	await get_tree().create_timer(3.0).timeout

	var fade_tween = create_tween()
	fade_tween.tween_property($Bg, "modulate:a", 0.0, 0.5)
	fade_tween.tween_property(date_label, "modulate:a", 0.0, 0.5)

	await fade_tween.finished

	get_tree().change_scene_to_file("res://scenes/desktop/desktop.tscn")
