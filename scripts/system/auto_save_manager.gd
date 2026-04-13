extends Node
## Глобальный менеджер авто-сохранения (autoload).
## SaveManager UI читает/пишет настройки через этот скрипт.

const AUTOSAVE_SETTING_PATH := "user://save_manager.cfg"

var _playtime_minutes: int = 0
var _playtime_timer: Timer = null
var autosave_enabled: bool = false : set = _set_autosave_enabled


func _ready() -> void:
	_load_setting()
	_start_timer()


func _set_autosave_enabled(value: bool) -> void:
	autosave_enabled = value
	_save_setting(value)


func do_auto_save(slot: int = 1) -> void:
	if not autosave_enabled:
		return
	if not DatabaseManager or not QuestManager:
		return

	DatabaseManager.auto_save(
		slot,
		QuestManager.current_day,
		QuestManager.violations,
		QuestManager.trust_level,
		QuestManager.story_flags,
		QuestManager.completed_quests,
		_playtime_minutes
	)
	print("💾 Авто-сохранение (слот %d, день %d, %d мин)" % [slot, QuestManager.current_day, _playtime_minutes])


func get_playtime_minutes() -> int:
	return _playtime_minutes


# ──────────── Таймер ────────────

func _start_timer() -> void:
	_playtime_timer = Timer.new()
	_playtime_timer.wait_time = 60.0
	_playtime_timer.one_shot = false
	_playtime_timer.timeout.connect(_on_tick)
	add_child(_playtime_timer)
	_playtime_timer.start()


func _on_tick() -> void:
	_playtime_minutes += 1


# ──────────── Настройки ────────────

func _save_setting(enabled: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("autosave", "enabled", enabled)
	cfg.save(AUTOSAVE_SETTING_PATH)


func _load_setting() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(AUTOSAVE_SETTING_PATH) == OK:
		autosave_enabled = cfg.get_value("autosave", "enabled", false)
	else:
		autosave_enabled = false
