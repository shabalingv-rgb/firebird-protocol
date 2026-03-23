extends Control

@onready var notification_popup = $NotificationPopup
@onready var notification_label = $NotificationPopup/NotificationLabel
@onready var clock_label = $Taskbar/ClockLabel

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
	$DesktopIcons/CalculatorIcon.pressed.connect(_open_calculator)
	
	# Запуск обновления часов
	await get_tree().create_timer(2.0).timeout
	show_notification("📧 Новое письмо от HR НИИ")
	
	# Обновление часов каждую секунду (реальное время)
	update_clock()
	
func update_clock():
	if GameState.current_day == 0:
		# В кафе время идёт медленнее (1 реальная секунда = 5 игровых минут)
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
	# Заглушка для пасхалки

func _open_browser():
	print("Открытие браузера...")
	# Переход к туториалу

func _open_calculator():
	print("Запуск калькулятора...")
	# Заглушка

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
		# Здесь можно добавить проверку границ рамки
		pass
