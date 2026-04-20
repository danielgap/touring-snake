extends Control

const CORNER_RADIUS: int = 12
const BG_COLOR: Color = Color("#0f1623")
const BORDER_COLOR: Color = Color("#1e293b")
const TEXT_COLOR: Color = Color("#f1f5f9")
const MUTED_TEXT: Color = Color("#64748b")
const ACCENT_BLUE: Color = Color("#0ea5e9")
const ACCENT_GREEN: Color = Color("#22c55e")
const ACCENT_AMBER: Color = Color("#f59e0b")
const IMPORT_DEST: String = "user://questions_imported.json"
const MG_IMPORT_DEST: String = "user://minijuegos_imported.json"

@onready var overlay: ColorRect = %Overlay
@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var show_name_edit: LineEdit = %ShowNameEdit
@onready var subtitle_edit: LineEdit = %SubtitleEdit
@onready var team_count_spin: SpinBox = %TeamCountSpin
@onready var teams_container: VBoxContainer = %TeamsContainer
@onready var questions_path_label: Label = %QuestionsPathLabel
@onready var import_btn: Button = %ImportBtn
@onready var question_count_label: Label = %QuestionCountLabel
@onready var mg_path_label: Label = %MgPathLabel2
@onready var mg_import_btn: Button = %MgImportBtn
@onready var mg_count_label: Label = %MgCountLabel
@onready var points_correct_spin: SpinBox = %PointsCorrectSpin
@onready var points_incorrect_spin: SpinBox = %PointsIncorrectSpin
@onready var mqtt_host_edit: LineEdit = %MqttHostEdit
@onready var mqtt_port_spin: SpinBox = %MqttPortSpin
@onready var save_btn: Button = %SaveBtn
@onready var cancel_btn: Button = %CancelBtn
@onready var reset_btn: Button = %ResetBtn
@onready var file_dialog: FileDialog = %FileDialog
@onready var mg_file_dialog: FileDialog = %MgFileDialog


func _ready() -> void:
	visible = false
	_connect_signals()
	_apply_styles()


# ═══════════════════════════════════════════════════════════════════
#  Public API
# ═══════════════════════════════════════════════════════════════════

func show_settings() -> void:
	_load_config_to_ui()
	visible = true


func hide_settings() -> void:
	visible = false


# ═══════════════════════════════════════════════════════════════════
#  Config ↔ UI
# ═══════════════════════════════════════════════════════════════════

func _load_config_to_ui() -> void:
	team_count_spin.set_block_signals(true)

	show_name_edit.text = ShowConfig.get_show_name()
	subtitle_edit.text = ShowConfig.get_subtitle()
	team_count_spin.value = float(ShowConfig.get_team_count())

	questions_path_label.text = ShowConfig.get_questions_file()
	question_count_label.text = "%d preguntas cargadas" % ContentRepo.get_question_count()

	mg_path_label.text = ShowConfig.get_minigames_file()
	mg_count_label.text = "%d minijuegos cargados" % ContentRepo.get_minigame_count()

	points_correct_spin.value = float(ShowConfig.get_points_correct())
	points_incorrect_spin.value = float(ShowConfig.get_points_incorrect())

	mqtt_host_edit.text = ShowConfig.get_mqtt_host()
	mqtt_port_spin.value = float(ShowConfig.get_mqtt_port())

	team_count_spin.set_block_signals(false)
	_rebuild_teams_ui()


func _save_and_close() -> void:
	ShowConfig.set_show_name(show_name_edit.text)
	ShowConfig.set_subtitle(subtitle_edit.text)
	ShowConfig.set_team_count(int(team_count_spin.value))

	for child: Node in teams_container.get_children():
		var team_id: int = child.get_meta("team_id", 0)
		var name_edit: LineEdit = child.get_node_or_null("NameEdit") as LineEdit
		var color_btn: ColorPickerButton = child.get_node_or_null("ColorBtn") as ColorPickerButton
		if name_edit != null:
			ShowConfig.set_team_name(team_id, name_edit.text)
		if color_btn != null:
			ShowConfig.set_team_color(team_id, color_btn.color)

	ShowConfig.sync_teams_to_count()
	ShowConfig.set_points_correct(int(points_correct_spin.value))
	ShowConfig.set_points_incorrect(int(points_incorrect_spin.value))
	ShowConfig.set_mqtt_host(mqtt_host_edit.text)
	ShowConfig.set_mqtt_port(int(mqtt_port_spin.value))
	ShowConfig.save_config()
	hide_settings()


# ═══════════════════════════════════════════════════════════════════
#  Questions import
# ═══════════════════════════════════════════════════════════════════

func _on_import_questions() -> void:
	file_dialog.popup_centered()


func _on_file_selected(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SettingsController: No se pudo abrir %s" % path)
		return

	var raw_text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("SettingsController: El archivo no es un JSON array válido")
		return

	var dest: FileAccess = FileAccess.open(IMPORT_DEST, FileAccess.WRITE)
	if dest == null:
		push_error("SettingsController: No se pudo escribir en %s" % IMPORT_DEST)
		return
	dest.store_string(raw_text)

	ShowConfig.set_questions_file(IMPORT_DEST)
	ShowConfig.save_config()
	ContentRepo.load_questions()

	questions_path_label.text = IMPORT_DEST
	question_count_label.text = "%d preguntas cargadas" % ContentRepo.get_question_count()


# ═══════════════════════════════════════════════════════════════════
#  Minigames import
# ═══════════════════════════════════════════════════════════════════

func _on_import_minigames() -> void:
	mg_file_dialog.popup_centered()


func _on_mg_file_selected(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SettingsController: No se pudo abrir %s" % path)
		return

	var raw_text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SettingsController: El archivo de minijuegos no es un JSON válido")
		return

	var dest: FileAccess = FileAccess.open(MG_IMPORT_DEST, FileAccess.WRITE)
	if dest == null:
		push_error("SettingsController: No se pudo escribir en %s" % MG_IMPORT_DEST)
		return
	dest.store_string(raw_text)

	ShowConfig.set_minigames_file(MG_IMPORT_DEST)
	ShowConfig.save_config()
	ContentRepo.load_minigames()

	mg_path_label.text = MG_IMPORT_DEST
	mg_count_label.text = "%d minijuegos cargados" % ContentRepo.get_minigame_count()


# ═══════════════════════════════════════════════════════════════════
#  Teams UI
# ═══════════════════════════════════════════════════════════════════

func _rebuild_teams_ui() -> void:
	for child: Node in teams_container.get_children():
		child.queue_free()

	var count: int = int(team_count_spin.value)
	for i: int in range(count):
		var team_id: int = i + 1
		var row: HBoxContainer = HBoxContainer.new()
		row.set_meta("team_id", team_id)
		row.add_theme_constant_override("separation", 8)

		var team_label: Label = Label.new()
		team_label.text = "Equipo %d" % team_id
		team_label.add_theme_color_override("font_color", ShowConfig.get_team_color(team_id))
		team_label.add_theme_font_size_override("font_size", 20)
		team_label.custom_minimum_size = Vector2(90, 0)
		team_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

		var name_edit: LineEdit = LineEdit.new()
		name_edit.name = "NameEdit"
		name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_edit.custom_minimum_size = Vector2(0, 48)
		name_edit.text = ShowConfig.get_team_name(team_id)
		name_edit.placeholder_text = "Equipo %d" % team_id
		name_edit.add_theme_color_override("font_color", TEXT_COLOR)
		name_edit.add_theme_color_override("font_placeholder_color", MUTED_TEXT)
		name_edit.add_theme_color_override("caret_color", TEXT_COLOR)
		_apply_line_edit_bg(name_edit)

		var color_btn: ColorPickerButton = ColorPickerButton.new()
		color_btn.name = "ColorBtn"
		color_btn.custom_minimum_size = Vector2(56, 48)
		color_btn.color = ShowConfig.get_team_color(team_id)

		row.add_child(team_label)
		row.add_child(name_edit)
		row.add_child(color_btn)
		teams_container.add_child(row)


func _on_team_count_changed(_value: float) -> void:
	_rebuild_teams_ui()


func _on_reset_pressed() -> void:
	ShowConfig.reset_to_defaults()
	_load_config_to_ui()


# ═══════════════════════════════════════════════════════════════════
#  Wiring
# ═══════════════════════════════════════════════════════════════════

func _connect_signals() -> void:
	import_btn.pressed.connect(_on_import_questions)
	file_dialog.file_selected.connect(_on_file_selected)
	mg_import_btn.pressed.connect(_on_import_minigames)
	mg_file_dialog.file_selected.connect(_on_mg_file_selected)
	save_btn.pressed.connect(_save_and_close)
	cancel_btn.pressed.connect(hide_settings)
	reset_btn.pressed.connect(_on_reset_pressed)
	team_count_spin.value_changed.connect(_on_team_count_changed)


# ═══════════════════════════════════════════════════════════════════
#  Styling
# ═══════════════════════════════════════════════════════════════════

func _apply_styles() -> void:
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = BG_COLOR
	panel_style.border_color = BORDER_COLOR
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(CORNER_RADIUS)
	settings_panel.add_theme_stylebox_override("panel", panel_style)

	for le: LineEdit in [show_name_edit, subtitle_edit, mqtt_host_edit]:
		le.add_theme_color_override("font_color", TEXT_COLOR)
		le.add_theme_color_override("font_placeholder_color", MUTED_TEXT)
		le.add_theme_color_override("caret_color", TEXT_COLOR)
		_apply_line_edit_bg(le)

	for sb: SpinBox in [team_count_spin, points_correct_spin, points_incorrect_spin, mqtt_port_spin]:
		var sb_edit: LineEdit = sb.get_line_edit()
		if sb_edit != null:
			sb_edit.add_theme_color_override("font_color", TEXT_COLOR)
			sb_edit.add_theme_color_override("caret_color", TEXT_COLOR)
			_apply_line_edit_bg(sb_edit)

	_apply_action_button(save_btn, ACCENT_GREEN)
	_apply_action_button(cancel_btn, MUTED_TEXT)
	_apply_action_button(reset_btn, ACCENT_AMBER)
	_apply_action_button(import_btn, ACCENT_BLUE)
	_apply_action_button(mg_import_btn, ACCENT_AMBER)


func _apply_line_edit_bg(le: LineEdit) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("#1e293b")
	style.set_corner_radius_all(6)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	le.add_theme_stylebox_override("normal", style)

	var focused: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	focused.border_color = ACCENT_BLUE
	focused.set_border_width_all(1)
	le.add_theme_stylebox_override("focused", focused)


func _apply_action_button(btn: Button, accent: Color) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(accent.r * 0.15, accent.g * 0.15, accent.b * 0.15, 1.0)
	normal.border_color = Color(accent.r * 0.4, accent.g * 0.4, accent.b * 0.4, 1.0)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(8)
	normal.content_margin_top = 10.0
	normal.content_margin_bottom = 10.0
	normal.content_margin_left = 16.0
	normal.content_margin_right = 16.0

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(accent.r * 0.3, accent.g * 0.3, accent.b * 0.3, 1.0)
	hover.border_color = accent

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_color", accent)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
