extends Node
## Устаревшая заглушка: в игре используй autoload **DatabaseManager** (C# `FirebirdDatabase`).
## Этот скрипт в сцену класть не нужно — см. `project.godot` → Autoload.

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


func save_player_progress_with_unlocks(role: String, day: int, violations: int, flags: Dictionary, quests: Array, unlock_conditions: Dictionary):
	if has_node("/root/DatabaseManager"):
		var fb = get_node("/root/DatabaseManager")
		fb.SavePlayerProgressWithUnlocks(role, day, violations, flags, quests, unlock_conditions)
	else:
		print("💾 Прогресс сохранён (заглушка): день=", day)


# ═══════════════════════════════════════════
# Методы для unlock_conditions (обёртки)
# ═══════════════════════════════════════════

func set_unlock_condition(condition_name: String, value: bool = true):
	if GameState and GameState.has_method("set_unlock_condition"):
		GameState.set_unlock_condition(condition_name, value)


func is_condition_unlocked(condition_name: String) -> bool:
	if GameState and GameState.has_method("is_condition_unlocked"):
		return GameState.is_condition_unlocked(condition_name)
	return false
