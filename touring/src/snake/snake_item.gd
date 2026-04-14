class_name SnakeItem
extends Node2D

const UiLab = preload("res://src/ui/ui_lab.gd")

const ITEM_COLOR := Color("#D66CFF")
const PULSE_MIN: float = 0.8
const PULSE_MAX: float = 1.0
const PULSE_SPEED: float = 4.0
const CELL_ITEM: int = 2
const CELL_EMPTY: int = 0

var grid_position: Vector2i = Vector2i(-1, -1)
var _grid = null
var _pulse_time: float = 0.0
var _is_active: bool = false
var _spawn_scale: float = 1.0

func setup(grid) -> void:
	_grid = grid

func spawn() -> void:
	var empty: Vector2i = _grid.get_random_empty_cell()
	if empty.x < 0:
		return
	grid_position = empty
	_grid.set_cell(empty.x, empty.y, CELL_ITEM)
	_is_active = true
	_pulse_time = 0.0
	_spawn_scale = 0.0
	queue_redraw()
	# Pop-in animation
	var tween := get_tree().create_tween()
	tween.tween_property(self, "_spawn_scale", 1.0, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func consume() -> void:
	if _is_active:
		_grid.set_cell(grid_position.x, grid_position.y, CELL_EMPTY)
		_is_active = false
		grid_position = Vector2i(-1, -1)
		queue_redraw()

func _process(delta: float) -> void:
	if _is_active:
		_pulse_time += delta * PULSE_SPEED
		queue_redraw()

func _draw() -> void:
	if not _is_active or not _grid:
		return
	var screen_pos: Vector2 = _grid.grid_to_screen(grid_position.x, grid_position.y)
	var scale: float = PULSE_MIN + (PULSE_MAX - PULSE_MIN) * (0.5 + 0.5 * sin(_pulse_time))
	var base_radius: float = (_grid.CELL_SIZE / 2.0 - 2.0) * scale
	var radius: float = base_radius * _spawn_scale
	draw_circle(screen_pos, (base_radius + 8.0) * _spawn_scale, Color(UiLab.ACCENT_MAGENTA, 0.12))
	draw_circle(screen_pos, (base_radius + 4.0) * _spawn_scale, Color(ITEM_COLOR, 0.28))
	draw_circle(screen_pos, radius, ITEM_COLOR)
	draw_circle(screen_pos, radius * 0.35, Color(1, 1, 1, 0.4))
