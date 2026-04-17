extends Control

## Сцена классического судоку 9×9: генерация новой партии, три уровня сложности,
## ввод цифр мышью (панель 1–9) или с клавиатуры, возврат на рабочий стол.

# Сколько клеток уже заполнены в начале (чем больше — тем проще).
const CLUES_EASY := 46
const CLUES_MEDIUM := 36
const CLUES_HARD := 28

const DESKTOP_SCENE := "res://scenes/desktop/desktop.tscn"
const GRID_SIZE := 81

@onready var _back_button: Button = $MainVBox/TopBar/BackButton
@onready var _hint_button: Button = $MainVBox/TopBar/HintButton
@onready var _easy_button: Button = $MainVBox/DifficultyRow/EasyButton
@onready var _medium_button: Button = $MainVBox/DifficultyRow/MediumButton
@onready var _hard_button: Button = $MainVBox/DifficultyRow/HardButton
@onready var _new_game_button: Button = $MainVBox/DifficultyRow/NewGameButton
@onready var _board_grid: GridContainer = $MainVBox/BoardContainer/BoardGrid
@onready var _thick_lines: Control = $MainVBox/BoardContainer/ThickLines
@onready var _number_pad: HBoxContainer = $MainVBox/NumberPad
@onready var _status_label: Label = $MainVBox/StatusLabel

# Текущее поле игрока (0 = пусто, 1–9 = цифра).
var puzzle: PackedInt32Array = PackedInt32Array()
# Эталонное решение (для проверки победы и подсветки ошибок).
var solution: PackedInt32Array = PackedInt32Array()
# 1 = клетка дана с начала (нельзя менять), 0 = можно редактировать.
var given: PackedByteArray = PackedByteArray()

var _cell_buttons: Array[Button] = []
var _selected_index: int = -1
# 0 = лёгкий, 1 = средний, 2 = сложный.
var _difficulty: int = 0


func _ready() -> void:
	# Растягиваем массивы под 81 клетку.
	puzzle.resize(GRID_SIZE)
	solution.resize(GRID_SIZE)
	given.resize(GRID_SIZE)

	_back_button.pressed.connect(_go_to_desktop)
	_hint_button.pressed.connect(_show_hint)
	_new_game_button.pressed.connect(_start_new_game)
	# Смена уровня сразу генерирует новое поле (не нужно отдельно жать «Новая партия»).
	_easy_button.pressed.connect(func() -> void:
		_difficulty = 0
		_start_new_game()
	)
	_medium_button.pressed.connect(func() -> void:
		_difficulty = 1
		_start_new_game()
	)
	_hard_button.pressed.connect(func() -> void:
		_difficulty = 2
		_start_new_game()
	)

	# Группа переключателей: одновременно активен только один уровень.
	var group := ButtonGroup.new()
	_easy_button.button_group = group
	_medium_button.button_group = group
	_hard_button.button_group = group
	_easy_button.button_pressed = true

	_build_board_cells()
	_build_number_pad()
	_start_new_game()
	# Рисуем толстые линии после того, как все элементы отрисованы
	_draw_thick_lines()


## Создаём 81 кнопку-клетку и вешаем на каждую свой индекс.
func _build_board_cells() -> void:
	for c in _board_grid.get_children():
		c.queue_free()
	_cell_buttons.clear()

	for i in GRID_SIZE:
		var b := Button.new()
		b.custom_minimum_size = Vector2(44, 44)
		b.focus_mode = Control.FOCUS_NONE
		b.flat = true
		var idx: int = i
		b.pressed.connect(_on_cell_pressed.bind(idx))
		_board_grid.add_child(b)
		_cell_buttons.append(b)


## Подписываем кнопки 1–9 и «Стереть».
func _build_number_pad() -> void:
	for c in _number_pad.get_children():
		c.queue_free()
	for n in range(1, 10):
		var btn := Button.new()
		btn.text = str(n)
		btn.custom_minimum_size = Vector2(40, 36)
		btn.pressed.connect(_on_digit_chosen.bind(n))
		_number_pad.add_child(btn)
	var clear_btn := Button.new()
	clear_btn.text = "Стереть"
	clear_btn.pressed.connect(_clear_selected_cell)
	_number_pad.add_child(clear_btn)


func _go_to_desktop() -> void:
	get_tree().change_scene_to_file(DESKTOP_SCENE)


## Новая партия: полное решение → копия → случайно убираем лишние цифры.
func _start_new_game() -> void:
	var clues := CLUES_EASY
	match _difficulty:
		0:
			clues = CLUES_EASY
		1:
			clues = CLUES_MEDIUM
		2:
			clues = CLUES_HARD

	solution = _generate_full_solution()
	puzzle = solution.duplicate()
	given.fill(0)

	var positions: Array[int] = []
	for i in GRID_SIZE:
		positions.append(i)
	positions.shuffle()

	var to_remove: int = GRID_SIZE - clues
	for k in to_remove:
		var idx: int = positions[k]
		puzzle[idx] = 0

	for i in GRID_SIZE:
		given[i] = 1 if puzzle[i] != 0 else 0

	_selected_index = -1
	_refresh_all_cells()
	_status_label.text = "Выберите клетку, затем цифру (или клавиши 1–9). Удачи!"


## Рекурсивное заполнение пустой сетки случайным валидным решением.
func _generate_full_solution() -> PackedInt32Array:
	var g := PackedInt32Array()
	g.resize(GRID_SIZE)
	g.fill(0)
	_fill_grid_random(g)
	return g


func _fill_grid_random(g: PackedInt32Array) -> bool:
	var pos := _find_first_empty(g)
	if pos < 0:
		return true
	var row: int = int(pos / 9.0)
	var col: int = pos % 9
	var nums: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9]
	nums.shuffle()
	for n in nums:
		if _can_place(g, row, col, n):
			g[pos] = n
			if _fill_grid_random(g):
				return true
			g[pos] = 0
	return false


func _find_first_empty(g: PackedInt32Array) -> int:
	for i in GRID_SIZE:
		if g[i] == 0:
			return i
	return -1


## Проверка правил судоку: строка, столбец и блок 3×3.
func _can_place(g: PackedInt32Array, row: int, col: int, val: int) -> bool:
	for i in 9:
		if g[row * 9 + i] == val:
			return false
		if g[i * 9 + col] == val:
			return false
	var br: int = row - (row % 3)
	var bc: int = col - (col % 3)
	for r in range(br, br + 3):
		for c in range(bc, bc + 3):
			if g[r * 9 + c] == val:
				return false
	return true


func _on_cell_pressed(index: int) -> void:
	# Стартовые цифры нельзя менять — сбрасываем выделение.
	if given[index]:
		_selected_index = -1
		_refresh_all_cells()
		_status_label.text = "Эта клетка дана условием — её нельзя менять."
		return
	_selected_index = index
	_refresh_all_cells()
	_status_label.text = "Клетка выбрана. Введите цифру 1–9 или нажмите «Стереть»."


func _on_digit_chosen(digit: int) -> void:
	if _selected_index < 0:
		_status_label.text = "Сначала нажмите на свободную клетку."
		return
	if given[_selected_index]:
		return
	puzzle[_selected_index] = digit
	_refresh_cell(_selected_index)
	_check_win_after_move()


func _clear_selected_cell() -> void:
	if _selected_index < 0:
		return
	if given[_selected_index]:
		return
	puzzle[_selected_index] = 0
	_refresh_cell(_selected_index)
	_status_label.text = "Клетка очищена."


## Подсказка: заполняет выбранную клетку правильным значением или случайную пустую.
func _show_hint() -> void:
	if _selected_index >= 0 and not given[_selected_index] and puzzle[_selected_index] == 0:
		# Если клетка выбрана и пуста — показываем правильное значение.
		puzzle[_selected_index] = solution[_selected_index]
		_refresh_cell(_selected_index)
		_status_label.text = "Подсказка: в эту клетку нужно поставить %d." % solution[_selected_index]
		_check_win_after_move()
	else:
		# Иначе находим все пустые клетки и выбираем случайную.
		var empty_cells: Array[int] = []
		for i in GRID_SIZE:
			if puzzle[i] == 0:
				empty_cells.append(i)
		if empty_cells.is_empty():
			_status_label.text = "Нет пустых клеток для подсказки."
			return
		empty_cells.shuffle()
		var hint_idx: int = empty_cells.front()
		puzzle[hint_idx] = solution[hint_idx]
		_selected_index = hint_idx
		_refresh_all_cells()
		_status_label.text = "Подсказка: в клетку (%d, %d) поставлено %d." % [floori(hint_idx / 9.0) + 1, hint_idx % 9 + 1, solution[hint_idx]]
		_check_win_after_move()


func _check_win_after_move() -> void:
	for i in GRID_SIZE:
		if puzzle[i] == 0:
			_status_label.text = "Продолжайте заполнять поле."
			return
		if puzzle[i] != solution[i]:
			_status_label.text = "Все клетки заполнены, но есть ошибки. Проверьте цифры."
			return
	
	# Победа!
	_status_label.text = "Победа! Судоку решён верно."
	_on_sudoku_completed(true)


func _on_sudoku_completed(is_success: bool) -> void:
	"""Вызывается когда игрок завершил партию в Судоку"""
	print("🧩 Судоку завершено! Успех: ", is_success)

	if not is_success:
		return

	# Устанавливаем условие разблокировки через GameState
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("set_unlock_condition"):
		game_state.set_unlock_condition("sudoku_completed", true)

	# Сохраняем состояние
	if game_state and game_state.has_method("save_game_state"):
		game_state.save_game_state()

	print("🔓 Условие 'sudoku_completed' установлено — письмо от HR разблокировано!")

	# Показываем уведомление о новом письме
	_show_hr_email_notification()


func _show_hr_email_notification() -> void:
	"""Показ уведомления о новом письме от HR"""
	var dialog = AcceptDialog.new()
	dialog.title = "📬 НОВОЕ ПИСЬМО!"
	dialog.dialog_text = "Вам пришло письмо от Отдела кадров НИИ \"Файербёрд\".\n\nПроверьте почту на рабочем столе."
	
	# Применяем игровой шрифт через Theme (как в email_client.gd)
	var quest_font: FontFile = preload("res://assets/fonts/PressStart2P-Regular.ttf")
	var dialog_theme = Theme.new()
	dialog_theme.default_font = quest_font
	dialog_theme.default_font_size = 14
	dialog.theme = dialog_theme
	
	add_child(dialog)
	dialog.popup_centered(Vector2i(500, 200))
	dialog.confirmed.connect(dialog.queue_free)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		match k.keycode:
			KEY_1, KEY_KP_1:
				_on_digit_chosen(1)
			KEY_2, KEY_KP_2:
				_on_digit_chosen(2)
			KEY_3, KEY_KP_3:
				_on_digit_chosen(3)
			KEY_4, KEY_KP_4:
				_on_digit_chosen(4)
			KEY_5, KEY_KP_5:
				_on_digit_chosen(5)
			KEY_6, KEY_KP_6:
				_on_digit_chosen(6)
			KEY_7, KEY_KP_7:
				_on_digit_chosen(7)
			KEY_8, KEY_KP_8:
				_on_digit_chosen(8)
			KEY_9, KEY_KP_9:
				_on_digit_chosen(9)
			KEY_BACKSPACE, KEY_DELETE:
				_clear_selected_cell()
			KEY_ESCAPE:
				_selected_index = -1
				_refresh_all_cells()


## Обновляем внешний вид одной кнопки: текст, цвет.
func _refresh_cell(index: int) -> void:
	var b: Button = _cell_buttons[index]
	var v: int = puzzle[index]
	b.text = "" if v == 0 else str(v)

	var normal := StyleBoxFlat.new()
	# Границы кнопок не рисуем — линии рисуются через ColorRect
	normal.border_width_left = 0
	normal.border_width_top = 0
	normal.border_width_right = 0
	normal.border_width_bottom = 0

	if given[index]:
		# «Задача» — чуть темнее фона, цифра ярче (кнопка не disabled — иначе не нажмётся).
		normal.bg_color = Color(0.12, 0.14, 0.22)
		b.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	else:
		if v != 0 and v != solution[index]:
			# Неверная цифра — лёгкая красноватая подсветка.
			normal.bg_color = Color(0.25, 0.12, 0.12)
			b.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
		else:
			normal.bg_color = Color(0.18, 0.2, 0.28)
			b.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))

	if index == _selected_index:
		normal.bg_color = normal.bg_color.lerp(Color(0.4, 0.45, 0.2), 0.35)

	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", normal)


func _refresh_all_cells() -> void:
	for i in GRID_SIZE:
		_refresh_cell(i)


## Рисуем все линии (тонкие и толстые) через отдельный скрипт thick_lines.gd.
## Этот скрипт использует _draw() для рисования линий, что гарантирует правильное позиционирование.
func _draw_thick_lines() -> void:
	# Ждём несколько кадров, чтобы GridContainer успел вычислить свои размеры
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Вызываем перерисовку
	_thick_lines.queue_redraw()
