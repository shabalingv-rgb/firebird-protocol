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
		if flicker_timer > 0.1:
			flicker_timer = 0.0
			var flicker = randf_range(0.95, 1.0)
			modulate.a = flicker


func _on_new_game_pressed():
	print("🆕 Новая игра — выбор слота")
	# Открываем менеджер сохранений в режиме создания
	# GameState передаёт режим сцене save_manager
	if GameState:
		GameState.save_manager_mode = "create"
	get_tree().change_scene_to_file("res://scenes/save_manager/save_manager.tscn")


func _on_continue_game_pressed():
	print("▶️ Продолжить — выбор сохранения")
	if not DatabaseManager:
		push_error("❌ DatabaseManager не доступен")
		return

	# Проверяем есть ли хоть одно сохранение
	var has_save := false
	for slot in [1, 2, 3]:
		var progress = DatabaseManager.LoadPlayerProgress(slot)
		if not progress.is_empty() and int(progress.get("CURRENT_DAY", progress.get("current_day", 0))) > 0:
			has_save = true
			break

	if has_save:
		# Есть сохранения — открываем менеджер сохранений в режиме загрузки
		if GameState:
			GameState.save_manager_mode = "load"
		get_tree().change_scene_to_file("res://scenes/save_manager/save_manager.tscn")
	else:
		# Нет сохранений — предупреждение
		_show_no_save_dialog()


func _show_no_save_dialog():
	var dialog := AcceptDialog.new()
	dialog.title = "💾 Нет сохранений"
	dialog.dialog_text = "У вас пока нет сохранений.\n\nВыберите «Новая игра», чтобы начать."
	dialog.ok_button_text = "OK"
	_add_retro_theme_to_dialog(dialog)
	add_child(dialog)
	dialog.popup_centered(Vector2i(500, 200))
	dialog.confirmed.connect(dialog.queue_free)


func _add_retro_theme_to_dialog(dialog: Window) -> void:
	var font: FontFile = preload("res://assets/fonts/PressStart2P-Regular.ttf")
	var dlg_theme := Theme.new()
	dlg_theme.default_font = font
	dlg_theme.default_font_size = 12
	dialog.theme = dlg_theme


func _on_settings_pressed():
	print("Настройки...")


func _on_exit_pressed():
	print("Выход из игры...")
	get_tree().quit()
