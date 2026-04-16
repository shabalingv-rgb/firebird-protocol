extends Node
## Глобальный менеджер авто-сохранения (autoload).
## Сохраняет в отдельный слот 0 (автосохранение), не трогая ручные слоты 1-3.
## SaveManager UI читает настройки через этот скрипт.

const AUTOSAVE_SETTING_PATH := "user://save_manager.cfg"
const AUTOSAVE_SLOT := 0          # Специальный слот для автосохранения
const AUTOSAVE_INTERVAL := 300.0  # 5 минут в секундах

var _playtime_minutes: int = 0
var _playtime_timer: Timer = null
var _autosave_timer: Timer = null
var autosave_enabled: bool = false : set = _set_autosave_enabled


func _ready() -> void:
	_load_setting()
	_start_playtime_timer()
	_start_autosave_timer()


func _set_autosave_enabled(value: bool) -> void:
	autosave_enabled = value
	_save_setting(value)

	# Вкл/выкл таймер автосохранения
	if _autosave_timer:
		if value:
			_autosave_timer.start()
		else:
			_autosave_timer.stop()


func do_auto_save() -> void:
	"""Сохранить текущее состояние в слот автосохранения (0)."""
	if not autosave_enabled:
		return
	if not DatabaseManager or not QuestManager:
		return

	DatabaseManager.AutoSave(
		AUTOSAVE_SLOT,
		QuestManager.current_day,
		QuestManager.violations,
		QuestManager.trust_level,
		QuestManager.story_flags,
		QuestManager.completed_quests,
		_playtime_minutes
	)
	print("💾 Авто-сохранение (день %d, %d мин)" % [QuestManager.current_day, _playtime_minutes])


func get_playtime_minutes() -> int:
	return _playtime_minutes


# ──────────── Таймеры ────────────

func _start_playtime_timer() -> void:
	_playtime_timer = Timer.new()
	_playtime_timer.wait_time = 60.0
	_playtime_timer.one_shot = false
	_playtime_timer.timeout.connect(_on_playtime_tick)
	add_child(_playtime_timer)
	_playtime_timer.start()


func _on_playtime_tick() -> void:
	_playtime_minutes += 1


func _start_autosave_timer() -> void:
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = AUTOSAVE_INTERVAL
	_autosave_timer.one_shot = false
	_autosave_timer.timeout.connect(_on_autosave_tick)
	add_child(_autosave_timer)

	if autosave_enabled:
		_autosave_timer.start()


func _on_autosave_tick() -> void:
	# Проверяем, что игра идёт (день > 0)
	if QuestManager and QuestManager.current_day > 0:
		print("⏱ Авто-сохранение по таймеру (каждые 5 мин)")
		do_auto_save()


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
