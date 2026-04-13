extends Node

var state_machine: Node = null

func _content() -> Control:
	var main := get_tree().root.find_child("Main", true, false)
	return main.get_node("Content") as Control

const TAP_ZONE_SIZE := 48.0
const TAP_WINDOW := 0.8
const TAP_COUNT_REQUIRED := 3

var _container: VBoxContainer
var _dots_label: Label
var _dot_timer: Timer
var _dot_index: int = 0
var _tap_times: Array[float] = []
var _dots_texts: Array[String] = ["...", ".  ", ".. "]

func enter(_msg: Dictionary = {}) -> void:
	var content := _content()
	
	_container = VBoxContainer.new()
	content.add_child(_container)
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_container.offset_left = 0
	_container.offset_right = 0
	_container.offset_top = 0
	_container.offset_bottom = 0
	_container.alignment = VBoxContainer.ALIGNMENT_CENTER
	_container.add_theme_constant_override("separation", 8)
	
	var label := Label.new()
	label.text = "Esperando conexión de archivos"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color("#5A6070"))
	_container.add_child(label)
	
	_dots_label = Label.new()
	_dots_label.text = "..."
	_dots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dots_label.add_theme_font_size_override("font_size", 28)
	_dots_label.add_theme_color_override("font_color", Color("#5A6070"))
	_container.add_child(_dots_label)
	
	_dot_timer = Timer.new()
	_dot_timer.wait_time = 1.5
	_dot_timer.timeout.connect(_on_dot_timer)
	content.add_child(_dot_timer)
	_dot_timer.start()

func exit() -> void:
	var content := _content()
	for child in content.get_children():
		child.queue_free()
	_tap_times.clear()

func handle_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if event.position.x < TAP_ZONE_SIZE and event.position.y < TAP_ZONE_SIZE:
			_register_tap()
		elif event.position.x > 1920.0 - TAP_ZONE_SIZE and event.position.y < TAP_ZONE_SIZE:
			EventBus.gm_trigger_menu.emit()

func _register_tap() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_tap_times.append(now)
	while _tap_times.size() > 0 and now - _tap_times[0] > TAP_WINDOW:
		_tap_times.pop_front()
	if _tap_times.size() >= TAP_COUNT_REQUIRED:
		_tap_times.clear()
		EventBus.gm_trigger_activate.emit()
		state_machine.transition_to(&"RevealState")

func _on_dot_timer() -> void:
	_dot_index = (_dot_index + 1) % _dots_texts.size()
	if _dots_label:
		_dots_label.text = _dots_texts[_dot_index]
