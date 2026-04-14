extends CanvasLayer
## Пауз-меню — вызывается по **Esc** из любой точки игры.
## Ставит `get_tree().paused = true` при открытии.

@onready var overlay: ColorRect = $Overlay
@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var resume_btn: Button = $Panel/VBoxContainer/ResumeButton
@onready var save_btn: Button = $Panel/VBoxContainer/SaveButton
@onready var quit_btn: Button = $Panel/VBoxContainer/QuitButton

var is_open: bool = false


func _ready() -> void:
	# Этот узел должен работать даже при паузе
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Прячем при старте
	visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	resume_btn.pressed.connect(_on_resume)
	save_btn.pressed.connect(_on_save)
	quit_btn.pressed.connect(_on_quit)

	print("⏸ Pause Menu загружен")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()

		if is_open:
			hide_menu()
		else:
			# Не открываем в главном меню
			var current_scene = get_tree().current_scene
			if current_scene and current_scene.name != "MainMenu_tscn":
				show_menu()


func show_menu() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	get_tree().paused = true

	# Анимация появления
	overlay.modulate = Color(0, 0, 0, 0)
	var tween = create_tween()
	tween.tween_property(overlay, "modulate", Color(0, 0, 0, 0.75), 0.2)

	resume_btn.grab_focus()
	print("⏸ Игра на паузе")


func hide_menu() -> void:
	if not is_open:
		return
	is_open = false
	get_tree().paused = false

	# Анимация скрытия
	var tween = create_tween()
	tween.tween_property(overlay, "modulate", Color(0, 0, 0, 0), 0.15)
	tween.tween_callback(func():
		visible = false
	)
	print("▶ Игра возобновлена")


# ──────────── Кнопки ────────────

func _on_resume() -> void:
	hide_menu()


func _on_save() -> void:
	# Открываем менеджер сохранений в режиме сохранения
	if GameState:
		GameState.save_manager_mode = "load"

	# Запоминаем откуда пришли (для кнопки "Назад")
	if GameState:
		GameState.previous_scene = get_tree().current_scene.scene_file_path if get_tree().current_scene else "res://scenes/desktop/desktop.tscn"

	# Скрываем паузу, но НЕ снимаем авто-паузу — save_manager не игровой процесс
	get_tree().paused = false
	hide_menu()

	get_tree().change_scene_to_file("res://scenes/save_manager/save_manager.tscn")


func _on_quit() -> void:
	_show_quit_confirm()


# ──────────── Подтверждение выхода ────────────

func _show_quit_confirm() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "🚪 Выход"
	dialog.dialog_text = "Несохранённый прогресс будет потерян.\n\nВы уверены, что хотите выйти в главное меню?"
	dialog.ok_button_text = "Выйти"
	dialog.cancel_button_text = "Отмена"
	_add_retro_theme(dialog)

	add_child(dialog)
	dialog.popup_centered(Vector2i(550, 180))

	dialog.confirmed.connect(func():
		get_tree().paused = false
		hide_menu()

		# Сбрасываем несохранённые данные
		if QuestManager:
			QuestManager.active_quest = {}

		print("🚪 Выход в главное меню (без сохранения)")
		get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn.tscn")
		dialog.queue_free()
	)

	dialog.canceled.connect(func():
		dialog.queue_free()
	)


# ──────────── Утилиты ────────────

func _retro_font() -> FontFile:
	return preload("res://assets/fonts/PressStart2P-Regular.ttf")


func _add_retro_theme(window: Window) -> void:
	var theme := Theme.new()
	theme.default_font = _retro_font()
	theme.default_font_size = 12
	window.theme = theme
