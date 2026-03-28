extends Control

# ⭐ ОБЯЗАТЕЛЬНО в начале файла!
@onready var subject_label = $EmailHeader/Subject
@onready var sender_label = $EmailHeader/Sender
@onready var date_label = $EmailHeader/DateLabel
@onready var email_list = $EmailList
@onready var reply_button = $EmailHeader/ReplyButton
@onready var body_label = $Body
@onready var back_button = $EmailHeader/BackButton

var current_emails: Array = []
var current_day_emails: Array = []
var active_quest: Dictionary = {}

func _ready():
	# Подключаем сигналы
	if email_list:
		email_list.item_selected.connect(_on_email_selected)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	# Подключаемся к сигналам БД
	DatabaseManager.database_ready.connect(_on_database_ready)	
	
	print("📧 Email Client загружен")
	
	# Подключаемся к сигналам ТОЛЬКО если ещё не подключено
	if DatabaseManager and not DatabaseManager.database_ready.is_connected(_on_database_ready):
		DatabaseManager.database_ready.connect(_on_database_ready)
		
		# Если БД уже готова - загружаем сразу
		if DatabaseManager.is_initialized:
			load_emails_for_day(1)
	else:
		# Если БД ещё не готова - загружаем позже
		load_emails_for_day(1)
	
	# Проверяем, есть ли письма
	if EmailSystem.inbox.size() == 0:
		print("⚠️ Входящих писем нет!")
		subject_label.text = "Нет писем"
		body_label.text = "Задания будут приходить по мере выполнения работы."
		return
	
	# Загружаем письма для дня 1 (временно)
	load_emails_for_day(1)
	
	refresh_email_list()
	load_first_unread_email()

func refresh_email_list():
	if not email_list:
		return
	
	email_list.clear()
	
	for i in range(EmailSystem.inbox.size()):
		var email = EmailSystem.inbox[i]
		var time = email.get("time", "Неизвестно")
		var sender = email.get("from", "Unknown")
		var subject = email.subject
		
		var display_text = "%s\n%s\n%s" % [time, sender, subject]
		
		email_list.add_item(display_text)
		email_list.set_item_metadata(i, i)
		
		# ⚠️ УДАЛИ или закомментируй эту строку:
		# email_list.set_item_custom_font(i, 0, true)
		
func _on_email_selected(index):
	var email_index = email_list.get_item_metadata(index)
	if email_index < EmailSystem.inbox.size():
		var email = EmailSystem.inbox[email_index]
		show_email(email)

func load_first_unread_email():
	for email in EmailSystem.inbox:
		if not email.read:
			show_email(email)
			return
	
	# Если все прочитаны, покажем последнее
	if EmailSystem.inbox.size() > 0:
		show_email(EmailSystem.inbox[-1])

func show_email(email: Dictionary):
	subject_label.text = email.subject
	body_label.text = email.body
	EmailSystem.mark_as_read(email)
	
	# Обновляем список (чтобы показать что прочитано)
	refresh_email_list()
	
	# Добавляем кнопку "Отправить отчёт" если это письмо с заданием
	if email.has("quest_id"):
		add_report_button(email.quest_id)

func add_report_button(quest_id: String):
	# Удаляем старую кнопку если есть
	if has_node("CheckQuest"):
		$CheckQuest.queue_free()
	
	var btn = Button.new()
	btn.name = "CheckQuest"
	btn.text = "📤 Отправить отчёт о выполнении"
	btn.pressed.connect(func(): submit_quest_report(quest_id))
	
	# Добавляем кнопку под текстом письма
	if $Body is TextEdit:
		# Если TextEdit, добавляем как дочерний элемент
		$Body.add_child(btn)
	else:
		# Если Label, добавляем рядом
		add_child(btn)
		btn.owner = self

func submit_quest_report(quest_id: String):
	print("📤 Отправка отчёта по заданию: ", quest_id)
	
	# Проверяем выполнение через QuestManager
	if QuestManager.is_quest_completed(quest_id):
		if QuestManager.active_quest and not QuestManager.active_quest.is_empty():
			QuestManager.complete_quest(true)
			show_success_message()
		else:
			show_error_message("Нет активного задания")
			
		show_success_message()
	else:
		show_error_message("Задание ещё не выполнено! Проверьте запрос в терминале.")

func show_success_message():
	body_label.text += "\n\n✅ Отчёт отправлен! Задание выполнено."

func show_error_message(msg: String):
	body_label.text += "\n\n❌ " + msg

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/desktop/desktop.tscn")
	
func _on_database_ready():
	print("📧 Email Client: БД готова")
	# Загружаем письма для текущего дня
	if QuestManager:
		load_emails_for_day(QuestManager.current_day)
	else:
		load_emails_for_day(1)
		
func load_emails_for_day(day_number: int):
	"""Загрузка писем для конкретного дня"""
	print("📬 Загрузка писем для дня ", day_number)
	
	if not DatabaseManager:
		print("❌ DatabaseManager не доступен")
		return
	
	# Проверяем кэш
	print("📋 В кэше писем всего: ", DatabaseManager.cached_emails.size())
	
	current_emails = DatabaseManager.get_emails_for_day(day_number)
	current_day_emails = current_emails
	
	print("📫 Загружено писем для дня ", day_number, ": ", current_emails.size())
	
	# Выводим все письма для отладки
	for email in current_emails:
		print("   📧 Письмо: ", email.subject)
	
	if current_emails.is_empty():
		print("⚠️ Писем нет для дня ", day_number)
		show_empty_message()
	else:
		display_emails()
				
func display_emails():
	"""Отображение списка писем"""
	# Очищаем текущий список
	$EmailList.clear()
	
	for email in current_day_emails:
		var list_item = email.subject
		if not email.is_required:
			list_item = "[Непрочитанное] " + list_item
		$EmailList.add_item(list_item)
		
func _on_email_list_item_selected(index: int):
	"""Выбор письма для чтения"""
	if index >= 0 and index < current_day_emails.size():
		var email = current_day_emails[index]
		display_email(email)
		
		# Проверяем есть ли задание для этого письма
		var quest = DatabaseManager.get_quest_for_email(email.id)
		if quest and not quest.is_empty():
			active_quest = quest
			print("🎯 Активное задание: ", quest.title)
			
func display_email(email: Dictionary):
	"""Отображение содержимого письма"""
	$EmailHeader/Subject.text = email.subject
	$EmailHeader/Sender.text = "От: " + email.sender
	$EmailHeader/DateLabel.text = email.get("publish_date", "")
	$Body.text = email.body
	
	# Показываем кнопку ответа если это задание
	if active_quest and not active_quest.is_empty():
		$EmailHeader/ReplyButton.visible = true
		$EmailHeader/ReplyButton.text = "📤 Отправить отчёт"
	else:
		$EmailHeader/ReplyButton.visible = false

func _on_reply_button_pressed():
	"""Отправка отчёта"""
	if active_quest.is_empty():
		return
	
	show_report_dialog()

func show_report_dialog():
	"""Показ диалога выбора варианта отчёта"""
	var dialog = ConfirmationDialog.new()
	dialog.title = "📤 Отправка отчёта"
	
	var vbox = VBoxContainer.new()
	
	var label = Label.new()
	label.text = "Выберите вариант отчёта:"
	vbox.add_child(label)
	
	var option_button = OptionButton.new()
	option_button.add_item("Задание выполнено. Данные прилагаются.")
	option_button.add_item("Обнаружены аномалии. Требуется проверка.")
	option_button.add_item("Ничего подозрительного не найдено.")
	vbox.add_child(option_button)
	
	dialog.add_child(vbox)
	
	dialog.confirmed.connect(func():
		var selected_text = option_button.get_item_text(option_button.selected)
		send_report(selected_text)
	)
	
	add_child(dialog)
	dialog.popup_centered()
		


func send_report(report_text: String):
	"""Отправка отчёта"""
	print("📤 Отчёт отправлен: ", report_text)
	
	# Сохраняем выбор
	DatabaseManager.save_player_choice(
		active_quest.id,
		"report_text",
		report_text,
		QuestManager.current_day
	)
	
	# Проверяем текст отчёта на "подозрительный"
	if "аномалии" in report_text.to_lower() or "ошибки" in report_text.to_lower():
		# Игрок сообщил о проблемах - это может повлиять на сюжет
		QuestManager.set_story_flag("reported_anomaly")
	
	# Показываем успех
	var dialog = AcceptDialog.new()
	dialog.title = "✅ Успешно"
	dialog.dialog_text = "Отчёт отправлен руководству!"
	add_child(dialog)
	dialog.popup_centered()

func show_empty_message():
	"""Показ сообщения что писем нет"""
	$EmailHeader/EmailList.clear()
	$EmailHeader/Subject.text = "Нет писем"
	$EmailHeader/Sender.text = "Отправитель: "
	$Body.text = "Задания будут приходить по мере выполнения работы."
