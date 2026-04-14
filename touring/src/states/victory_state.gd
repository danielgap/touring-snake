extends Node

const UiLab = preload("res://src/ui/ui_lab.gd")
const SnakeGridScene = preload("res://src/snake/snake_grid.gd")
const SnakePlayerScene = preload("res://src/snake/snake_player.gd")
const SnakeRendererScene = preload("res://src/snake/snake_renderer.gd")

var state_machine: Node = null

var _grid = null
var _player = null
var _renderer = null
var _message_glow_label: RichTextLabel
var _message_label: RichTextLabel

const HINT_TEXT := "la letra que necesitas es..."
const CONTINUE_TEXT := "Busca la báscula para continuar"
const MESSAGE_TOP_BASE := 980
const MESSAGE_BOTTOM_BASE := -20
const MESSAGE_FLOAT_OFFSET := 8

var _u_positions: Array[Vector2i] = [
	Vector2i(6, 2), Vector2i(6, 4), Vector2i(6, 6), Vector2i(6, 8), Vector2i(6, 10),
	Vector2i(6, 12), Vector2i(7, 12), Vector2i(9, 12), Vector2i(11, 12),
	Vector2i(13, 12), Vector2i(15, 12), Vector2i(17, 12), Vector2i(18, 12),
	Vector2i(18, 10), Vector2i(18, 8), Vector2i(18, 6), Vector2i(18, 4), Vector2i(18, 2),
]

func _content() -> Control:
	var main := get_tree().root.find_child("Main", true, false)
	return main.get_node("Content") as Control

func enter(_msg: Dictionary = {}) -> void:
	var content := _content()

	# ── Solid dark background ──
	var bg := ColorRect.new()
	bg.color = UiLab.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_child(bg)

	Sfx.play("victory_fanfare")

	# ── Top hint: "la letra que necesitas es..." ──
	var hint := UiLab.make_label(HINT_TEXT, 40, UiLab.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	hint.set_anchors_preset(Control.PRESET_FULL_RECT)
	hint.offset_left = 0
	hint.offset_top = 80
	hint.offset_right = 0
	hint.offset_bottom = 140
	content.add_child(hint)

	# ── Grid for position calculations (hidden — no drawing) ──
	_grid = SnakeGridScene.new()
	_grid.name = "VictoryGrid"
	content.add_child(_grid)
	_grid.visible = false

	# ── Player body ──
	_player = SnakePlayerScene.new()
	_player.name = "VictoryPlayer"
	content.add_child(_player)
	_player.body.clear()
	for i in _u_positions.size():
		_player.body.append(Vector2i(i, 0))
	_player.is_alive = true

	# ── Renderer (draws the snake segments) ──
	_renderer = SnakeRendererScene.new()
	_renderer.name = "VictoryRenderer"
	content.add_child(_renderer)
	_renderer.setup(_player, _grid)

	# ── Bottom message: "Busca la báscula para continuar" ──
	_message_glow_label = RichTextLabel.new()
	_message_glow_label.bbcode_enabled = true
	_message_glow_label.fit_content = true
	_message_glow_label.scroll_active = false
	_message_glow_label.text = CONTINUE_TEXT
	content.add_child(_message_glow_label)
	_message_glow_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_message_glow_label.offset_left = 220
	_message_glow_label.offset_top = MESSAGE_TOP_BASE
	_message_glow_label.offset_right = -220
	_message_glow_label.offset_bottom = MESSAGE_BOTTOM_BASE
	_message_glow_label.add_theme_font_size_override("normal_font_size", 54)
	_message_glow_label.add_theme_color_override("default_color", Color(UiLab.ACCENT_CYAN, 0.22))
	_message_glow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_glow_label.modulate = Color.TRANSPARENT

	_message_label = RichTextLabel.new()
	_message_label.bbcode_enabled = true
	_message_label.fit_content = true
	_message_label.scroll_active = false
	_message_label.text = CONTINUE_TEXT
	content.add_child(_message_label)
	_message_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_message_label.offset_left = 220
	_message_label.offset_top = MESSAGE_TOP_BASE
	_message_label.offset_right = -220
	_message_label.offset_bottom = MESSAGE_BOTTOM_BASE
	_message_label.add_theme_font_size_override("normal_font_size", 46)
	_message_label.add_theme_color_override("default_color", UiLab.ACCENT_CYAN)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.modulate = Color.TRANSPARENT

	# ── Animate snake to U ──
	_animate_to_u()

func exit() -> void:
	var content := _content()
	for child in content.get_children():
		child.queue_free()

func _animate_to_u() -> void:
	var tween := get_tree().create_tween()
	tween.tween_interval(0.5)
	for i in _u_positions.size():
		var idx := i
		var target := _u_positions[i]
		tween.tween_callback(func():
			if idx < _player.body.size():
				_player.body[idx] = target
				if _renderer:
					_renderer.queue_redraw()
		)
		tween.tween_interval(0.05)
	tween.tween_interval(0.8)
	tween.tween_callback(_on_u_complete)
	tween.tween_interval(0.3)
	tween.tween_callback(_show_message)

func _on_u_complete() -> void:
	# Start the glow pulse on the U
	if _renderer:
		_renderer.start_pulse()
	# Subtle screen flash
	var content := _content()
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 1)
	flash.modulate = Color(1, 1, 1, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(flash)
	var ft := flash.create_tween()
	ft.tween_property(flash, "modulate:a", 0.1, 0.08)
	ft.tween_property(flash, "modulate:a", 0.0, 0.5)
	ft.tween_callback(flash.queue_free)

func _show_message() -> void:
	var tween := _message_label.create_tween()
	tween.parallel().tween_property(_message_glow_label, "modulate", Color.WHITE, 0.9)
	tween.parallel().tween_property(_message_label, "modulate", Color.WHITE, 0.9)
	tween.tween_callback(_start_message_pulse)
	tween.tween_callback(_start_message_float)

func _start_message_pulse() -> void:
	if not _message_glow_label:
		return
	var tween := _message_glow_label.create_tween().set_loops()
	tween.tween_property(_message_glow_label, "modulate:a", 0.28, 1.4)
	tween.tween_property(_message_glow_label, "modulate:a", 0.12, 1.4)

func _start_message_float() -> void:
	if not _message_label or not _message_glow_label:
		return
	var tween := _message_label.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(_message_label, "offset_top", MESSAGE_TOP_BASE - MESSAGE_FLOAT_OFFSET, 1.8)
	tween.parallel().tween_property(_message_label, "offset_bottom", MESSAGE_BOTTOM_BASE - MESSAGE_FLOAT_OFFSET, 1.8)
	tween.parallel().tween_property(_message_glow_label, "offset_top", MESSAGE_TOP_BASE - MESSAGE_FLOAT_OFFSET, 1.8)
	tween.parallel().tween_property(_message_glow_label, "offset_bottom", MESSAGE_BOTTOM_BASE - MESSAGE_FLOAT_OFFSET, 1.8)
	tween.parallel().tween_property(_message_label, "offset_top", MESSAGE_TOP_BASE, 1.8)
	tween.parallel().tween_property(_message_label, "offset_bottom", MESSAGE_BOTTOM_BASE, 1.8)
	tween.parallel().tween_property(_message_glow_label, "offset_top", MESSAGE_TOP_BASE, 1.8)
	tween.parallel().tween_property(_message_glow_label, "offset_bottom", MESSAGE_BOTTOM_BASE, 1.8)
