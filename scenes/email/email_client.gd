extends Control

# ⭐ ОБЯЗАТЕЛЬНО в начале файла!
@onready var subject_label = $EmailHeader/Subject
@onready var sender_label = $EmailHeader/Sender
@onready var date_label = $EmailHeader/DateLabel
@onready var email_list = $EmailList
@onready var reply_button = $EmailHeader/ReplyButton
@onready var body_label = $EmailBody
@onready var back_button = $BackButton

var current_emails: Array = []
var current_day_emails: Array = []
var active_quest: Dictionary = {}
var original_email_body: String = ""  # Для восстановления текста при предупреждении

# Шрифт для уведомлений (загружаем один раз)
var quest_font: FontFile = preload("res://assets/fonts/PressStart2P-Regular.ttf")

# Вспомогательная функция для получения значения из C# словаря (регистронезависимо)
func get_dict_value(data: Dictionary, key: String, default = null):
	"""Получение значения из словаря с игнорированием регистра ключей"""
	# Сначала пробуем как есть
	if data.has(key):
		return data[key]
	
	# Потом ищем без учёта регистра
	var key_lower = key.to_lower()
	for k in data.keys():
		if str(k).to_lower() == key_lower:
			return data[k]
	
	return default

func _ready():
	if email_list:
		email_list.item_selected.connect(_on_email_selected)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if reply_button:
		reply_button.pressed.connect(_on_reply_button_pressed)

	print("📧 Email Client загруен")

	if DatabaseManager and not DatabaseManager.DatabaseReady.is_connected(_on_database_ready):
		DatabaseManager.DatabaseReady.connect(_on_database_ready)

	var day := 1
	if QuestManager:
		day = QuestManager.current_day

	if DatabaseManager and DatabaseManager.IsInitialized:
		load_emails_for_day(day)
	else:
		# БД поднимется позже — _on_database_ready вызовет load_emails_for_day
		pass

	# ❌ УДАЛИ ЭТОТ БЛОК (устарел):
	# if EmailSystem.inbox.is_empty():
	#     print("⚠️ Входящих писем нет!")
	#     subject_label.text = "Нет писем"
	#     return

func refresh_email_list():
	if not email_list:
		return
	
	email_list.clear()
	
	for i in range(EmailSystem.inbox.size()):
		var email = EmailSystem.inbox[i]
		var time = email.get("TIME", "Неизвестно")
		var sender = email.get("FROM", "Unknown")
		var subject = email.get("SUBJECT", "Без темы")
		
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
		# Используем .get() для првоерки статуса 'READ' (или 'read')
		# Если ключа нет, по умолчанию возвращаем false
		var is_read = email.get("READ", email.get("read", false))
		
		if not is_read:
			show_email(email)
			return
	
	# Если все прочитаны, покажем последнее
	if EmailSystem.inbox.size() > 0:
		show_email(EmailSystem.inbox[-1])

func show_email(email: Dictionary):
	subject_label.text = email.get("SUBJECT", "Без темы")
	sender_label.text = email.get("SENDER", "Неизвестно")
	body_label.text = email.get("BODY", "")
	original_email_body = body_label.text  # Сбрасываем оригинальный текст
	EmailSystem.mark_as_read(email)

	# Обновляем список (чтобы показать что прочитано)
	refresh_email_list()

	# Добавляем кнопку "Отправить отчёт" если это письмо с заданием
	var email_type = email.get("email_type", email.get("EMAIL_TYPE", "")).to_lower()
	var has_quest_id = email.get("quest_id", email.get("QUEST_ID", null)) != null
	
	if email_type == "quest" or has_quest_id:
		# Это письмо с заданием
		pass

func submit_quest_report(quest_id: String):
	# Проверяем, что есть активное задание и его ID совпадает
	if QuestManager.active_quest and not QuestManager.active_quest.is_empty():
		var active_id = QuestManager.active_quest.get("ID", QuestManager.active_quest.get("id", ""))
		if str(active_id) == quest_id:
			QuestManager.complete_quest(true)
			show_success_message()
		else:
			show_quest_not_completed_warning("Активное задание не совпадает. Выполните текущее задание в терминале.")
	else:
		show_quest_not_completed_warning("Нет активного задания! Откройте терминал и выполните SQL-запрос.")

func show_quest_not_completed_warning(details: String):
	"""Показ предупреждения если задание ещё не выполнено"""
	var dialog = AcceptDialog.new()
	dialog.title = "⛔ Задание не выполнено"
	dialog.dialog_text = details + "\n\nОткройте терминал и выполните SQL-запрос, затем нажмите 'Отправить' снова."
	dialog.ok_button_text = "Понятно"
	
	# Применяем игровой шрифт
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

func _create_quest_theme() -> Theme:
	"""Создаёт тему с игровым шрифтом для диалогов"""
	var theme = Theme.new()
	theme.default_font = quest_font
	theme.default_font_size = 14
	return theme

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
	"""Загрузка писем для конкретного дня из кэша Firebird"""
	print("📬 Загрузка писем для дня ", day_number)
	
	if not DatabaseManager:
		print("❌ DatabaseManager не доступен")
		return
	
	# ✅ Используем C# метод из FirebirdDatabase.cs
	var emails_data = DatabaseManager.GetEmailsForDay(day_number)

	print("📋 В кэше всего писем: ", DatabaseManager.GetCachedEmailsCount())
	print("📫 Писем для дня ", day_number, ": ", emails_data.size())
	
	# Конвертируем C# Dictionary в GDScript Dictionary
	current_emails = []
	for email_data in emails_data:
		var gd_email = {}
		for key in email_data.keys():
			var normalized_key = str(key).to_lower()
			gd_email[normalized_key] = email_data[key]
		print("🔍 Ключи в письме: ", gd_email.keys())
		print("📧 subject = ", gd_email.get("subject", "[НЕ НАЙДЕНО]"))
		current_emails.append(gd_email)
	
	current_day_emails = current_emails
	
	# Отладочный вывод
	for email in current_emails:
		print("📧 Письмо: ", email.get("subject", "Без темы"))
	
	# ✅ ОДИН БЛОК (убери дубликат!)
	if current_emails.is_empty():
		print("⚠️ Писем нет для дня ", day_number)
		show_empty_message()
	else:
		print("✅ Писем загружено: ", current_emails.size())
		display_emails_list()
		display_email_content(0)  # ← Показываем первое письмо

func display_emails_list():
	#Отображение списка писем в EmailList
	email_list.clear()

	for i in range(current_emails.size()):
		var email = current_emails[i]
		var subject = email.get("SUBJECT", email.get("subject", "Без темы"))
		var sender = email.get("SENDER", email.get("sender", "Неизвестно"))
		var email_type = email.get("email_type", "info")

		#Иконка в зависимости от типа
		var icon = ""
		match email_type:
			"quest": icon = "🎯 "
			"info": icon = "📄 "
			"warning": icon = "⚠️ "

		#Добавляем в список (храним индекс для поиска)
		email_list.add_item(icon + subject + " - " + sender)
		email_list.set_item_metadata(i, i) #Сохраняем индекс

	#Авто-выбор первого письма
	if current_emails.size() > 0:
		email_list.select(0)
		display_email_content(0)
	

func display_emails():
	"""Отображение списка писем"""
	$EmailList.clear()
	var idx := 0
	for email in current_day_emails:
		var list_item = str(email.get("SUBJECT", email.get("subject", "Без темы")))
		var is_required = int(email.get("IS_REQUIRED", email.get("is_required", 1))) == 1
		if not is_required:
			list_item = "[Необязательное] " + list_item
		$EmailList.add_item(list_item)
		$EmailList.set_item_metadata(idx, idx)
		idx += 1
		
func _on_email_list_item_selected(index: int):
	"""При клике на письмо в списке"""
	display_email_content(index)

			
func display_email_content(index: int):
	"""Отображение содержимого выбранного письма"""
	if index < 0 or index >= current_emails.size():
		return

	var email = current_emails[index]

	# ✅ Обновляем ВСЕ поля UI
	if has_node("EmailHeader/Subject"):
		$EmailHeader/Subject.text = email.get("subject", "Без темы")
	else:
		print("❌ Не найден узел EmailHeader/Subject")
	
	if has_node("EmailHeader/Sender"):
		$EmailHeader/Sender.text = "От: " + email.get("sender", "Неизвестно")
	else:
		print("❌ Не найден узел EmailHeader/Sender")
	
	if has_node("EmailBody"):
		$EmailBody.bbcode_enabled = true
		$EmailBody.add_theme_font_override("normal_font", quest_font)
		$EmailBody.add_theme_font_override("bold_font", quest_font)
		$EmailBody.add_theme_font_override("italics_font", quest_font)
		$EmailBody.add_theme_font_override("mono_font", quest_font)
		$EmailBody.text = email.get("body", "")
		original_email_body = $EmailBody.text  # Сохраняем оригинальный текст
	else:
		print("❌ Не найден узел EmailBody")
	
	# Показываем кнопку ответа если это задание
	var email_type = email.get("email_type", email.get("EMAIL_TYPE", "")).to_lower()
	
	if email_type == "quest":
		if has_node("EmailHeader/ReplyButton"):
			$EmailHeader/ReplyButton.visible = true
			$EmailHeader/ReplyButton.text = "📤 Отправить отчёт"

			# Загружаем связанное задание
			var email_id = int(email.get("id", email.get("ID", 0)))
			load_quest_for_email(email_id)
	else:
		if has_node("EmailHeader/ReplyButton"):
			$EmailHeader/ReplyButton.visible = false

func _on_reply_button_pressed():
	"""Отправка отчёта"""
	if active_quest.is_empty():
		show_quest_not_completed_warning("Нет активного задания для этого письма!")
		return

	show_report_dialog()

func show_report_dialog():
	"""Показ диалога выбора варианта отчёта"""
	var dialog = ConfirmationDialog.new()
	dialog.title = "📤 Отправка отчёта"
	dialog.dialog_text = "Выберите вариант отчёта:"
	dialog.ok_button_text = "Отправить"
	dialog.cancel_button_text = "Отмена"
	
	# Применяем игровой шрифт
	dialog.theme = _create_quest_theme()

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	
	# Пустой лейбл-распорка чтобы отодвинуть радиокнопки от заголовка
	var spacer = Label.new()
	spacer.text = ""
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	var options = [
		"Задание выполнено. Данные прилагаются.",
		"Обнаружены аномалии. Требуется проверка.",
		"Ничего подозрительного не найдено."
	]

	var selected_report = options[0]
	var radio_buttons = []

	for i in range(options.size()):
		var radio = Button.new()
		radio.toggle_mode = true
		radio.button_pressed = (i == 0)
		radio.alignment = HORIZONTAL_ALIGNMENT_LEFT
		radio.text = "● " + options[i] if i == 0 else "○ " + options[i]
		radio.pressed.connect(func():
			for rb in radio_buttons:
				rb.button_pressed = false
				var idx = radio_buttons.find(rb)
				rb.text = "○ " + options[idx]
			radio.button_pressed = true
			radio.text = "● " + options[radio_buttons.find(radio)]
			selected_report = options[radio_buttons.find(radio)]
		)
		radio_buttons.append(radio)
		vbox.add_child(radio)
	
	# Распорка после радиокнопок
	var spacer_bottom = Label.new()
	spacer_bottom.text = ""
	spacer_bottom.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer_bottom)

	dialog.add_child(vbox)

	dialog.confirmed.connect(func():
		send_report(selected_report)
	)

	add_child(dialog)
	dialog.popup_centered(Vector2i(600, 230))
		


func send_report(report_text: String):
	"""Отправка отчёта"""
	print("📤 Отчёт отправлен: ", report_text)
	var qid = int(active_quest.get("ID", active_quest.get("id", 0)))
	DatabaseManager.SavePlayerChoice(qid, "report_text", report_text, QuestManager.current_day)

	# Проверяем текст отчёта на "подозрительный"
	if "аномалии" in report_text.to_lower() or "ошибки" in report_text.to_lower():
		QuestManager.set_story_flag("reported_anomaly")

	show_success_message()

func show_empty_message():
	"""Показ сообщения что писем нет"""
	if has_node("EmailList"):
		$EmailList.clear()
	
	if has_node("EmailHeader/Subject"):
		$EmailHeader/Subject.text = "Нет писем"
	
	if has_node("EmailHeader/Sender"):
		$EmailHeader/Sender.text = "От: "
	
	if has_node("EmailBody"):
		$EmailBody.text = "Задания будут приходить по мере выполнения работы."

func load_quest_for_email(email_id: int):
	"""Загрузка задания для письма"""
	var quest_data = DatabaseManager.GetQuestForEmail(email_id)

	if quest_data and not quest_data.is_empty():
		active_quest = {}
		for key in quest_data.keys():
			active_quest[key] = quest_data[key]
	else:
		print("⚠️ Задание не найдено для email_id=", email_id)
