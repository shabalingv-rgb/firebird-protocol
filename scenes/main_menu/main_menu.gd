extends Control

var flicker_timer: float = 0.0
var flicker_enabled: bool = true

func _ready():
	# Подключаем кнопки
	$NewGame.pressed.connect(_on_new_game_pressed)
	$ContGame.pressed.connect(_on_continue_game_pressed)
	$OptGame.pressed.connect(_on_settings_pressed)
	$ExitGame.pressed.connect(_on_exit_pressed)
	
	# Создаём debug панель если её нет
	if not has_node("DebugPanel"):
		var debug_scene = preload("res://scenes/debug/debug_panel.tscn")
		var debug_panel = debug_scene.instantiate()
		add_child(debug_panel)

	
func _process(delta):
	if flicker_enabled:
		flicker_timer += delta
		if flicker_timer > 0.1:  # Мерцание каждые 0.1 секунды
			flicker_timer = 0.0
			# Случайное небольшое изменение прозрачности
			var flicker = randf_range(0.95, 1.0)
			modulate.a = flicker

func _on_new_game_pressed():
	QuestManager.reset_progress()
	QuestManager.start_day(1)  # ✅ Это должно быть!
	
	# Переход на рабочий стол
	get_tree().change_scene_to_file("res://scenes/desktop/desktop.tscn")
			
func _on_continue_game_pressed():
	print("Продолжение игры...")
	if FileAccess.file_exists("user://save_state.json"):
		GameState.load_game_state()
		print("Загрузка с дня: ", GameState.current_day)
		get_tree().change_scene_to_file("res://scenes/desktop/desktop.tscn")
	else:
		print("Сохранение не найдено!")

func _on_settings_pressed():
	print("Настройки...")
	# get_tree().change_scene_to_file("res://scenes/settings.tscn")

func _on_exit_pressed():
	print("Выход из игры...")
	get_tree().quit()
