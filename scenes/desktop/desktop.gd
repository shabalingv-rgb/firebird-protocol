extends Control

@onready var notification_popup = $NotificationPopup
@onready var notification_label = $NotificationPopup/NotificationLabel
@onready var clock_label = $Taskbar/ClockLabel
@onready var guide_icon = $DesktopIcons/GuideIcon

var game_time: Dictionary = {
	"hour": 19,  # 7 вечера
	"minute": 30,
	"day": 0     # День 0 - это вечер перед работой
}

func _ready():
	# Подключаем иконки
	$DesktopIcons/EmailIcon.pressed.connect(_open_email)
	$DesktopIcons/TerminalIcon.pressed.connect(_open_terminal)
	$DesktopIcons/SudokuIcon.pressed.connect(_open_sudoku)
	$DesktopIcons/BrowserIcon.pressed.connect(_open_browser)
	$DesktopIcons/GuideIcon.pressed.connect(_open_guide)
	$DesktopIcons/EndDay.pressed.connect(_on_finish_day_button_pressed)
	
	# Запуск обновления часов
	await get_tree().create_timer(2.0).timeout
	show_notification("📧 Новое письмо от HR НИИ")
	
	# Обновление часов каждую секунду (реальное время)
	update_clock()
	
func update_clock():
	if !is_inside_tree():
		return

	if GameState.current_day == 0:
		game_time.minute += 1
		if game_time.minute >= 60:
			game_time.minute = 0
			game_time.hour += 1

	var time_str = "%02d:%02d" % [game_time.hour, game_time.minute]
	clock_label.text = time_str

	await get_tree().create_timer(1.0).timeout
	update_clock()
	
func start_work_day():
	game_time.hour = 9
	game_time.minute = 0
	game_time.day = 1
	
func advance_game_time(hours: int):
	"""Продвинуть игровое время на N часов"""
	game_time.hour += hours
	while game_time.hour >= 24:
		game_time.hour -= 24
		game_time.day += 1
		on_new_day()
		
func on_new_day():
	print("Начался новый день: ", game_time.day)
	GameState.next_day()
	# Здесь можно добавлять новые задания
	
	# Показываем уведомление ТОЛЬКО один раз
	if not GameState.get_flag("email_notification_shown"):
		await get_tree().create_timer(2.0).timeout
		show_notification("📧 Новое письмо от HR НИИ")
		GameState.set_flag("email_notification_shown", true)	
	

func show_notification(text: String):
	notification_label.text = text
	notification_popup.visible = true
	# Автоскрытие через 5 секунд
	await get_tree().create_timer(5.0).timeout
	notification_popup.visible = false

func _open_email():
	print("Открытие почты...")
	get_tree().change_scene_to_file("res://scenes/email/email_client.tscn")

func _open_terminal():
	print("Открытие терминала...")
	get_tree().change_scene_to_file("res://scenes/terminal/terminal.tscn")
	
func _open_sudoku():
	print("Запуск Sudoku...")
	get_tree().change_scene_to_file("res://scenes/sudoku/sudoku.tscn")

func _open_browser():
	print("Открытие браузера...")
	get_tree().change_scene_to_file("res://scenes/browser/browser.tscn")

func _open_guide():
	print("📖 Открытие справочника...")
	get_tree().change_scene_to_file("res://scenes/guide/guide_client.tscn")

func complete_task(difficulty: String):
	match difficulty:
		"easy":
			advance_game_time(1)   # 1 час
		"medium":
			advance_game_time(4)   # 4 часа
		"hard":
			advance_game_time(8)   # 8 часов
	
	# Автосохранение при коммите
	GameState.save_game_state()

	# Ограничиваем курсор (после того как будет маска)
	# Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	
func _input(event):
	if event is InputEventMouseMotion:
		pass

func show_new_day_notification(day: int):
	show_notification("📬 Новые задания на день %d!" % day)
	
func _on_finish_day_button_pressed():
	"""Завершение рабочего дня — проверка квестов и подтверждение"""
	if not QuestManager:
		_advance_day()
		return

	# Проверяем незавершённые квесты
	var incomplete_quests = _get_incomplete_quests()

	if incomplete_quests.size() > 0:
		_show_day_end_warning(incomplete_quests)
	else:
		_advance_day()

func _get_incomplete_quests() -> Array:
	var incomplete = []
	var emails = DatabaseManager.GetEmailsForDay(QuestManager.current_day)

	for email in emails:
		var email_type = email.get("EMAIL_TYPE", email.get("email_type", "")).to_lower()
		if email_type != "quest":
			continue

		var email_id = int(email.get("ID", email.get("id", -1)))
		var quest = DatabaseManager.GetQuestForEmail(email_id)
		if quest == null or quest.is_empty():
			continue

		var title = quest.get("TITLE", quest.get("title", "Неизвестное задание"))
		var quest_id = int(quest.get("ID", quest.get("id", -1)))

		if not QuestManager.is_quest_completed(quest_id):
			incomplete.append(title)

	return incomplete

func _show_day_end_warning(incomplete_quests: Array):
	var dialog = ConfirmationDialog.new()
	dialog.title = "⚠️ Невыполненные задания"

	var warning_text = "У вас осталось невыполненных заданий: %d\n\n" % incomplete_quests.size()
	for q in incomplete_quests:
		warning_text += "  • " + q + "\n"
	warning_text += "\nНевыполнение рабочих обязанностей грозит последствиями.\nВы уверены, что хотите закончить рабочий день?"

	dialog.dialog_text = warning_text
	dialog.ok_button_text = "Завершить смену"
	dialog.cancel_button_text = "Остаться"

	# Игровой шрифт
	var font = preload("res://assets/fonts/PressStart2P-Regular.ttf")
	var dlg_theme = Theme.new()
	dlg_theme.default_font = font
	dlg_theme.default_font_size = 12
	dialog.theme = dlg_theme

	add_child(dialog)
	dialog.popup_centered(Vector2i(600, 300))

	dialog.confirmed.connect(func():
		dialog.queue_free()
		_advance_day()
	)
	dialog.canceled.connect(func():
		dialog.queue_free()
	)

func _advance_day():
	QuestManager.next_day()
	var next_day = QuestManager.current_day

	if next_day > 31:
		print("🏁 Конец игры (25 июля)")
		return

	# Сохраняем ссылку на tree ДО смены сцены
	var tree = get_tree()
	var packed_scene = load("res://scenes/desktop/next_day_transition.tscn") as PackedScene
	var scene = packed_scene.instantiate()
	scene.set_day(next_day)

	tree.root.remove_child(self)
	tree.root.add_child(scene)
	tree.current_scene = scene
