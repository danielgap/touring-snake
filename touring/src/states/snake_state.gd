extends Node

const UiLab = preload("res://src/ui/ui_lab.gd")
const BackdropScene = preload("res://src/ui/terminal_backdrop.gd")
const SnakeGridScene = preload("res://src/snake/snake_grid.gd")
const SnakePlayerScene = preload("res://src/snake/snake_player.gd")
const SnakeItemScene = preload("res://src/snake/snake_item.gd")
const SnakeInputScene = preload("res://src/snake/snake_input.gd")
const SnakeRendererScene = preload("res://src/snake/snake_renderer.gd")

var state_machine: Node = null

const TICK_SPEED := 0.15
const TARGET_ITEMS := 15
const INITIAL_POSITION := Vector2i(12, 7)

# Layout constants — calculated for 1920×1200
const MARGIN := 40.0
const TOP_BAR_H := 80.0
const GRID_PAD := 32.0  # padding around grid inside frame
const TAG_ROW_H := 28.0

var _grid = null
var _player = null
var _item = null
var _input_handler = null
var _renderer = null
var _tick_timer: Timer
var _score_label: Label
var _status_label: Label
var _overlay_panel: PanelContainer
var _retry_button: Button
var _score: int = 0
var _is_game_over: bool = false

func _content() -> Control:
	var main := get_tree().root.find_child("Main", true, false)
	return main.get_node("Content") as Control

func enter(_msg: Dictionary = {}) -> void:
	var content := _content()
	_score = 0
	_is_game_over = false
	content.add_child(BackdropScene.new())
	_build_shell(content)

	_grid = SnakeGridScene.new()
	_grid.name = "SnakeGrid"
	content.add_child(_grid)
	# Align grid drawing to the frame interior
	var grid_offset_x := (1920.0 - SnakeGridScene.GRID_WIDTH) / 2.0
	var grid_offset_y := MARGIN + TOP_BAR_H + 16.0 + GRID_PAD + TAG_ROW_H + 8.0 + GRID_PAD
	_grid.set_custom_offset(Vector2(grid_offset_x, grid_offset_y))

	_player = SnakePlayerScene.new()
	_player.name = "SnakePlayer"
	content.add_child(_player)
	_player.reset(INITIAL_POSITION)
	for seg in _player.body:
		_grid.set_cell(seg.x, seg.y, SnakeGridScene.CellType.SNAKE)

	_item = SnakeItemScene.new()
	_item.name = "SnakeItem"
	content.add_child(_item)
	_item.setup(_grid)
	_item.spawn()

	_input_handler = SnakeInputScene.new()
	_input_handler.name = "SnakeInput"
	content.add_child(_input_handler)
	_input_handler.setup(_player)

	_renderer = SnakeRendererScene.new()
	_renderer.name = "SnakeRenderer"
	content.add_child(_renderer)
	_renderer.setup(_player, _grid)

	_player.self_collision.connect(_on_game_over)
	_player.body_changed.connect(func(): if _renderer: _renderer.queue_redraw())

	_tick_timer = Timer.new()
	_tick_timer.wait_time = TICK_SPEED
	_tick_timer.timeout.connect(_on_tick)
	content.add_child(_tick_timer)
	_tick_timer.start()

	_update_score_display()
	_set_status("Recolectá nodos magenta sin colapsar", UiLab.MUTED)
	EventBus.gm_skip_snake.connect(_on_gm_skip)

func exit() -> void:
	if EventBus.gm_skip_snake.is_connected(_on_gm_skip):
		EventBus.gm_skip_snake.disconnect(_on_gm_skip)
	var content := _content()
	for child in content.get_children():
		child.queue_free()

func handle_input(event: InputEvent) -> void:
	if not _is_game_over and _input_handler:
		_input_handler.handle_input(event)

func _build_shell(content: Control) -> void:
	# === TOP BAR — single row, full width ===
	var top_bar := HBoxContainer.new()
	top_bar.position = Vector2(MARGIN, MARGIN)
	top_bar.size = Vector2(1920.0 - MARGIN * 2.0, TOP_BAR_H)
	top_bar.add_theme_constant_override("separation", 16)
	content.add_child(top_bar)

	# Left: header info
	var header := PanelContainer.new()
	UiLab.apply_panel(header, UiLab.SURFACE_SOFT, UiLab.BORDER, 14, 2)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(header)

	var h_margin := MarginContainer.new()
	h_margin.add_theme_constant_override("margin_left", 24)
	h_margin.add_theme_constant_override("margin_top", 12)
	h_margin.add_theme_constant_override("margin_right", 24)
	h_margin.add_theme_constant_override("margin_bottom", 12)
	header.add_child(h_margin)

	var h_row := HBoxContainer.new()
	h_row.add_theme_constant_override("separation", 16)
	h_row.alignment = BoxContainer.ALIGNMENT_CENTER
	h_margin.add_child(h_row)

	h_row.add_child(UiLab.make_label("EVA-9 // FIELD PROFILE TRACE", 15, UiLab.ACCENT_GREEN))
	h_row.add_child(UiLab.make_label("RETÍCULA DE RASTREO CONDUCTUAL", 24, UiLab.TEXT))
	_status_label = UiLab.make_label("", 17, UiLab.ACCENT_CYAN)
	h_row.add_child(_status_label)

	# Right: score
	var score := PanelContainer.new()
	UiLab.apply_panel(score, UiLab.SURFACE_SOFT, UiLab.ACCENT_CYAN, 14, 2)
	score.custom_minimum_size = Vector2(420, 0)
	top_bar.add_child(score)

	var s_margin := MarginContainer.new()
	s_margin.add_theme_constant_override("margin_left", 24)
	s_margin.add_theme_constant_override("margin_top", 12)
	s_margin.add_theme_constant_override("margin_right", 24)
	s_margin.add_theme_constant_override("margin_bottom", 12)
	score.add_child(s_margin)

	var s_row := HBoxContainer.new()
	s_row.add_theme_constant_override("separation", 14)
	s_row.alignment = BoxContainer.ALIGNMENT_CENTER
	s_margin.add_child(s_row)

	var s_left := VBoxContainer.new()
	s_left.add_theme_constant_override("separation", 2)
	s_left.add_child(UiLab.make_label("DATA HARVEST", 14, UiLab.ACCENT_GREEN))
	s_left.add_child(UiLab.make_label("15 nodos sensibles", 14, UiLab.MUTED))
	s_row.add_child(s_left)

	_score_label = UiLab.make_label("", 32, UiLab.TEXT)
	s_row.add_child(_score_label)

	# === GRID FRAME — centered below top bar ===
	var grid_w: float = SnakeGridScene.GRID_WIDTH
	var grid_h: float = SnakeGridScene.GRID_HEIGHT
	var frame_w := grid_w + GRID_PAD * 2.0
	var frame_h := grid_h + GRID_PAD + TAG_ROW_H + GRID_PAD  # tags top + grid + pad bottom
	var frame_x := (1920.0 - frame_w) / 2.0
	var frame_y := MARGIN + TOP_BAR_H + 16.0  # 16px gap below top bar

	var frame := PanelContainer.new()
	UiLab.apply_panel(frame, Color(UiLab.SURFACE, 0.9), UiLab.ACCENT_CYAN, 18, 2)
	frame.position = Vector2(frame_x, frame_y)
	frame.custom_minimum_size = Vector2(frame_w, frame_h)
	content.add_child(frame)

	var f_margin := MarginContainer.new()
	f_margin.add_theme_constant_override("margin_left", GRID_PAD)
	f_margin.add_theme_constant_override("margin_top", GRID_PAD)
	f_margin.add_theme_constant_override("margin_right", GRID_PAD)
	f_margin.add_theme_constant_override("margin_bottom", GRID_PAD / 2.0)
	frame.add_child(f_margin)

	var f_layout := VBoxContainer.new()
	f_layout.add_theme_constant_override("separation", 8)
	f_margin.add_child(f_layout)

	var tags := HBoxContainer.new()
	tags.add_theme_constant_override("separation", 10)
	tags.add_child(UiLab.make_tag("PROFILE GRID", UiLab.ACCENT_CYAN, Color(UiLab.ACCENT_CYAN, 0.06)))
	tags.add_child(UiLab.make_tag("SCAN LIVE", UiLab.ACCENT_GREEN, Color(UiLab.ACCENT_GREEN, 0.06)))
	tags.add_child(UiLab.make_tag("WALL COLLISION", UiLab.ACCENT_MAGENTA, Color(UiLab.ACCENT_MAGENTA, 0.06)))
	f_layout.add_child(tags)

	var viewport := Control.new()
	viewport.custom_minimum_size = Vector2(grid_w, grid_h)
	f_layout.add_child(viewport)

	# Force grid offset to match frame interior
	# Grid draws at _get_offset() which centers in 1920×1200
	# We need it to align with the frame's interior top-left
	# So we tell the grid where to draw via a method

func _on_tick() -> void:
	if _is_game_over or not _player or not _player.is_alive:
		return
	for seg in _player.body:
		_grid.set_cell(seg.x, seg.y, SnakeGridScene.CellType.EMPTY)
	_player.move(_grid)
	if not _player.is_alive:
		return
	for seg in _player.body:
		_grid.set_cell(seg.x, seg.y, SnakeGridScene.CellType.SNAKE)
	if _player.get_head() == _item.grid_position:
		_item.consume()
		_score += 1
		_player.grow()
		Sfx.play("eat_item")
		EventBus.snake_ate_item.emit()
		_update_score_display()
		_set_status("Nodo recuperado · rastro extendido", UiLab.ACCENT_GREEN)
		if _score >= TARGET_ITEMS:
			_tick_timer.stop()
			EventBus.snake_victory.emit()
			state_machine.transition_to(&"VictoryState")
			return
		_item.spawn()

func _on_game_over() -> void:
	_is_game_over = true
	_tick_timer.stop()
	Sfx.play("game_over")
	EventBus.snake_died.emit()
	_set_status("Sistema colapsado · autocruce detectado", UiLab.DANGER)
	var content := _content()
	_overlay_panel = PanelContainer.new()
	UiLab.apply_panel(_overlay_panel, Color(UiLab.SURFACE, 0.96), UiLab.DANGER, 22, 2)
	_overlay_panel.position = Vector2(610, 420)
	_overlay_panel.custom_minimum_size = Vector2(700, 300)
	content.add_child(_overlay_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_bottom", 34)
	_overlay_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	layout.add_child(UiLab.make_tag("ANOMALY", UiLab.DANGER, Color(UiLab.DANGER, 0.08)))
	var title := UiLab.make_label("SISTEMA COLAPSADO", 42, UiLab.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)
	var copy := UiLab.make_label("El perfil se cruzó con su propio historial. Reiniciá la retícula para reconstruir la lectura.", 24, UiLab.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(copy)

	_retry_button = Button.new()
	_retry_button.text = "REINTENTAR"
	_retry_button.custom_minimum_size = Vector2(240, 64)
	_retry_button.add_theme_font_size_override("font_size", 24)
	UiLab.apply_button_style(_retry_button, UiLab.ACCENT_GREEN, UiLab.SURFACE_ALT)
	_retry_button.pressed.connect(_on_retry)
	layout.add_child(_retry_button)

func _on_retry() -> void:
	Sfx.play("retry")
	if _overlay_panel and _overlay_panel.is_inside_tree():
		_overlay_panel.queue_free()
	_grid.clear_grid()
	_player.reset(INITIAL_POSITION)
	for seg in _player.body:
		_grid.set_cell(seg.x, seg.y, SnakeGridScene.CellType.SNAKE)
	_score = 0
	_is_game_over = false
	_update_score_display()
	_set_status("Retícula reiniciada · lectura restablecida", UiLab.ACCENT_CYAN)
	_item.spawn()
	if _renderer:
		_renderer.queue_redraw()
	_tick_timer.start()

func _on_gm_skip() -> void:
	state_machine.transition_to(&"VictoryState")

func _update_score_display() -> void:
	if _score_label:
		_score_label.text = "DATOS %02d / %02d" % [_score, TARGET_ITEMS]

func _set_status(text: String, color: Color) -> void:
	if _status_label:
		_status_label.text = text
		_status_label.add_theme_color_override("font_color", color)
