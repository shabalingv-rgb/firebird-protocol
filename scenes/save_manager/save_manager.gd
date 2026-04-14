extends Control
## Менеджер сохранений — создание, загрузка, удаление слотов.
## Авто-сохранение и таймер времени делегированы autoload **AutoSaveManager**.
##
## Режимы работы (устанавливаются из главного меню):
##   mode = "create"  → «Новая игра»  — показать слоты, при создании → сразу в игру
##   mode = "load"    → «Продолжить»  — показать слоты, при загрузке → в игру

@onready var slots_container: VBoxContainer = $SlotsPanel/SaveSlotsContainer
@onready var autosave_checkbox: CheckBox = $AutoSaveContainer/AutoSaveCheckbox
@onready var back_button: Button = $BackButton
@onready var title_label: Label = $TitleLabel

const MAX_SLOTS := 3

var save_slots: Array = []
var mode: String = "load"  # "create" или "load"


func _ready() -> void:
	# Читаем режим из GameState (устанавливается главным меню)
	if GameState:
		mode = GameState.save_manager_mode

	print("💾 Save Manager загружен (режим: %s)" % mode)

	back_button.pressed.connect(_on_back_pressed)
	autosave_checkbox.pressed.connect(_on_autosave_toggled)

	# Синхронизируем чекбокс с глобальной настройкой
	var auto_save_mgr = get_node_or_null("/root/AutoSaveManager")
	if auto_save_mgr:
		autosave_checkbox.button_pressed = auto_save_mgr.autosave_enabled

	# Заголовок зависит от режима
	if mode == "create":
		title_label.text = "💾 НОВАЯ ИГРА — Выберите слот"
	else:
		title_label.text = "💾 ПРОДОЛЖИТЬ — Выберите сохранение"

	_refresh_slots()


# ──────────── Обновление UI ────────────

func _refresh_slots() -> void:
	"""Перезагрузка списка сохранений из БД и перерисовка UI."""
	print("💾 Загрузка слотов сохранений...")

	if not DatabaseManager:
		_show_error_dialog("DatabaseManager не доступен.\nБаза данных ещё не инициализирована.")
		return

	save_slots = DatabaseManager.GetSaveSlotsList()
	if save_slots == null:
		_show_error_dialog("Ошибка загрузки сохранений.\nПроверьте подключение к базе данных.")
		save_slots = []

	# Удаляем старые дочерние узлы
	for child in slots_container.get_children():
		child.queue_free()

	for i in MAX_SLOTS:
		var slot_number := i + 1
		var slot_data: Dictionary = {}

		for slot in save_slots:
			var s: Dictionary = slot as Dictionary
			var sv = s.get("SAVE_SLOT", s.get("save_slot", -1))
			if int(sv) == slot_number:
				slot_data = s
				break

		_create_slot_ui(slot_number, slot_data)


func _create_slot_ui(slot_number: int, slot_data: Dictionary) -> void:
	"""Создание UI-элемента для одного слота."""
	var slot_container := HBoxContainer.new()
	slot_container.name = "Slot%d" % slot_number
	slot_container.add_theme_constant_override("separation", 20)
	slot_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# ── Стиль слота (рамка) ──
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0.06, 0, 0.5)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4

	if not slot_data.is_empty():
		style.border_color = Color(0, 1, 0, 1)  # зелёная рамка — есть сохранение
	else:
		style.border_color = Color(0, 0.5, 0, 0.6)  # тёмно-зелёная — пустой слот
	slot_container.add_theme_stylebox_override("panel", style)
	slot_container.add_theme_constant_override("separation", 20)

	# ── Информация ──
	var info_container := VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title := Label.new()
	title.text = "💾 Слот %d" % slot_number
	title.add_theme_font_override("font", _retro_font())
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0, 1, 0, 1))
	info_container.add_child(title)

	if not slot_data.is_empty():
		var day: int = int(slot_data.get("CURRENT_DAY", slot_data.get("current_day", 1)))
		var role: String = str(slot_data.get("USER_ROLE", slot_data.get("user_role", "employee")))
		var violations: int = int(slot_data.get("VIOLATIONS", slot_data.get("violations", 0)))
		var trust: int = int(slot_data.get("TRUST_LEVEL", slot_data.get("trust_level", 50)))
		var playtime: int = int(slot_data.get("TOTAL_PLAYTIME_MINUTES", slot_data.get("total_playtime_minutes", 0)))
		var last_saved: String = str(slot_data.get("LAST_SAVED", slot_data.get("last_saved", "")))

		_add_info_label(info_container, "Роль: %s" % role, Color(0, 0.85, 0, 1))
		_add_info_label(info_container, "День: %d" % day, Color(0, 0.85, 0, 1))
		_add_info_label(info_container, "Доверие: %d%%" % trust, Color(0, 0.85, 0, 1))

		var viol_label := Label.new()
		viol_label.text = "Нарушения: %d/%d" % [violations, QuestManager.MAX_VIOLATIONS]
		viol_label.add_theme_font_override("font", _retro_font())
		viol_label.add_theme_font_size_override("font_size", 10)
		viol_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1) if violations >= 3 else Color(0, 0.85, 0, 1))
		info_container.add_child(viol_label)

		_add_info_label(info_container, "Время игры: %d мин" % playtime, Color(0, 0.85, 0, 1))

		if last_saved != "":
			_add_info_label(info_container, "Сохранено: %s" % last_saved, Color(0, 0.7, 0, 1))
	else:
		var empty_label := Label.new()
		empty_label.text = "Пустой слот"
		empty_label.add_theme_font_override("font", _retro_font())
		empty_label.add_theme_font_size_override("font_size", 10)
		empty_label.add_theme_color_override("font_color", Color(0, 0.5, 0, 0.7))
		info_container.add_child(empty_label)

	slot_container.add_child(info_container)

	# ── Кнопки (горизонтально) ──
	var btn_container := HBoxContainer.new()
	btn_container.add_theme_constant_override("separation", 10)
	btn_container.size_flags_horizontal = Control.SIZE_SHRINK_END
	btn_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	if not slot_data.is_empty():
		# Порядок: Сохранить → Загрузить → Удалить

		# Кнопка сохранения — только если пришли из пауз-меню
		if _came_from_pause():
			var save_btn := _make_button("💾 Сохранить", Color(0, 1, 0, 1), Color(0, 0.2, 0, 1))
			save_btn.pressed.connect(_on_save_current.bind(slot_number))
			btn_container.add_child(save_btn)

		# Кнопка загрузки
		var load_btn := _make_button("📥 Загрузить", Color(0, 1, 0, 1), Color(0, 0.3, 0, 1))
		load_btn.pressed.connect(_on_load_pressed.bind(slot_number))
		btn_container.add_child(load_btn)

		# Кнопка удаления
		var delete_btn := _make_button("🗑 Удалить", Color(1, 0.4, 0.4, 1), Color(0.3, 0, 0, 1))
		delete_btn.pressed.connect(_on_delete_pressed.bind(slot_number))
		btn_container.add_child(delete_btn)
	else:
		var create_btn := _make_button("➕ Создать", Color(0, 1, 0, 1), Color(0, 0.3, 0, 1))
		create_btn.pressed.connect(_on_create_pressed.bind(slot_number))
		btn_container.add_child(create_btn)

	slot_container.add_child(btn_container)
	slots_container.add_child(slot_container)


func _add_info_label(parent: VBoxContainer, text: String, color: Color = Color(0, 0.85, 0, 1)) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", _retro_font())
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)


# ──────────── Кнопки ────────────

func _make_button(text: String, font_color: Color, bg_color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_override("font", _retro_font())
	btn.add_theme_font_size_override("font_size", 12)
	btn.custom_minimum_size = Vector2(160, 36)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	# Стиль кнопки
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = font_color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(font_color.r * 0.3, font_color.g * 0.3, font_color.b * 0.3, 0.5)
	hover_style.border_width_left = 2
	hover_style.border_width_top = 2
	hover_style.border_width_right = 2
	hover_style.border_width_bottom = 2
	hover_style.border_color = font_color
	hover_style.corner_radius_top_left = 4
	hover_style.corner_radius_top_right = 4
	hover_style.corner_radius_bottom_right = 4
	hover_style.corner_radius_bottom_left = 4

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_color_override("font_color", font_color)

	return btn


# ──────────── Загрузка ────────────

func _on_load_pressed(slot_number: int) -> void:
	print("📥 Загрузка слота %d..." % slot_number)

	if not DatabaseManager:
		_show_error_dialog("DatabaseManager не доступен.")
		return

	var progress: Dictionary = DatabaseManager.LoadPlayerProgress(slot_number)
	if progress == null or progress.is_empty():
		_show_error_dialog("Прогресс пуст для слота %d." % slot_number)
		return

	if QuestManager:
		QuestManager.player_role = str(progress.get("USER_ROLE", progress.get("user_role", "employee")))
		QuestManager.current_day = int(progress.get("CURRENT_DAY", progress.get("current_day", 1)))
		QuestManager.violations = int(progress.get("VIOLATIONS", progress.get("violations", 0)))
		QuestManager.trust_level = int(progress.get("TRUST_LEVEL", progress.get("trust_level", 50)))

		var raw_flags = progress.get("FLAGS_UNLOCKED", progress.get("flags_unlocked", null))
		if raw_flags != null and str(raw_flags).length() > 0:
			var parsed_flags = JSON.parse_string(str(raw_flags))
			QuestManager.story_flags = parsed_flags if parsed_flags is Dictionary else {}
		else:
			QuestManager.story_flags = {}

		var raw_quests = progress.get("QUESTS_COMPLETED", progress.get("quests_completed", null))
		if raw_quests != null and str(raw_quests).length() > 0:
			var parsed_quests = JSON.parse_string(str(raw_quests))
			QuestManager.completed_quests = parsed_quests if parsed_quests is Array else []
		else:
			QuestManager.completed_quests = []

		print("✅ Сохранение загружено: день %d, роль %s" % [QuestManager.current_day, QuestManager.player_role])

	# Синхронизируем GameState
	if GameState:
		GameState.current_day = QuestManager.current_day
		GameState.security_violations = QuestManager.violations
		GameState.story_flags = QuestManager.story_flags.duplicate()

	get_tree().change_scene_to_file("res://scenes/desktop/desktop.tscn")


# ──────────── Создание ────────────

func _on_create_pressed(slot_number: int) -> void:
	print("➕ Создание слота %d..." % slot_number)

	if not DatabaseManager:
		_show_error_dialog("DatabaseManager не доступен.")
		return

	var success: bool = DatabaseManager.CreateSaveSlot(slot_number)
	if success:
		print("✅ Слот %d создан — запускаю игру" % slot_number)

		# Инициализируем QuestManager для новой игры
		if QuestManager:
			QuestManager.reset_progress()
			QuestManager.current_day = 1

		# Синхронизируем GameState
		if GameState:
			GameState.current_day = 1
			GameState.security_violations = 0
			GameState.story_flags = {}

		# Сразу запускаем рабочий стол (день 1)
		get_tree().change_scene_to_file("res://scenes/desktop/desktop.tscn")
	else:
		_show_error_dialog("Ошибка создания слота %d.\nВозможно, слот уже существует." % slot_number)


# ──────────── Удаление ────────────

func _on_delete_pressed(slot_number: int) -> void:
	print("🗑 Удаление слота %d..." % slot_number)

	var confirm := ConfirmationDialog.new()
	confirm.title = "Подтверждение удаления"
	confirm.dialog_text = "Удалить сохранение в слоте %d?\n\nЭто действие нельзя отменить." % slot_number
	_add_retro_theme_to_dialog(confirm)
	add_child(confirm)
	confirm.popup_centered(Vector2i(550, 180))

	confirm.confirmed.connect(func():
		if not DatabaseManager:
			_show_error_dialog("DatabaseManager не доступен.")
			return
		var ok: bool = DatabaseManager.DeleteSaveSlot(slot_number)
		if ok:
			print("✅ Слот %d удалён" % slot_number)
			_refresh_slots()
		else:
			_show_error_dialog("Ошибка удаления слота %d." % slot_number)
		confirm.queue_free()
	)

	confirm.canceled.connect(func():
		confirm.queue_free()
	)


# ──────────── Авто-сохранение ────────────

func _on_autosave_toggled() -> void:
	var enabled: bool = autosave_checkbox.button_pressed
	print("🔄 Авто-сохранение: %s" % ("включено" if enabled else "выключено"))
	var auto_save_mgr = get_node_or_null("/root/AutoSaveManager")
	if auto_save_mgr:
		auto_save_mgr.autosave_enabled = enabled


# ──────────── Навигация ────────────

func _on_back_pressed() -> void:
	# Если пришли из пауз-меню — возвращаемся туда, иначе в главное меню
	if GameState and GameState.previous_scene != "":
		var target = GameState.previous_scene
		GameState.previous_scene = ""
		get_tree().change_scene_to_file(target)
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn.tscn")


# ──────────── Утилиты ────────────

func _came_from_pause() -> bool:
	"""Проверка: пришли ли мы из пауз-меню (через кнопку «Сохранить»)."""
	if GameState:
		return GameState.previous_scene.begins_with("res://scenes/") and GameState.previous_scene != "res://scenes/main_menu/main_menu.tscn.tscn"
	return false


func _on_save_current(slot_number: int) -> void:
	"""Сохранить текущий прогресс в указанный слот и вернуться в игру."""
	print("💾 Сохранение в слот %d..." % slot_number)

	if not DatabaseManager or not QuestManager:
		_show_error_dialog("Невозможно сохранить — данные не доступны.")
		return

	var auto_mgr = get_node_or_null("/root/AutoSaveManager")
	var playtime = auto_mgr.get_playtime_minutes() if auto_mgr else 0

	DatabaseManager.AutoSave(
		slot_number,
		QuestManager.current_day,
		QuestManager.violations,
		QuestManager.trust_level,
		QuestManager.story_flags,
		QuestManager.completed_quests,
		playtime
	)

	print("✅ Слот %d сохранён — возвращаюсь в игру" % slot_number)

	# Возвращаемся в предыдущую сцену
	if GameState and GameState.previous_scene != "":
		var target = GameState.previous_scene
		GameState.previous_scene = ""
		get_tree().change_scene_to_file(target)
	else:
		get_tree().change_scene_to_file("res://scenes/desktop/desktop.tscn")


func _retro_font() -> FontFile:
	return preload("res://assets/fonts/PressStart2P-Regular.ttf")


func _add_retro_theme_to_dialog(dialog: Window) -> void:
	var font: FontFile = _retro_font()
	var dlg_theme := Theme.new()
	dlg_theme.default_font = font
	dlg_theme.default_font_size = 12
	dialog.theme = dlg_theme


func _show_error_dialog(message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "❌ Ошибка"
	dialog.dialog_text = message
	dialog.ok_button_text = "OK"
	_add_retro_theme_to_dialog(dialog)
	add_child(dialog)
	dialog.popup_centered(Vector2i(550, 220))
	dialog.confirmed.connect(dialog.queue_free)
