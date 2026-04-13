extends Node

const UiLab = preload("res://src/ui/ui_lab.gd")
const BackdropScene = preload("res://src/ui/terminal_backdrop.gd")

var state_machine: Node = null

func _content() -> Control:
	var main := get_tree().root.find_child("Main", true, false)
	return main.get_node("Content") as Control

const PASSWORD := "PERFIL"
const MAX_CHARS := 6
const EVA9_MESSAGE := "Cada expediente es un PERFIL. Tu huella digital no es privada: es un producto. Ingresá la clave para abrir el expediente."

var _message_label: Label
var _display: HBoxContainer
var _display_panel: PanelContainer
var _char_labels: Array[Label] = []
var _slot_panels: Array[PanelContainer] = []
var _input_text: String = ""
var _keyboard_rows: VBoxContainer
var _status_label: Label
var _is_active: bool = false
var _is_submitting: bool = false

var _keys_row1: Array[String] = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
var _keys_row2: Array[String] = ["A", "S", "D", "F", "G", "H", "J", "K", "L", "Ñ"]
var _keys_row3: Array[String] = ["Z", "X", "C", "V", "B", "N", "M", "⌫", "OK"]

func enter(_msg: Dictionary = {}) -> void:
	_is_active = true
	_is_submitting = false
	_input_text = ""
	_char_labels.clear()
	_slot_panels.clear()
	var content := _content()
	content.add_child(BackdropScene.new())
	_create_layout(content)
	_update_display()
	_set_status("Clave requerida · 6 caracteres", UiLab.MUTED)

func exit() -> void:
	_is_active = false
	var content := _content()
	for child in content.get_children():
		child.queue_free()
	_char_labels.clear()
	_slot_panels.clear()

func _create_layout(content: Control) -> void:
	var shell := MarginContainer.new()
	shell.set_anchors_preset(Control.PRESET_FULL_RECT)
	shell.offset_left = 88
	shell.offset_top = 70
	shell.offset_right = -88
	shell.offset_bottom = -64
	content.add_child(shell)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 26)
	shell.add_child(root)

	root.add_child(_create_header())
	root.add_child(_create_body())
	root.add_child(_create_keyboard_panel())

func _create_header() -> Control:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)

	var title_block := VBoxContainer.new()
	title_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_block.add_theme_constant_override("separation", 8)
	title_block.add_child(UiLab.make_label("EVA-9 // PROFILE ACCESS LAYER", 16, UiLab.ACCENT_GREEN))
	var title := UiLab.make_label("DOSSIER DE ACCESO BIOMÉTRICO", 42, UiLab.TEXT)
	title_block.add_child(title)
	var subtitle := UiLab.make_label("Interfaz de clasificación para lectura de huella digital y perfil algorítmico.", 24, UiLab.ACCENT_CYAN)
	title_block.add_child(subtitle)
	header.add_child(title_block)

	var tag_row := HBoxContainer.new()
	tag_row.alignment = BoxContainer.ALIGNMENT_END
	tag_row.add_theme_constant_override("separation", 12)
	tag_row.add_child(UiLab.make_tag("SUBJECT EVA-9", UiLab.ACCENT_CYAN))
	tag_row.add_child(UiLab.make_tag("ACCESS FILTER", UiLab.ACCENT_GREEN, Color(UiLab.ACCENT_GREEN, 0.08)))
	tag_row.add_child(UiLab.make_tag("CLASSIFIED", UiLab.ACCENT_MAGENTA, Color(UiLab.ACCENT_MAGENTA, 0.08)))
	header.add_child(tag_row)
	return header

func _create_body() -> Control:
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 24)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL

	body.add_child(_create_narrative_panel())
	body.add_child(_create_access_panel())
	return body

func _create_narrative_panel() -> Control:
	var panel := PanelContainer.new()
	UiLab.apply_panel(panel, UiLab.SURFACE_SOFT, UiLab.BORDER, 20, 2)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	layout.add_child(UiLab.make_tag("PROFILE ANALYSIS", UiLab.ACCENT_GREEN, Color(UiLab.ACCENT_GREEN, 0.08)))

	_message_label = UiLab.make_label(EVA9_MESSAGE, 28, UiLab.TEXT)
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(_message_label)

	layout.add_child(UiLab.make_divider(Color(UiLab.BORDER, 0.8), 2))
	layout.add_child(UiLab.make_label("Expediente activo", 20, UiLab.ACCENT_CYAN))
	layout.add_child(UiLab.make_label("• La IA usa señales únicas para construir perfiles.", 20, UiLab.MUTED))
	layout.add_child(UiLab.make_label("• Tu huella digital puede convertirse en un identificador rastreable.", 20, UiLab.MUTED))
	layout.add_child(UiLab.make_label("• Acción requerida: escribir la palabra núcleo para continuar.", 20, UiLab.MUTED))

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	footer.add_child(UiLab.make_tag("BIOMETRICS", UiLab.ACCENT_CYAN, Color(UiLab.ACCENT_CYAN, 0.06)))
	footer.add_child(UiLab.make_tag("PROFILE TRACE", UiLab.ACCENT_MAGENTA, Color(UiLab.ACCENT_MAGENTA, 0.06)))
	layout.add_child(footer)

	return panel

func _create_access_panel() -> Control:
	var panel := PanelContainer.new()
	UiLab.apply_panel(panel, UiLab.SURFACE_SOFT, UiLab.ACCENT_CYAN, 20, 2)
	panel.custom_minimum_size = Vector2(700, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	layout.add_child(UiLab.make_label("MATRIZ DE ACCESO", 18, UiLab.ACCENT_GREEN))
	var title := UiLab.make_label("Ingresá la clave del expediente", 32, UiLab.TEXT)
	layout.add_child(title)

	var tag_row := HBoxContainer.new()
	tag_row.add_theme_constant_override("separation", 12)
	tag_row.add_child(UiLab.make_tag("6 SLOTS", UiLab.ACCENT_CYAN, Color(UiLab.ACCENT_CYAN, 0.06)))
	tag_row.add_child(UiLab.make_tag("SENSITIVE INPUT", UiLab.ACCENT_MAGENTA, Color(UiLab.ACCENT_MAGENTA, 0.06)))
	layout.add_child(tag_row)

	_display_panel = PanelContainer.new()
	UiLab.apply_panel(_display_panel, Color(UiLab.SURFACE_ALT, 0.8), UiLab.BORDER, 18, 2)
	layout.add_child(_display_panel)

	var display_margin := MarginContainer.new()
	display_margin.add_theme_constant_override("margin_left", 20)
	display_margin.add_theme_constant_override("margin_top", 22)
	display_margin.add_theme_constant_override("margin_right", 20)
	display_margin.add_theme_constant_override("margin_bottom", 22)
	_display_panel.add_child(display_margin)

	_display = HBoxContainer.new()
	_display.alignment = BoxContainer.ALIGNMENT_CENTER
	_display.add_theme_constant_override("separation", 14)
	display_margin.add_child(_display)

	for _i in MAX_CHARS:
		var slot := PanelContainer.new()
		UiLab.apply_panel(slot, Color(UiLab.BG, 0.65), UiLab.BORDER_SOFT, 12, 2)
		slot.custom_minimum_size = Vector2(82, 100)
		_display.add_child(slot)
		_slot_panels.append(slot)

		var slot_margin := MarginContainer.new()
		slot_margin.add_theme_constant_override("margin_left", 8)
		slot_margin.add_theme_constant_override("margin_top", 14)
		slot_margin.add_theme_constant_override("margin_right", 8)
		slot_margin.add_theme_constant_override("margin_bottom", 14)
		slot.add_child(slot_margin)

		var char_label := UiLab.make_label("_", 46, UiLab.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		char_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_margin.add_child(char_label)
		_char_labels.append(char_label)

	_status_label = UiLab.make_label("", 20, UiLab.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(_status_label)
	return panel

func _create_keyboard_panel() -> Control:
	var panel := PanelContainer.new()
	UiLab.apply_panel(panel, UiLab.SURFACE_SOFT, UiLab.BORDER, 20, 2)
	panel.custom_minimum_size = Vector2(0, 320)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	_keyboard_rows = VBoxContainer.new()
	_keyboard_rows.add_theme_constant_override("separation", 12)
	margin.add_child(_keyboard_rows)

	_keyboard_rows.add_child(UiLab.make_label("TECLADO DE EXPEDIENTE", 18, UiLab.ACCENT_GREEN))
	_keyboard_rows.add_child(UiLab.make_label("Seleccioná cada carácter desde la matriz de captura.", 22, UiLab.MUTED))

	_create_key_row(_keys_row1)
	_create_key_row(_keys_row2)
	_create_key_row(_keys_row3)
	return panel

func _create_key_row(keys: Array[String]) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_keyboard_rows.add_child(row)

	for key_text in keys:
		var btn := Button.new()
		btn.text = key_text
		btn.custom_minimum_size = Vector2(96, 66)
		if key_text == "⌫" or key_text == "OK":
			btn.custom_minimum_size = Vector2(148, 66)
		btn.add_theme_font_size_override("font_size", 24)
		UiLab.apply_button_style(btn, UiLab.ACCENT_CYAN if key_text != "OK" else UiLab.ACCENT_GREEN, UiLab.SURFACE_ALT)
		if key_text == "⌫":
			UiLab.apply_button_style(btn, UiLab.ACCENT_MAGENTA, UiLab.SURFACE_ALT)
		btn.pressed.connect(_on_key_pressed.bind(key_text))
		row.add_child(btn)

func _on_key_pressed(key: String) -> void:
	if _is_submitting or not _is_active:
		return
	if key == "⌫":
		if _input_text.length() > 0:
			_input_text = _input_text.substr(0, _input_text.length() - 1)
			_update_display()
			Sfx.play("backspace")
			_set_status("Retroceso aplicado", UiLab.MUTED)
	elif key == "OK":
		_submit()
	else:
		if _input_text.length() < MAX_CHARS:
			_input_text += key
			_update_display()
			Sfx.play("key_click")
			_set_status("Captura %d/%d" % [_input_text.length(), MAX_CHARS], UiLab.ACCENT_CYAN)

func _update_display() -> void:
	for i in MAX_CHARS:
		if i < _input_text.length():
			_char_labels[i].text = _input_text[i]
			_char_labels[i].add_theme_color_override("font_color", UiLab.TEXT)
			UiLab.apply_panel(_slot_panels[i], Color(UiLab.ACCENT_CYAN, 0.08), Color(UiLab.ACCENT_CYAN, 0.55), 12, 2)
		else:
			_char_labels[i].text = "_"
			_char_labels[i].add_theme_color_override("font_color", UiLab.MUTED)
			UiLab.apply_panel(_slot_panels[i], Color(UiLab.BG, 0.65), UiLab.BORDER_SOFT, 12, 2)

func _submit() -> void:
	if _input_text.length() < MAX_CHARS:
		_set_status("La clave requiere 6 caracteres completos", UiLab.WARNING)
		return
	_is_submitting = true
	if _input_text.to_upper() == PASSWORD:
		_show_success()
	else:
		_show_error()

func _show_success() -> void:
	Sfx.play("password_success")
	for i in MAX_CHARS:
		UiLab.apply_panel(_slot_panels[i], Color(UiLab.ACCENT_GREEN, 0.08), UiLab.ACCENT_GREEN, 12, 2)
		_char_labels[i].add_theme_color_override("font_color", UiLab.ACCENT_GREEN)
	_set_status("Acceso validado · expediente abierto", UiLab.ACCENT_GREEN)
	EventBus.password_accepted.emit()
	await get_tree().create_timer(0.3).timeout
	if _is_active:
		state_machine.transition_to(&"TransitionState")

func _show_error() -> void:
	Sfx.play("password_error")
	for i in MAX_CHARS:
		UiLab.apply_panel(_slot_panels[i], Color(UiLab.DANGER, 0.08), UiLab.DANGER, 12, 2)
		_char_labels[i].add_theme_color_override("font_color", UiLab.DANGER)
	_set_status("Clave rechazada · perfil inconsistente", UiLab.DANGER)
	var tween := _display_panel.create_tween()
	tween.tween_property(_display_panel, "position:x", _display_panel.position.x + 14.0, 0.04)
	tween.tween_property(_display_panel, "position:x", _display_panel.position.x - 14.0, 0.04)
	tween.tween_property(_display_panel, "position:x", _display_panel.position.x, 0.04)
	await tween.finished
	if not _is_active:
		return
	await get_tree().create_timer(0.55).timeout
	if not _is_active:
		return
	_input_text = ""
	_update_display()
	_set_status("Reintentá la captura", UiLab.MUTED)
	_is_submitting = false

func _set_status(text: String, color: Color) -> void:
	if _status_label:
		_status_label.text = text
		_status_label.add_theme_color_override("font_color", color)

func handle_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if event.position.x > 1920.0 - 48.0 and event.position.y < 48.0:
			EventBus.gm_trigger_menu.emit()
