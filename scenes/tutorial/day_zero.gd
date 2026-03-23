extends Control

# Система вопросов
var questions: Array[Dictionary] = [
	{
		"question": "Выведите все столбцы из таблицы employees",
		"instruction": "Используйте команду SELECT с символом * для выбора всех колонок.",
		"answer": "SELECT * FROM employees",
		"alternatives": [
			"SELECT * FROM employees;",  # с точкой с запятой
			"select * from employees",    # lowercase
			"SELECT * FROM EMPLOYEES"     # uppercase
		]
	},
	{
		"question": "Выберите только имена (name) из таблицы employees",
		"instruction": "Укажите конкретный столбец вместо *",
		"answer": "SELECT name FROM employees",
		"alternatives": [
			"SELECT name FROM employees;",
			"select name from employees",
			"SELECT NAME FROM EMPLOYEES"
		]
	},
	{
		"question": "Найдите всех сотрудников с зарплатой больше 5000",
		"instruction": "Используйте WHERE для фильтрации: WHERE salary > 5000",
		"answer": "SELECT * FROM employees WHERE salary > 5000",
		"alternatives": [
			"SELECT * FROM employees WHERE salary > 5000;",
			"select * from employees where salary > 5000",
			"SELECT * FROM EMPLOYEES WHERE SALARY > 5000"
		]
	}
]

var current_question_index: int = 0
var correct_answers: int = 0

@onready var title_label = $TutorialPanel/TitleLabel
@onready var instruction_label = $TutorialPanel/InstructionLabel
@onready var query_input = $TutorialPanel/QueryInput
@onready var feedback_label = $TutorialPanel/FeedbackLabel
@onready var check_button = $TutorialPanel/CheckButton
@onready var next_button = $TutorialPanel/NextButton
@onready var progress_bar = $ProgressBar
@onready var skip_button = $TutorialPanel/SkipButton

func _ready():
	# Подключаем кнопки
	check_button.pressed.connect(_on_check_pressed)
	next_button.pressed.connect(_on_next_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	skip_button.visible = false  # Скрыта по умолчанию
	
	# Скрываем кнопку "Далее" изначально
	next_button.visible = false
	
	# Загружаем первый вопрос
	load_question(current_question_index)

func load_question(index: int):
	if index >= questions.size():
		finish_tutorial()
		return
	skip_button.visible = false
	
	var q = questions[index]
	title_label.text = "Вопрос %d из %d" % [index + 1, questions.size()]
	instruction_label.text = "%s\n\n%s" % [q.question, q.instruction]
	query_input.text = ""
	feedback_label.text = ""
	feedback_label.modulate = Color.WHITE
	
	# Обновляем прогресс
	progress_bar.value = (index / float(questions.size())) * 100
	
	# Сбрасываем кнопки
	check_button.visible = true
	next_button.visible = false
	query_input.editable = true
	query_input.grab_focus()

func _on_check_pressed():
	var user_query = query_input.text.strip_edges()
	
	if user_query.is_empty():
		feedback_label.text = "⚠️ Введите SQL-запрос!"
		feedback_label.modulate = Color.YELLOW
		return
	
	var current_q = questions[current_question_index]
	
	if check_answer(user_query, current_q):
		# Правильно!
		correct_answers += 1
		feedback_label.text = "✅ Правильно! Отличная работа."
		feedback_label.modulate = Color.GREEN
		GameState.set_flag("day_zero_q%d_correct" % current_question_index, true)
	else:
		# Неправильно - но НЕ добавляем нарушение!
		feedback_label.text = "❌ Неверно. Правильный ответ: " + current_q.answer
		feedback_label.modulate = Color.RED
		GameState.set_flag("day_zero_q%d_correct" % current_question_index, false)
	
	# Показываем кнопку "Далее" всегда
	check_button.visible = false
	next_button.visible = true
	query_input.editable = false
	skip_button.visible = true
	
func check_answer(user_query: String, question: Dictionary) -> bool:
	# Нормализуем: убираем точку с запятой, приводим к верхнему регистру, убираем двойные пробелы
	var normalized_user = user_query.to_upper().replace(";", "").strip_edges()
	normalized_user = normalized_user.replace("  ", " ")
	
	# Проверяем основной ответ
	var normalized_correct = question.answer.to_upper().replace(";", "").strip_edges()
	
	if normalized_user == normalized_correct:
		return true
	
	# Проверяем альтернативные варианты
	for alt in question.alternatives:
		var normalized_alt = alt.to_upper().replace(";", "").strip_edges()
		if normalized_user == normalized_alt:
			return true
	
	return false

func _on_next_pressed():
	current_question_index += 1
	load_question(current_question_index)
	
func _on_skip_pressed():
	# Пропускаем вопрос (считаем как неправильный ответ)
	GameState.set_flag("day_zero_q%d_correct" % current_question_index, false)
	_on_next_pressed()

func finish_tutorial():
	progress_bar.value = 100
	
	if correct_answers >= 2:
		# Успех!
		title_label.text = "🎉 Поздравляем!"
		instruction_label.text = "Вы успешно прошли тестирование!\n\nПравильных ответов: %d из %d\n\nВаше резюме отправлено в НИИ. Ожидайте приглашения на работу." % [correct_answers, questions.size()]
		query_input.visible = false
		check_button.visible = false
		next_button.visible = false
		feedback_label.text = ""
		
		# Устанавливаем флаг успешного прохождения
		GameState.set_flag("persistent_day_zero_passed", true)
		GameState.set_flag("day_zero_completed", true)
		
		# Кнопка "Продолжить"
		var continue_button = Button.new()
		continue_button.text = "Начать первый рабочий день"
		continue_button.pressed.connect(_on_tutorial_completed)
		$TutorialPanel.add_child(continue_button)
	else:
		# Провал
		title_label.text = "😔 Тест не пройден"
		instruction_label.text = "Правильных ответов: %d из %d\n\nНеобходимо минимум 2 правильных ответа." % [correct_answers, questions.size()]
		query_input.visible = false
		check_button.visible = false
		next_button.visible = false
		feedback_label.text = ""
		skip_button.visible = false
		
		var retry_button = Button.new()
		retry_button.text = "Попробовать снова"
		retry_button.pressed.connect(_on_retry_tutorial)
		$TutorialPanel.add_child(retry_button)

func _on_tutorial_completed():
	# Переход к первому рабочему дню
	get_tree().change_scene_to_file("res://scenes/desktop/desktop.tscn")
	# Здесь позже будет переход на сцену Day 1

func _on_retry_tutorial():
	# Перезапуск туториала
	current_question_index = 0
	correct_answers = 0
	
	# Удаляем кнопки завершения/повтора
	for child in $TutorialPanel.get_children():
		if child is Button and child != check_button and child != next_button:
			child.queue_free()
	
	# Показываем основные элементы
	query_input.visible = true
	query_input.editable = true
	check_button.visible = true
	next_button.visible = false
	skip_button.visible = false  # Скрыта пока не ответим
	
	# Очищаем текст
	feedback_label.text = ""
	query_input.text = ""
	query_input.grab_focus()
	
	# Загружаем первый вопрос
	load_question(0)
