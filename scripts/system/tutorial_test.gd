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
var is_processing: bool = false  # Флаг блокировки ввода во время анимаций/таймеров

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
	is_processing = false
	
	print("📝 Вопрос ", index + 1, "/", tutorial_questions.size())


func check_answer():
	"""Проверка ответа"""
	if is_processing:
		return  # Игнорируем повторные нажатия во время обработки
	
	var q = tutorial_questions[current_question_index]
	var user_answer = answer_input.text.strip_edges().to_upper()
	var correct_answer = q["correct_answer"].strip_edges().to_upper()
	
	if user_answer == correct_answer:
		# ✅ Правильно
		feedback_label.text = "✅ Правильно! " + q["explanation"]
		feedback_label.add_theme_color_override("font_color", Color.GREEN)
		
		# Блокируем ввод на время показа сообщения
		is_processing = true
		
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
	if is_processing:
		return
	
	if current_question_index < tutorial_questions.size():
		current_question_index += 1
		show_question(current_question_index)
	else:
		# Возвращаемся на рабочий стол
		get_tree().change_scene_to_file("res://scenes/desktop/desktop.tscn")


func _on_skip_pressed():
	"""Пропуск вопроса (с нарушением!)"""
	if is_processing:
		return
	
	print("⚠️ Вопрос пропущен")
	feedback_label.text = "⚠️ Вопрос пропущен. Это считается как нарушение."
	feedback_label.add_theme_color_override("font_color", Color.ORANGE)
	violations_in_test += 1
	
	# Блокируем ввод на время показа сообщения
	is_processing = true
	
	await get_tree().create_timer(1.5).timeout
	current_question_index += 1
	show_question(current_question_index)


func _on_hint_pressed():
	"""Показ подсказки"""
	if is_processing:
		return
	
	var q = tutorial_questions[current_question_index]
	feedback_label.text = "💡 Подсказка: " + q["hint"]
	feedback_label.add_theme_color_override("font_color", Color.YELLOW)


func _on_answer_submitted(new_text: String):
	"""Enter в поле ответа"""
	check_answer()
