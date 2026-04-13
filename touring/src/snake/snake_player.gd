class_name SnakePlayer
extends Node

signal body_changed()
signal self_collision()

const INITIAL_LENGTH: int = 3

var body: Array[Vector2i] = []
var direction: Vector2i = Vector2i.RIGHT
var next_direction: Vector2i = Vector2i.RIGHT
var grow_pending: int = 0
var is_alive: bool = true

func reset(start_pos: Vector2i) -> void:
	body.clear()
	for i: int in INITIAL_LENGTH:
		body.append(Vector2i(start_pos.x - i, start_pos.y))
	direction = Vector2i.RIGHT
	next_direction = Vector2i.RIGHT
	grow_pending = 0
	is_alive = true
	body_changed.emit()

func set_direction(new_dir: Vector2i) -> void:
	if new_dir == -direction:
		return
	next_direction = new_dir

func move(grid) -> void:
	if not is_alive:
		return
	direction = next_direction
	var new_head := Vector2i(body[0].x + direction.x, body[0].y + direction.y)
	if not grid.is_valid_cell(new_head.x, new_head.y):
		is_alive = false
		self_collision.emit()
		return
	var check_body := body.duplicate()
	if grow_pending <= 0:
		check_body.pop_back()
	if new_head in check_body:
		is_alive = false
		self_collision.emit()
		return
	body.insert(0, new_head)
	if grow_pending > 0:
		grow_pending -= 1
	else:
		body.pop_back()
	body_changed.emit()

func grow(amount: int = 1) -> void:
	grow_pending += amount

func get_head() -> Vector2i:
	return body[0]

func get_length() -> int:
	return body.size()
