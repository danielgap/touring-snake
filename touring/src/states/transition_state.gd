extends Node

const UiLab = preload("res://src/ui/ui_lab.gd")
const BackdropScene = preload("res://src/ui/terminal_backdrop.gd")

var state_machine: Node = null

func _content() -> Control:
	var main := get_tree().root.find_child("Main", true, false)
	return main.get_node("Content") as Control

func enter(_msg: Dictionary = {}) -> void:
	var content := _content()
	content.add_child(BackdropScene.new())

	var access_panel := PanelContainer.new()
	UiLab.apply_panel(access_panel, UiLab.SURFACE_SOFT, UiLab.ACCENT_GREEN, 24, 2)
	access_panel.custom_minimum_size = Vector2(920, 360)
	access_panel.position = Vector2(500, 370)
	access_panel.modulate = Color(1, 1, 1, 0)
	content.add_child(access_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 40)
	access_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	var tags := HBoxContainer.new()
	tags.add_theme_constant_override("separation", 12)
	tags.add_child(UiLab.make_tag("ACCESS GRANTED", UiLab.ACCENT_GREEN, Color(UiLab.ACCENT_GREEN, 0.08)))
	tags.add_child(UiLab.make_tag("PROFILE UNSEALED", UiLab.ACCENT_CYAN, Color(UiLab.ACCENT_CYAN, 0.08)))
	layout.add_child(tags)

	var title := UiLab.make_label("ACCESO CONCEDIDO", 54, UiLab.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	var subtitle := UiLab.make_label("Expediente biométrico validado. Redirigiendo al módulo de rastreo para extracción de datos conductuales.", 24, UiLab.ACCENT_CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(subtitle)

	layout.add_child(UiLab.make_divider(Color(UiLab.BORDER, 0.9), 2))

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 14)
	footer.add_child(UiLab.make_tag("ROUTING TO EVA-9 GRID", UiLab.ACCENT_CYAN, Color(UiLab.ACCENT_CYAN, 0.06)))
	footer.add_child(UiLab.make_tag("SUBJECT TRACE LIVE", UiLab.ACCENT_MAGENTA, Color(UiLab.ACCENT_MAGENTA, 0.06)))
	layout.add_child(footer)

	Sfx.play("transition_whoosh")

	var tween := content.create_tween()
	tween.tween_property(access_panel, "modulate", Color.WHITE, 0.35)
	tween.parallel().tween_property(access_panel, "scale", Vector2(1.02, 1.02), 0.35).from(Vector2(0.96, 0.96))
	tween.tween_interval(0.55)
	tween.tween_property(access_panel, "modulate", Color.TRANSPARENT, 0.6)
	tween.tween_callback(func():
		EventBus.transition_complete.emit()
		state_machine.transition_to(&"SnakeState")
	)

func exit() -> void:
	var content := _content()
	for child in content.get_children():
		child.queue_free()
