class_name SnakeGrid
extends Node2D

const UiLab = preload("res://src/ui/ui_lab.gd")

enum CellType { EMPTY, SNAKE, ITEM }

const GRID_COLS: int = 25
const GRID_ROWS: int = 15
const CELL_SIZE: int = 60
const GRID_WIDTH: int = GRID_COLS * CELL_SIZE
const GRID_HEIGHT: int = GRID_ROWS * CELL_SIZE

var cells: Array = []
var _custom_offset: Vector2 = Vector2.ZERO
var _use_custom_offset: bool = false

func set_custom_offset(offset: Vector2) -> void:
	_custom_offset = offset
	_use_custom_offset = true
	queue_redraw()

func _ready() -> void:
	_initialize_grid()

func _initialize_grid() -> void:
	cells.clear()
	for _row in GRID_ROWS:
		var row: Array = []
		row.resize(GRID_COLS)
		row.fill(CellType.EMPTY)
		cells.append(row)

func _draw() -> void:
	var offset := _get_offset()
	var grid_rect := Rect2(offset, Vector2(GRID_WIDTH, GRID_HEIGHT))
	draw_rect(grid_rect, Color(UiLab.SURFACE_ALT, 0.62), true)
	draw_rect(grid_rect, Color(UiLab.BORDER, 0.85), false, 2.0)
	var grid_color := Color(UiLab.ACCENT_CYAN, 0.16)
	for x in range(GRID_COLS + 1):
		var from := offset + Vector2(x * CELL_SIZE, 0)
		var to := offset + Vector2(x * CELL_SIZE, GRID_HEIGHT)
		draw_line(from, to, grid_color, 1.0)
	for y in range(GRID_ROWS + 1):
		var from := offset + Vector2(0, y * CELL_SIZE)
		var to := offset + Vector2(GRID_WIDTH, y * CELL_SIZE)
		draw_line(from, to, grid_color, 1.0)
	for x in range(GRID_COLS):
		for y in range(GRID_ROWS):
			if int(x + y) % 2 == 0:
				var cell_rect := Rect2(offset + Vector2(x * CELL_SIZE, y * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
				draw_rect(cell_rect.grow(-1.0), Color(1, 1, 1, 0.015), true)

func _get_offset() -> Vector2:
	if _use_custom_offset:
		return _custom_offset
	var screen_size := Vector2(1920, 1200)
	return (screen_size - Vector2(GRID_WIDTH, GRID_HEIGHT)) / 2.0

func grid_to_screen(col: int, row: int) -> Vector2:
	var offset := _get_offset()
	return offset + Vector2(col * CELL_SIZE + CELL_SIZE / 2.0, row * CELL_SIZE + CELL_SIZE / 2.0)

func screen_to_grid(screen_pos: Vector2) -> Vector2i:
	var offset := _get_offset()
	var local := screen_pos - offset
	return Vector2i(int(local.x / CELL_SIZE), int(local.y / CELL_SIZE))

func is_valid_cell(col: int, row: int) -> bool:
	return col >= 0 and col < GRID_COLS and row >= 0 and row < GRID_ROWS

func wrap_position(col: int, row: int) -> Vector2i:
	var wrapped_col := posmod(col, GRID_COLS)
	var wrapped_row := posmod(row, GRID_ROWS)
	return Vector2i(wrapped_col, wrapped_row)

func get_cell(col: int, row: int) -> int:
	if not is_valid_cell(col, row):
		return CellType.EMPTY
	return cells[row][col]

func set_cell(col: int, row: int, cell_type: int) -> void:
	if is_valid_cell(col, row):
		cells[row][col] = cell_type

func clear_grid() -> void:
	_initialize_grid()

func get_random_empty_cell() -> Vector2i:
	var empty_cells: Array[Vector2i] = []
	for row in GRID_ROWS:
		for col in GRID_COLS:
			if cells[row][col] == CellType.EMPTY:
				empty_cells.append(Vector2i(col, row))
	if empty_cells.is_empty():
		return Vector2i(-1, -1)
	return empty_cells[randi() % empty_cells.size()]

func get_grid_center_position() -> Vector2:
	return _get_offset() + Vector2(GRID_WIDTH, GRID_HEIGHT) / 2.0
