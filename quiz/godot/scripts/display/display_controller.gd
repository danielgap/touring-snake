extends Control

## ── HY300 mini-projector optimized palette ──────────────────────
## Target: HY300-class Android mini projector
##   • ~150 lumens, native 320x240/640x360, contrast ~500:1
##   • Godot renders at 720p → projector downscales ~3x
##   • Blacks → gray, subtle differences → invisible, thin borders → gone
##
## Strategy:
##   • BG lighter (projector can't show deep black anyway)
##   • Cards MUCH lighter than BG — need clear edge separation
##   • Borders 4-5px (survive 3x downscale as 1-2px)
##   • Glow alpha 0.75+ (perceived ~0.25 after washout)
##   • PURE white text, bright saturated accents
##   • Active states use BRIGHT solid backgrounds, not subtle tints
##
## Presenter & Contestant keep the subtler tablet palette.

const BG_CONSOLE := Color("#111827")         # medium-dark — projector turns this into gray anyway, lighter = cleaner
const CARD_BG := Color("#1e3050")            # clearly lighter than BG — visible card edges even after washout
const CARD_BG_DIM := Color("#182440")        # dimmer but still distinct from BG
const CARD_BORDER := Color("#3a5575")        # medium-bright border visible after downscale
const CORNER_RADIUS := 16                    # larger radius survives downscale better

const TEAM1_COLOR := Color("#93bbfd")        # very bright blue — survives washout as clear blue
const TEAM2_COLOR := Color("#fcd34d")        # very bright amber — survives as clear yellow
const TEAM3_COLOR := Color("#fca5a5")        # very bright red — survives as clear pink-red
const TEAM1_BG := Color("#1e3a6e")           # clearly blue-tinted — team identity visible
const TEAM2_BG := Color("#4a3814")           # clearly amber-tinted
const TEAM3_BG := Color("#4a2020")           # clearly red-tinted

const PHASE_IDLE_COLOR := Color("#7a8a9e")   # bright gray — readable on washed-out BG
const PHASE_QUESTION_COLOR := Color("#67d4f8") # very bright cyan — AL AIRE needs to pop
const PHASE_LOCKED_COLOR := Color("#fcd34d") # bright amber
const PHASE_REVEAL_COLOR := Color("#6ee7a0") # bright mint green — survives washout as clear green
const PHASE_CORRECT_COLOR := Color("#6ee7a0")
const PHASE_INCORRECT_COLOR := Color("#fca5a5")
const PHASE_MINIGAME_COLOR := Color("#fcd34d")

const TEXT_BRIGHT := Color("#ffffff")          # PURE white — non-negotiable on projector
const TEXT_DIM := Color("#c8d4e4")             # bright secondary — still clearly readable
const TEXT_MUTED := Color("#7a8ea6")           # dim but NOT invisible
const ACCENT_BLUE := Color("#67d4f8")          # very bright accent
const BORDER_THICK := 5                        # survives 3x downscale as 1-2px
const BORDER_NORMAL := 3                       # survives as 1px minimum
const GLOW_SIZE := 16                          # big glow — survives as ~5px halo
const GLOW_ALPHA := 0.75                       # strong — perceived as ~0.25 after washout

## ── Nodes ─────────────────────────────────────────────────────────
@onready var phase_label: Label = %PhaseLabel
@onready var t1_score: Label = %T1Score
@onready var t2_score: Label = %T2Score
@onready var t3_score: Label = %T3Score
@onready var question_text: Label = %QuestionText
@onready var opt_a: Label = %OptA
@onready var opt_b: Label = %OptB
@onready var opt_c: Label = %OptC
@onready var opt_d: Label = %OptD
@onready var opt_card_a: PanelContainer = %OptCardA
@onready var opt_card_b: PanelContainer = %OptCardB
@onready var opt_card_c: PanelContainer = %OptCardC
@onready var opt_card_d: PanelContainer = %OptCardD
@onready var team_locks_label: Label = %TeamLocksLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var lock_label: Label = %LockLabel
## Dynamic nodes
var _trivia_card: PanelContainer
var _trivia_label: Label
var _minigame_card: PanelContainer
var _minigame_title: Label
var _minigame_desc: Label
var _minigame_material: Label
var _minigame_rules: Label
var _minigame_meta: Label
var _question_images_container: VBoxContainer
var _minigame_images_container: VBoxContainer
## Idle scoreboard nodes
var _idle_scoreboard: VBoxContainer
var _idle_logo_rect: TextureRect
var _idle_show_name: Label
var _idle_team_cards: Array[PanelContainer] = []
var _idle_standby: Label
var _idle_pulse_tweens: Array[Tween] = []

## ── Animation state ──────────────────────────────────────────────
var _prev_phase: int = -1
var _prev_question_text: String = ""
var _prev_scores: Dictionary = {}
var _prev_question_images: PackedStringArray = PackedStringArray()
var _prev_minigame_images: PackedStringArray = PackedStringArray()
var _active_tweens: Array[Tween] = []


func _ready() -> void:
	_apply_styles()
	_wire_config_values()
	_update_team_visibility()
	AppState.game_state_changed.connect(_render_state)
	AppState.scores_changed.connect(_render_scores)
	ShowConfig.config_changed.connect(_on_config_changed)
	_render_state(AppState.current_state)
	_render_scores(AppState.current_state.scores)


# ═══════════════════════════════════════════════════════════════════
#  Config wiring (runtime overrides from ShowConfig)
# ═══════════════════════════════════════════════════════════════════

func _wire_config_values() -> void:
	%T1Name.text = ShowConfig.get_team_short(1)
	%T2Name.text = ShowConfig.get_team_short(2)
	%T3Name.text = ShowConfig.get_team_short(3)


func _on_config_changed() -> void:
	_wire_config_values()
	_update_team_visibility()


func _update_team_visibility() -> void:
	var count: int = ShowConfig.get_team_count()
	%ScoreCard2.visible = count >= 2
	%ScoreCard3.visible = count >= 3


# ═══════════════════════════════════════════════════════════════════
#  Visual styling (applied once at startup)
# ═══════════════════════════════════════════════════════════════════

func _apply_styles() -> void:
	$Background.color = BG_CONSOLE

	# Phase card — thick border, strong glow
	%PhaseCard.add_theme_stylebox_override("panel", _make_glow_card(CARD_BG, PHASE_IDLE_COLOR, BORDER_THICK, PHASE_IDLE_COLOR, GLOW_SIZE))
	phase_label.add_theme_color_override("font_color", PHASE_IDLE_COLOR)

	# Score cards — team-colored with STRONG glow (projector needs it)
	%ScoreCard1.add_theme_stylebox_override("panel", _make_glow_card(TEAM1_BG, TEAM1_COLOR, BORDER_THICK, TEAM1_COLOR, GLOW_SIZE))
	%ScoreCard2.add_theme_stylebox_override("panel", _make_glow_card(TEAM2_BG, TEAM2_COLOR, BORDER_THICK, TEAM2_COLOR, GLOW_SIZE))
	%ScoreCard3.add_theme_stylebox_override("panel", _make_glow_card(TEAM3_BG, TEAM3_COLOR, BORDER_THICK, TEAM3_COLOR, GLOW_SIZE))
	t1_score.add_theme_color_override("font_color", TEAM1_COLOR)
	t2_score.add_theme_color_override("font_color", TEAM2_COLOR)
	t3_score.add_theme_color_override("font_color", TEAM3_COLOR)
	%T1Name.add_theme_color_override("font_color", TEAM1_COLOR)
	%T2Name.add_theme_color_override("font_color", TEAM2_COLOR)
	%T3Name.add_theme_color_override("font_color", TEAM3_COLOR)

	# Question card — bright blue border, strong glow
	%QuestionCard.add_theme_stylebox_override("panel", _make_glow_card(Color("#0f1f35"), ACCENT_BLUE, BORDER_THICK, ACCENT_BLUE, 12))

	# Option cards — default dim state with visible border
	_style_option_card(opt_card_a, CARD_BG_DIM, CARD_BORDER, BORDER_NORMAL)
	_style_option_card(opt_card_b, CARD_BG_DIM, CARD_BORDER, BORDER_NORMAL)
	_style_option_card(opt_card_c, CARD_BG_DIM, CARD_BORDER, BORDER_NORMAL)
	_style_option_card(opt_card_d, CARD_BG_DIM, CARD_BORDER, BORDER_NORMAL)

	# Bottom bar — readable dim text
	team_locks_label.add_theme_color_override("font_color", TEXT_DIM)
	feedback_label.add_theme_color_override("font_color", TEXT_DIM)
	lock_label.add_theme_color_override("font_color", TEXT_DIM)

	# Trivia card — shown only on REVEAL phase
	_create_trivia_card()

	# Question images container — dynamic TextureRects above question text
	_create_question_images_container()

	# Minigame card — shown only on MINIGAME phase
	_create_minigame_card()

	# Idle scoreboard — shown only on IDLE phase
	_create_idle_scoreboard()


func _make_glow_card(bg: Color, border: Color, border_w: int, glow_color: Color = Color.TRANSPARENT, glow_size: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_w)
	style.set_corner_radius_all(CORNER_RADIUS)
	if glow_size > 0:
		style.shadow_color = Color(glow_color.r, glow_color.g, glow_color.b, GLOW_ALPHA)
		style.shadow_size = glow_size
		style.anti_aliasing_size = 1
	return style


func _style_option_card(card: PanelContainer, bg: Color, border: Color, border_w: int = BORDER_NORMAL, glow_color: Color = Color.TRANSPARENT, glow_size: int = 0) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_w)
	style.set_corner_radius_all(CORNER_RADIUS)
	if glow_size > 0:
		style.shadow_color = Color(glow_color.r, glow_color.g, glow_color.b, GLOW_ALPHA)
		style.shadow_size = glow_size
	card.add_theme_stylebox_override("panel", style)


func _create_trivia_card() -> void:
	var center_vbox: VBoxContainer = get_node_or_null("MarginContainer/RootVBox/CenterVBox")
	if center_vbox == null:
		push_warning("DisplayController: CenterVBox not found for trivia card")
		return
	_trivia_card = PanelContainer.new()
	_trivia_card.name = "TriviaCard"
	_trivia_card.visible = false
	# Insert after OptionsGrid in CenterVBox
	var options_grid: Node = center_vbox.get_node_or_null("OptionsGrid")
	if options_grid != null:
		var idx: int = options_grid.get_index()
		center_vbox.add_child(_trivia_card)
		center_vbox.move_child(_trivia_card, idx + 1)
	else:
		center_vbox.add_child(_trivia_card)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 16)
	_trivia_card.add_child(margin)

	_trivia_label = Label.new()
	_trivia_label.name = "TriviaText"
	_trivia_label.add_theme_font_size_override("font_size", 30)
	_trivia_label.add_theme_color_override("font_color", TEXT_DIM)
	_trivia_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_trivia_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_trivia_label.text = ""
	margin.add_child(_trivia_label)

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0f1f35")
	style.border_color = ACCENT_BLUE
	style.set_border_width_all(BORDER_THICK)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.shadow_color = Color(ACCENT_BLUE.r, ACCENT_BLUE.g, ACCENT_BLUE.b, 0.5)
	style.shadow_size = 10
	_trivia_card.add_theme_stylebox_override("panel", style)


func _render_trivia(state: GameState) -> void:
	if _trivia_card == null:
		return
	if state.phase != Enums.GamePhase.REVEAL or state.current_question.id <= 0:
		_trivia_card.visible = false
		return
	var question: Question = ContentRepo.get_question_by_id(state.current_question.id)
	if question.trivia.is_empty():
		_trivia_card.visible = false
		return
	_trivia_card.visible = true
	_trivia_label.text = "💡 %s" % question.trivia


func _create_question_images_container() -> void:
	var question_card: PanelContainer = get_node_or_null("MarginContainer/RootVBox/CenterVBox/QuestionCard")
	if question_card == null:
		push_warning("DisplayController: QuestionCard not found for images container")
		return
	# Find the inner MarginContainer → VBox
	var vbox: VBoxContainer = question_card.get_child(0) as VBoxContainer
	if vbox == null:
		return
	_question_images_container = VBoxContainer.new()
	_question_images_container.name = "QuestionImages"
	_question_images_container.add_theme_constant_override("separation", 8)
	# Insert at index 0 — above the question text
	vbox.add_child(_question_images_container)
	vbox.move_child(_question_images_container, 0)


func _render_question_images(state: GameState) -> void:
	if _question_images_container == null:
		return
	var images: PackedStringArray = state.current_question.images
	var should_hide: bool = images.is_empty() or state.phase == Enums.GamePhase.MINIGAME
	if not should_hide and images == _prev_question_images:
		return
	_prev_question_images = images
	# Clear previous images
	for child: Node in _question_images_container.get_children():
		child.queue_free()
	if should_hide:
		_question_images_container.visible = false
		_prev_question_images = PackedStringArray()
		return
	_question_images_container.visible = true
	_build_image_nodes(images, _question_images_container, 400, 300)


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
	_build_image_nodes(images, _minigame_images_container, 400, 300)


func _build_image_nodes(filenames: PackedStringArray, container: VBoxContainer, max_w: int, max_h: int) -> void:
	if filenames.size() == 1:
		var tex: Texture2D = ImageLoader.load_image(filenames[0])
		var rect: TextureRect = _make_image_rect(tex, max_w, max_h)
		container.add_child(rect)
	elif filenames.size() > 1:
		var grid: GridContainer = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
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
		# Placeholder — gray panel with "?" label
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
		label.add_theme_font_size_override("font_size", 48)
		label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5, 1.0))
		panel.add_child(label)
		return panel


func _create_minigame_card() -> void:
	var center_vbox: VBoxContainer = get_node_or_null("MarginContainer/RootVBox/CenterVBox")
	if center_vbox == null:
		push_warning("DisplayController: CenterVBox not found for minigame card")
		return
	_minigame_card = PanelContainer.new()
	_minigame_card.name = "MinigameCard"
	_minigame_card.visible = false
	center_vbox.add_child(_minigame_card)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 20)
	_minigame_card.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	_minigame_title = Label.new()
	_minigame_title.name = "MgTitle"
	_minigame_title.add_theme_font_size_override("font_size", 40)
	_minigame_title.add_theme_color_override("font_color", PHASE_MINIGAME_COLOR)
	_minigame_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_minigame_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_minigame_title.text = ""
	vbox.add_child(_minigame_title)

	_minigame_desc = Label.new()
	_minigame_desc.name = "MgDesc"
	_minigame_desc.add_theme_font_size_override("font_size", 28)
	_minigame_desc.add_theme_color_override("font_color", TEXT_BRIGHT)
	_minigame_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_minigame_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_minigame_desc.text = ""
	vbox.add_child(_minigame_desc)

	_minigame_material = Label.new()
	_minigame_material.name = "MgMaterial"
	_minigame_material.add_theme_font_size_override("font_size", 24)
	_minigame_material.add_theme_color_override("font_color", TEXT_DIM)
	_minigame_material.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_minigame_material.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_minigame_material.text = ""
	vbox.add_child(_minigame_material)

	_minigame_rules = Label.new()
	_minigame_rules.name = "MgRules"
	_minigame_rules.add_theme_font_size_override("font_size", 24)
	_minigame_rules.add_theme_color_override("font_color", TEXT_DIM)
	_minigame_rules.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_minigame_rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_minigame_rules.text = ""
	vbox.add_child(_minigame_rules)

	_minigame_meta = Label.new()
	_minigame_meta.name = "MgMeta"
	_minigame_meta.add_theme_font_size_override("font_size", 24)
	_minigame_meta.add_theme_color_override("font_color", PHASE_MINIGAME_COLOR)
	_minigame_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_minigame_meta.text = ""
	vbox.add_child(_minigame_meta)

	_minigame_images_container = VBoxContainer.new()
	_minigame_images_container.name = "MgImages"
	_minigame_images_container.add_theme_constant_override("separation", 8)
	vbox.add_child(_minigame_images_container)

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1a1500")
	style.border_color = PHASE_MINIGAME_COLOR
	style.set_border_width_all(BORDER_THICK)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.shadow_color = Color(PHASE_MINIGAME_COLOR.r, PHASE_MINIGAME_COLOR.g, PHASE_MINIGAME_COLOR.b, 0.6)
	style.shadow_size = 14
	_minigame_card.add_theme_stylebox_override("panel", style)


func _create_idle_scoreboard() -> void:
	var center_vbox: VBoxContainer = get_node_or_null("MarginContainer/RootVBox/CenterVBox")
	if center_vbox == null:
		push_warning("DisplayController: CenterVBox not found for idle scoreboard")
		return

	_idle_scoreboard = VBoxContainer.new()
	_idle_scoreboard.name = "IdleScoreboard"
	_idle_scoreboard.visible = false
	_idle_scoreboard.add_theme_constant_override("separation", 24)
	_idle_scoreboard.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_idle_scoreboard.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center_vbox.add_child(_idle_scoreboard)

	# Logo TextureRect (max 200×200)
	_idle_logo_rect = TextureRect.new()
	_idle_logo_rect.name = "LogoRect"
	_idle_logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_idle_logo_rect.custom_minimum_size = Vector2(200, 200)
	_idle_logo_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_idle_logo_rect.visible = false
	_idle_scoreboard.add_child(_idle_logo_rect)

	# Show name label
	_idle_show_name = Label.new()
	_idle_show_name.name = "ShowNameLabel"
	_idle_show_name.add_theme_font_size_override("font_size", 42)
	_idle_show_name.add_theme_color_override("font_color", TEXT_BRIGHT)
	_idle_show_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_idle_show_name.text = ""
	_idle_scoreboard.add_child(_idle_show_name)

	# Teams HBox
	var teams_hbox: HBoxContainer = HBoxContainer.new()
	teams_hbox.name = "TeamsHBox"
	teams_hbox.add_theme_constant_override("separation", 24)
	teams_hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_idle_scoreboard.add_child(teams_hbox)

	# Create 3 team cards (show/hide based on team_count)
	var team_colors: Array[Color] = [TEAM1_COLOR, TEAM2_COLOR, TEAM3_COLOR]
	var team_bgs: Array[Color] = [TEAM1_BG, TEAM2_BG, TEAM3_BG]
	for i in range(3):
		var team_id: int = i + 1
		var tc: Color = team_colors[i]
		var tbg: Color = team_bgs[i]

		var card: PanelContainer = PanelContainer.new()
		card.name = "TeamCard%d" % team_id

		var card_style: StyleBoxFlat = StyleBoxFlat.new()
		card_style.bg_color = Color(tc.r * 0.25, tc.g * 0.25, tc.b * 0.25, 1.0)
		card_style.border_color = tc
		card_style.set_border_width_all(BORDER_THICK)
		card_style.set_corner_radius_all(CORNER_RADIUS)
		card_style.shadow_color = Color(tc.r, tc.g, tc.b, 0.6)
		card_style.shadow_size = GLOW_SIZE
		card_style.content_margin_left = 32
		card_style.content_margin_right = 32
		card_style.content_margin_top = 16
		card_style.content_margin_bottom = 16
		card.add_theme_stylebox_override("panel", card_style)

		var card_vbox: VBoxContainer = VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", 8)
		card.add_child(card_vbox)

		var team_name_label: Label = Label.new()
		team_name_label.name = "TeamName"
		team_name_label.add_theme_font_size_override("font_size", 24)
		team_name_label.add_theme_color_override("font_color", tc)
		team_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		team_name_label.text = ""
		card_vbox.add_child(team_name_label)

		var score_label: Label = Label.new()
		score_label.name = "ScoreValue"
		score_label.add_theme_font_size_override("font_size", 56)
		score_label.add_theme_color_override("font_color", TEXT_BRIGHT)
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_label.text = "0"
		card_vbox.add_child(score_label)

		teams_hbox.add_child(card)
		_idle_team_cards.append(card)

	# Standby label
	_idle_standby = Label.new()
	_idle_standby.name = "StandbyLabel"
	_idle_standby.add_theme_font_size_override("font_size", 24)
	_idle_standby.add_theme_color_override("font_color", PHASE_IDLE_COLOR)
	_idle_standby.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_idle_standby.text = "STANDBY"
	_idle_standby.visible = false
	_idle_scoreboard.add_child(_idle_standby)


func _render_idle_scoreboard(state: GameState) -> void:
	if state.phase == Enums.GamePhase.IDLE and state.current_minigame.id <= 0:
		# Show scoreboard, hide other cards AND top bar scores
		_idle_scoreboard.visible = true
		%QuestionCard.visible = false
		%ScoreCard1.visible = false
		%ScoreCard2.visible = false
		%ScoreCard3.visible = false
		%PhaseCard.visible = false
		var options_grid: Node = get_node_or_null("MarginContainer/RootVBox/CenterVBox/OptionsGrid")
		if options_grid != null:
			options_grid.visible = false
		if _trivia_card != null:
			_trivia_card.visible = false
		if _minigame_card != null:
			_minigame_card.visible = false
		if _question_images_container != null:
			_question_images_container.visible = false
		if _minigame_images_container != null:
			_minigame_images_container.visible = false

		# Update logo
		var logo_path: String = ShowConfig.get_logo_path()
		if logo_path.is_empty():
			_idle_logo_rect.visible = false
		else:
			var tex: Texture2D = ImageLoader.load_image_absolute(logo_path)
			if tex != null:
				_idle_logo_rect.texture = tex
				_idle_logo_rect.visible = true
			else:
				_idle_logo_rect.visible = false

		# Update show name
		_idle_show_name.text = ShowConfig.get_show_name()

		# Update team cards
		var count: int = ShowConfig.get_team_count()
		for i in range(3):
			var team_id: int = i + 1
			var card: PanelContainer = _idle_team_cards[i]
			card.visible = team_id <= count
			if card.visible:
				var card_vbox: VBoxContainer = card.get_child(0) as VBoxContainer
				if card_vbox != null:
					var team_name_label: Label = card_vbox.get_node_or_null("TeamName")
					var score_label: Label = card_vbox.get_node_or_null("ScoreValue")
					if team_name_label != null:
						team_name_label.text = ShowConfig.get_team_name(team_id)
					if score_label != null:
						score_label.text = str(int(state.scores.get(team_id, 0)))

		_start_idle_pulse()
	else:
		_hide_idle_scoreboard()


func _hide_idle_scoreboard() -> void:
	if _idle_scoreboard == null:
		return
	if _idle_scoreboard.visible:
		_stop_idle_pulse()
		_idle_scoreboard.visible = false
		# Restore top bar visibility
		%ScoreCard1.visible = true
		_update_team_visibility()
		%PhaseCard.visible = true
		# Restore normal card visibility
		%QuestionCard.visible = true
		var options_grid: Node = get_node_or_null("MarginContainer/RootVBox/CenterVBox/OptionsGrid")
		if options_grid != null:
			options_grid.visible = true


func _start_idle_pulse() -> void:
	_stop_idle_pulse()
	var count: int = ShowConfig.get_team_count()
	for i in range(count):
		if i >= _idle_team_cards.size():
			break
		var card: PanelContainer = _idle_team_cards[i]
		var style: StyleBoxFlat = card.get_theme_stylebox("panel")
		if style == null:
			continue
		var tw: Tween = create_tween()
		tw.set_loops(0)
		tw.tween_method(_set_card_shadow_alpha.bind(card), 0.4, 0.9, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_method(_set_card_shadow_alpha.bind(card), 0.9, 0.4, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_idle_pulse_tweens.append(tw)


func _stop_idle_pulse() -> void:
	for tw: Tween in _idle_pulse_tweens:
		if tw.is_valid():
			tw.kill()
	_idle_pulse_tweens.clear()


func _set_card_shadow_alpha(card: PanelContainer, alpha: float) -> void:
	var style: StyleBoxFlat = card.get_theme_stylebox("panel")
	if style == null:
		return
	var c: Color = style.shadow_color
	style.shadow_color = Color(c.r, c.g, c.b, alpha)


func _render_minigame_card(state: GameState) -> void:
	if _minigame_card == null:
		return
	if state.phase != Enums.GamePhase.MINIGAME or state.current_minigame.id <= 0:
		_minigame_card.visible = false
		return
	_minigame_card.visible = true
	var mg: MiniGame = state.current_minigame
	_minigame_title.text = "🎮 %s" % mg.nombre
	_minigame_desc.text = mg.descripcion

	if not mg.material.is_empty():
		var bullets: String = ""
		for item in mg.material:
			bullets += "• %s  " % str(item)
		_minigame_material.text = "📦 %s" % bullets
	else:
		_minigame_material.text = ""

	if not mg.reglas.is_empty():
		_minigame_rules.text = "📜 %s" % mg.reglas
	else:
		_minigame_rules.text = ""

	var meta_parts: PackedStringArray = []
	meta_parts.append("⏱ %ds" % mg.tiempo)
	if not mg.participantes.is_empty():
		meta_parts.append("👥 %s" % mg.participantes)
	meta_parts.append("⭐ Dificultad: %d" % mg.dificultad)
	_minigame_meta.text = "  ·  ".join(meta_parts)


# ═══════════════════════════════════════════════════════════════════
#  Main render pipeline
# ═══════════════════════════════════════════════════════════════════

func _render_state(state: GameState) -> void:
	var phase_changed: bool = _prev_phase != state.phase
	var question_changed: bool = _prev_question_text != state.current_question.text

	_render_phase(state)
	_render_question(state, question_changed)
	_render_options(state, phase_changed)
	_render_score_cards(state)
	_render_team_locks(state)
	_render_feedback(state)
	_render_lock_info(state)
	_render_trivia(state)
	_render_minigame_card(state)
	_render_question_images(state)
	_render_minigame_images(state)
	_render_idle_scoreboard(state)

	if phase_changed and _prev_phase >= 0:
		_animate_phase_transition(state)
	_prev_phase = state.phase
	_prev_question_text = state.current_question.text


func _render_scores(scores: Dictionary) -> void:
	var changed_teams: Array[int] = []
	var count: int = ShowConfig.get_team_count()
	for team_id in range(1, count + 1):
		if int(scores.get(team_id, 0)) != int(_prev_scores.get(team_id, 0)):
			changed_teams.append(team_id)
	t1_score.text = str(int(scores.get(1, 0)))
	t2_score.text = str(int(scores.get(2, 0)))
	t3_score.text = str(int(scores.get(3, 0)))
	for team_id in changed_teams:
		_animate_score_pulse(team_id)
	_prev_scores = scores.duplicate()


# ═══════════════════════════════════════════════════════════════════
#  Section renderers
# ═══════════════════════════════════════════════════════════════════

func _render_phase(state: GameState) -> void:
	var phase_color: Color = PHASE_IDLE_COLOR
	match state.phase:
		Enums.GamePhase.IDLE:
			phase_label.text = "STANDBY"
			phase_color = PHASE_IDLE_COLOR
		Enums.GamePhase.QUESTION:
			if state.answers_enabled:
				phase_label.text = "AL AIRE"
				phase_color = PHASE_QUESTION_COLOR
			else:
				phase_label.text = "EN JUEGO"
				phase_color = PHASE_QUESTION_COLOR
		Enums.GamePhase.LOCKED:
			# LOCKED: never leak result to audience — show neutral text
			phase_label.text = "RESPUESTA TOMADA"
			phase_color = PHASE_LOCKED_COLOR
		Enums.GamePhase.REVEAL:
			phase_label.text = "REVELADA"
			phase_color = PHASE_REVEAL_COLOR
		Enums.GamePhase.MINIGAME:
			phase_label.text = "MINIJUEGO"
			phase_color = PHASE_MINIGAME_COLOR
		_:
			phase_label.text = "STANDBY"
			phase_color = PHASE_IDLE_COLOR

	# Dynamic phase card — bright border + massive glow for HY300
	phase_label.add_theme_color_override("font_color", phase_color)
	var phase_style: StyleBoxFlat = %PhaseCard.get_theme_stylebox("panel")
	if phase_style:
		phase_style.border_color = phase_color
		phase_style.bg_color = Color(phase_color.r * 0.25, phase_color.g * 0.25, phase_color.b * 0.25, 1.0)
		phase_style.shadow_color = Color(phase_color.r, phase_color.g, phase_color.b, 0.85)
		phase_style.shadow_size = GLOW_SIZE + 8


func _render_question(state: GameState, animate: bool = false) -> void:
	if state.phase == Enums.GamePhase.MINIGAME:
		question_text.text = ""
		question_text.add_theme_color_override("font_color", TEXT_MUTED)
		return
	if state.current_question.text.is_empty():
		question_text.text = "En instantes..."
		question_text.add_theme_color_override("font_color", TEXT_MUTED)
	else:
		question_text.text = state.current_question.text
		question_text.add_theme_color_override("font_color", TEXT_BRIGHT)
		if animate:
			_animate_question_in()


func _render_options(state: GameState, phase_changed: bool = false) -> void:
	# Hide options during MINIGAME phase
	if state.phase == Enums.GamePhase.MINIGAME:
		for label: Label in [opt_a, opt_b, opt_c, opt_d]:
			label.text = ""
		for card: PanelContainer in [opt_card_a, opt_card_b, opt_card_c, opt_card_d]:
			_style_option_card(card, CARD_BG_DIM, CARD_BORDER, BORDER_NORMAL)
		return

	var options: PackedStringArray = state.current_question.options
	var letters: Array[String] = ["A", "B", "C", "D"]
	var labels: Array[Label] = [opt_a, opt_b, opt_c, opt_d]
	var cards: Array[PanelContainer] = [opt_card_a, opt_card_b, opt_card_c, opt_card_d]

	# Fill option text
	for i in range(4):
		if i < options.size():
			labels[i].text = "%s) %s" % [letters[i], options[i]]
		else:
			labels[i].text = "%s) --" % letters[i]

	# Dynamic styling per option — projector needs BOLD differentiation
	var selected_letter: String = state.last_selected_option.to_upper() if not state.last_selected_option.is_empty() else ""
	var correct_letter: String = state.revealed_correct_option.to_upper() if not state.revealed_correct_option.is_empty() else ""

	for i in range(4):
		var letter := letters[i]
		var card := cards[i]
		var label := labels[i]

		if state.phase == Enums.GamePhase.REVEAL:
			_render_option_reveal(i, letter, card, label, selected_letter, correct_letter, state)
		elif state.phase == Enums.GamePhase.LOCKED and letter == selected_letter:
			# Selected option — VERY BRIGHT team-colored bg + thick border + massive glow
			# 0.4 multiplier so bg is bright enough to see on HY300
			var tc := _team_color(state.locked_team_id)
			_style_option_card(card, Color(tc.r * 0.4, tc.g * 0.4, tc.b * 0.4, 1.0), tc, BORDER_THICK, tc, 18)
			label.add_theme_color_override("font_color", TEXT_BRIGHT)
		elif state.phase == Enums.GamePhase.QUESTION and not state.current_question.text.is_empty():
			# Question active — bright blue border (0.8 multiplier for HY300 visibility)
			_style_option_card(card, CARD_BG, Color(ACCENT_BLUE.r * 0.8, ACCENT_BLUE.g * 0.8, ACCENT_BLUE.b * 0.8, 1.0), BORDER_THICK)
			label.add_theme_color_override("font_color", TEXT_BRIGHT)
		else:
			# Idle — dim but still readable on projector
			_style_option_card(card, CARD_BG_DIM, CARD_BORDER, BORDER_NORMAL)
			label.add_theme_color_override("font_color", TEXT_DIM)


func _render_option_reveal(i: int, letter: String, card: PanelContainer, label: Label, selected: String, correct: String, state: GameState) -> void:
	if letter == correct:
		# Correct answer — BRIGHT green bg + thick border + massive glow (HY300 needs it BIG)
		_style_option_card(card, Color("#0e4528"), PHASE_REVEAL_COLOR, BORDER_THICK, PHASE_REVEAL_COLOR, 20)
		label.add_theme_color_override("font_color", TEXT_BRIGHT)
	elif letter == selected and state.answer_feedback_status == Enums.AnswerFeedbackStatus.INCORRECT:
		# Wrong selection — BRIGHT red bg + thick border + massive glow
		_style_option_card(card, Color("#451414"), PHASE_INCORRECT_COLOR, BORDER_THICK, PHASE_INCORRECT_COLOR, 20)
		label.add_theme_color_override("font_color", TEXT_BRIGHT)
	else:
		# Not relevant — dim
		_style_option_card(card, CARD_BG_DIM, CARD_BORDER, BORDER_NORMAL)
		label.add_theme_color_override("font_color", TEXT_DIM)


func _render_score_cards(state: GameState) -> void:
	_update_score_card_style(1, %ScoreCard1, TEAM1_BG, TEAM1_COLOR, state)
	if %ScoreCard2.visible:
		_update_score_card_style(2, %ScoreCard2, TEAM2_BG, TEAM2_COLOR, state)
	if %ScoreCard3.visible:
		_update_score_card_style(3, %ScoreCard3, TEAM3_BG, TEAM3_COLOR, state)


func _render_team_locks(state: GameState) -> void:
	var parts: PackedStringArray = []
	var count: int = ShowConfig.get_team_count()
	for team_id in range(1, count + 1):
		var lock_state: int = state.team_lock_state(team_id)
		var status_text: String = "listo"
		match lock_state:
			Enums.TeamLockState.LOCKED_OUT:
				status_text = "BLOQUEADO"
			Enums.TeamLockState.ACTIVE:
				status_text = "EN TURNO"
			Enums.TeamLockState.FROZEN:
				status_text = "EN PAUSA"
		parts.append("%s: %s" % [ShowConfig.get_team_short(team_id), status_text])
	team_locks_label.text = "  ·  ".join(parts)


func _render_feedback(state: GameState) -> void:
	if state.locked_team_id <= 0:
		feedback_label.text = "Aguardando respuesta..."
		feedback_label.add_theme_color_override("font_color", TEXT_MUTED)
		return

	# LOCKED: never leak result to audience on projector
	if state.phase == Enums.GamePhase.LOCKED:
		feedback_label.text = "%s — RESPUESTA TOMADA" % ShowConfig.get_team_name(state.locked_team_id).to_upper()
		feedback_label.add_theme_color_override("font_color", PHASE_LOCKED_COLOR)
		return

	match state.answer_feedback_status:
		Enums.AnswerFeedbackStatus.CORRECT:
			feedback_label.text = "%s — CORRECTA" % ShowConfig.get_team_name(state.locked_team_id).to_upper()
			feedback_label.add_theme_color_override("font_color", PHASE_CORRECT_COLOR)
		Enums.AnswerFeedbackStatus.INCORRECT:
			feedback_label.text = "%s — INCORRECTA" % ShowConfig.get_team_name(state.locked_team_id).to_upper()
			feedback_label.add_theme_color_override("font_color", PHASE_INCORRECT_COLOR)
		Enums.AnswerFeedbackStatus.PENDING:
			feedback_label.text = "%s — Pendiente" % ShowConfig.get_team_name(state.locked_team_id)
			feedback_label.add_theme_color_override("font_color", PHASE_LOCKED_COLOR)
		_:
			feedback_label.text = "Esperando decisión..."
			feedback_label.add_theme_color_override("font_color", TEXT_DIM)


func _render_lock_info(state: GameState) -> void:
	if state.phase == Enums.GamePhase.REVEAL:
		lock_label.text = "Correcta: %s · Respondió: %s" % [
			state.revealed_correct_option if not state.revealed_correct_option.is_empty() else "--",
			_locked_team_text(state),
		]
		lock_label.add_theme_color_override("font_color", TEXT_DIM)
	elif state.locked_team_id > 0:
		lock_label.text = "%s eligió %s" % [
			ShowConfig.get_team_name(state.locked_team_id),
			state.last_selected_option if not state.last_selected_option.is_empty() else "--",
		]
		lock_label.add_theme_color_override("font_color", _team_color(state.locked_team_id))
	elif state.phase == Enums.GamePhase.QUESTION and state.answers_enabled and state.answer_authority_team_id > 0:
		lock_label.text = "Turno · %s" % ShowConfig.get_team_name(state.answer_authority_team_id)
		lock_label.add_theme_color_override("font_color", TEXT_DIM)
	elif state.answers_enabled:
		lock_label.text = "Pregunta abierta · Esperando respuesta..."
		lock_label.add_theme_color_override("font_color", TEXT_DIM)
	else:
		lock_label.text = ""
		lock_label.add_theme_color_override("font_color", TEXT_MUTED)


# ═══════════════════════════════════════════════════════════════════
#  Helpers
# ═══════════════════════════════════════════════════════════════════

func _team_color(team_id: int) -> Color:
	return ShowConfig.get_team_color(team_id)


func _locked_team_text(state: GameState) -> String:
	if state.locked_team_id <= 0:
		return "nadie"
	return "%s (%s)" % [
		ShowConfig.get_team_name(state.locked_team_id),
		state.last_selected_option if not state.last_selected_option.is_empty() else "sin opción",
	]


func _update_score_card_style(team_id: int, card: PanelContainer, dim_bg: Color, bright: Color, state: GameState) -> void:
	var border_color: Color = Color(bright.r * 0.7, bright.g * 0.7, bright.b * 0.7, 1.0)
	var bg: Color = dim_bg
	var glow_intensity: float = 0.0
	if state.locked_team_id == team_id:
		border_color = bright
		bg = Color(bright.r * 0.35, bright.g * 0.35, bright.b * 0.35, 1.0)
		glow_intensity = 0.8
	elif state.phase == Enums.GamePhase.QUESTION and state.answers_enabled and state.answer_authority_team_id == team_id:
		border_color = bright
		bg = Color(bright.r * 0.28, bright.g * 0.28, bright.b * 0.28, 1.0)
		glow_intensity = 0.6
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border_color
	style.set_border_width_all(BORDER_THICK)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	if glow_intensity > 0.0:
		style.shadow_color = Color(bright.r, bright.g, bright.b, glow_intensity)
		style.shadow_size = GLOW_SIZE
	card.add_theme_stylebox_override("panel", style)


# ═══════════════════════════════════════════════════════════════════
#  Tween animations (HY300-safe — large, bold, dramatic)
# ═══════════════════════════════════════════════════════════════════

func _kill_tweens() -> void:
	for tw: Tween in _active_tweens:
		if tw.is_valid():
			tw.kill()
	_active_tweens.clear()


func _make_tween() -> Tween:
	var tw := create_tween()
	_active_tweens.append(tw)
	return tw


## Question text — fade in + scale up when new question arrives
func _animate_question_in() -> void:
	%QuestionCard.modulate.a = 0.0
	%QuestionCard.scale = Vector2(0.95, 0.95)
	var tw := _make_tween()
	tw.set_parallel(true)
	tw.tween_property(%QuestionCard, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(%QuestionCard, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Option cards — staggered fade in when question phase starts
func _animate_phase_transition(state: GameState) -> void:
	match state.phase:
		Enums.GamePhase.QUESTION:
			_animate_options_stagger_in()
		Enums.GamePhase.LOCKED:
			_animate_option_selected(state)
		Enums.GamePhase.REVEAL:
			_animate_reveal(state)


func _animate_options_stagger_in() -> void:
	var cards: Array[PanelContainer] = [opt_card_a, opt_card_b, opt_card_c, opt_card_d]
	for i in range(4):
		cards[i].modulate.a = 0.0
		cards[i].scale = Vector2(0.9, 0.9)
	var tw := _make_tween()
	for i in range(4):
		tw.set_parallel(false)
		tw.tween_interval(0.08 * i)
		tw.set_parallel(true)
		tw.tween_property(cards[i], "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(cards[i], "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)


## Selected option — pulse + scale bump
func _animate_option_selected(state: GameState) -> void:
	var selected_letter: String = state.last_selected_option.to_upper()
	var cards_map: Dictionary = {"A": opt_card_a, "B": opt_card_b, "C": opt_card_c, "D": opt_card_d}
	var card: PanelContainer = cards_map.get(selected_letter)
	if not card:
		return
	# Pulse: scale up then back
	card.scale = Vector2(1.08, 1.08)
	var tw := _make_tween()
	tw.tween_property(card, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Reveal — correct option gets a dramatic pulse, wrong gets a shake
func _animate_reveal(state: GameState) -> void:
	var selected_letter: String = state.last_selected_option.to_upper()
	var correct_letter: String = state.revealed_correct_option.to_upper()
	var cards_map: Dictionary = {"A": opt_card_a, "B": opt_card_b, "C": opt_card_c, "D": opt_card_d}

	# Correct answer — big scale pulse
	var correct_card: PanelContainer = cards_map.get(correct_letter)
	if correct_card:
		correct_card.scale = Vector2(0.9, 0.9)
		var tw := _make_tween()
		tw.tween_property(correct_card, "scale", Vector2(1.06, 1.06), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(correct_card, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	# Wrong answer — horizontal shake
	if selected_letter != correct_letter:
		var wrong_card: PanelContainer = cards_map.get(selected_letter)
		if wrong_card:
			var tw2 := _make_tween()
			tw2.tween_property(wrong_card, "position:x", wrong_card.position.x + 8, 0.05)
			tw2.tween_property(wrong_card, "position:x", wrong_card.position.x - 8, 0.05)
			tw2.tween_property(wrong_card, "position:x", wrong_card.position.x + 4, 0.05)
			tw2.tween_property(wrong_card, "position:x", wrong_card.position.x, 0.05)

	# Phase card flash — brighten then settle
	%PhaseCard.modulate.a = 0.5
	var tw3 := _make_tween()
	tw3.tween_property(%PhaseCard, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Score pulse — scale up and back when score changes
func _animate_score_pulse(team_id: int) -> void:
	var score_label: Label
	match team_id:
		1: score_label = t1_score
		2: score_label = t2_score
		3: score_label = t3_score
		_: return
	score_label.scale = Vector2(1.4, 1.4)
	var tw := _make_tween()
	tw.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
