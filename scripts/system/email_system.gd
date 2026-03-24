extends Node

var inbox: Array[Dictionary] = []
var current_email: Dictionary = {}

func _ready():
	print("📧 Email System загружена!")

func add_email(email: Dictionary):
	inbox.append(email)
	print("  Входящее письмо: ", email.subject)

func get_unread_count() -> int:
	var count = 0
	for email in inbox:
		if not email.read:
			count += 1
	return count

func get_email_by_id(email_id: String) -> Dictionary:
	for email in inbox:
		if email.get("quest_id") == email_id:
			return email
	return {}

func mark_as_read(email: Dictionary):
	email.read = true
