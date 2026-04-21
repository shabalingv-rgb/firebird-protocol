extends Control

@onready var question_label = $QuestionContainer/QuestionLabel
@onready var code_example = $QuestionContainer/CodeExample
@onready var answer_input = $QuestionContainer/AnswerInput
@onready var feedback_label = $FeedbackLabel
@onready var progress_bar = $ProgressBar
@onready var next_button = $NextButton
@onready var skip_button = $SkipButton
@onready var hint_button = $QuestionContainer/HintButton

var current_question_index: int = 0
var test_completed: bool = false
var violations_in_test: int = 0
var is_busy: bool = false  # Флаг блокировки ввода во время анимаций/таймеров

# Вопросы инструктажа
var tutorial_questions: Array = [
	{
		"question": "Vopros 1: Kakaya komanda ispolzuetsya dlya vyborki dannykh iz tablicy?",
		"code_example": "-- Primer:\n??? * FROM employees",
		"correct_answer": "SELECT",
		"hint": "Eta komanda nachinaetsya na bukvu 'S'",
		"explanation": "Komanda SELECT ispolzuetsya dlya vyborki dannykh iz tablicy."
	},
	{
		"question": "Vopros 2: Kakoe klyuchevoe slovo ukazyvaet tablicu dlya zaprosa?",
		"code_example": "SELECT * ??? employees",
		"correct_answer": "FROM",
		"hint": "Eto slovo perevoditsya kak 'IZ'",
		"explanation": "Klyuchevoe slovo FROM ukazyvaet istochnik dannykh."
	},
	{
		"question": "Vopros 3: Kak otfiltrirovat zapisi po usloviyu?",
		"code_example": "SELECT * FROM employees ??? salary > 50000",
		"correct_answer": "WHERE",
		"hint": "Perevoditsya kak 'GDE'",
		"explanation": "WHERE filtriruet rezultaty po zadannomu usloviyu."
	},
	{
		"question": "Vopros 4: Prakticheskoe zadanie - poluchite vsekh sotrudnikov",
		"code_example": "-- Napishite polnyj zapros:\n-- Tablica: employees\n-- Nuzhno: vse kolonki",
		"correct_answer": "SELECT * FROM employees",
		"hint": "SELECT + * + FROM + imya_tablicy",
		"explanation": "Otlichno! Eto bazovyj zapros dlya polucheniya vsekh dannykh."
	},
	{
		"question": "Vopros 5: Prakticheskoe zadanie - najdite sotrudnikov iz IT otdela",
		"code_example": "-- Tablica: employees\n-- Uslovie: department = 'IT'",
		"correct_answer": "SELECT * FROM employees WHERE department = 'IT'",
		"hint": "Dobavte WHERE posle FROM",
		"explanation": "Prevoskhodno! Vy gotovy k rabote!"
	}
]

func _ready():
	print("📚 Tutorial Test загружен")
	
	# Подключаем сигналы
	next_button.pressed.connect(_on_next_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	hint_button.pressed.connect(_on_hint_pressed)
	answer_input.text_submitted.connect(_on_answer_submitted)
	
	# Показываем первый вопрос
	show_question(0)


func _input(event):
	# Обработка ввода только английских букв и символов SQL (как в терминале)
	if event is InputEventKey and event.pressed and answer_input.has_focus():
		# A-Z — вводим английские буквы (физические клавиши, любая раскладка)
		if event.keycode >= KEY_A and event.keycode <= KEY_Z:
			get_viewport().set_input_as_handled()
			var letter = char(event.keycode) if event.shift_pressed else char(event.keycode + 32)
			_insert_text(answer_input.caret_column, letter)
			return
		
		# 0-9
		if event.keycode >= KEY_0 and event.keycode <= KEY_9:
			get_viewport().set_input_as_handled()
			var idx = event.keycode - KEY_0
			var ch = str(idx)
			_insert_text(answer_input.caret_column, ch)
			return
		
		# Символы SQL: * = < > ' , . ( ) - _ пробел
		var sql_symbols = {
			KEY_ASTERISK: "*", KEY_EQUAL: "=", KEY_LESS: "<", KEY_GREATER: ">",
			KEY_APOSTROPHE: "'", KEY_COMMA: ",", KEY_PERIOD: ".",
			KEY_PARENLEFT: "(", KEY_PARENRIGHT: ")",
			KEY_MINUS: "-", KEY_UNDERSCORE: "_", KEY_SPACE: " "
		}
		if event.keycode in sql_symbols:
			get_viewport().set_input_as_handled()
			var ch = sql_symbols[event.keycode]
			_insert_text(answer_input.caret_column, ch)
			return
		
		# Backspace
		if event.keycode == KEY_BACKSPACE:
			get_viewport().set_input_as_handled()
			var caret = answer_input.caret_column
			if caret > 0:
				var text = answer_input.text
				answer_input.text = text.erase(caret - 1, 1)
				answer_input.caret_column = caret - 1
			return
		
		# Delete
		if event.keycode == KEY_DELETE:
			get_viewport().set_input_as_handled()
			var text = answer_input.text
			var caret = answer_input.caret_column
			if caret < text.length():
				answer_input.text = text.erase(caret, 1)
				answer_input.caret_column = caret
			return
		
		# Стрелки влево/вправо
		if event.keycode == KEY_LEFT:
			get_viewport().set_input_as_handled()
			if answer_input.caret_column > 0:
				answer_input.caret_column -= 1
			return
		if event.keycode == KEY_RIGHT:
			get_viewport().set_input_as_handled()
			if answer_input.caret_column < answer_input.text.length():
				answer_input.caret_column += 1
			return
		
		# Enter (уже обрабатывается через text_submitted, но на всякий случай)
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
			check_answer()
			return


func _insert_text(at_position: int, text_to_insert: String):
	"""Вставка текста в указанную позицию"""
	var current_text = answer_input.text
	answer_input.text = current_text.insert(at_position, text_to_insert)
	answer_input.caret_column = at_position + text_to_insert.length()


func show_question(index: int):
	"""Показ вопроса"""
	if index >= tutorial_questions.size():
		complete_tutorial()
		return
	
	var q = tutorial_questions[index]
	
	question_label.text = q["question"]
	code_example.text = q["code_example"]
	answer_input.text = ""
	answer_input.grab_focus()
	feedback_label.text = ""
	feedback_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Обновляем прогресс
	progress_bar.value = (index * 100.0) / tutorial_questions.size()
	
	# Снимаем блокировку ввода
	is_busy = false
	
	print("📝 Вопрос ", index + 1, "/", tutorial_questions.size())


func check_answer():
	"""Проверка ответа"""
	if is_busy:
		return  # Игнорируем повторные нажатия во время обработки
	
	var q = tutorial_questions[current_question_index]
	var user_answer = answer_input.text.strip_edges().to_upper()
	var correct_answer = q["correct_answer"].strip_edges().to_upper()
	
	if user_answer == correct_answer:
		# ✅ Правильно
		feedback_label.text = "✅ Правильно! " + q["explanation"]
		feedback_label.add_theme_color_override("font_color", Color.GREEN)
		
		# Блокируем ввод на время показа сообщения
		is_busy = true
		
		# Воспроизводим звук успеха (опционально)
		# $SuccessSound.play()
		
		await get_tree().create_timer(2.0).timeout
		current_question_index += 1
		show_question(current_question_index)
	else:
		# ❌ Неправильно
		feedback_label.text = "❌ Неправильно. Попробуйте ещё раз или используйте подсказку."
		feedback_label.add_theme_color_override("font_color", Color.RED)
		violations_in_test += 1


func complete_tutorial():
	"""Завершение инструктажа"""
	test_completed = true
	
	var final_message = ""
	if violations_in_test == 0:
		final_message = "🎉 Отлично! Все ответы правильные с первого раза!"
	elif violations_in_test <= 2:
		final_message = "👍 Хорошо! Вы справились с инструктажем."
	else:
		final_message = "⚠️ Инструктаж пройден, но рекомендуется повторить основы SQL."
	
	question_label.text = "ИНСТРУКТАЖ ЗАВЕРШЁН"
	code_example.text = final_message
	answer_input.visible = false
	hint_button.visible = false
	skip_button.visible = false
	next_button.text = "Продолжить"
	
	progress_bar.value = 100
	
	print("✅ Инструктаж завершён. Ошибок: ", violations_in_test)
	
	# Сохраняем результат в QuestManager
	if QuestManager:
		QuestManager.tutorial_completed = true
		QuestManager.tutorial_violations = violations_in_test
	
	# Разблокируем День 2
	unlock_day_2()


func unlock_day_2():
	"""Разблокировка второго дня"""
	print("🔓 Разблокировка Дня 2...")
	
	if DatabaseManager:
		# Обновляем письмо от HR - убираем условие блокировки
		DatabaseManager.call("ExecuteNonQuery", 
			"UPDATE emails SET unlock_condition = NULL WHERE subject = 'Приглашение на работу'")
		
		# Отмечаем что инструктаж пройден
		DatabaseManager.call("ExecuteNonQuery",
			"UPDATE player_progress SET flags_unlocked = JSON_INSERT(COALESCE(flags_unlocked, '{}'), '$.tutorial_completed', true) WHERE save_slot = 1")
		
		print("✅ День 2 разблокирован!")


func _on_next_pressed():
	if is_busy:
		return
	
	if current_question_index < tutorial_questions.size():
		current_question_index += 1
		show_question(current_question_index)
	else:
		# Возвращаемся на рабочий стол (или в почту)
		get_tree().change_scene_to_file("res://scenes/desktop/desktop.tscn")


func _on_skip_pressed():
	"""Пропуск вопроса (с нарушением!)"""
	if is_busy:
		return
	
	print("⚠️ Вопрос пропущен")
	feedback_label.text = "⚠️ Вопрос пропущен. Это считается как нарушение."
	feedback_label.add_theme_color_override("font_color", Color.ORANGE)
	violations_in_test += 1
	
	# Блокируем ввод на время показа сообщения
	is_busy = true
	
	await get_tree().create_timer(1.5).timeout
	current_question_index += 1
	show_question(current_question_index)


func _on_hint_pressed():
	"""Показ подсказки"""
	if is_busy:
		return
	
	var q = tutorial_questions[current_question_index]
	feedback_label.text = "💡 Подсказка: " + q["hint"]
	feedback_label.add_theme_color_override("font_color", Color.YELLOW)


func _on_answer_submitted(_new_text: String):
	"""Enter в поле ответа"""
	check_answer()
