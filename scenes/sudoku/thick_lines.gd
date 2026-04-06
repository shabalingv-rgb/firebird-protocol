extends Control

## Скрипт для рисования линий судоку поверх сетки.
## Рисует тонкие и толстые линии, разделяющие клетки и блоки 3×3.

var thin_color := Color(0.4, 0.45, 0.6)
var thick_color := Color(0.85, 0.9, 1.0)
var thin_thickness := 1.0
var thick_thickness := 4.0


func _draw() -> void:
	# Используем размер самого узла, в котором рисуем
	var grid_size: Vector2 = self.size
	if grid_size.x <= 0 or grid_size.y <= 0:
		return
	
	var cell_width: float = grid_size.x / 9.0
	var cell_height: float = grid_size.y / 9.0

	# Рисуем тонкие линии
	# Вертикальные тонкие линии (между колонками 0-1, 1-2, 3-4, 4-5, 6-7, 7-8)
	var thin_cols: Array[int] = [0, 1, 3, 4, 6, 7]
	for col: int in thin_cols:
		var x: float = float(col + 1) * cell_width
		draw_line(Vector2(x, 0), Vector2(x, grid_size.y), thin_color, thin_thickness)

	# Горизонтальные тонкие линии (между рядами 0-1, 1-2, 3-4, 4-5, 6-7, 7-8)
	var thin_rows: Array[int] = [0, 1, 3, 4, 6, 7]
	for row: int in thin_rows:
		var y: float = float(row + 1) * cell_height
		draw_line(Vector2(0, y), Vector2(grid_size.x, y), thin_color, thin_thickness)

	# Рисуем толстые линии между блоками 3×3
	# Вертикальные толстые линии (между колонками 2-3 и 5-6)
	var thick_cols: Array[int] = [2, 5]
	for col: int in thick_cols:
		var x: float = float(col + 1) * cell_width
		draw_line(Vector2(x, 0), Vector2(x, grid_size.y), thick_color, thick_thickness)

	# Горизонтальные толстые линии (между рядами 2-3 и 5-6)
	var thick_rows: Array[int] = [2, 5]
	for row: int in thick_rows:
		var y: float = float(row + 1) * cell_height
		draw_line(Vector2(0, y), Vector2(grid_size.x, y), thick_color, thick_thickness)
