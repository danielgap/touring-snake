extends Node

const UiLab = preload("res://src/ui/ui_lab.gd")
const BackdropScene = preload("res://src/ui/terminal_backdrop.gd")

var state_machine: Node = null
var _title_label: Label = null

func _content() -> Control:
	var main := get_tree().root.find_child("Main", true, false)
	return main.get_node("Content") as Control

func enter(_msg: Dictionary = {}) -> void:
	var content := _content()
	content.add_child(BackdropScene.new())

	var shell := MarginContainer.new()
	shell.set_anchors_preset(Control.PRESET_FULL_RECT)
	shell.offset_left = 260
	shell.offset_top = 180
	shell.offset_right = -260
	shell.offset_bottom = -180
	content.add_child(shell)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 22)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	shell.add_child(root)

	root.add_child(UiLab.make_tag("EVA-9 // BOOT", UiLab.ACCENT_CYAN, Color(UiLab.ACCENT_CYAN, 0.08)))

	var splash := PanelContainer.new()
	UiLab.apply_panel(splash, UiLab.SURFACE_SOFT, UiLab.ACCENT_CYAN, 24, 2)
	splash.custom_minimum_size = Vector2(860, 300)
	root.add_child(splash)

	var splash_margin := MarginContainer.new()
	splash_margin.add_theme_constant_override("margin_left", 56)
	splash_margin.add_theme_constant_override("margin_top", 40)
	splash_margin.add_theme_constant_override("margin_right", 56)
	splash_margin.add_theme_constant_override("margin_bottom", 40)
	splash.add_child(splash_margin)

	var splash_layout := VBoxContainer.new()
	splash_layout.add_theme_constant_override("separation", 16)
	splash_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	splash_margin.add_child(splash_layout)

	var boot_label := UiLab.make_label("INICIALIZANDO EXPEDIENTE BIOMÉTRICO", 18, UiLab.ACCENT_GREEN, HORIZONTAL_ALIGNMENT_CENTER)
	boot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_layout.add_child(boot_label)

	_title_label = UiLab.make_label("EVA-9", 96, UiLab.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_layout.add_child(_title_label)

	var subtitle := UiLab.make_label("Conectando capa de acceso y lectura de perfil", 26, UiLab.ACCENT_CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_layout.add_child(subtitle)

	splash.modulate = Color(1, 1, 1, 0)
	_title_label.modulate = Color(1, 1, 1, 0)
	var tween := content.create_tween()
	tween.tween_property(splash, "modulate", Color.WHITE, 0.7).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_title_label, "modulate", Color.WHITE, 1.0).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_set_title_x.bind(-5.0)).set_delay(0.25)
	tween.tween_callback(_set_title_x.bind(5.0))
	tween.tween_callback(_set_title_x.bind(0.0))

	Sfx.play("boot")

	var timer := Timer.new()
	timer.name = "InitTimer"
	timer.wait_time = 1.8
	timer.one_shot = true
	timer.timeout.connect(_go_to_password)
	content.add_child(timer)
	timer.start()

func exit() -> void:
	_title_label = null
	var content := _content()
	for child in content.get_children():
		child.queue_free()

func _set_title_x(value: float) -> void:
	if _title_label and _title_label.is_inside_tree():
		_title_label.position.x = value

func _go_to_password() -> void:
	if state_machine:
		state_machine.transition_to(&"PasswordState")
