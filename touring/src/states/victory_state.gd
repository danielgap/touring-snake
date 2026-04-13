extends Node

const UiLab = preload("res://src/ui/ui_lab.gd")
const SnakeGridScene = preload("res://src/snake/snake_grid.gd")
const SnakePlayerScene = preload("res://src/snake/snake_player.gd")
const SnakeRendererScene = preload("res://src/snake/snake_renderer.gd")

var state_machine: Node = null

var _grid = null
var _player = null
var _renderer = null
var _message_label: RichTextLabel

const DRA_TORRES_MSG := "[i]La letra U es porque tu huella digital es ÚNICA. No hay dos iguales en el mundo. Pero en internet, esa unicidad se convierte en un rastro que otros pueden seguir. ¿Sabés dónde dejás la tuya?[/i]"

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

	# ── Centered title ──
	var title := UiLab.make_label("HUELLA ÚNICA", 56, UiLab.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.offset_left = 0
	title.offset_top = 50
	title.offset_right = 0
	title.offset_bottom = 120
	content.add_child(title)

	var subtitle := UiLab.make_label("Tu huella digital reconstruida como firma biometrica", 24, UiLab.ACCENT_CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.set_anchors_preset(Control.PRESET_FULL_RECT)
	subtitle.offset_left = 0
	subtitle.offset_top = 120
	subtitle.offset_right = 0
	subtitle.offset_bottom = 155
	content.add_child(subtitle)

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

	# ── Message at bottom ──
	_message_label = RichTextLabel.new()
	_message_label.bbcode_enabled = true
	_message_label.fit_content = true
	_message_label.scroll_active = false
	_message_label.text = DRA_TORRES_MSG
	content.add_child(_message_label)
	_message_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_message_label.offset_left = 280
	_message_label.offset_top = 920
	_message_label.offset_right = -280
	_message_label.offset_bottom = -40
	_message_label.add_theme_font_size_override("normal_font_size", 30)
	_message_label.add_theme_color_override("default_color", UiLab.MUTED)
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
	tween.tween_callback(_show_message)

func _show_message() -> void:
	var tween := _message_label.create_tween()
	tween.tween_property(_message_label, "modulate", Color.WHITE, 0.9)
