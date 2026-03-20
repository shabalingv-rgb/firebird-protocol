extends Control

@onready var notification_popup = $NotificationPopup
@onready var notification_label = $NotificationPopup/NotificationLabel

func _ready():
	# Подключаем иконки
	$DesktopIcons/EmailIcon.pressed.connect(_open_email)
	$DesktopIcons/TerminalIcon.pressed.connect(_open_terminal)
	$DesktopIcons/SudokuIcon.pressed.connect(_open_sudoku)
	$DesktopIcons/BrowserIcon.pressed.connect(_open_browser)
	$DesktopIcons/CalculatorIcon.pressed.connect(_open_calculator)
	
	# Показываем уведомление о письме через 2 секунды после старта
	await get_tree().create_timer(2.0).timeout
	show_notification("📧 Новое письмо от HR НИИ")

func show_notification(text: String):
	notification_label.text = text
	notification_popup.visible = true
	# Автоскрытие через 5 секунд
	await get_tree().create_timer(5.0).timeout
	notification_popup.visible = false

func _open_email():
	print("Открытие почты...")
	# get_tree().change_scene_to_file("res://scenes/email/email_client.tscn")

func _open_terminal():
	print("Открытие терминала...")
	# get_tree().change_scene_to_file("res://scenes/terminal/terminal.tscn")

func _open_sudoku():
	print("Запуск Sudoku...")
	# Заглушка для пасхалки

func _open_browser():
	print("Открытие браузера...")
	# Переход к туториалу

func _open_calculator():
	print("Запуск калькулятора...")
	# Заглушка
