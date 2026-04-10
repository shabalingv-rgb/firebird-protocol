extends Node
## ⚠️ УСТАРЕВШИЙ ФАЙЛ — НЕ ИСПОЛЬЗУЕТСЯ!
##
## Autoload "DatabaseManager" в project.godot указывает на C# класс:
##   scripts/system/FirebirdDatabase.cs (UID: uid://h85iqknxq553)
##
## Этот GDScript-файл остался от старой архитектуры и не подключён.
## Не добавляйте сюда код — он не будет работать!
##
## Для работы с БД используйте:
##   - DatabaseManager.GetEmailsForDay(day_id)   (C# метод)
##   - DatabaseManager.GetQuestForEmail(email_id)
##   - DatabaseManager.LoadPlayerProgress()
##   - DatabaseManager.ExecuteQuery(sql)
##
## Если нужен GDScript-обёртка — создайте новый файл с другим именем.

func get_emails_for_day(day_id: int) -> Array:
	if has_node("/root/DatabaseManager"):
		var fb = get_node("/root/DatabaseManager")
		return fb.GetEmailsForDay(day_id)
	return []


func get_quest_for_email(email_id: int) -> Dictionary:
	if has_node("/root/DatabaseManager"):
		var fb = get_node("/root/DatabaseManager")
		return fb.GetQuestForEmail(email_id)
	return {}


func load_player_progress(save_slot: int = 1) -> Dictionary:
	return {
		"current_day": 1,
		"violations": 0,
		"trust_level": 50,
		"flags_unlocked": {},
		"quests_completed": []
	}


func save_player_progress(role: String, day: int, violations: int, flags: Dictionary, quests: Array):
	print("💾 Прогресс сохранён: день=", day)
