extends Control

# Ссылки на узлы
@onready var subject_label = $EmailHeader/Subject
@onready var sender_label = $EmailHeader/Sender
@onready var date_label = $EmailHeader/DateLabel
@onready var reply_button = $EmailHeader/ReplyButton
@onready var body_label = $EmailBody
@onready var back_button = $BackButton
@onready var email_tabs = $EmailTabs
@onready var inbox_list = $EmailTabs/Входящие/InboxList
@onready var archive_list = $EmailTabs/Архив/ArchiveList

# Данные
var current_emails: Array = []       # Письма текущего дня (все)
var active_quest: Dictionary = {}     # Текущее активное задание
var original_email_body: String = ""  # Для восстановления текста
var archived_emails: Array = []       # Архив: прочитанные + выполненные квесты

# Шрифт для уведомлений
var quest_font: FontFile = preload("res://assets/fonts/PressStart2P-Regular.ttf")

# Глобальное хранилище архива (чтобы не терять при переоткрытии сцены)
static var persistent_archive: Array = []

func _ready():
	if inbox_list:
		inbox_list.item_selected.connect(_on_inbox_selected)
	if archive_list:
		archive_list.item_selected.connect(_on_archive_selected)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if reply_button:
		reply_button.pressed.connect(_on_reply_button_pressed)
	if email_tabs:
		email_tabs.tab_changed.connect(_on_tab_changed)

	print("📧 Email Client загружен")

	if DatabaseManager and not DatabaseManager.DatabaseReady.is_connected(_on_database_ready):
		DatabaseManager.DatabaseReady.connect(_on_database_ready)

	# Восстанавливаем архив из глобального хранилища
	archived_emails = persistent_archive.duplicate()

	# Применяем игровой шрифт к вкладкам
	if email_tabs:
		var tabs_theme = Theme.new()
		tabs_theme.default_font = quest_font
		tabs_theme.default_font_size = 12
		email_tabs.theme = tabs_theme

	var day := 1
	if QuestManager:
		day = QuestManager.current_day

	if DatabaseManager and DatabaseManager.IsInitialized:
		load_emails_for_day(day)
	else:
		pass

func _load_archived_emails():
	"""Загрузка архива из сохранённого прогресса (если есть)."""
	# Пока архив пуст — будет заполняться при смене дня/завершении квеста
	archived_emails = []

func _on_database_ready():
	print("📧 Email Client: БД готова")
	if QuestManager:
		load_emails_for_day(QuestManager.current_day)
	else:
		load_emails_for_day(1)

# ═══════════════════════════════════════════
# ЗАГРУЗКА ПИСЕМ
# ═══════════════════════════════════════════

func load_emails_for_day(day_number: int):
	print("📬 Загрузка писем для дня ", day_number)

	if not DatabaseManager:
		print("❌ DatabaseManager не доступен")
		return

	# Архивируем все письма предыдущих дней (чтобы не потерять при переоткрытии сцены)
	if day_number > 1:
		for prev_day in range(1, day_number):
			var prev_emails_data = DatabaseManager.GetEmailsForDay(prev_day)
			for email_data in prev_emails_data:
				var gd_email = {}
				for key in email_data.keys():
					var normalized_key = str(key).to_lower()
					gd_email[normalized_key] = email_data[key]

				var email_id = int(gd_email.get("id", gd_email.get("ID", -1)))
				var already_archived = false
				for archived in archived_emails:
					if int(archived.get("id", archived.get("ID", -1))) == email_id:
						already_archived = true
						break
				if not already_archived:
					archived_emails.append(gd_email)
					persistent_archive.append(gd_email)

	var emails_data = DatabaseManager.GetEmailsForDay(day_number)

	current_emails = []
	for email_data in emails_data:
		var gd_email = {}
		for key in email_data.keys():
			var normalized_key = str(key).to_lower()
			gd_email[normalized_key] = email_data[key]

		var email_id = int(gd_email.get("id", gd_email.get("ID", -1)))
		var already_archived = false
		for archived in archived_emails:
			if int(archived.get("id", archived.get("ID", -1))) == email_id:
				already_archived = true
				break
		if already_archived:
			continue

		current_emails.append(gd_email)

	if current_emails.is_empty():
		print("⚠️ Писем нет для дня ", day_number)
		show_empty_message()
	else:
		print("✅ Писем загружено: ", current_emails.size())
		refresh_inbox()

func refresh_inbox():
	if not inbox_list:
		return

	inbox_list.clear()

	# Сначала собираем письма для архивации (нельзя модифицировать массив во время итерации)
	var to_archive = []
	for email in current_emails:
		var email_type = email.get("email_type", "")
		var email_id = email.get("id", email.get("ID", -1))
		if email_type == "quest" and QuestManager and QuestManager.is_quest_completed(email_id):
			to_archive.append(email)

	# Архивируем выполненные
	for email in to_archive:
		archive_email(email)

	# Отображаем оставшиеся
	for email in current_emails:
		var subject = email.get("subject", "Без темы")
		var sender = email.get("sender", "Неизвестно")
		var email_type = email.get("email_type", "info")
		var icon = _get_email_icon(email_type)
		inbox_list.add_item(icon + subject + " — " + sender)
		inbox_list.set_item_metadata(inbox_list.item_count - 1, inbox_list.item_count - 1)

	# Авто-выбор первого письма
	if inbox_list.item_count > 0:
		inbox_list.select(0)
		var idx = inbox_list.get_item_metadata(0)
		if idx >= 0 and idx < current_emails.size():
			show_email(current_emails[idx])
	elif archived_emails.size() > 0:
		refresh_archive()

func _get_email_icon(email_type: String) -> String:
	match email_type:
		"quest": return "🎯 "
		"info": return "📄 "
		"warning": return "⚠️ "
		_: return "📄 "

func refresh_archive():
	"""Обновление списка архива."""
	if not archive_list:
		return

	archive_list.clear()

	for i in range(archived_emails.size()):
		var email = archived_emails[i]
		var subject = email.get("subject", "Без темы")
		var sender = email.get("sender", "Неизвестно")
		var email_type = email.get("email_type", "info")
		var day_id = email.get("day_id", email.get("DAY_ID", "?"))

		var icon = _get_email_icon(email_type)
		var day_prefix = "[День %s] " % str(day_id)
		archive_list.add_item(icon + day_prefix + subject + " — " + sender)
		archive_list.set_item_metadata(i, i)

# ═══════════════════════════════════════════
# ВЫБОР ПИСЕМ
# ═══════════════════════════════════════════

func _on_inbox_selected(index: int):
	"""Выбор письма во входящих."""
	var metadata = inbox_list.get_item_metadata(index)
	if metadata >= 0 and metadata < current_emails.size():
		# Письмо из текущего дня
		show_email(current_emails[metadata])
	elif metadata < 0:
		# Письмо из архива (незавершённый квест)
		var archive_index = -metadata - 1
		if archive_index >= 0 and archive_index < archived_emails.size():
			show_email(archived_emails[archive_index])

func _on_archive_selected(index: int):
	if index >= 0 and index < archived_emails.size():
		show_archived_email(archived_emails[index])

func show_archived_email(email: Dictionary):
	"""Показать письмо из архива (без кнопки ответа)."""
	subject_label.text = email.get("SUBJECT", email.get("subject", "Без темы"))
	sender_label.text = "От: " + email.get("SENDER", email.get("sender", "Неизвестно"))
	body_label.text = email.get("BODY", email.get("body", ""))
	original_email_body = body_label.text

	if has_node("EmailHeader/ReplyButton"):
		$EmailHeader/ReplyButton.visible = false

func _on_tab_changed(tab: int):
	"""При переключении вкладки обновляем отображение."""
	if tab == 1:  # Архив
		refresh_archive()

# ═══════════════════════════════════════════
# ОТОБРАЖЕНИЕ ПИСЬМА
# ═══════════════════════════════════════════

func show_email(email: Dictionary):
	subject_label.text = email.get("SUBJECT", email.get("subject", "Без темы"))
	sender_label.text = "От: " + email.get("SENDER", email.get("sender", "Неизвестно"))
	
	# Помечаем письмо прочитанным в БД (и обновляем кэш)
	var email_id = email.get("ID", email.get("id", -1))
	if email_id > 0 and DatabaseManager and DatabaseManager.IsInitialized:
		DatabaseManager.MarkEmailAsRead(email_id)
	body_label.text = email.get("BODY", email.get("body", ""))
	original_email_body = body_label.text

	# Кнопка для квестов
	var email_type = email.get("email_type", email.get("EMAIL_TYPE", "")).to_lower()

	if email_type == "quest":
		if has_node("EmailHeader/ReplyButton"):
			$EmailHeader/ReplyButton.visible = true
			$EmailHeader/ReplyButton.text = "📤 Отправить отчёт"
			var quest_email_id = int(email.get("id", email.get("ID", 0)))
			load_quest_for_email(quest_email_id)
	else:
		if has_node("EmailHeader/ReplyButton"):
			$EmailHeader/ReplyButton.visible = false

# ═══════════════════════════════════════════
# АРХИВИРОВАНИЕ
# ═══════════════════════════════════════════

func archive_email(email: Dictionary):
	var email_id = email.get("id", email.get("ID", -1))
	for archived in archived_emails:
		if archived.get("id", archived.get("ID", -1)) == email_id:
			return

	archived_emails.append(email.duplicate())
	persistent_archive.append(email.duplicate())
	# Удаляем из current_emails (если ещё там)
	for i in range(current_emails.size() - 1, -1, -1):
		if int(current_emails[i].get("id", current_emails[i].get("ID", -1))) == int(email_id):
			current_emails.remove_at(i)
			break

func archive_current_day_emails():
	var to_archive = current_emails.duplicate()
	for email in to_archive:
		archive_email(email)

func archive_completed_quest_email():
	var email_id = active_quest.get("EMAIL_ID", active_quest.get("email_id", -1))
	if email_id < 0:
		return
	for i in range(current_emails.size() - 1, -1, -1):
		if int(current_emails[i].get("id", current_emails[i].get("ID", -1))) == int(email_id):
			archive_email(current_emails[i])
			refresh_inbox()
			refresh_archive()
			return

# ═══════════════════════════════════════════
# ОТПРАВКА ОТЧЁТА
# ═══════════════════════════════════════════

func _on_reply_button_pressed():
	if active_quest.is_empty():
		show_quest_not_completed_warning("Нет активного задания для этого письма!")
		return

	var quest_id = active_quest.get("ID", active_quest.get("id", -1))
	if QuestManager and not QuestManager.is_quest_completed(quest_id):
		show_quest_not_completed_warning("Сначала выполните SQL-запрос в терминале! Система не подтвердила завершение задания.")
		return

	show_report_dialog()

func show_report_dialog():
	var dialog = ConfirmationDialog.new()
	dialog.title = "📤 Отправка отчёта"
	dialog.dialog_text = "Выберите вариант отчёта:"
	dialog.ok_button_text = "Отправить"
	dialog.cancel_button_text = "Отмена"
	dialog.theme = _create_quest_theme()

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)

	var spacer = Label.new()
	spacer.text = ""
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	var options = [
		"Задание выполнено. Данные прилагаются.",
		"Обнаружены аномалии. Требуется проверка.",
		"Ничего подозрительного не найдено."
	]

	var button_group = ButtonGroup.new()
	var radio_buttons = []

	for i in range(options.size()):
		var radio = Button.new()
		radio.toggle_mode = true
		radio.button_group = button_group
		radio.alignment = HORIZONTAL_ALIGNMENT_LEFT
		radio.text = "● " + options[i] if i == 0 else "○ " + options[i]
		radio.pressed.connect(func():
			for rb in radio_buttons:
				rb.text = "○ " + rb.get_meta("option_text")
			radio.text = "● " + options[i]
		)
		radio.set_meta("option_text", options[i])
		radio_buttons.append(radio)
		vbox.add_child(radio)

	if radio_buttons.size() > 0:
		radio_buttons[0].button_pressed = true

	var spacer_bottom = Label.new()
	spacer_bottom.text = ""
	spacer_bottom.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer_bottom)

	dialog.add_child(vbox)

	dialog.confirmed.connect(func():
		var selected = button_group.get_pressed_button()
		var report = selected.get_meta("option_text") if selected else options[0]
		send_report(report)
	)

	add_child(dialog)
	dialog.popup_centered(Vector2i(600, 230))

func send_report(report_text: String):
	print("📤 Отчёт отправлен: ", report_text)
	var qid = int(active_quest.get("ID", active_quest.get("id", 0)))
	DatabaseManager.SavePlayerChoice(qid, "report_text", report_text, QuestManager.current_day)

	if "аномалии" in report_text.to_lower() or "ошибки" in report_text.to_lower():
		QuestManager.set_story_flag("reported_anomaly")

	# Архивируем письмо связанного задания
	archive_completed_quest_email()

	show_success_message()

# ═══════════════════════════════════════════
# ВСПОМОГАТЕЛЬНЫЕ
# ═══════════════════════════════════════════

func show_quest_not_completed_warning(details: String):
	var dialog = AcceptDialog.new()
	dialog.title = "⛔ Задание не выполнено"
	dialog.dialog_text = details + "\n\nОткройте терминал и выполните SQL-запрос, затем нажмите 'Отправить' снова."
	dialog.ok_button_text = "Понятно"
	dialog.theme = _create_quest_theme()
	add_child(dialog)
	dialog.popup_centered(Vector2i(600, 250))
	dialog.confirmed.connect(dialog.queue_free)

func show_success_message():
	var dialog = AcceptDialog.new()
	dialog.title = "✅ Задание выполнено"
	dialog.dialog_text = "Отчёт отправлен руководству!\nЗадание успешно завершено."
	dialog.theme = _create_quest_theme()
	add_child(dialog)
	dialog.popup_centered(Vector2i(500, 200))
	dialog.confirmed.connect(dialog.queue_free)

func show_error_message(msg: String):
	var dialog = AcceptDialog.new()
	dialog.title = "❌ Ошибка"
	dialog.dialog_text = msg
	dialog.theme = _create_quest_theme()
	add_child(dialog)
	dialog.popup_centered(Vector2i(500, 200))
	dialog.confirmed.connect(dialog.queue_free)

func show_empty_message():
	if has_node("EmailHeader/Subject"):
		$EmailHeader/Subject.text = "Нет писем"
	if has_node("EmailHeader/Sender"):
		$EmailHeader/Sender.text = "От: "
	if has_node("EmailBody"):
		$EmailBody.text = "Задания будут приходить по мере выполнения работы."

func _create_quest_theme() -> Theme:
	var new_theme = Theme.new()
	new_theme.default_font = quest_font
	new_theme.default_font_size = 14
	return new_theme

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/desktop/desktop.tscn")

func load_quest_for_email(email_id: int):
	var quest_data = DatabaseManager.GetQuestForEmail(email_id)

	if quest_data and not quest_data.is_empty():
		active_quest = {}
		for key in quest_data.keys():
			active_quest[key] = quest_data[key]
	else:
		print("⚠️ Задание не найдено для email_id=", email_id)

func submit_quest_report(quest_id: String):
	if QuestManager.active_quest and not QuestManager.active_quest.is_empty():
		var active_id = QuestManager.active_quest.get("ID", QuestManager.active_quest.get("id", ""))
		if str(active_id) == quest_id:
			QuestManager.complete_quest(true)
			show_success_message()
		else:
			show_quest_not_completed_warning("Активное задание не совпадает. Выполните текущее задание в терминале.")
	else:
		show_quest_not_completed_warning("Нет активного задания! Откройте терминал и выполните SQL-запрос.")
