extends Control

@onready var day_label = $DayLabel
@onready var day_slider = $DaySlider
@onready var role_button = $RoleButton
@onready var role_label = $RoleLabel

var current_role: String = "employee"  # employee, journalist, manager

func _ready():
	# Скрываем панель по умолчанию
	visible = false
	
	day_slider.value_changed.connect(_on_day_changed)
	role_button.pressed.connect(_on_role_changed)
	$CompleteDayBtn.pressed.connect(_on_complete_day)
	$SkipDayBtn.pressed.connect(_on_skip_day)
	$AddEmailBtn.pressed.connect(_on_add_email)
	$ClearProgressBtn.pressed.connect(_on_clear_progress)
	$CloseBtn.pressed.connect(_on_close)
	
	update_labels()

func _input(event):
	# Показываем панель по F1
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		visible = not visible

func update_labels():
	var d := QuestManager.current_day if QuestManager else GameState.current_day
	day_label.text = "Current Day: %d" % d
	role_label.text = "Role: " + current_role.capitalize()
	day_slider.value = d

func _on_day_changed(value):
	var v := int(value)
	if QuestManager:
		QuestManager.current_day = v
	GameState.current_day = v
	update_labels()
	print("📅 Debug: День изменён на ", v)

func _on_role_changed():
	# Циклически переключаем роли
	var roles = ["employee", "journalist", "manager"]
	var current_index = roles.find(current_role)
	current_role = roles[(current_index + 1) % roles.size()]
	update_labels()
	print("🎭 Debug: Роль изменена на ", current_role)

func _on_complete_day():
	var d := QuestManager.current_day if QuestManager else 1
	print("✅ Debug: День ", d, " завершён!")
	if QuestManager and QuestManager.active_quest and not QuestManager.active_quest.is_empty():
		var qid = QuestManager.active_quest.get("ID", QuestManager.active_quest.get("id", -1))
		if qid != -1 and not QuestManager.completed_quests.has(qid):
			QuestManager.completed_quests.append(qid)
		QuestManager.active_quest = {}
	EmailSystem.inbox.clear()
	GameState.advance_game_time(8)
	if QuestManager:
		QuestManager.next_day()
	update_labels()
	
func _on_skip_day():
	if QuestManager:
		QuestManager.current_day += 1
	GameState.current_day += 1
	update_labels()
	print("⏭️ Debug: Пропуск до дня ", QuestManager.current_day if QuestManager else GameState.current_day)

func _on_add_email():
	var test_email = {
		"from": "debug@nii-firebird.gov",
		"subject": "Test Email",
		"body": "This is a test email for debugging purposes.",
		"time": Time.get_datetime_string_from_system(),
		"read": false
	}
	EmailSystem.add_email(test_email)
	print("📧 Debug: Добавлено тестовое письмо")

func _on_clear_progress():
	GameState.reset_violations()
	GameState.current_day = 1
	EmailSystem.inbox.clear()
	if QuestManager:
		QuestManager.reset_progress()
	print("🗑️ Debug: Прогресс сброшен")

func _on_close():
	visible = false
