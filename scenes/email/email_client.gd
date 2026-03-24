extends Control

@onready var subject_label = $EmailHeader/SubjectLabel
@onready var body_label = $EmailBody
@onready var back_button = $EmailHeader/BackButton

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	
	# Проверяем, есть ли письма
	if EmailSystem.inbox.size() == 0:
		print("⚠️ Входящих писем нет!")
		subject_label.text = "Нет писем"
		body_label.text = "Задания будут приходить по мере выполнения работы."
		return
	
	load_first_unread_email()

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

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/desktop/desktop.tscn")
