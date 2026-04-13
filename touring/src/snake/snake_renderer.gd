class_name SnakeRenderer
extends Node2D

const UiLab = preload("res://src/ui/ui_lab.gd")

const HEAD_COLOR := Color("#46E0FF")
const BODY_COLOR := Color("#73E7A8")
const DEAD_COLOR := Color("#FF5C7A")

var _player = null
var _grid = null
var _flash_timer: float = 0.0
var _is_dead: bool = false

func setup(player, grid) -> void:
	_player = player
	_grid = grid
	player.body_changed.connect(queue_redraw)
	player.self_collision.connect(_on_self_collision)

func clear() -> void:
	_player = null
	_grid = null

func _on_self_collision() -> void:
	_is_dead = true
	_flash_timer = 0.0
	set_process(true)

func _process(delta: float) -> void:
	if _is_dead:
		_flash_timer += delta
		queue_redraw()
		if _flash_timer > 0.6:
			_is_dead = false
			set_process(false)

func _draw() -> void:
	if not _player or not _grid:
		return
	var body: Array[Vector2i] = _player.body
	var cell_size: float = float(_grid.CELL_SIZE)
	var segment_size: float = cell_size - 4.0
	for i: int in body.size():
		var pos: Vector2 = _grid.grid_to_screen(body[i].x, body[i].y)
		var rect := Rect2(pos.x - segment_size / 2.0, pos.y - segment_size / 2.0, segment_size, segment_size)
		var color: Color
		if _is_dead:
			color = DEAD_COLOR if int(_flash_timer * 10.0) % 2 == 0 else Color.TRANSPARENT
		elif i == 0:
			color = HEAD_COLOR
		else:
			var t: float = float(i) / float(body.size())
			color = BODY_COLOR.lerp(Color(UiLab.ACCENT_CYAN, 0.55), t)
		draw_rect(rect, color)
		if not _is_dead:
			draw_rect(rect.grow(-6.0), Color(1, 1, 1, 0.08))
