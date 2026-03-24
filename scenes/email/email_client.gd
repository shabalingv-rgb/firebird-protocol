extends Control

# ⭐ ОБЯЗАТЕЛЬНО в начале файла!
@onready var email_list = $EmailList
@onready var subject_label = $EmailHeader/SubjectLabel
@onready var body_label = $EmailBody
@onready var back_button = $EmailHeader/BackButton

func _ready():
	# Подключаем сигналы
	if email_list:
		email_list.item_selected.connect(_on_email_selected)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	# Проверяем, есть ли письма
	if EmailSystem.inbox.size() == 0:
		print("⚠️ Входящих писем нет!")
		subject_label.text = "Нет писем"
		body_label.text = "Задания будут приходить по мере выполнения работы."
		return
	
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
	if $EmailBody is TextEdit:
		# Если TextEdit, добавляем как дочерний элемент
		$EmailBody.add_child(btn)
	else:
		# Если Label, добавляем рядом
		add_child(btn)
		btn.owner = self

func submit_quest_report(quest_id: String):
	print("📤 Отправка отчёта по заданию: ", quest_id)
	
	# Проверяем выполнение через QuestManager
	if QuestManager.is_quest_completed(quest_id):
		QuestManager.complete_quest(quest_id)
		show_success_message()
	else:
		show_error_message("Задание ещё не выполнено! Проверьте запрос в терминале.")

func show_success_message():
	body_label.text += "\n\n✅ Отчёт отправлен! Задание выполнено."

func show_error_message(msg: String):
	body_label.text += "\n\n❌ " + msg

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/desktop/desktop.tscn")
