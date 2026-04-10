extends Node
"""
Глобальный обработчик горячих клавиш.
Подключён как autoload, работает из любой сцены.
"""

var debug_canvas: CanvasLayer = null

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		print("🔧 Debug: F1 нажат! Открываю дебаг-панель...")
		get_viewport().set_input_as_handled()
		_open_debug_panel()


func _open_debug_panel():
	print("🔧 Debug: Открываю дебаг-панель (F1)")
	
	# Создаём CanvasLayer если нет
	if not debug_canvas or not is_instance_valid(debug_canvas):
		debug_canvas = CanvasLayer.new()
		debug_canvas.name = "DebugCanvasLayer"
		debug_canvas.layer = 100  # Поверх всех сцен
		get_tree().root.add_child(debug_canvas)
	
	# Проверяем не открыта ли уже
	if debug_canvas.has_node("DebugPanel"):
		print("🔧 Debug: Переключаю видимость")
		var existing = debug_canvas.get_node("DebugPanel")
		existing.visible = not existing.visible
		print("🔧 Debug: visible=", existing.visible)
		return
	
	var debug_path = "res://scenes/debug/debug_panel.tscn"
	if not ResourceLoader.exists(debug_path):
		print("❌ Debug: debug_panel.tscn не найден")
		return
	
	print("🔧 Debug: Загружаю сцену...")
	var debug_scene = load(debug_path)
	var debug_panel = debug_scene.instantiate()
	debug_panel.name = "DebugPanel"
	debug_canvas.add_child(debug_panel)
	
	# Позиционируем
	debug_panel.position = Vector2(100, 100)
	
	# Показываем
	debug_panel.visible = true
	
	print("🔧 Debug: Панель открыта на CanvasLayer, visible=", debug_panel.visible)
