extends Node

var state_machine: Node = null

func _content() -> Control:
	var main := get_tree().root.find_child("Main", true, false)
	return main.get_node("Content") as Control

const CHAR_DELAY := 0.03
const MESSAGE := "Cada expediente es un PERFIL. Vuestra huella digital no es privada — es un producto. Encontrad la clave en lo que compartís."

var _label: Label
var _char_index: int = 0
var _timer: Timer
var _active: bool = false

func enter(_msg: Dictionary = {}) -> void:
	_active = true
	var content := _content()
	
	_label = Label.new()
	_label.text = ""
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", Color("#00FF88"))
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_label)
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.offset_left = 100
	_label.offset_right = -100
	_label.offset_top = 0
	_label.offset_bottom = 0
	
	_char_index = 0
	
	_timer = Timer.new()
	_timer.wait_time = CHAR_DELAY
	_timer.timeout.connect(_on_char_tick)
	content.add_child(_timer)
	_timer.start()

func exit() -> void:
	_active = false
	var content := _content()
	for child in content.get_children():
		child.queue_free()

func handle_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if event.position.x < 48.0 and event.position.y < 48.0:
			_skip_to_end()

func _on_char_tick() -> void:
	if not _active:
		return
	if _char_index < MESSAGE.length():
		_label.text = MESSAGE.substr(0, _char_index + 1)
		_char_index += 1
	else:
		_timer.stop()
		_on_typewriter_complete()

func _on_typewriter_complete() -> void:
	if not _active:
		return
	await get_tree().create_timer(1.5).timeout
	if not _active:
		return
	state_machine.transition_to(&"PasswordState")

func _skip_to_end() -> void:
	if not _active:
		return
	_active = false
	_timer.stop()
	_label.text = MESSAGE
	await get_tree().create_timer(0.5).timeout
	state_machine.transition_to(&"PasswordState")
