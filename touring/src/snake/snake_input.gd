class_name SnakeInput
extends Node

const SWIPE_THRESHOLD: float = 20.0
const MOUSE_DRAG_THRESHOLD: float = 16.0

var _touch_start: Vector2 = Vector2.ZERO
var _is_touching: bool = false
var _mouse_start: Vector2 = Vector2.ZERO
var _is_mouse_dragging: bool = false
var _player = null

signal direction_changed(new_dir: Vector2i)

func setup(player) -> void:
	_player = player

func handle_input(event: InputEvent) -> void:
	if not _player or not _player.is_alive:
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			_handle_keyboard(key_event)
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touch_start = touch.position
			_is_touching = true
		elif _is_touching:
			_is_touching = false
			_process_swipe(touch.position)
	elif event is InputEventScreenDrag:
		if _is_touching:
			var delta: Vector2 = event.position - _touch_start
			if delta.length() >= SWIPE_THRESHOLD:
				_determine_direction(delta)
				_touch_start = event.position
	elif event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.pressed:
				_mouse_start = mouse_button.position
				_is_mouse_dragging = true
			elif _is_mouse_dragging:
				_is_mouse_dragging = false
				_process_mouse_drag(mouse_button.position)
	elif event is InputEventMouseMotion:
		if _is_mouse_dragging:
			var mouse_delta: Vector2 = event.position - _mouse_start
			if mouse_delta.length() >= MOUSE_DRAG_THRESHOLD:
				_determine_direction(mouse_delta)
				_mouse_start = event.position

func _process_swipe(end_pos: Vector2) -> void:
	var delta := end_pos - _touch_start
	if delta.length() < SWIPE_THRESHOLD:
		return
	_determine_direction(delta)

func _process_mouse_drag(end_pos: Vector2) -> void:
	var delta: Vector2 = end_pos - _mouse_start
	if delta.length() < MOUSE_DRAG_THRESHOLD:
		return
	_determine_direction(delta)

func _handle_keyboard(event: InputEventKey) -> void:
	if event.keycode == KEY_UP or event.keycode == KEY_W:
		_set_direction(Vector2i.UP)
	elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
		_set_direction(Vector2i.DOWN)
	elif event.keycode == KEY_LEFT or event.keycode == KEY_A:
		_set_direction(Vector2i.LEFT)
	elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
		_set_direction(Vector2i.RIGHT)

func _set_direction(new_dir: Vector2i) -> void:
	if new_dir != _player.direction:
		_player.set_direction(new_dir)
		Sfx.play("direction_tick")
		direction_changed.emit(new_dir)

func _determine_direction(delta: Vector2) -> void:
	var new_dir: Vector2i
	if absf(delta.x) > absf(delta.y):
		new_dir = Vector2i.RIGHT if delta.x > 0 else Vector2i.LEFT
	else:
		new_dir = Vector2i.DOWN if delta.y > 0 else Vector2i.UP
	_set_direction(new_dir)
