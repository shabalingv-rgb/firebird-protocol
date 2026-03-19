extends Control

var flicker_timer: float = 0.0
var flicker_enabled: bool = true

func _ready():
	# Подключаем кнопки
	$NewGame.pressed.connect(_on_new_game_pressed)
	$ContGame.pressed.connect(_on_continue_game_pressed)
	$OptGame.pressed.connect(_on_settings_pressed)
	$ExitGame.pressed.connect(_on_exit_pressed)
	
func _process(delta):
	if flicker_enabled:
		flicker_timer += delta
		if flicker_timer > 0.1:  # Мерцание каждые 0.1 секунды
			flicker_timer = 0.0
			# Случайное небольшое изменение прозрачности
			var flicker = randf_range(0.95, 1.0)
			modulate.a = flicker

func _on_new_game_pressed():
	print("Запуск новой игры...")
	# Сброс нарушений для новой игры
	GameState.reset_violations()
	GameState.current_day = 0
	# Переход к сцене "Нулевого дня" (пока заглушка)
	get_tree().change_scene_to_file("res://scenes/desktop/desktop.tscn")

func _on_continue_game_pressed():
	print("Продолжение игры...")
	# Проверка наличия сохранения
	if FileAccess.file_exists("user://save_state.json"):
		GameState.load_game_state()
		print("Загрузка с дня: ", GameState.current_day)
		# Переход к последней сцене
	else:
		print("Сохранение не найдено!")

func _on_settings_pressed():
	print("Настройки...")
	# get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_exit_pressed():
	print("Выход из игры...")
	get_tree().quit()
