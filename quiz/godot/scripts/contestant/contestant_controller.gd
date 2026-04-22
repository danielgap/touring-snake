extends Control

## ── Broadcast palette (base colors — team colors from ShowConfig) ──
const BG_CONSOLE := Color("#060a12")
const CORNER_RADIUS := 12
const GLOW_SIZE := 6

const STATUS_READY := Color("#475569")
const STATUS_ACTIVE := Color("#22c55e")
const STATUS_LOCKED := Color("#ef4444")
const STATUS_WAITING := Color("#f59e0b")

const TEXT_BRIGHT := Color("#f1f5f9")
const TEXT_DIM := Color("#94a3b8")
const ACCENT_BLUE := Color("#0ea5e9")

## ── Nodes ─────────────────────────────────────────────────────────
@onready var team_badge: PanelContainer = %TeamBadge
@onready var team_name: Label = %TeamName
@onready var status_badge: PanelContainer = %StatusBadge
@onready var status_label: Label = %StatusLabel
@onready var question_label: Label = %QuestionLabel
@onready var answer_a: Button = %AnswerA
@onready var answer_b: Button = %AnswerB
@onready var answer_c: Button = %AnswerC
@onready var answer_d: Button = %AnswerD
@onready var feedback_card: PanelContainer = %FeedbackCard
@onready var feedback_label: Label = %FeedbackLabel

## ── Minigame dynamic nodes ────────────────────────────────────────
var _mg_card: PanelContainer
var _mg_title: Label
var _mg_desc: Label
var _mg_meta: Label

## ── Internal ──────────────────────────────────────────────────────
var _team_color: Color = Color("#3b82f6")
var _team_bg: Color = Color("#0f2850")
var _prev_phase: int = -1
var _prev_can_answer: bool = false
var _prev_question_text: String = ""
var _prev_question_images: PackedStringArray = PackedStringArray()
var _prev_minigame_images: PackedStringArray = PackedStringArray()
var _active_tweens: Array[Tween] = []
var _question_images_container: VBoxContainer
var _minigame_images_container: VBoxContainer

## ── Idle scoreboard ───────────────────────────────────────────────
var _idle_scoreboard: VBoxContainer
var _idle_logo_rect: TextureRect
var _idle_show_name: Label
var _idle_team_card: PanelContainer
var _idle_team_name_label: Label
var _idle_team_score_label: Label
var _idle_pulse_tweens: Array[Tween] = []

## ── Buzzer mode ────────────────────────────────────────────────────
var _buzzer_button: Button
var _buzzer_pulse_tweens: Array[Tween] = []
var _mqtt_status_label: Label


func _ready() -> void:
	_apply_base_styles()
	answer_a.pressed.connect(func() -> void: _on_answer_pressed("A"))
	answer_b.pressed.connect(func() -> void: _on_answer_pressed("B"))
	answer_c.pressed.connect(func() -> void: _on_answer_pressed("C"))
	answer_d.pressed.connect(func() -> void: _on_answer_pressed("D"))
	AppState.game_state_changed.connect(_render_state)
	AppState.team_id_changed.connect(_render_team)
	ShowConfig.config_changed.connect(_on_config_changed)
	MqttBus.connected.connect(_on_mqtt_status_changed.bind(true))
	MqttBus.disconnected.connect(_on_mqtt_status_changed.bind(false))
	MqttBus.connection_error.connect(_on_mqtt_error)
	_render_team(AppState.selected_team_id)
	_render_state(AppState.current_state)


# ═══════════════════════════════════════════════════════════════════
#  Styles
# ═══════════════════════════════════════════════════════════════════

func _apply_base_styles() -> void:
	$Background.color = BG_CONSOLE

	# Question card — blue glow
	%QuestionCard.add_theme_stylebox_override("panel", _make_glow_card(Color("#081525"), ACCENT_BLUE, 2, ACCENT_BLUE, 8))

	# Feedback card — default dim
	feedback_card.add_theme_stylebox_override("panel", _make_card(Color("#0f1623"), Color("#1e293b")))

	# Answer buttons — big console style
	for btn: Button in [answer_a, answer_b, answer_c, answer_d]:
		_apply_answer_button(btn, Color("#151d2e"), Color("#334155"))

	# Minigame card — dynamic
	_create_minigame_card()

	# Question images container — dynamic TextureRects above question text
	_create_question_images_container()

	# Idle scoreboard — dynamic
	_create_idle_scoreboard()

	# Buzzer button — dynamic
	_create_buzzer_button()

	# MQTT status indicator
	_create_mqtt_status()


func _create_mqtt_status() -> void:
	_mqtt_status_label = Label.new()
	_mqtt_status_label.name = "MqttStatus"
	_mqtt_status_label.add_theme_font_size_override("font_size", 14)
	_mqtt_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_mqtt_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_update_mqtt_status(false)
	var top_bar: Node = get_node_or_null("RootMargin/RootVBox/HeaderBar")
	if top_bar != null:
		top_bar.add_child(_mqtt_status_label)


func _update_mqtt_status(connected: bool) -> void:
	if _mqtt_status_label == null:
		return
	if connected:
		_mqtt_status_label.text = "MQTT ●"
		_mqtt_status_label.add_theme_color_override("font_color", STATUS_ACTIVE)
	else:
		_mqtt_status_label.text = "MQTT ○ %s" % _get_mqtt_diag()
		_mqtt_status_label.add_theme_color_override("font_color", STATUS_LOCKED)


func _get_mqtt_diag() -> String:
	var host: String = _get_mqtt_host_display()
	var diag: String = MqttBus.get_diag_info()
	return "%s | %s" % [host, diag]


func _get_mqtt_host_display() -> String:
	if ShowConfig:
		return ShowConfig.get_mqtt_host()
	return "?"


func _on_answer_pressed(option: String) -> void:
	var state: GameState = AppState.current_state
	var team_id: int = AppState.selected_team_id
	var can: bool = state.can_team_answer(team_id)
	var reason: String = ""
	if team_id <= 0:
		reason = "sin_equipo"
	elif state.phase != Enums.GamePhase.QUESTION:
		reason = "phase=%d" % state.phase
	elif not state.answers_enabled:
		reason = "answers_disabled"
	elif state.is_team_locked_out(team_id):
		reason = "locked_out"
	elif state.is_team_excluded_from_rebote(team_id):
		reason = "rebote_excluded"
	elif state.answer_authority_team_id > 0 and state.answer_authority_team_id != team_id:
		reason = "authority_team=%d" % state.answer_authority_team_id
	elif state.locked_team_id != 0:
		reason = "locked_team=%d" % state.locked_team_id
	elif not state.last_selected_option.is_empty():
		reason = "already_answered=%s" % state.last_selected_option
	elif state.answer_authority_team_id == 0:
		reason = "no_authority"
	if not can:
		feedback_label.text = "NO ENVIADO (%s) · T%d · MQTT %s" % [reason, team_id, "●" if MqttBus.is_broker_connected() else "○"]
		return
	feedback_label.text = "Enviando %s..." % option
	GameService.submit_answer(option)


func _on_mqtt_status_changed(connected: bool) -> void:
	_update_mqtt_status(connected)


func _on_mqtt_error(reason: String) -> void:
	if _mqtt_status_label == null:
		return
	_mqtt_status_label.text = "MQTT ✕ %s" % reason
	_mqtt_status_label.add_theme_color_override("font_color", STATUS_LOCKED)


func _apply_answer_button(btn: Button, bg: Color, border: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = border
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(CORNER_RADIUS)
	normal.content_margin_top = 16
	normal.content_margin_bottom = 16
	normal.content_margin_left = 20
	normal.content_margin_right = 20

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(border.r * 0.6, border.g * 0.6, border.b * 0.6, 1.0)
	hover.border_color = border
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(CORNER_RADIUS)
	hover.content_margin_top = 16
	hover.content_margin_bottom = 16
	hover.content_margin_left = 20
	hover.content_margin_right = 20
	hover.shadow_color = Color(border.r, border.g, border.b, 0.3)
	hover.shadow_size = 8

	var disabled := StyleBoxFlat.new()
	disabled.bg_color = Color("#0c1018")
	disabled.border_color = Color("#151d2e")
	disabled.set_border_width_all(1)
	disabled.set_corner_radius_all(CORNER_RADIUS)
	disabled.content_margin_top = 16
	disabled.content_margin_bottom = 16
	disabled.content_margin_left = 20
	disabled.content_margin_right = 20

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", TEXT_BRIGHT)
	btn.add_theme_color_override("font_hover_color", Color("#ffffff"))
	btn.add_theme_color_override("font_disabled_color", Color("#334155"))


func _apply_answer_highlight(btn: Button, border_color: Color, bg_color: Color) -> void:
	var glow := StyleBoxFlat.new()
	glow.bg_color = bg_color
	glow.border_color = border_color
	glow.set_border_width_all(3)
	glow.set_corner_radius_all(CORNER_RADIUS)
	glow.content_margin_top = 16
	glow.content_margin_bottom = 16
	glow.content_margin_left = 20
	glow.content_margin_right = 20
	glow.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.6)
	glow.shadow_size = 12

	var hover := glow.duplicate() as StyleBoxFlat
	hover.shadow_size = 16

	btn.add_theme_stylebox_override("normal", glow)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", glow)
	btn.add_theme_stylebox_override("disabled", glow)
	btn.add_theme_color_override("font_color", Color("#ffffff"))
	btn.add_theme_color_override("font_hover_color", Color("#ffffff"))
	btn.add_theme_color_override("font_disabled_color", Color("#ffffff"))


func _apply_answer_border_highlight(btn: Button, border_color: Color) -> void:
	# Subtle highlight: colored border only, no glow, dark fill — secondary visual weight
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0c1018")
	style.border_color = border_color
	style.set_border_width_all(3)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	style.content_margin_left = 20
	style.content_margin_right = 20

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("disabled", style)
	btn.add_theme_color_override("font_color", border_color)
	btn.add_theme_color_override("font_hover_color", border_color)
	btn.add_theme_color_override("font_disabled_color", border_color)


func _make_card(bg: Color, border: Color, border_w: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_w)
	style.set_corner_radius_all(CORNER_RADIUS)
	return style


func _make_glow_card(bg: Color, border: Color, border_w: int, glow_color: Color, glow_size: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_w)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.shadow_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.35)
	style.shadow_size = glow_size
	return style


# ═══════════════════════════════════════════════════════════════════
#  Render
# ═══════════════════════════════════════════════════════════════════

func _render_team(team_id: int) -> void:
	var tid: int = team_id if team_id > 0 else 1
	_team_color = ShowConfig.get_team_color(tid)
	_team_bg = Color(_team_color.r * 0.15, _team_color.g * 0.15, _team_color.b * 0.15, 1.0)

	if team_id > 0:
		team_name.text = ShowConfig.get_team_name(team_id).to_upper()
	else:
		team_name.text = "SIN EQUIPO"

	# Team badge — glow with team color
	team_badge.add_theme_stylebox_override("panel", _make_glow_card(_team_bg, _team_color, 3, _team_color, GLOW_SIZE))


func _on_config_changed() -> void:
	_render_team(AppState.selected_team_id)


func _render_state(state: GameState) -> void:
	var can_answer: bool = _can_answer(state)
	var team_id: int = AppState.selected_team_id
	var phase_changed: bool = _prev_phase != state.phase
	var can_answer_changed: bool = _prev_can_answer != can_answer
	var question_changed: bool = _prev_question_text != state.current_question.text

	# ── Status badge ───────────────────────────────────────────────
	var status_text: String = "ESPERANDO"
	var status_color: Color = STATUS_READY
	if team_id <= 0:
		status_text = "SIN EQUIPO"
		status_color = STATUS_READY
	elif state.phase == Enums.GamePhase.IDLE:
		status_text = "ESPERANDO"
		status_color = STATUS_READY
	elif state.phase == Enums.GamePhase.MINIGAME:
		status_text = "MINIJUEGO"
		status_color = STATUS_WAITING
	elif state.is_team_locked_out(team_id):
		status_text = "BLOQUEADO"
		status_color = STATUS_LOCKED
	elif state.phase == Enums.GamePhase.REVEAL:
		status_text = "REVELADA"
		status_color = ACCENT_BLUE
	elif can_answer:
		status_text = "TU TURNO"
		status_color = STATUS_ACTIVE
	elif state.phase == Enums.GamePhase.QUESTION and state.is_team_excluded_from_rebote(team_id):
		status_text = "FUERA DE REBOTE"
		status_color = STATUS_LOCKED
	elif state.phase == Enums.GamePhase.QUESTION:
		status_text = "EN JUEGO"
		status_color = STATUS_WAITING
	elif state.phase == Enums.GamePhase.LOCKED:
		if state.locked_team_id == team_id:
			# LOCKED: never leak result — always show neutral ENVIADA
			status_text = "ENVIADA"
			status_color = STATUS_WAITING
		else:
			status_text = "TOMADA"
			status_color = STATUS_WAITING

	status_label.text = status_text
	status_label.add_theme_color_override("font_color", status_color)
	var badge_style: StyleBoxFlat = _make_glow_card(
		Color(status_color.r * 0.15, status_color.g * 0.15, status_color.b * 0.15, 1.0),
		status_color, 2, status_color, 4
	)
	status_badge.add_theme_stylebox_override("panel", badge_style)

	# ── Question ───────────────────────────────────────────────────
	if state.phase == Enums.GamePhase.MINIGAME:
		question_label.text = ""
	else:
		question_label.text = state.current_question.text if not state.current_question.text.is_empty() else "Esperando pregunta del presentador..."
	if question_changed and not state.current_question.text.is_empty() and state.phase != Enums.GamePhase.MINIGAME:
		_animate_question_in()

	# ── Answer buttons ─────────────────────────────────────────────
	var should_show_answers: bool = _should_show_answers(state, team_id)
	answer_a.get_parent().visible = should_show_answers

	var options: PackedStringArray = state.current_question.options
	answer_a.text = _button_text("A", options, 0)
	answer_b.text = _button_text("B", options, 1)
	answer_c.text = _button_text("C", options, 2)
	answer_d.text = _button_text("D", options, 3)

	answer_a.disabled = not can_answer
	answer_b.disabled = not can_answer
	answer_c.disabled = not can_answer
	answer_d.disabled = not can_answer

	# Style answer buttons
	var is_reveal: bool = state.phase == Enums.GamePhase.REVEAL and not state.revealed_correct_option.is_empty() and not state.current_question.options.is_empty()
	var correct_letter: String = state.revealed_correct_option.to_upper()
	if correct_letter not in ["A", "B", "C", "D"]:
		is_reveal = false

	# During LOCKED: highlight own answer with neutral amber (no result leak)
	var is_locked_me: bool = state.phase == Enums.GamePhase.LOCKED and state.locked_team_id == team_id
	var my_answer: String = state.last_selected_option.to_upper() if is_locked_me else ""
	if my_answer not in ["A", "B", "C", "D"]:
		is_locked_me = false

	# During REVEAL with incorrect answer: show my wrong + correct
	var is_reveal_with_mine: bool = is_reveal \
		and state.locked_team_id == team_id \
		and not state.last_selected_option.is_empty() \
		and state.answer_feedback_status == Enums.AnswerFeedbackStatus.INCORRECT

	var buttons: Dictionary = {"A": answer_a, "B": answer_b, "C": answer_c, "D": answer_d}

	for letter: String in buttons:
		var btn: Button = buttons[letter]
		if (is_reveal or is_reveal_with_mine) and letter == correct_letter:
			# Correct answer — HERO: full green glow + fill
			_apply_answer_highlight(btn, STATUS_ACTIVE, Color(STATUS_ACTIVE.r * 0.2, STATUS_ACTIVE.g * 0.2, STATUS_ACTIVE.b * 0.2, 1.0))
		elif is_reveal_with_mine and letter == my_answer:
			# My wrong answer during reveal — subtle red border only
			_apply_answer_border_highlight(btn, STATUS_LOCKED)
		elif is_reveal:
			# Dim other answers
			_apply_answer_button(btn, Color("#0a0e16"), Color("#1a1f2e"))
		elif is_locked_me and letter == my_answer:
			# LOCKED: neutral amber highlight — never leak correct/incorrect
			_apply_answer_highlight(btn, STATUS_WAITING, Color(STATUS_WAITING.r * 0.2, STATUS_WAITING.g * 0.2, STATUS_WAITING.b * 0.2, 1.0))
		elif is_locked_me:
			# LOCKED + other answers — dim
			_apply_answer_button(btn, Color("#0a0e16"), Color("#1a1f2e"))
		elif can_answer:
			_apply_answer_button(btn, _team_bg, _team_color)
		else:
			_apply_answer_button(btn, Color("#151d2e"), Color("#334155"))

	# ── Feedback card ──────────────────────────────────────────────
	feedback_label.text = _feedback_text(state, can_answer)
	_update_feedback_style(state, can_answer)

	# ── Buzzer mode (gates A/B/C/D visibility) ───────────────────
	_render_buzzer(state)

	# ── Minigame card ─────────────────────────────────────────────
	_render_minigame_card(state)
	_render_minigame_images(state)
	_render_question_images(state)

	# ── Idle scoreboard ───────────────────────────────────────────
	_render_idle_scoreboard(state)

	# ── Minigame content visibility ────────────────────────────────
	if state.phase == Enums.GamePhase.MINIGAME and state.current_minigame.id > 0:
		%QuestionCard.visible = false
		feedback_card.visible = false
	elif state.phase != Enums.GamePhase.IDLE:
		%QuestionCard.visible = true
		feedback_card.visible = true

	# ── Animations on state transitions ────────────────────────────
	if can_answer_changed:
		if can_answer:
			_animate_buttons_enabled()
		else:
			_animate_buttons_disabled()
	if phase_changed:
		if state.phase == Enums.GamePhase.LOCKED and state.locked_team_id == team_id:
			_animate_answer_locked()
		elif state.phase == Enums.GamePhase.REVEAL:
			_animate_reveal_feedback(state)
	_prev_phase = state.phase
	_prev_can_answer = can_answer
	_prev_question_text = state.current_question.text


func _should_show_answers(state: GameState, team_id: int) -> bool:
	if state.phase == Enums.GamePhase.LOCKED or state.phase == Enums.GamePhase.REVEAL:
		return true
	if state.phase != Enums.GamePhase.QUESTION:
		return false
	return state.answer_authority_team_id == team_id and team_id > 0


func _update_feedback_style(state: GameState, can_answer: bool) -> void:
	var border_color: Color = Color("#1e293b")
	var bg: Color = Color("#0f1623")
	var text_color: Color = TEXT_DIM

	var team_id: int = AppState.selected_team_id

	if can_answer:
		border_color = STATUS_ACTIVE
		bg = Color(STATUS_ACTIVE.r * 0.12, STATUS_ACTIVE.g * 0.12, STATUS_ACTIVE.b * 0.12, 1.0)
		text_color = STATUS_ACTIVE
	elif state.is_team_locked_out(team_id):
		border_color = STATUS_LOCKED
		bg = Color(STATUS_LOCKED.r * 0.12, STATUS_LOCKED.g * 0.12, STATUS_LOCKED.b * 0.12, 1.0)
		text_color = STATUS_LOCKED
	elif state.phase == Enums.GamePhase.LOCKED and state.locked_team_id == team_id:
		# LOCKED: neutral amber — never leak result
		border_color = STATUS_WAITING
		bg = Color(STATUS_WAITING.r * 0.12, STATUS_WAITING.g * 0.12, STATUS_WAITING.b * 0.12, 1.0)
		text_color = STATUS_WAITING
	elif state.phase == Enums.GamePhase.REVEAL:
		border_color = ACCENT_BLUE
		bg = Color(ACCENT_BLUE.r * 0.12, ACCENT_BLUE.g * 0.12, ACCENT_BLUE.b * 0.12, 1.0)
		text_color = ACCENT_BLUE

	var style := _make_card(bg, border_color, 2)
	if text_color != TEXT_DIM:
		var glow_mult: float = 0.25
		style.shadow_color = Color(border_color.r, border_color.g, border_color.b, glow_mult)
		style.shadow_size = 4
	feedback_card.add_theme_stylebox_override("panel", style)
	feedback_label.add_theme_color_override("font_color", text_color)


# ═══════════════════════════════════════════════════════════════════
#  Helpers
# ═══════════════════════════════════════════════════════════════════

func _button_text(letter: String, options: PackedStringArray, index: int) -> String:
	if index >= options.size():
		return "%s) --" % letter
	return "%s) %s" % [letter, options[index]]


func _can_answer(state: GameState) -> bool:
	return state.can_team_answer(AppState.selected_team_id)


func _feedback_text(state: GameState, can_answer: bool) -> String:
	if AppState.selected_team_id <= 0:
		return "Elegí un equipo antes de responder."
	if state.phase == Enums.GamePhase.MINIGAME:
		return ""
	if state.is_team_locked_out(AppState.selected_team_id):
		return "Tablet bloqueada por el presentador."
	if state.phase == Enums.GamePhase.REVEAL:
		if state.locked_team_id == AppState.selected_team_id:
			return "Ronda cerrada · %s · Correcta: %s" % [
				_feedback_summary(state),
				state.revealed_correct_option if not state.revealed_correct_option.is_empty() else "--",
			]
		return "Correcta: %s · %s" % [
			state.revealed_correct_option if not state.revealed_correct_option.is_empty() else "--",
			_feedback_summary(state),
		]
	if state.locked_team_id == AppState.selected_team_id:
		# During LOCKED, hide result — suspense for the presenter reveal
		if state.phase == Enums.GamePhase.LOCKED:
			return "Respuesta enviada: %s · Esperando resultado..." % (
				state.last_selected_option if not state.last_selected_option.is_empty() else "seleccionada"
			)
		match state.answer_feedback_status:
			Enums.AnswerFeedbackStatus.CORRECT:
				return "✅ CORRECTA — Su respuesta %s fue aceptada." % (
					state.last_selected_option if not state.last_selected_option.is_empty() else "seleccionada"
				)
			Enums.AnswerFeedbackStatus.INCORRECT:
				return "❌ INCORRECTA — Su respuesta %s fue rechazada." % (
					state.last_selected_option if not state.last_selected_option.is_empty() else "seleccionada"
				)
			_:
				return "Respuesta enviada: %s · Esperando resultado..." % (
					state.last_selected_option if not state.last_selected_option.is_empty() else "seleccionada"
				)
	if state.locked_team_id > 0:
		# During LOCKED, hide result — presenter hasn't revealed yet
		if state.phase == Enums.GamePhase.LOCKED:
			return "Respondió %s · Esperando resultado..." % ShowConfig.get_team_name(state.locked_team_id)
		return "Respondió %s · %s" % [ShowConfig.get_team_name(state.locked_team_id), _feedback_summary(state)]
	if state.answer_authority_team_id > 0 and state.answer_authority_team_id != AppState.selected_team_id:
		return "Turno reservado para %s." % ShowConfig.get_team_name(state.answer_authority_team_id)
	if state.answer_authority_team_id == AppState.selected_team_id and can_answer:
		return "SU TURNO — Respondan ahora."
	if state.phase == Enums.GamePhase.QUESTION and state.answers_enabled and state.answer_authority_team_id == 0:
		if ShowConfig.get_buzzer_mode_enabled():
			return "PULSEN EL PULSADOR para tomar el turno."
		else:
			return "Esperando que el presentador asigne turno."
	if can_answer:
		return "RESPONDAN AHORA — La primera respuesta cierra la ronda."
	if state.current_question.text.is_empty():
		return "Esperando pregunta del presentador."
	return "Esperen habilitación del presentador."


func _feedback_summary(state: GameState) -> String:
	match state.answer_feedback_status:
		Enums.AnswerFeedbackStatus.CORRECT:
			return "Dada por correcta."
		Enums.AnswerFeedbackStatus.INCORRECT:
			return "Dada por incorrecta."
		Enums.AnswerFeedbackStatus.PENDING:
			return "Espera corrección."
		_:
			return "Esperando decisión."


# ═══════════════════════════════════════════════════════════════════
#  Minigame card
# ═══════════════════════════════════════════════════════════════════

func _create_minigame_card() -> void:
	var root_vbox: VBoxContainer = get_node_or_null("RootMargin/RootVBox")
	if root_vbox == null:
		push_warning("ContestantController: RootVBox not found for minigame card")
		return
	_mg_card = PanelContainer.new()
	_mg_card.name = "MinigameCard"
	_mg_card.visible = false
	root_vbox.add_child(_mg_card)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	_mg_card.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	_mg_title = Label.new()
	_mg_title.name = "MgTitle"
	_mg_title.add_theme_font_size_override("font_size", 32)
	_mg_title.add_theme_color_override("font_color", TEXT_BRIGHT)
	_mg_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mg_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_mg_title)

	_mg_desc = Label.new()
	_mg_desc.name = "MgDesc"
	_mg_desc.add_theme_font_size_override("font_size", 20)
	_mg_desc.add_theme_color_override("font_color", TEXT_DIM)
	_mg_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mg_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_mg_desc)

	_mg_meta = Label.new()
	_mg_meta.name = "MgMeta"
	_mg_meta.add_theme_font_size_override("font_size", 18)
	_mg_meta.add_theme_color_override("font_color", STATUS_WAITING)
	_mg_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_mg_meta)

	_minigame_images_container = VBoxContainer.new()
	_minigame_images_container.name = "MgImages"
	_minigame_images_container.add_theme_constant_override("separation", 6)
	vbox.add_child(_minigame_images_container)

	var style := StyleBoxFlat.new()
	style.bg_color = _team_bg
	style.border_color = _team_color
	style.set_border_width_all(3)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.shadow_color = Color(_team_color.r, _team_color.g, _team_color.b, 0.35)
	style.shadow_size = GLOW_SIZE
	_mg_card.add_theme_stylebox_override("panel", style)


func _render_minigame_card(state: GameState) -> void:
	if _mg_card == null:
		return
	if state.phase != Enums.GamePhase.MINIGAME or state.current_minigame.id <= 0:
		_mg_card.visible = false
		return
	_mg_card.visible = true
	var mg: MiniGame = state.current_minigame
	_mg_title.text = "🎮 %s" % mg.nombre
	_mg_desc.text = mg.descripcion
	_mg_meta.text = "⏱ %ds" % mg.tiempo

	# Re-style with current team colors
	var style := StyleBoxFlat.new()
	style.bg_color = _team_bg
	style.border_color = _team_color
	style.set_border_width_all(3)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.shadow_color = Color(_team_color.r, _team_color.g, _team_color.b, 0.35)
	style.shadow_size = GLOW_SIZE
	_mg_card.add_theme_stylebox_override("panel", style)
	_mg_title.add_theme_color_override("font_color", _team_color)


# ═══════════════════════════════════════════════════════════════════
#  Tween animations (tablet 10" — polished but not overpowering)
# ═══════════════════════════════════════════════════════════════════

func _make_tween() -> Tween:
	var tw := create_tween()
	return tw


## Question card — fade + scale in
func _animate_question_in() -> void:
	%QuestionCard.modulate.a = 0.0
	%QuestionCard.scale = Vector2(0.96, 0.96)
	var tw := _make_tween()
	tw.set_parallel(true)
	tw.tween_property(%QuestionCard, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(%QuestionCard, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Answer buttons — staggered scale-in when enabled
func _animate_buttons_enabled() -> void:
	var buttons: Array[Button] = [answer_a, answer_b, answer_c, answer_d]
	for btn: Button in buttons:
		btn.scale = Vector2(0.85, 0.85)
		btn.modulate.a = 0.3
	var tw := _make_tween()
	for i in range(4):
		tw.set_parallel(false)
		tw.tween_interval(0.05)
		tw.set_parallel(true)
		tw.tween_property(buttons[i], "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(buttons[i], "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)


## Answer buttons — quick fade when disabled
func _animate_buttons_disabled() -> void:
	var state: GameState = AppState.current_state
	var correct_letter: String = state.revealed_correct_option.to_upper() if state.phase == Enums.GamePhase.REVEAL else ""
	var buttons: Dictionary = {"A": answer_a, "B": answer_b, "C": answer_c, "D": answer_d}
	var tw := _make_tween()
	tw.set_parallel(true)
	for letter: String in buttons:
		if letter == correct_letter:
			continue  # Don't fade the correct answer during reveal
		tw.tween_property(buttons[letter], "modulate:a", 0.6, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.set_parallel(false)


## Status badge pulse when answer is locked
func _animate_answer_locked() -> void:
	%StatusBadge.scale = Vector2(1.15, 1.15)
	var tw := _make_tween()
	tw.tween_property(%StatusBadge, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Feedback card — dramatic reveal on correct/incorrect
func _animate_reveal_feedback(state: GameState) -> void:
	var team_id: int = AppState.selected_team_id
	var is_correct: bool = state.locked_team_id == team_id and state.answer_feedback_status == Enums.AnswerFeedbackStatus.CORRECT
	var is_incorrect: bool = state.locked_team_id == team_id and state.answer_feedback_status == Enums.AnswerFeedbackStatus.INCORRECT

	if is_correct or is_incorrect:
		# Dramatic scale bounce + flash
		feedback_card.modulate.a = 0.0
		feedback_card.scale = Vector2(0.8, 0.8)
		var flash_color: Color = STATUS_ACTIVE if is_correct else STATUS_LOCKED
		var tw := _make_tween()
		tw.set_parallel(true)
		tw.tween_property(feedback_card, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(feedback_card, "scale", Vector2(1.08, 1.08), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		# Then settle to 1.0
		var tw2 := _make_tween()
		tw2.tween_interval(0.35)
		tw2.set_parallel(false)
		tw2.tween_property(feedback_card, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

		# Flash the answer buttons too — but keep correct button at full alpha
		var correct_letter: String = state.revealed_correct_option.to_upper()
		var all_buttons: Dictionary = {"A": answer_a, "B": answer_b, "C": answer_c, "D": answer_d}
		var tw3 := _make_tween()
		tw3.set_parallel(true)
		for letter: String in all_buttons:
			var btn: Button = all_buttons[letter]
			if letter == correct_letter:
				btn.modulate.a = 1.0
			else:
				btn.modulate.a = 0.3
				tw3.tween_property(btn, "modulate:a", 0.6, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		# Standard reveal — gentler animation
		feedback_card.modulate.a = 0.0
		feedback_card.scale = Vector2(0.95, 0.95)
		var tw := _make_tween()
		tw.set_parallel(true)
		tw.tween_property(feedback_card, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(feedback_card, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# If this team answered, pulse team badge
	if state.locked_team_id == team_id:
		team_badge.scale = Vector2(1.15, 1.15)
		var tw2 := _make_tween()
		tw2.tween_property(team_badge, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# ═══════════════════════════════════════════════════════════════════
#  Image rendering (Contestant — max 250×200)
# ═══════════════════════════════════════════════════════════════════

func _create_question_images_container() -> void:
	var root_vbox: VBoxContainer = get_node_or_null("RootMargin/RootVBox")
	if root_vbox == null:
		push_warning("ContestantController: RootVBox not found for images container")
		return
	_question_images_container = VBoxContainer.new()
	_question_images_container.name = "QuestionImages"
	_question_images_container.add_theme_constant_override("separation", 6)
	root_vbox.add_child(_question_images_container)
	# Move it right before QuestionCard
	var question_card: Node = get_node_or_null("RootMargin/RootVBox/QuestionCard")
	if question_card != null:
		root_vbox.move_child(_question_images_container, question_card.get_index())


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
	_build_contestant_image_nodes(images, _question_images_container, 250, 200)


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
	_build_contestant_image_nodes(images, _minigame_images_container, 250, 200)


func _build_contestant_image_nodes(filenames: PackedStringArray, container: VBoxContainer, max_w: int, max_h: int) -> void:
	if filenames.size() == 1:
		var tex: Texture2D = ImageLoader.load_image(filenames[0])
		var rect: TextureRect = _make_image_rect(tex, max_w, max_h)
		container.add_child(rect)
	elif filenames.size() > 1:
		var grid: GridContainer = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
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
		label.add_theme_font_size_override("font_size", 36)
		label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5, 1.0))
		panel.add_child(label)
		return panel


func _create_placeholder_texture() -> ImageTexture:
	var img: Image = Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.2, 0.25, 1.0))
	return ImageTexture.create_from_image(img)


# ═══════════════════════════════════════════════════════════════════
#  Idle scoreboard
# ═══════════════════════════════════════════════════════════════════

func _create_idle_scoreboard() -> void:
	_idle_scoreboard = VBoxContainer.new()
	_idle_scoreboard.name = "IdleScoreboard"
	_idle_scoreboard.alignment = BoxContainer.ALIGNMENT_CENTER
	_idle_scoreboard.add_theme_constant_override("separation", 24)

	# Logo
	_idle_logo_rect = TextureRect.new()
	_idle_logo_rect.name = "IdleLogo"
	_idle_logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_idle_logo_rect.custom_minimum_size = Vector2(120, 120)
	_idle_logo_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_idle_logo_rect.visible = false
	_idle_scoreboard.add_child(_idle_logo_rect)

	# Show name
	_idle_show_name = Label.new()
	_idle_show_name.name = "IdleShowName"
	_idle_show_name.add_theme_font_size_override("font_size", 32)
	_idle_show_name.add_theme_color_override("font_color", TEXT_BRIGHT)
	_idle_show_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_idle_scoreboard.add_child(_idle_show_name)

	# Team card (single card — this contestant's team)
	_idle_team_card = PanelContainer.new()
	_idle_team_card.name = "IdleTeamCard"
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#0f1623")
	card_style.border_color = _team_color
	card_style.set_border_width_all(3)
	card_style.set_corner_radius_all(CORNER_RADIUS)
	card_style.shadow_color = Color(_team_color.r, _team_color.g, _team_color.b, 0.6)
	card_style.shadow_size = 12
	_idle_team_card.add_theme_stylebox_override("panel", card_style)

	var card_vbox := VBoxContainer.new()
	card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card_vbox.add_theme_constant_override("separation", 8)

	_idle_team_name_label = Label.new()
	_idle_team_name_label.name = "TeamName"
	_idle_team_name_label.add_theme_font_size_override("font_size", 22)
	_idle_team_name_label.add_theme_color_override("font_color", _team_color)
	_idle_team_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_vbox.add_child(_idle_team_name_label)

	_idle_team_score_label = Label.new()
	_idle_team_score_label.name = "ScoreValue"
	_idle_team_score_label.add_theme_font_size_override("font_size", 48)
	_idle_team_score_label.add_theme_color_override("font_color", TEXT_BRIGHT)
	_idle_team_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_vbox.add_child(_idle_team_score_label)

	_idle_team_card.add_child(card_vbox)
	_idle_scoreboard.add_child(_idle_team_card)

	# Add to scene after team_badge (top section)
	var root_vbox: VBoxContainer = get_node_or_null("RootMargin/RootVBox")
	if root_vbox != null:
		root_vbox.add_child(_idle_scoreboard)

	_idle_scoreboard.visible = false


func _render_idle_scoreboard(state: GameState) -> void:
	if state.phase == Enums.GamePhase.IDLE and state.current_minigame.id <= 0:
		_idle_scoreboard.visible = true

		# Hide other content
		%QuestionCard.visible = false
		answer_a.get_parent().visible = false  # AnswerButtons row
		feedback_card.visible = false
		if _mg_card != null:
			_mg_card.visible = false
		if _question_images_container != null:
			_question_images_container.visible = false
		if _minigame_images_container != null:
			_minigame_images_container.visible = false

		# Logo
		var logo_path: String = ShowConfig.get_logo_path()
		if not logo_path.is_empty():
			var tex: Texture2D = ImageLoader.load_image_absolute(logo_path)
			if tex != null:
				_idle_logo_rect.texture = tex
				_idle_logo_rect.visible = true
			else:
				_idle_logo_rect.visible = false
		else:
			_idle_logo_rect.visible = false

		# Show name
		_idle_show_name.text = ShowConfig.get_show_name()

		# Team card
		var tid: int = AppState.selected_team_id
		if tid > 0:
			var tc: Color = ShowConfig.get_team_color(tid)
			_idle_team_name_label.text = ShowConfig.get_team_name(tid).to_upper()
			_idle_team_name_label.add_theme_color_override("font_color", tc)
			_idle_team_score_label.text = str(int(state.scores.get(tid, 0)))
			var style: StyleBoxFlat = _idle_team_card.get_theme_stylebox("panel")
			if style != null:
				style.border_color = tc
				style.shadow_color = Color(tc.r, tc.g, tc.b, 0.6)
		_idle_team_card.visible = tid > 0

		_start_idle_pulse()
	else:
		_hide_idle_scoreboard()


func _hide_idle_scoreboard() -> void:
	if _idle_scoreboard == null:
		return
	if _idle_scoreboard.visible:
		_stop_idle_pulse()
		_idle_scoreboard.visible = false
		# Restore content managed directly by the current game state render.
		%QuestionCard.visible = true
		feedback_card.visible = true


func _start_idle_pulse() -> void:
	_stop_idle_pulse()
	if _idle_team_card == null or not _idle_team_card.visible:
		return
	var style: StyleBoxFlat = _idle_team_card.get_theme_stylebox("panel")
	if style == null:
		return
	var tw: Tween = create_tween()
	tw.set_loops(0)
	tw.tween_property(style, "shadow_color:a", 0.9, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(style, "shadow_color:a", 0.4, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_pulse_tweens.append(tw)


func _stop_idle_pulse() -> void:
	for tw: Tween in _idle_pulse_tweens:
		if tw.is_valid():
			tw.kill()
	_idle_pulse_tweens.clear()


# ═══════════════════════════════════════════════════════════════════
#  Buzzer mode
# ═══════════════════════════════════════════════════════════════════

func _create_buzzer_button() -> void:
	_buzzer_button = Button.new()
	_buzzer_button.name = "BuzzerButton"
	_buzzer_button.visible = false
	_buzzer_button.custom_minimum_size = Vector2(0, 210)
	_buzzer_button.add_theme_font_size_override("font_size", 42)
	_buzzer_button.text = "⚡ PULSAR"
	_buzzer_button.pressed.connect(func() -> void: GameService.submit_buzzer())

	# Add as sibling before the answer buttons parent container
	var answer_parent: Node = answer_a.get_parent()
	answer_parent.get_parent().add_child(_buzzer_button)
	answer_parent.get_parent().move_child(_buzzer_button, answer_parent.get_index())

	_apply_buzzer_styles_active()


func _apply_buzzer_styles_active() -> void:
	if _buzzer_button == null:
		return
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(_team_color.r * 0.28, _team_color.g * 0.28, _team_color.b * 0.28, 1.0)
	normal.border_color = _team_color
	normal.set_border_width_all(4)
	normal.set_corner_radius_all(CORNER_RADIUS)
	normal.shadow_color = Color(_team_color.r, _team_color.g, _team_color.b, 0.7)
	normal.shadow_size = 20
	normal.content_margin_top = 24
	normal.content_margin_bottom = 24
	normal.content_margin_left = 28
	normal.content_margin_right = 28

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(_team_color.r * 0.38, _team_color.g * 0.38, _team_color.b * 0.38, 1.0)
	hover.border_color = _team_color
	hover.shadow_size = 26

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(_team_color.r * 0.18, _team_color.g * 0.18, _team_color.b * 0.18, 1.0)
	pressed.shadow_size = 10

	var disabled := StyleBoxFlat.new()
	disabled.bg_color = Color("#0c1018")
	disabled.border_color = Color("#151d2e")
	disabled.set_border_width_all(2)
	disabled.set_corner_radius_all(CORNER_RADIUS)
	disabled.content_margin_top = 24
	disabled.content_margin_bottom = 24
	disabled.content_margin_left = 28
	disabled.content_margin_right = 28

	_buzzer_button.add_theme_stylebox_override("normal", normal)
	_buzzer_button.add_theme_stylebox_override("hover", hover)
	_buzzer_button.add_theme_stylebox_override("pressed", pressed)
	_buzzer_button.add_theme_stylebox_override("disabled", disabled)
	_buzzer_button.add_theme_color_override("font_color", TEXT_BRIGHT)
	_buzzer_button.add_theme_color_override("font_hover_color", Color("#ffffff"))
	_buzzer_button.add_theme_color_override("font_disabled_color", Color("#334155"))
	_buzzer_button.add_theme_constant_override("outline_size", 2)
	_buzzer_button.add_theme_color_override("outline_color", Color(0, 0, 0, 0.45))


func _apply_buzzer_styles_disabled() -> void:
	if _buzzer_button == null:
		return
	var disabled := StyleBoxFlat.new()
	disabled.bg_color = Color("#0c1018")
	disabled.border_color = Color("#151d2e")
	disabled.set_border_width_all(2)
	disabled.set_corner_radius_all(CORNER_RADIUS)
	disabled.content_margin_top = 24
	disabled.content_margin_bottom = 24
	disabled.content_margin_left = 28
	disabled.content_margin_right = 28

	_buzzer_button.add_theme_stylebox_override("disabled", disabled)
	_buzzer_button.add_theme_color_override("font_disabled_color", Color("#334155"))


func _buzzer_ready_text(prefix: String = "⚡", action: String = "PULSAR") -> String:
	var team_name_text: String = ShowConfig.get_team_name(AppState.selected_team_id).to_upper() if AppState.selected_team_id > 0 else "TU EQUIPO"
	return "%s %s · %s" % [prefix, action, team_name_text]


func _render_buzzer(state: GameState) -> void:
	# If virtual buzzer disabled in config, hide it — answer buttons follow normal visibility
	if not ShowConfig.get_buzzer_mode_enabled():
		_buzzer_button.visible = false
		_stop_buzzer_pulse()
		return
	var team_id: int = AppState.selected_team_id
	var answer_parent: Node = answer_a.get_parent()
	var authority_team_id: int = state.answer_authority_team_id

	# During LOCKED or REVEAL, always hide buzzer
	if state.phase == Enums.GamePhase.LOCKED or state.phase == Enums.GamePhase.REVEAL:
		_buzzer_button.visible = false
		_stop_buzzer_pulse()
		answer_parent.visible = true
		return

	if state.phase == Enums.GamePhase.MINIGAME:
		_buzzer_button.visible = false
		_stop_buzzer_pulse()
		return

	# QUESTION phase — buzzer always active
	if state.phase == Enums.GamePhase.QUESTION:
		if authority_team_id == 0:
			# No winner yet — show buzzer, hide answers
			_buzzer_button.visible = true
			answer_parent.visible = false
			var excluded: bool = state.is_team_excluded_from_rebote(team_id)
			var locked: bool = state.is_team_locked_out(team_id)
			if team_id > 0 and not excluded and not locked and state.answers_enabled:
				_buzzer_button.disabled = false
				if not state.rebote_excluded_team_ids.is_empty():
					_buzzer_button.text = _buzzer_ready_text("🔄 REBOTE", "PULSAR")
				else:
					_buzzer_button.text = _buzzer_ready_text("⚡", "PULSAR")
				_apply_buzzer_styles_active()
				_start_buzzer_pulse()
			else:
				_buzzer_button.disabled = true
				if team_id <= 0:
					_buzzer_button.text = "SELECCIONÁ EQUIPO"
				elif excluded:
					_buzzer_button.text = "FUERA DE REBOTE"
				elif locked:
					_buzzer_button.text = "BLOQUEADO"
				else:
					_buzzer_button.text = "ESPERANDO..."
				_apply_buzzer_styles_disabled()
				_stop_buzzer_pulse()
		elif authority_team_id == team_id:
			# This team has the turn — show A/B/C/D, hide buzzer
			_buzzer_button.visible = false
			answer_parent.visible = true
			_stop_buzzer_pulse()
		else:
			# Another team has the turn — show disabled buzzer
			_buzzer_button.visible = true
			answer_parent.visible = false
			_buzzer_button.disabled = true
			if state.buzzer_winner_team_id > 0 and state.buzzer_winner_team_id == authority_team_id:
				_buzzer_button.text = "OTRO EQUIPO PULSÓ"
			elif authority_team_id > 0:
				_buzzer_button.text = "TURNO RESERVADO"
			else:
				_buzzer_button.text = "ESPERANDO..."
			_apply_buzzer_styles_disabled()
			_stop_buzzer_pulse()
		return

	# IDLE phase with no minigame — show ready buzzer
	if state.phase == Enums.GamePhase.IDLE and state.current_minigame.id <= 0:
		_buzzer_button.visible = true
		if team_id > 0:
			_buzzer_button.disabled = false
			_buzzer_button.text = _buzzer_ready_text("⚡", "LISTO")
			_apply_buzzer_styles_active()
			_start_buzzer_pulse()
		else:
			_buzzer_button.disabled = true
			_buzzer_button.text = "SELECCIONÁ EQUIPO"
			_apply_buzzer_styles_disabled()
			_stop_buzzer_pulse()
		return

	# Default: hide buzzer
	_buzzer_button.visible = false
	_stop_buzzer_pulse()


func _start_buzzer_pulse() -> void:
	_stop_buzzer_pulse()
	if _buzzer_button == null or not _buzzer_button.visible:
		return
	var style: StyleBoxFlat = _buzzer_button.get_theme_stylebox("normal")
	if style == null:
		return
	var tw: Tween = create_tween()
	tw.set_loops(0)
	tw.tween_property(style, "shadow_size", 24.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(style, "shadow_size", 8.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_buzzer_pulse_tweens.append(tw)


func _stop_buzzer_pulse() -> void:
	for tw: Tween in _buzzer_pulse_tweens:
		if tw.is_valid():
			tw.kill()
	_buzzer_pulse_tweens.clear()
