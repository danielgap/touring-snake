extends Control

## ── Broadcast palette ────────────────────────────────────────────
const BG_CONSOLE := Color("#060a12")
const CARD_BG := Color("#0f1623")
const CARD_BG_ALT := Color("#0b1019")
const CARD_BORDER := Color("#1e293b")
const CORNER_RADIUS := 12

const TEAM1_COLOR := Color("#3b82f6")   # Blue
const TEAM2_COLOR := Color("#f59e0b")   # Amber
const TEAM3_COLOR := Color("#ef4444")   # Red
const TEAM1_BG := Color("#0f2850")
const TEAM2_BG := Color("#2d1f06")
const TEAM3_BG := Color("#2d0f0f")
const TEAM1_DIM := Color("#1e3a5f")
const TEAM2_DIM := Color("#3d2e0a")
const TEAM3_DIM := Color("#3d1515")

const PHASE_IDLE_COLOR := Color("#475569")
const PHASE_QUESTION_COLOR := Color("#0ea5e9")
const PHASE_LOCKED_COLOR := Color("#f59e0b")
const PHASE_REVEAL_COLOR := Color("#22c55e")
const PHASE_CORRECT_COLOR := Color("#22c55e")
const PHASE_INCORRECT_COLOR := Color("#ef4444")
const PHASE_MINIGAME_COLOR := Color("#f59e0b")

const TEXT_BRIGHT := Color("#f1f5f9")
const TEXT_DIM := Color("#94a3b8")
const TEXT_MUTED := Color("#475569")
const ACCENT_BLUE := Color("#0ea5e9")
const GLOW_SIZE := 6

## ── Phase panels ─────────────────────────────────────────────────
@onready var idle_panel: VBoxContainer = %IdlePanel
@onready var question_panel: VBoxContainer = %QuestionPanel
@onready var locked_panel: VBoxContainer = %LockedPanel
@onready var reveal_panel: VBoxContainer = %RevealPanel
@onready var minigame_panel: VBoxContainer = %MiniGamePanel

## ── Top bar ──────────────────────────────────────────────────────
@onready var phase_label: Label = %PhaseLabel
@onready var team1_score_value: Label = %Team1ScoreValue
@onready var team2_score_value: Label = %Team2ScoreValue
@onready var team3_score_value: Label = %Team3ScoreValue

## ── Sidebar — team controls ──────────────────────────────────────
@onready var team1_status: Label = %T1Status
@onready var team2_status: Label = %T2Status
@onready var team3_status: Label = %T3Status
@onready var team1_lock_btn: Button = %T1LockBtn
@onready var team1_force_btn: Button = %T1ForceBtn
@onready var team2_lock_btn: Button = %T2LockBtn
@onready var team2_force_btn: Button = %T2ForceBtn
@onready var team3_lock_btn: Button = %T3LockBtn
@onready var team3_force_btn: Button = %T3ForceBtn

## ── Sidebar — score controls ─────────────────────────────────────
@onready var team1_sub_btn: Button = %T1SubBtn
@onready var team1_add_btn: Button = %T1AddBtn
@onready var team2_sub_btn: Button = %T2SubBtn
@onready var team2_add_btn: Button = %T2AddBtn
@onready var team3_sub_btn: Button = %T3SubBtn
@onready var team3_add_btn: Button = %T3AddBtn

## ── Idle panel — unified flow ────────────────────────────────────
@onready var progress_label: Label = %ProgressLabel
@onready var next_question_btn: Button = %NextQuestionBtn
@onready var mg_quick_btn: Button = %MgQuickBtn
@onready var round_selector: OptionButton = %RoundSelector
@onready var reset_used_btn: Button = %ResetUsedBtn
@onready var preview_label: Label = %PreviewLabel
@onready var manual_toggle: Button = %ManualToggle
@onready var manual_content: ScrollContainer = %ManualContent
@onready var question_selector: OptionButton = %QuestionSelector
@onready var load_selected_btn: Button = %LoadSelectedBtn

## ── Idle panel — minigame selectors ──────────────────────────────
@onready var mg_category_selector: OptionButton = %MgCategorySelector
@onready var mg_selector: OptionButton = %MgSelector
@onready var mg_launch_btn: Button = %MgLaunchBtn
@onready var mg_category_row: HBoxContainer = mg_category_selector.get_parent()
@onready var mg_row: HBoxContainer = mg_selector.get_parent()

## ── Question panel ───────────────────────────────────────────────
@onready var question_text: Label = %QuestionText
@onready var opt_a: Label = %OptA
@onready var opt_b: Label = %OptB
@onready var opt_c: Label = %OptC
@onready var opt_d: Label = %OptD
@onready var lock_info: Label = %LockInfo
@onready var q_reveal_btn: Button = %QRevealBtn
var skip_btn: Button

## ── Locked panel ─────────────────────────────────────────────────
@onready var locked_q_text: Label = %LockedQText
@onready var answered_label: Label = %AnsweredLabel
@onready var correct_btn: Button = %CorrectBtn
@onready var incorrect_btn: Button = %IncorrectBtn
@onready var reopen_btn: Button = %ReopenBtn
@onready var locked_reveal_btn: Button = %LockedRevealBtn

## ── Reveal panel ─────────────────────────────────────────────────
@onready var reveal_answer: Label = %RevealAnswer
@onready var result_label: Label = %ResultLabel
@onready var next_btn: Button = %NextBtn
@onready var reveal_mg_btn: Button = %RevealMgBtn

## ── MiniGame panel ───────────────────────────────────────────────
@onready var mg_active_title: Label = %MgActiveTitle
@onready var mg_active_desc: Label = %MgActiveDesc
@onready var mg_active_material: Label = %MgActiveMaterial
@onready var mg_active_rules: Label = %MgActiveRules
@onready var mg_active_meta: Label = %MgActiveMeta
@onready var mg_end_btn: Button = %MgEndBtn

## ── Bottom bar ───────────────────────────────────────────────────
@onready var refresh_btn: Button = %RefreshBtn
@onready var reset_locks_btn: Button = %ResetLocksBtn
@onready var clear_session_btn: Button = %ClearSessionBtn
@onready var settings_btn: Button = %SettingsBtn

## ── Internal state ───────────────────────────────────────────────
var _round_values: Array[String] = []
var _question_ids: Array[int] = []
var _mg_ids: Array[int] = []
var _selector_syncing: bool = false
var _mg_selector_syncing: bool = false
var _showing_selector: bool = false
var _showing_mg_preview: bool = false
var _correct_btn_style: StyleBoxFlat
var _incorrect_btn_style: StyleBoxFlat
var _prev_phase: int = -1
var _prev_scores: Dictionary = {}
var _question_images_container: VBoxContainer
var _minigame_images_container: VBoxContainer
var _buzzer_indicator: Label
var _prev_question_images: PackedStringArray = PackedStringArray()
var _prev_minigame_images: PackedStringArray = PackedStringArray()


func _ready() -> void:
	_hide_removed_nodes()
	_apply_styles()
	_connect_signals()
	_wire_config_values()
	_update_team_visibility()
	_sync_selector_controls()
	_render_state(AppState.current_state)
	_render_scores(AppState.current_state.scores)


func _hide_removed_nodes() -> void:
	if manual_toggle != null:
		manual_toggle.visible = false
	if question_selector != null:
		question_selector.visible = false
	if load_selected_btn != null:
		load_selected_btn.visible = false
	if clear_session_btn != null:
		clear_session_btn.visible = false
	_reparent_from_manual_section()
	_create_skip_button()


func _reparent_from_manual_section() -> void:
	var base_path: String = "RootMargin/RootVBox/ContentArea/MainArea/IdlePanel"
	var manual_section: Node = get_node_or_null("%s/ManualSection" % base_path)
	var idle_panel_node: Node = get_node_or_null(base_path)
	if manual_section == null or idle_panel_node == null:
		return

	# Reparent nodes we need OUT of ManualSection before hiding it
	var nodes_to_reparent: PackedStringArray = [
		"ManualContent/ManualVBox/RoundRow",
		"ManualContent/ManualVBox/MgCategoryRow",
		"ManualContent/ManualVBox/MgRow",
		"ManualContent/ManualVBox/PreviewCard",
		"ManualContent/ManualVBox/ManualActions",
	]
	for rel_path: String in nodes_to_reparent:
		var node: Node = get_node_or_null("%s/ManualSection/%s" % [base_path, rel_path])
		if node != null:
			node.reparent(idle_panel_node)

	# Hide QRow (question selector, not needed)
	var q_row: Node = get_node_or_null("%s/ManualSection/ManualContent/ManualVBox/QRow" % base_path)
	if q_row != null:
		q_row.visible = false

	# Now safe to hide the empty ManualSection
	manual_section.visible = false


# ═══════════════════════════════════════════════════════════════════
#  Visual styling (applied once at startup)
# ═══════════════════════════════════════════════════════════════════

func _apply_styles() -> void:
	# ── Background ─────────────────────────────────────────────────
	$Background.color = BG_CONSOLE

	# ── Phase indicator — glowing LED panel ─────────────────────────
	%PhaseCard.add_theme_stylebox_override("panel", _make_glow_card(CARD_BG, PHASE_IDLE_COLOR, 3))

	# ── Score cards — team-colored with glow halo ───────────────────
	%ScoreCard1.add_theme_stylebox_override("panel", _make_glow_card(TEAM1_BG, TEAM1_COLOR, 3, TEAM1_COLOR, GLOW_SIZE))
	%ScoreCard2.add_theme_stylebox_override("panel", _make_glow_card(TEAM2_BG, TEAM2_COLOR, 3, TEAM2_COLOR, GLOW_SIZE))
	%ScoreCard3.add_theme_stylebox_override("panel", _make_glow_card(TEAM3_BG, TEAM3_COLOR, 3, TEAM3_COLOR, GLOW_SIZE))
	team1_score_value.add_theme_color_override("font_color", TEAM1_COLOR)
	team2_score_value.add_theme_color_override("font_color", TEAM2_COLOR)
	team3_score_value.add_theme_color_override("font_color", TEAM3_COLOR)

	# ── Sidebar team cards — team identity with glow ────────────────
	%Team1Card.add_theme_stylebox_override("panel", _make_glow_card(TEAM1_BG, TEAM1_DIM, 2, TEAM1_DIM, 3))
	%Team2Card.add_theme_stylebox_override("panel", _make_glow_card(TEAM2_BG, TEAM2_DIM, 2, TEAM2_DIM, 3))
	%Team3Card.add_theme_stylebox_override("panel", _make_glow_card(TEAM3_BG, TEAM3_DIM, 2, TEAM3_DIM, 3))
	%T1Name.add_theme_color_override("font_color", TEAM1_COLOR)
	%T2Name.add_theme_color_override("font_color", TEAM2_COLOR)
	%T3Name.add_theme_color_override("font_color", TEAM3_COLOR)
	%T1SName.add_theme_color_override("font_color", TEAM1_COLOR)
	%T2SName.add_theme_color_override("font_color", TEAM2_COLOR)
	%T3SName.add_theme_color_override("font_color", TEAM3_COLOR)

	# ── Preview card ────────────────────────────────────────────────
	%PreviewCard.add_theme_stylebox_override("panel", _make_card(CARD_BG_ALT, CARD_BORDER))

	# ── Question card — blue accent glow ────────────────────────────
	%QuestionCard.add_theme_stylebox_override("panel", _make_glow_card(Color("#081525"), ACCENT_BLUE, 2, ACCENT_BLUE, 8))

	# ── Answered card — amber attention glow ────────────────────────
	%AnsweredCard.add_theme_stylebox_override("panel", _make_glow_card(Color("#1a1500"), PHASE_LOCKED_COLOR, 2, PHASE_LOCKED_COLOR, 8))

	# ── Reveal card — green success glow ────────────────────────────
	%RevealCard.add_theme_stylebox_override("panel", _make_glow_card(Color("#0a1f10"), PHASE_REVEAL_COLOR, 2, PHASE_REVEAL_COLOR, 8))

	# ── Correct/Incorrect — emergency correction (dimmer, less prominent) ──
	_correct_btn_style = _make_console_button_style(Color("#059669"), Color("#10b981"))
	_incorrect_btn_style = _make_console_button_style(Color("#dc2626"), Color("#ef4444"))
	correct_btn.add_theme_stylebox_override("normal", _correct_btn_style)
	correct_btn.add_theme_stylebox_override("hover", _make_console_button_style(Color("#10b981"), Color("#34d399")))
	correct_btn.add_theme_stylebox_override("pressed", _correct_btn_style)
	correct_btn.add_theme_color_override("font_color", Color("#10b981"))
	correct_btn.add_theme_color_override("font_hover_color", Color.WHITE)

	incorrect_btn.add_theme_stylebox_override("normal", _incorrect_btn_style)
	incorrect_btn.add_theme_stylebox_override("hover", _make_console_button_style(Color("#ef4444"), Color("#f87171")))
	incorrect_btn.add_theme_stylebox_override("pressed", _incorrect_btn_style)
	incorrect_btn.add_theme_color_override("font_color", Color("#ef4444"))
	incorrect_btn.add_theme_color_override("font_hover_color", Color.WHITE)

	# ── Action buttons — console style ──────────────────────────────
	var all_buttons: Array[Button] = [
		reset_used_btn,
		q_reveal_btn, reopen_btn, locked_reveal_btn, next_btn,
		refresh_btn, reset_locks_btn,
		team1_lock_btn, team1_force_btn, team2_lock_btn, team2_force_btn,
		team3_lock_btn, team3_force_btn,
		team1_sub_btn, team1_add_btn, team2_sub_btn, team2_add_btn,
		team3_sub_btn, team3_add_btn,
		mg_launch_btn, mg_end_btn,
	]
	for btn: Button in all_buttons:
		if btn != null:
			_apply_console_button(btn)

	# ── Main action buttons — game-show glow ────────────────────────
	_apply_game_glow_button(next_question_btn, ACCENT_BLUE)
	_apply_game_glow_button(mg_quick_btn, PHASE_MINIGAME_COLOR)
	_apply_game_glow_button(reveal_mg_btn, PHASE_MINIGAME_COLOR)

	# ── Primary action buttons — colored accent ─────────────────────
	_apply_accent_button(next_btn, PHASE_REVEAL_COLOR)
	_apply_accent_button(q_reveal_btn, Color("#a855f7"))
	_apply_accent_button(mg_launch_btn, PHASE_MINIGAME_COLOR)
	_apply_accent_button(mg_end_btn, PHASE_REVEAL_COLOR)

	# ── Question images container (dynamic) ──────────────────────────
	_create_question_images_container()

	# ── Minigame images container (dynamic) ───────────────────────────
	_create_minigame_images_container()

	# ── Buzzer indicator (dynamic) ─────────────────────────────────────
	_create_buzzer_indicator()


func _make_card(bg: Color, border: Color, border_w: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_w)
	style.set_corner_radius_all(CORNER_RADIUS)
	return style


func _make_glow_card(bg: Color, border: Color, border_w: int, glow_color: Color = Color.TRANSPARENT, glow_size: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_w)
	style.set_corner_radius_all(CORNER_RADIUS)
	if glow_size > 0:
		style.shadow_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.35)
		style.shadow_size = glow_size
		style.anti_aliasing_size = 1
	return style


func _make_game_button(bg: Color, border: Color, fg: Color, glow_color: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	style.content_margin_left = 28
	style.content_margin_right = 28
	if glow_color != Color.TRANSPARENT:
		style.shadow_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.4)
		style.shadow_size = 10
	return style


func _apply_console_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#151d2e")
	normal.border_color = Color("#1e293b")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(CORNER_RADIUS)
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	normal.content_margin_left = 12
	normal.content_margin_right = 12

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("#1e293b")
	hover.border_color = Color("#334155")
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(CORNER_RADIUS)
	hover.content_margin_top = 6
	hover.content_margin_bottom = 6
	hover.content_margin_left = 12
	hover.content_margin_right = 12

	var disabled := StyleBoxFlat.new()
	disabled.bg_color = Color("#0c1018")
	disabled.border_color = Color("#131a28")
	disabled.set_border_width_all(1)
	disabled.set_corner_radius_all(CORNER_RADIUS)
	disabled.content_margin_top = 6
	disabled.content_margin_bottom = 6
	disabled.content_margin_left = 12
	disabled.content_margin_right = 12

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", TEXT_BRIGHT)
	btn.add_theme_color_override("font_hover_color", Color("#ffffff"))
	btn.add_theme_color_override("font_disabled_color", TEXT_MUTED)


func _apply_accent_button(btn: Button, accent: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(accent.r * 0.25, accent.g * 0.25, accent.b * 0.25, 1.0)
	normal.border_color = Color(accent.r * 0.5, accent.g * 0.5, accent.b * 0.5, 1.0)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(CORNER_RADIUS)
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	normal.content_margin_left = 16
	normal.content_margin_right = 16

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(accent.r * 0.35, accent.g * 0.35, accent.b * 0.35, 1.0)
	hover.border_color = accent
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(CORNER_RADIUS)
	hover.shadow_color = Color(accent.r, accent.g, accent.b, 0.3)
	hover.shadow_size = 6
	hover.content_margin_top = 8
	hover.content_margin_bottom = 8
	hover.content_margin_left = 16
	hover.content_margin_right = 16

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_color", accent)
	btn.add_theme_color_override("font_hover_color", Color("#ffffff"))


func _apply_game_glow_button(btn: Button, accent: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(accent.r * 0.3, accent.g * 0.3, accent.b * 0.3, 1.0)
	normal.border_color = Color(accent.r * 0.6, accent.g * 0.6, accent.b * 0.6, 1.0)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(CORNER_RADIUS)
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	normal.content_margin_left = 20
	normal.content_margin_right = 20

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(accent.r * 0.45, accent.g * 0.45, accent.b * 0.45, 1.0)
	hover.border_color = accent
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(CORNER_RADIUS)
	hover.shadow_color = Color(accent.r, accent.g, accent.b, 0.5)
	hover.shadow_size = 12
	hover.content_margin_top = 12
	hover.content_margin_bottom = 12
	hover.content_margin_left = 20
	hover.content_margin_right = 20

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(accent.r * 0.2, accent.g * 0.2, accent.b * 0.2, 1.0)
	pressed.border_color = Color(accent.r * 0.5, accent.g * 0.5, accent.b * 0.5, 1.0)
	pressed.set_border_width_all(2)
	pressed.set_corner_radius_all(CORNER_RADIUS)
	pressed.content_margin_top = 12
	pressed.content_margin_bottom = 12
	pressed.content_margin_left = 20
	pressed.content_margin_right = 20

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", accent)
	btn.add_theme_color_override("font_hover_color", Color("#ffffff"))


func _apply_text_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color.TRANSPARENT
	normal.border_color = Color.TRANSPARENT
	normal.set_border_width_all(0)
	normal.set_corner_radius_all(0)
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4
	normal.content_margin_left = 8
	normal.content_margin_right = 8

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1.0, 1.0, 1.0, 0.04)
	hover.border_color = Color.TRANSPARENT
	hover.set_border_width_all(0)
	hover.set_corner_radius_all(CORNER_RADIUS)
	hover.content_margin_top = 4
	hover.content_margin_bottom = 4
	hover.content_margin_left = 8
	hover.content_margin_right = 8

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_color", TEXT_DIM)
	btn.add_theme_color_override("font_hover_color", TEXT_BRIGHT)


# ═══════════════════════════════════════════════════════════════════
#  Config wiring (runtime overrides from ShowConfig)
# ═══════════════════════════════════════════════════════════════════

func _wire_config_values() -> void:
	# Team names in sidebar
	%T1Name.text = ShowConfig.get_team_name(1)
	%T2Name.text = ShowConfig.get_team_name(2)
	%T3Name.text = ShowConfig.get_team_name(3)

	# Score row team short names
	%T1SName.text = ShowConfig.get_team_short(1)
	%T2SName.text = ShowConfig.get_team_short(2)
	%T3SName.text = ShowConfig.get_team_short(3)

	# Score card names (top bar)
	var t1_score_name: Label = get_node_or_null("RootMargin/RootVBox/TopBar/ScoreBar/ScoreCard1/ScorePad1/ScoreVBox1/Team1Name")
	var t2_score_name: Label = get_node_or_null("RootMargin/RootVBox/TopBar/ScoreBar/ScoreCard2/ScorePad2/ScoreVBox2/Team2Name")
	var t3_score_name: Label = get_node_or_null("RootMargin/RootVBox/TopBar/ScoreBar/ScoreCard3/ScorePad3/ScoreVBox3/Team3Name")
	if t1_score_name != null:
		t1_score_name.text = ShowConfig.get_team_short(1)
	if t2_score_name != null:
		t2_score_name.text = ShowConfig.get_team_short(2)
	if t3_score_name != null:
		t3_score_name.text = ShowConfig.get_team_short(3)

	# Score button text with configurable points
	var pts: int = ShowConfig.get_points_correct()
	team1_sub_btn.text = "-%d" % pts
	team1_add_btn.text = "+%d" % pts
	team2_sub_btn.text = "-%d" % pts
	team2_add_btn.text = "+%d" % pts
	team3_sub_btn.text = "-%d" % pts
	team3_add_btn.text = "+%d" % pts


func _on_config_changed() -> void:
	_wire_config_values()
	_update_team_visibility()


func _update_team_visibility() -> void:
	var count: int = ShowConfig.get_team_count()

	# Score cards in top bar
	%ScoreCard2.visible = count >= 2
	%ScoreCard3.visible = count >= 3

	# Sidebar team cards
	%Team2Card.visible = count >= 2
	%Team3Card.visible = count >= 3

	# Score manual rows (no unique_name — use path)
	var t2_row: Node = get_node_or_null("RootMargin/RootVBox/ContentArea/Sidebar/T2ScoreRow")
	var t3_row: Node = get_node_or_null("RootMargin/RootVBox/ContentArea/Sidebar/T3ScoreRow")
	if t2_row != null:
		t2_row.visible = count >= 2
	if t3_row != null:
		t3_row.visible = count >= 3


# ═══════════════════════════════════════════════════════════════════
#  Signal wiring
# ═══════════════════════════════════════════════════════════════════

func _connect_signals() -> void:
	# Main action buttons
	next_question_btn.pressed.connect(GameService.load_random_question_from_selected_round)
	mg_quick_btn.pressed.connect(GameService.load_random_minigame)
	reveal_mg_btn.pressed.connect(GameService.load_random_minigame)

	# Skip button
	if skip_btn != null:
		skip_btn.pressed.connect(GameService.skip_current_question)

	# Question actions
	refresh_btn.pressed.connect(ContentRepo.load_questions)
	reset_used_btn.pressed.connect(GameService.reset_used_questions)

	# Round actions
	reopen_btn.pressed.connect(_on_reopen_or_rebote)
	reset_locks_btn.pressed.connect(GameService.reset_team_locks)
	q_reveal_btn.pressed.connect(GameService.reveal_current_answer)
	locked_reveal_btn.pressed.connect(GameService.reveal_current_answer)

	# Selectors
	round_selector.item_selected.connect(_on_round_selected)

	# Minigame selectors
	mg_category_selector.item_selected.connect(_on_mg_category_selected)
	mg_selector.item_selected.connect(_on_mg_selected)

	# Minigame actions
	mg_launch_btn.pressed.connect(GameService.load_selected_minigame)
	mg_end_btn.pressed.connect(GameService.end_current_minigame)

	# Rebote
	correct_btn.pressed.connect(_on_correct_override)
	incorrect_btn.pressed.connect(_on_incorrect_override)

	# Next question (local UI only — shows selector)
	next_btn.pressed.connect(_on_next_question)

	# Team arbitration
	team1_lock_btn.pressed.connect(func() -> void: GameService.toggle_team_lock(1))
	team1_force_btn.pressed.connect(func() -> void: GameService.force_active_team(1))
	team2_lock_btn.pressed.connect(func() -> void: GameService.toggle_team_lock(2))
	team2_force_btn.pressed.connect(func() -> void: GameService.force_active_team(2))
	team3_lock_btn.pressed.connect(func() -> void: GameService.toggle_team_lock(3))
	team3_force_btn.pressed.connect(func() -> void: GameService.force_active_team(3))

	# Score adjustments (reads ShowConfig at call time so settings changes take effect)
	team1_sub_btn.pressed.connect(func() -> void: GameService.adjust_score(1, -ShowConfig.get_points_correct()))
	team1_add_btn.pressed.connect(func() -> void: GameService.adjust_score(1, ShowConfig.get_points_correct()))
	team2_sub_btn.pressed.connect(func() -> void: GameService.adjust_score(2, -ShowConfig.get_points_correct()))
	team2_add_btn.pressed.connect(func() -> void: GameService.adjust_score(2, ShowConfig.get_points_correct()))
	team3_sub_btn.pressed.connect(func() -> void: GameService.adjust_score(3, -ShowConfig.get_points_correct()))
	team3_add_btn.pressed.connect(func() -> void: GameService.adjust_score(3, ShowConfig.get_points_correct()))

	# State signals
	AppState.game_state_changed.connect(_render_state)
	AppState.scores_changed.connect(_render_scores)
	ContentRepo.questions_loaded.connect(_on_questions_loaded)
	GameService.presenter_selector_changed.connect(_on_selector_changed)
	GameService.used_questions_changed.connect(_on_used_questions_changed)
	GameService.presenter_minigame_selector_changed.connect(_on_mg_selector_changed)
	GameService.round_auto_advanced.connect(_on_round_auto_advanced)
	ContentRepo.minigames_loaded.connect(_on_minigames_loaded)

	# Settings panel
	settings_btn.pressed.connect(_on_settings_pressed)

	# Config reactivity
	ShowConfig.config_changed.connect(_on_config_changed)


# ═══════════════════════════════════════════════════════════════════
#  Main render pipeline
# ═══════════════════════════════════════════════════════════════════

func _render_state(state: GameState) -> void:
	var phase_changed: bool = _prev_phase != state.phase
	_update_phase_panels(state)
	_render_phase_label(state)
	_render_sidebar(state)
	_render_idle_panel(state)
	_render_question_panel(state)
	_render_locked_panel(state)
	_render_reveal_panel(state)
	_render_minigame_panel(state)
	_render_bottom_bar(state)
	_render_question_images(state)
	_render_minigame_images(state)
	if phase_changed and _prev_phase >= 0:
		_animate_panel_in(state)
	_prev_phase = state.phase


func _render_scores(scores: Dictionary) -> void:
	var changed_teams: Array[int] = []
	var count: int = ShowConfig.get_team_count()
	for team_id in range(1, count + 1):
		if int(scores.get(team_id, 0)) != int(_prev_scores.get(team_id, 0)):
			changed_teams.append(team_id)
	team1_score_value.text = str(int(scores.get(1, 0)))
	team2_score_value.text = str(int(scores.get(2, 0)))
	team3_score_value.text = str(int(scores.get(3, 0)))
	for team_id in changed_teams:
		_animate_score_pulse(team_id)
	_prev_scores = scores.duplicate()


# ═══════════════════════════════════════════════════════════════════
#  Phase panel switching
# ═══════════════════════════════════════════════════════════════════

func _update_phase_panels(state: GameState) -> void:
	var show_idle := false
	var show_question := false
	var show_locked := false
	var show_reveal := false
	var show_minigame := false

	if _showing_selector:
		show_idle = true
	else:
		match state.phase:
			Enums.GamePhase.IDLE:
				show_idle = true
			Enums.GamePhase.QUESTION:
				show_question = true
			Enums.GamePhase.LOCKED:
				show_locked = true
			Enums.GamePhase.REVEAL:
				show_reveal = true
			Enums.GamePhase.MINIGAME:
				show_minigame = true
			_:
				show_idle = true

	idle_panel.visible = show_idle
	question_panel.visible = show_question
	locked_panel.visible = show_locked
	reveal_panel.visible = show_reveal
	minigame_panel.visible = show_minigame

	# Reset selector override when phase changes away from REVEAL
	if state.phase != Enums.GamePhase.REVEAL:
		_showing_selector = false


func _on_next_question() -> void:
	_showing_selector = true
	_update_phase_panels(AppState.current_state)


func _on_reopen_or_rebote() -> void:
	var state: GameState = AppState.current_state
	if state.phase == Enums.GamePhase.LOCKED \
		and state.answer_feedback_status == Enums.AnswerFeedbackStatus.INCORRECT \
		and GameService.teams_available_for_rebote() > 0:
		GameService.activate_rebote()
	else:
		GameService.reopen_current_question()


func _on_correct_override() -> void:
	GameService.override_answer_correct()


func _on_incorrect_override() -> void:
	GameService.override_answer_incorrect()


# ═══════════════════════════════════════════════════════════════════
#  Section renderers
# ═══════════════════════════════════════════════════════════════════

func _render_phase_label(state: GameState) -> void:
	if phase_label == null:
		return
	var phase_color: Color = PHASE_IDLE_COLOR
	var round_name: String = GameService.get_selected_round_name()
	var round_suffix: String = ""
	if not round_name.is_empty() and state.phase != Enums.GamePhase.IDLE:
		round_suffix = " · " + round_name.to_upper()
	match state.phase:
		Enums.GamePhase.IDLE:
			phase_label.text = "STANDBY"
			phase_color = PHASE_IDLE_COLOR
		Enums.GamePhase.QUESTION:
			if state.answers_enabled:
				phase_label.text = "AL AIRE%s" % round_suffix
				phase_color = PHASE_QUESTION_COLOR
			else:
				phase_label.text = "EN JUEGO%s" % round_suffix
				phase_color = PHASE_QUESTION_COLOR
		Enums.GamePhase.LOCKED:
			match state.answer_feedback_status:
				Enums.AnswerFeedbackStatus.CORRECT:
					phase_label.text = "CORRECTA%s" % round_suffix
					phase_color = PHASE_CORRECT_COLOR
				Enums.AnswerFeedbackStatus.INCORRECT:
					phase_label.text = "INCORRECTA%s" % round_suffix
					phase_color = PHASE_INCORRECT_COLOR
				_:
					phase_label.text = "RESPUESTA%s" % round_suffix
					phase_color = PHASE_LOCKED_COLOR
		Enums.GamePhase.REVEAL:
			phase_label.text = "REVELADA%s" % round_suffix
			phase_color = PHASE_REVEAL_COLOR
		Enums.GamePhase.MINIGAME:
			phase_label.text = "MINIJUEGO"
			phase_color = PHASE_MINIGAME_COLOR
		_:
			phase_label.text = "STANDBY"
			phase_color = PHASE_IDLE_COLOR

	# Dynamic phase card — border + glow matches phase
	phase_label.add_theme_color_override("font_color", phase_color)
	var phase_style: StyleBoxFlat = %PhaseCard.get_theme_stylebox("panel")
	if phase_style:
		phase_style.border_color = phase_color
		phase_style.bg_color = Color(phase_color.r * 0.15, phase_color.g * 0.15, phase_color.b * 0.15, 1.0)
		phase_style.shadow_color = Color(phase_color.r, phase_color.g, phase_color.b, 0.5)
		phase_style.shadow_size = GLOW_SIZE + 4

	# Dynamic team card borders — highlight active/locked teams
	_update_team_card_style(1, %Team1Card, TEAM1_BG, TEAM1_COLOR, TEAM1_DIM, state)
	_update_team_card_style(2, %Team2Card, TEAM2_BG, TEAM2_COLOR, TEAM2_DIM, state)
	_update_team_card_style(3, %Team3Card, TEAM3_BG, TEAM3_COLOR, TEAM3_DIM, state)

	# ── Buzzer indicator ────────────────────────────────────────────
	_update_buzzer_indicator(state)


func _render_sidebar(state: GameState) -> void:
	# Team status labels with color coding
	_update_team_status(team1_status, state.team_lock_state(1))
	_update_team_status(team2_status, state.team_lock_state(2))
	_update_team_status(team3_status, state.team_lock_state(3))

	# Lock/force buttons
	var question_open: bool = not state.current_question.text.is_empty() and state.phase == Enums.GamePhase.QUESTION
	var has_live_authority: bool = question_open and state.answer_authority_team_id > 0

	team1_lock_btn.text = "Habilitar" if state.is_team_locked_out(1) else "Bloquear"
	team2_lock_btn.text = "Habilitar" if state.is_team_locked_out(2) else "Bloquear"
	team3_lock_btn.text = "Habilitar" if state.is_team_locked_out(3) else "Bloquear"
	team1_lock_btn.disabled = not question_open
	team2_lock_btn.disabled = not question_open
	team3_lock_btn.disabled = not question_open

	team1_force_btn.text = "Turno activo" if has_live_authority and state.answer_authority_team_id == 1 else "Dar turno"
	team2_force_btn.text = "Turno activo" if has_live_authority and state.answer_authority_team_id == 2 else "Dar turno"
	team3_force_btn.text = "Turno activo" if has_live_authority and state.answer_authority_team_id == 3 else "Dar turno"
	team1_force_btn.disabled = not question_open or state.is_team_locked_out(1)
	team2_force_btn.disabled = not question_open or state.is_team_locked_out(2)
	team3_force_btn.disabled = not question_open or state.is_team_locked_out(3)

	# Score buttons — always available
	team1_sub_btn.disabled = false
	team1_add_btn.disabled = false
	team2_sub_btn.disabled = false
	team2_add_btn.disabled = false
	team3_sub_btn.disabled = false
	team3_add_btn.disabled = false


func _render_idle_panel(state: GameState) -> void:
	var has_questions: bool = ContentRepo.get_question_count() > 0
	var has_round_questions: bool = _question_ids.size() > 0
	var has_minigames: bool = ContentRepo.get_minigame_count() > 0
	var has_selected_mg: bool = _mg_ids.size() > 0

	var q_count: int = ContentRepo.get_question_count()
	var rounds: PackedStringArray = ContentRepo.get_rounds()
	var mg_count: int = ContentRepo.get_minigame_count()
	var parts: PackedStringArray = []
	parts.append("%d preguntas" % q_count)
	parts.append("%d rondas" % rounds.size())
	parts.append("%d minijuegos" % mg_count)
	progress_label.text = " · ".join(parts)

	next_question_btn.disabled = not has_round_questions
	mg_quick_btn.disabled = not has_minigames

	round_selector.disabled = not has_questions
	reset_used_btn.disabled = not has_questions
	mg_launch_btn.disabled = not has_selected_mg
	mg_category_row.visible = has_minigames
	mg_row.visible = has_minigames
	mg_launch_btn.visible = has_minigames


func _render_question_panel(state: GameState) -> void:
	if state.current_question.text.is_empty():
		question_text.text = "Esperando pregunta..."
		opt_a.text = ""
		opt_b.text = ""
		opt_c.text = ""
		opt_d.text = ""
		lock_info.text = ""
		q_reveal_btn.disabled = true
		if skip_btn != null:
			skip_btn.disabled = true
		return

	question_text.text = state.current_question.text
	var options: PackedStringArray = state.current_question.options
	opt_a.text = "A) %s" % (options[0] if options.size() > 0 else "--")
	opt_b.text = "B) %s" % (options[1] if options.size() > 1 else "--")
	opt_c.text = "C) %s" % (options[2] if options.size() > 2 else "--")
	opt_d.text = "D) %s" % (options[3] if options.size() > 3 else "--")

	# Lock info
	if state.buzzer_winner_team_id > 0 and state.locked_team_id == 0 and state.answer_authority_team_id == state.buzzer_winner_team_id:
		lock_info.text = "⚡ %s pulsó primero — Esperando respuesta..." % ShowConfig.get_team_name(state.buzzer_winner_team_id)
	elif state.locked_team_id > 0:
		lock_info.text = "%s eligió %s · %s" % [
			ShowConfig.get_team_name(state.locked_team_id),
			state.last_selected_option if not state.last_selected_option.is_empty() else "--",
			Enums.answer_feedback_name(state.answer_feedback_status),
		]
	elif state.answers_enabled and state.answer_authority_team_id > 0:
		lock_info.text = "Turno reservado · %s" % ShowConfig.get_team_name(state.answer_authority_team_id)
	elif state.answers_enabled:
		lock_info.text = "Pregunta abierta · Esperando pulsador..."
	else:
		lock_info.text = ""

	# Reveal button (unified — same guard as locked panel)
	var needs_correction: bool = state.phase == Enums.GamePhase.LOCKED \
		and state.locked_team_id > 0 \
		and not state.correction_applied
	q_reveal_btn.disabled = state.current_question.text.is_empty() \
		or state.phase not in [Enums.GamePhase.QUESTION, Enums.GamePhase.LOCKED] \
		or needs_correction

	# Skip button
	if skip_btn != null:
		skip_btn.disabled = state.phase != Enums.GamePhase.QUESTION or state.current_question.text.is_empty()


func _render_locked_panel(state: GameState) -> void:
	locked_q_text.text = state.current_question.text if not state.current_question.text.is_empty() else ""

	# Who answered and result (auto-judged)
	if state.locked_team_id > 0:
		var team_name: String = ShowConfig.get_team_name(state.locked_team_id)
		var option: String = state.last_selected_option if not state.last_selected_option.is_empty() else "una opción"
		match state.answer_feedback_status:
			Enums.AnswerFeedbackStatus.CORRECT:
				answered_label.text = "✅ %s respondió %s — CORRECTA" % [team_name, option]
			Enums.AnswerFeedbackStatus.INCORRECT:
				answered_label.text = "❌ %s respondió %s — INCORRECTA" % [team_name, option]
			_:
				answered_label.text = "%s eligió %s" % [team_name, option]
	else:
		answered_label.text = "Sin respuesta tomada"

	# Correction buttons — now manual override only
	var can_override: bool = state.phase == Enums.GamePhase.LOCKED and state.locked_team_id > 0
	correct_btn.text = "🔧 Corregir: Correcta"
	incorrect_btn.text = "🔧 Corregir: Incorrecta"
	correct_btn.visible = can_override
	incorrect_btn.visible = can_override

	# Rebote button — appears when answer was incorrect and teams remain
	var rebote_available: bool = state.phase == Enums.GamePhase.LOCKED \
		and state.answer_feedback_status == Enums.AnswerFeedbackStatus.INCORRECT \
		and GameService.teams_available_for_rebote() > 0
	reopen_btn.text = "🔄 Rebote" if rebote_available else "Reabrir ronda"
	reopen_btn.disabled = state.current_question.text.is_empty() or state.phase not in [Enums.GamePhase.LOCKED, Enums.GamePhase.REVEAL]

	var needs_correction: bool = state.phase == Enums.GamePhase.LOCKED \
		and state.locked_team_id > 0 \
		and not state.correction_applied
	locked_reveal_btn.disabled = state.current_question.text.is_empty() or needs_correction


func _render_reveal_panel(state: GameState) -> void:
	# Correct answer with full text
	if state.revealed_correct_option.is_empty():
		reveal_answer.text = "--"
	else:
		var letter: String = state.revealed_correct_option.to_upper()
		var options: PackedStringArray = state.current_question.options
		var idx: int = letter.unicode_at(0) - 65  # A=0, B=1, etc.
		if idx >= 0 and idx < options.size():
			reveal_answer.text = "%s) %s" % [letter, options[idx]]
		else:
			reveal_answer.text = letter

	# Result for the team that answered
	if state.locked_team_id > 0:
		match state.answer_feedback_status:
			Enums.AnswerFeedbackStatus.CORRECT:
				result_label.text = "%s — CORRECTA" % ShowConfig.get_team_name(state.locked_team_id)
			Enums.AnswerFeedbackStatus.INCORRECT:
				result_label.text = "%s — INCORRECTA" % ShowConfig.get_team_name(state.locked_team_id)
			_:
				result_label.text = "%s — Pendiente" % ShowConfig.get_team_name(state.locked_team_id)
	else:
		result_label.text = "Sin respuesta"

	# Trivia / dato curioso — show on reveal for presenter to read aloud
	var question: Question = ContentRepo.get_question_by_id(state.current_question.id)
	if question != null and not question.trivia.is_empty():
		result_label.text += "\n\n💡 %s" % question.trivia
		result_label.add_theme_color_override("font_color", TEXT_DIM)
	else:
		if result_label.get_theme_color("font_color") == TEXT_DIM:
			result_label.add_theme_color_override("font_color", TEXT_BRIGHT)

	# Reveal minigame button
	reveal_mg_btn.disabled = ContentRepo.get_minigame_count() == 0


func _render_bottom_bar(state: GameState) -> void:
	refresh_btn.disabled = false
	reset_locks_btn.disabled = state.current_question.text.is_empty() or state.phase not in [Enums.GamePhase.QUESTION, Enums.GamePhase.LOCKED, Enums.GamePhase.REVEAL]


# ═══════════════════════════════════════════════════════════════════
#  Selector sync (round/question pickers)
# ═══════════════════════════════════════════════════════════════════

func _on_questions_loaded(_count: int) -> void:
	_sync_selector_controls()


func _on_selector_changed(_round_name: String, _question_id: int) -> void:
	_sync_selector_controls()


func _on_used_questions_changed() -> void:
	_sync_selector_controls()


func _on_round_selected(index: int) -> void:
	if _selector_syncing or index < 0 or index >= _round_values.size():
		return
	_showing_mg_preview = false
	GameService.set_presenter_round(_round_values[index])


func _on_round_auto_advanced(round_name: String) -> void:
	_sync_selector_controls()


func _sync_selector_controls() -> void:
	_selector_syncing = true
	_round_values.clear()
	_question_ids.clear()
	round_selector.clear()

	var rounds: PackedStringArray = ContentRepo.get_rounds()
	for round_name in rounds:
		_round_values.append(round_name)
		round_selector.add_item(round_name)

	var selected_round: String = GameService.get_selected_round_name()
	var selected_round_index: int = _find_round_index(selected_round)
	if selected_round_index >= 0:
		round_selector.select(selected_round_index)

	_selector_syncing = false
	_render_preview()
	_render_idle_panel(AppState.current_state)


func _render_preview() -> void:
	if _showing_mg_preview:
		_render_minigame_preview()
		return
	var selected_question: Question = GameService.get_selected_question()
	if selected_question.text.is_empty():
		preview_label.text = "Elegí una ronda y pregunta para ver la vista previa."
		return
	preview_label.text = selected_question.text.strip_edges()


func _find_round_index(round_name: String) -> int:
	for index: int in range(_round_values.size()):
		if _round_values[index] == round_name:
			return index
	return -1


# ═══════════════════════════════════════════════════════════════════
#  Dynamic team styling helpers
# ═══════════════════════════════════════════════════════════════════

func _update_team_card_style(team_id: int, card: PanelContainer, dim_bg: Color, bright: Color, dim_border: Color, state: GameState) -> void:
	var border_color: Color = dim_border
	var bg: Color = dim_bg
	var glow_intensity: float = 0.0
	if state.locked_team_id == team_id:
		border_color = bright
		bg = Color(bright.r * 0.25, bright.g * 0.25, bright.b * 0.25, 1.0)
		glow_intensity = 0.5
	elif state.phase == Enums.GamePhase.QUESTION and state.answers_enabled and state.answer_authority_team_id == team_id:
		border_color = bright
		bg = Color(bright.r * 0.18, bright.g * 0.18, bright.b * 0.18, 1.0)
		glow_intensity = 0.35
	elif state.is_team_locked_out(team_id):
		border_color = Color(bright.r * 0.4, bright.g * 0.4, bright.b * 0.4, 1.0)
	var style: StyleBoxFlat = card.get_theme_stylebox("panel")
	if style:
		style.border_color = border_color
		style.bg_color = bg
		if glow_intensity > 0:
			style.shadow_color = Color(bright.r, bright.g, bright.b, glow_intensity)
			style.shadow_size = 6
		else:
			style.shadow_size = 0


func _update_team_status(label: Label, lock_state: int) -> void:
	match lock_state:
		Enums.TeamLockState.READY:
			label.text = "LISTO"
			label.add_theme_color_override("font_color", TEXT_DIM)
		Enums.TeamLockState.LOCKED_OUT:
			label.text = "BLOQUEADO"
			label.add_theme_color_override("font_color", PHASE_INCORRECT_COLOR)
		Enums.TeamLockState.ACTIVE:
			label.text = "TURNO"
			label.add_theme_color_override("font_color", PHASE_REVEAL_COLOR)
		Enums.TeamLockState.FROZEN:
			label.text = "EN PAUSA"
			label.add_theme_color_override("font_color", PHASE_LOCKED_COLOR)


# ═══════════════════════════════════════════════════════════════════
#  Tween animations (tablet 10" — professional, not flashy)
# ═══════════════════════════════════════════════════════════════════

## Panel fade-in when phase changes
func _animate_panel_in(state: GameState) -> void:
	var target_panel: VBoxContainer
	match state.phase:
		Enums.GamePhase.IDLE:
			target_panel = idle_panel
		Enums.GamePhase.QUESTION:
			target_panel = question_panel
		Enums.GamePhase.LOCKED:
			target_panel = locked_panel
		Enums.GamePhase.REVEAL:
			target_panel = reveal_panel
		Enums.GamePhase.MINIGAME:
			target_panel = minigame_panel
		_:
			return
	if not target_panel:
		return
	target_panel.modulate.a = 0.0
	target_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(target_panel, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Score value pulse when changed
func _animate_score_pulse(team_id: int) -> void:
	var score_label: Label
	match team_id:
		1: score_label = team1_score_value
		2: score_label = team2_score_value
		3: score_label = team3_score_value
		_: return
	score_label.scale = Vector2(1.3, 1.3)
	var tw := create_tween()
	tw.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# ═══════════════════════════════════════════════════════════════════
#  Minigame selector (unified in manual section)
# ═══════════════════════════════════════════════════════════════════

func _on_mg_category_selected(index: int) -> void:
	if _mg_selector_syncing or index < 0:
		return
	var categories: PackedStringArray = ContentRepo.get_minigame_categories()
	if index >= categories.size():
		return
	_sync_minigame_selector(categories[index])


func _on_mg_selected(index: int) -> void:
	if _mg_selector_syncing or index < 0 or index >= _mg_ids.size():
		return
	_showing_mg_preview = true
	GameService.set_presenter_minigame(_mg_ids[index])


func _on_mg_selector_changed(minigame_id: int) -> void:
	_render_minigame_preview()


func _on_minigames_loaded(_count: int) -> void:
	_sync_minigame_selector()


func _sync_minigame_selector(force_category: String = "") -> void:
	_mg_selector_syncing = true
	_mg_ids.clear()
	mg_category_selector.clear()
	mg_selector.clear()

	var categories: PackedStringArray = ContentRepo.get_minigame_categories()
	var selected_category: String = force_category
	if selected_category.is_empty():
		if mg_category_selector.get_selected_id() >= 0:
			var cat_idx: int = mg_category_selector.get_selected()
			if cat_idx >= 0 and cat_idx < categories.size():
				selected_category = categories[cat_idx]
	# Populate categories
	for cat in categories:
		mg_category_selector.add_item(cat)
	# Select category
	if not selected_category.is_empty():
		for idx: int in range(categories.size()):
			if categories[idx] == selected_category:
				mg_category_selector.select(idx)
				break
	else:
		if not categories.is_empty():
			mg_category_selector.select(0)
			selected_category = categories[0]

	# Populate minigames for selected category
	var filtered: Array[MiniGame]
	if not selected_category.is_empty():
		filtered = ContentRepo.get_minigames_for_category(selected_category)
	else:
		filtered = ContentRepo.minigames

	for mg in filtered:
		_mg_ids.append(mg.id)
		var summary: String = mg.nombre.strip_edges()
		if summary.length() > 60:
			summary = "%s…" % summary.substr(0, 60)
		var usage_prefix: String = "[Usado]" if GameService.is_minigame_used(mg.id) else "[Nuevo]"
		mg_selector.add_item("%s MG%d — %s" % [usage_prefix, mg.id, summary])

	# Select the current selected minigame if it's in the list
	var current_mg_id: int = GameService.get_selected_minigame_id()
	var found_idx: int = -1
	for idx: int in range(_mg_ids.size()):
		if _mg_ids[idx] == current_mg_id:
			found_idx = idx
			break
	if found_idx >= 0:
		mg_selector.select(found_idx)
	elif not _mg_ids.is_empty():
		mg_selector.select(0)
		GameService.set_presenter_minigame(_mg_ids[0])

	_mg_selector_syncing = false
	_render_minigame_preview()
	_render_idle_panel(AppState.current_state)


func _render_minigame_preview() -> void:
	var mg: MiniGame = GameService.get_selected_minigame()
	if mg.id <= 0:
		if _showing_mg_preview:
			preview_label.text = "Elegí un minijuego para ver la vista previa."
		return
	_showing_mg_preview = true
	var material_text: String = ""
	if not mg.material.is_empty():
		material_text = " · 📦 " + ", ".join(mg.material)
	preview_label.text = "🎮 %s\n⏱ %ds · 👥 %s · ⭐ %d\n%s%s" % [
		mg.nombre,
		mg.tiempo,
		mg.participantes if not mg.participantes.is_empty() else "N/D",
		mg.dificultad,
		mg.descripcion,
		material_text,
	]


func _render_minigame_panel(state: GameState) -> void:
	if not minigame_panel.visible:
		return
	if state.current_minigame.id <= 0:
		mg_active_title.text = ""
		mg_active_desc.text = ""
		mg_active_material.text = ""
		mg_active_rules.text = ""
		mg_active_meta.text = ""
		return

	var mg: MiniGame = state.current_minigame
	mg_active_title.text = "🎮 %s" % mg.nombre
	mg_active_title.add_theme_color_override("font_color", PHASE_MINIGAME_COLOR)
	mg_active_desc.text = mg.descripcion

	if not mg.material.is_empty():
		mg_active_material.text = "📦 Material: " + ", ".join(mg.material)
	else:
		mg_active_material.text = ""

	if not mg.reglas.is_empty():
		mg_active_rules.text = "📜 %s" % mg.reglas
	else:
		mg_active_rules.text = ""

	var meta_parts: PackedStringArray = []
	meta_parts.append("⏱ %ds" % mg.tiempo)
	if not mg.participantes.is_empty():
		meta_parts.append("👥 %s" % mg.participantes)
	meta_parts.append("⭐ Dificultad: %d" % mg.dificultad)
	mg_active_meta.text = "  ·  ".join(meta_parts)


## Settings panel toggle
func _on_settings_pressed() -> void:
	# Lazily instance settings panel on first use
	if not has_node("SettingsPanelInstance"):
		var settings_scene: PackedScene = load("res://scenes/settings/settings_panel.tscn")
		if settings_scene == null:
			push_error("Presenter: No se pudo cargar scenes/settings/settings_panel.tscn")
			return
		var instance: Control = settings_scene.instantiate()
		if instance == null:
			push_error("Presenter: No se pudo instanciar settings_panel")
			return
		instance.name = "SettingsPanelInstance"
		add_child(instance)
	var settings: Node = get_node_or_null("SettingsPanelInstance")
	if settings == null:
		push_error("Presenter: SettingsPanelInstance no encontrado")
		return
	if settings.has_method("show_settings"):
		settings.show_settings()
	else:
		push_error("Presenter: Settings panel no tiene show_settings()")


# ═══════════════════════════════════════════════════════════════════
#  Buzzer indicator
# ═══════════════════════════════════════════════════════════════════

func _create_buzzer_indicator() -> void:
	_buzzer_indicator = Label.new()
	_buzzer_indicator.name = "BuzzerIndicator"
	_buzzer_indicator.add_theme_font_size_override("font_size", 16)
	_buzzer_indicator.add_theme_color_override("font_color", PHASE_LOCKED_COLOR)
	_buzzer_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_buzzer_indicator.text = "MODO PULSADOR ACTIVO"
	_buzzer_indicator.visible = false

	var phase_card: PanelContainer = get_node_or_null("RootMargin/RootVBox/TopBar/PhaseCard")
	if phase_card != null:
		var phase_pad: MarginContainer = phase_card.get_node_or_null("PhasePad")
		if phase_pad != null:
			var phase_vbox := VBoxContainer.new()
			phase_vbox.name = "PhaseVBox"
			phase_vbox.add_theme_constant_override("separation", 4)

			var p_label: Label = phase_pad.get_node_or_null("PhaseLabel")
			if p_label != null:
				p_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				p_label.reparent(phase_vbox)

			phase_vbox.add_child(_buzzer_indicator)
			phase_pad.add_child(phase_vbox)
			phase_card.custom_minimum_size = Vector2(0, 100)
		else:
			phase_card.add_child(_buzzer_indicator)
	else:
		var top_bar: Node = get_node_or_null("RootMargin/RootVBox/TopBar")
		if top_bar != null:
			top_bar.add_child(_buzzer_indicator)


func _update_buzzer_indicator(state: GameState) -> void:
	if _buzzer_indicator == null:
		return
	if state.phase == Enums.GamePhase.QUESTION and state.answer_authority_team_id == 0:
		var is_rebote: bool = not state.rebote_excluded_team_ids.is_empty()
		_buzzer_indicator.visible = true
		_buzzer_indicator.text = "🔄 REBOTE — Esperando pulsador" if is_rebote else "Esperando pulsador..."
		_buzzer_indicator.add_theme_color_override("font_color", PHASE_LOCKED_COLOR if is_rebote else PHASE_QUESTION_COLOR)
	elif state.answers_enabled and state.buzzer_winner_team_id > 0 and state.phase == Enums.GamePhase.QUESTION and state.answer_authority_team_id == state.buzzer_winner_team_id:
		_buzzer_indicator.visible = true
		_buzzer_indicator.text = "⚡ %s pulsó primero" % ShowConfig.get_team_name(state.buzzer_winner_team_id)
		_buzzer_indicator.add_theme_color_override("font_color", PHASE_REVEAL_COLOR)
	elif state.answers_enabled and state.phase == Enums.GamePhase.QUESTION and state.answer_authority_team_id > 0:
		_buzzer_indicator.visible = true
		_buzzer_indicator.text = "Turno reservado · %s" % ShowConfig.get_team_name(state.answer_authority_team_id)
		_buzzer_indicator.add_theme_color_override("font_color", PHASE_REVEAL_COLOR)
	elif state.phase == Enums.GamePhase.LOCKED and state.answer_feedback_status == Enums.AnswerFeedbackStatus.INCORRECT:
		_buzzer_indicator.visible = true
		_buzzer_indicator.text = "❌ INCORRECTA · Rebote disponible"
		_buzzer_indicator.add_theme_color_override("font_color", PHASE_INCORRECT_COLOR)
	else:
		_buzzer_indicator.visible = false


# ═══════════════════════════════════════════════════════════════════
#  Image rendering (Presenter — max 200×150)
# ═══════════════════════════════════════════════════════════════════

func _create_question_images_container() -> void:
	if question_panel == null:
		return
	_question_images_container = VBoxContainer.new()
	_question_images_container.name = "QuestionImages"
	_question_images_container.add_theme_constant_override("separation", 4)
	# Insert at index 0 — above the question text label
	question_panel.add_child(_question_images_container)
	question_panel.move_child(_question_images_container, 0)


func _create_minigame_images_container() -> void:
	if minigame_panel == null:
		return
	_minigame_images_container = VBoxContainer.new()
	_minigame_images_container.name = "MgImages"
	_minigame_images_container.add_theme_constant_override("separation", 4)
	minigame_panel.add_child(_minigame_images_container)


func _render_question_images(state: GameState) -> void:
	if _question_images_container == null:
		return
	var images: PackedStringArray = state.current_question.images
	var should_hide: bool = images.is_empty() or state.phase == Enums.GamePhase.MINIGAME
	if not should_hide and images == _prev_question_images:
		return
	_prev_question_images = images
	for child: Node in _question_images_container.get_children():
		child.queue_free()
	if should_hide:
		_question_images_container.visible = false
		_prev_question_images = PackedStringArray()
		return
	_question_images_container.visible = true
	_build_presenter_image_nodes(images, _question_images_container, 200, 150)


func _render_minigame_images(state: GameState) -> void:
	if _minigame_images_container == null:
		return
	var should_hide: bool = state.phase != Enums.GamePhase.MINIGAME or state.current_minigame.id <= 0
	var images: PackedStringArray = state.current_minigame.images if not should_hide else PackedStringArray()
	if not should_hide and images.is_empty():
		should_hide = true
	if not should_hide and images == _prev_minigame_images:
		return
	_prev_minigame_images = images
	for child: Node in _minigame_images_container.get_children():
		child.queue_free()
	if should_hide:
		_minigame_images_container.visible = false
		_prev_minigame_images = PackedStringArray()
		return
	_minigame_images_container.visible = true
	_build_presenter_image_nodes(images, _minigame_images_container, 200, 150)


func _build_presenter_image_nodes(filenames: PackedStringArray, container: VBoxContainer, max_w: int, max_h: int) -> void:
	if filenames.size() == 1:
		var tex: Texture2D = ImageLoader.load_image(filenames[0])
		var rect: TextureRect = _make_image_rect(tex, max_w, max_h)
		container.add_child(rect)
	elif filenames.size() > 1:
		var grid: GridContainer = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 4)
		grid.add_theme_constant_override("v_separation", 4)
		container.add_child(grid)
		for fname: String in filenames:
			var tex: Texture2D = ImageLoader.load_image(fname)
			var rect: TextureRect = _make_image_rect(tex, max_w / 2, max_h / 2)
			grid.add_child(rect)


func _make_image_rect(tex: Texture2D, max_w: int, max_h: int) -> Control:
	if tex != null:
		var rect: TextureRect = TextureRect.new()
		rect.texture = tex
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.custom_minimum_size = Vector2(max_w, max_h)
		rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		return rect
	else:
		var panel := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.18, 0.18, 0.22, 1.0)
		style.border_color = Color(0.35, 0.35, 0.4, 1.0)
		style.set_border_width_all(2)
		panel.add_theme_stylebox_override("panel", style)
		panel.custom_minimum_size = Vector2(max_w, max_h)
		panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var label := Label.new()
		label.text = "?"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 36)
		label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5, 1.0))
		panel.add_child(label)
		return panel


func _make_console_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(bg.r * 0.2, bg.g * 0.2, bg.b * 0.2, 1.0)
	style.border_color = Color(border.r * 0.5, border.g * 0.5, border.b * 0.5, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.content_margin_left = 14
	style.content_margin_right = 14
	return style


func _create_skip_button() -> void:
	if question_panel == null:
		return
	skip_btn = Button.new()
	skip_btn.name = "SkipBtn"
	skip_btn.text = "⏭ Saltar pregunta"
	skip_btn.custom_minimum_size = Vector2(0, 48)
	skip_btn.set("theme_override_font_sizes/font_size", 18)
	_apply_console_button(skip_btn)
	_apply_accent_button(skip_btn, TEXT_DIM)
	var q_actions: Node = question_panel.get_node_or_null("QActions")
	if q_actions != null:
		q_actions.add_child(skip_btn)
