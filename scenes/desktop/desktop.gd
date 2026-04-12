extends Control

@onready var notification_popup = $NotificationPopup
@onready var sender_label = $NotificationPopup/SenderLabel
@onready var subject_label = $NotificationPopup/SubjectLabel
@onready var timer_label = $NotificationPopup/TimerLabel
@onready var close_button = $NotificationPopup/CloseButton
@onready var clock_label = $Taskbar/ClockLabel
@onready var guide_icon = $DesktopIcons/GuideIcon

var game_time: Dictionary = {
	"hour": 19,  # 7 вечера
	"minute": 30,
	"day": 0     # День 0 - это вечер перед работой
}

# Таймер уведомления
var notification_timer: Timer = null
var notification_time_left: int = 10
var is_notification_showing: bool = false

func _ready():
	# Подключаем иконки
	$DesktopIcons/EmailIcon.pressed.connect(_open_email)
	$DesktopIcons/TerminalIcon.pressed.connect(_open_terminal)
	$DesktopIcons/SudokuIcon.pressed.connect(_open_sudoku)
	$DesktopIcons/BrowserIcon.pressed.connect(_open_browser)
	$DesktopIcons/GuideIcon.pressed.connect(_open_guide)
	$DesktopIcons/EndDay.pressed.connect(_on_finish_day_button_pressed)
	
	# Подключаем крестик закрытия
	close_button.pressed.connect(_close_notification)

	# Гарантированно скрываем уведомление при старте
	notification_popup.visible = false
	notification_popup.modulate = Color(1, 1, 1, 0)

	# Запуск обновления часов
	update_clock()
	
	# Показываем уведомление о новых письмах с небольшой задержкой
	await get_tree().create_timer(1.5).timeout
	_check_and_show_email_notification()

func _check_and_show_email_notification():
	"""Проверяет непрочитанные письма и показывает уведомление для первого"""
	if not DatabaseManager or not DatabaseManager.IsInitialized:
		return
	if is_notification_showing:
		return
	
	# Получаем письма текущего дня
	var day = 1
	if QuestManager:
		day = QuestManager.current_day
	
	var emails = DatabaseManager.GetEmailsForDay(day)
	
	# Сначала ИЩЕМ непрочитанное, не трогая UI
	var unread_sender = ""
	var unread_subject = ""
	for email in emails:
		var is_read_val = email.get("IS_READ", email.get("is_read", 0))
		if int(is_read_val) == 0:
			unread_sender = email.get("SENDER", email.get("sender", "?"))
			unread_subject = email.get("SUBJECT", email.get("subject", "?"))
			break
	
	# Если нашли — показываем, иначе — НИЧЕГО не делаем
	if unread_subject != "":
		_show_email_notification(unread_sender, unread_subject)
	else:
		print("📧 Все письма прочитаны — пропуск уведомления")

func _show_email_notification(sender: String, subject: String):
	"""Показывает уведомление с таймером 10 секунд"""
	if is_notification_showing:
		return
	
	is_notification_showing = true
	
	# Сначала устанавливаем текст (popup скрыт)
	sender_label.text = "📧 " + sender
	subject_label.text = subject
	timer_label.text = "10s"
	
	# Ждём один кадр чтобы текст отрисовался
	await get_tree().process_frame
	
	# Только теперь показываем popup
	notification_popup.visible = true
	notification_popup.modulate = Color(1, 1, 1, 1)
	
	# Запускаем таймер обратного отсчёта
	notification_time_left = 10
	_start_notification_timer()

func _start_notification_timer():
	"""Запускает обратный отсчёт 10 секунд"""
	# Создаём таймер если нет
	if notification_timer:
		notification_timer.stop()
		notification_timer.queue_free()
	
	notification_timer = Timer.new()
	notification_timer.wait_time = 1.0
	notification_timer.one_shot = false
	notification_timer.timeout.connect(_on_notification_tick)
	add_child(notification_timer)
	notification_timer.start()

func _on_notification_tick():
	"""Каждую секунду обновляем счётчик"""
	notification_time_left -= 1
	timer_label.text = str(notification_time_left) + "s"
	
	if notification_time_left <= 0:
		_close_notification()

func _close_notification():
	"""Закрывает уведомление"""
	is_notification_showing = false
	
	# Плавное исчезновение
	var tween = create_tween()
	tween.tween_property(notification_popup, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(func():
		notification_popup.visible = false
	)
	
	# Останавливаем таймер
	if notification_timer:
		notification_timer.stop()
		notification_timer.queue_free()
		notification_timer = null
	
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
	
	# Закрываем текущее уведомление если есть
	_close_notification()
	
	# Проверяем новые письма через пару секунд
	await get_tree().create_timer(2.0).timeout
	_check_and_show_email_notification()


func show_notification(text: String):
	"""Обратная совместимость — показывает короткое системное сообщение"""
	sender_label.text = "ℹ️ Система"
	subject_label.text = text
	timer_label.text = ""
	notification_popup.modulate = Color(1, 1, 1, 0)
	notification_popup.visible = true
	
	var tween = create_tween()
	tween.tween_property(notification_popup, "modulate", Color(1, 1, 1, 1), 0.3)
	
	# Автоскрытие через 5 секунд
	await get_tree().create_timer(5.0).timeout
	_close_notification()

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

		var quest_email_id = int(email.get("ID", email.get("id", -1)))
		var quest = DatabaseManager.GetQuestForEmail(quest_email_id)
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
