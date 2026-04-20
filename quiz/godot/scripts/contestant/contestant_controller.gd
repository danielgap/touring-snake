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

## ── Internal ──────────────────────────────────────────────────────
var _team_color: Color = Color("#3b82f6")
var _team_bg: Color = Color("#0f2850")
var _prev_phase: int = -1
var _prev_can_answer: bool = false
var _prev_question_text: String = ""
var _active_tweens: Array[Tween] = []


func _ready() -> void:
	_apply_base_styles()
	answer_a.pressed.connect(func() -> void: GameService.submit_answer("A"))
	answer_b.pressed.connect(func() -> void: GameService.submit_answer("B"))
	answer_c.pressed.connect(func() -> void: GameService.submit_answer("C"))
	answer_d.pressed.connect(func() -> void: GameService.submit_answer("D"))
	AppState.game_state_changed.connect(_render_state)
	AppState.team_id_changed.connect(_render_team)
	ShowConfig.config_changed.connect(_on_config_changed)
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
	elif state.is_team_locked_out(team_id):
		status_text = "BLOQUEADO"
		status_color = STATUS_LOCKED
	elif state.phase == Enums.GamePhase.REVEAL:
		status_text = "REVELADA"
		status_color = ACCENT_BLUE
	elif can_answer:
		status_text = "TU TURNO"
		status_color = STATUS_ACTIVE
	elif state.phase == Enums.GamePhase.QUESTION:
		status_text = "EN JUEGO"
		status_color = STATUS_WAITING
	elif state.phase == Enums.GamePhase.LOCKED:
		if state.locked_team_id == team_id:
			match state.answer_feedback_status:
				Enums.AnswerFeedbackStatus.CORRECT:
					status_text = "CORRECTA"
					status_color = STATUS_ACTIVE
				Enums.AnswerFeedbackStatus.INCORRECT:
					status_text = "INCORRECTA"
					status_color = STATUS_LOCKED
				_:
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
	question_label.text = state.current_question.text if not state.current_question.text.is_empty() else "Esperando pregunta del presentador..."
	if question_changed and not state.current_question.text.is_empty():
		_animate_question_in()

	# ── Answer buttons ─────────────────────────────────────────────
	var options: PackedStringArray = state.current_question.options
	answer_a.text = _button_text("A", options, 0)
	answer_b.text = _button_text("B", options, 1)
	answer_c.text = _button_text("C", options, 2)
	answer_d.text = _button_text("D", options, 3)

	answer_a.disabled = not can_answer
	answer_b.disabled = not can_answer
	answer_c.disabled = not can_answer
	answer_d.disabled = not can_answer

	# Color answer buttons based on can_answer state
	var btn_bg: Color = _team_bg if can_answer else Color("#151d2e")
	var btn_border: Color = _team_color if can_answer else Color("#334155")
	for btn: Button in [answer_a, answer_b, answer_c, answer_d]:
		_apply_answer_button(btn, btn_bg, btn_border)

	# ── Feedback card ──────────────────────────────────────────────
	feedback_label.text = _feedback_text(state, can_answer)
	_update_feedback_style(state, can_answer)

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
		match state.answer_feedback_status:
			Enums.AnswerFeedbackStatus.CORRECT:
				border_color = STATUS_ACTIVE
				bg = Color(STATUS_ACTIVE.r * 0.2, STATUS_ACTIVE.g * 0.2, STATUS_ACTIVE.b * 0.2, 1.0)
				text_color = STATUS_ACTIVE
			Enums.AnswerFeedbackStatus.INCORRECT:
				border_color = STATUS_LOCKED
				bg = Color(STATUS_LOCKED.r * 0.2, STATUS_LOCKED.g * 0.2, STATUS_LOCKED.b * 0.2, 1.0)
				text_color = STATUS_LOCKED
			_:
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
		if state.phase == Enums.GamePhase.LOCKED and state.locked_team_id == team_id:
			match state.answer_feedback_status:
				Enums.AnswerFeedbackStatus.CORRECT, Enums.AnswerFeedbackStatus.INCORRECT:
					glow_mult = 0.5
		style.shadow_color = Color(border_color.r, border_color.g, border_color.b, glow_mult)
		style.shadow_size = 8 if glow_mult > 0.3 else 4
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
		match state.answer_feedback_status:
			Enums.AnswerFeedbackStatus.CORRECT:
				return "CORRECTA — Su respuesta %s fue aceptada." % (
					state.last_selected_option if not state.last_selected_option.is_empty() else "seleccionada"
				)
			Enums.AnswerFeedbackStatus.INCORRECT:
				return "INCORRECTA — Su respuesta %s fue rechazada." % (
					state.last_selected_option if not state.last_selected_option.is_empty() else "seleccionada"
				)
			_:
				return "Respuesta enviada: %s · Esperando fallo del presentador." % (
					state.last_selected_option if not state.last_selected_option.is_empty() else "seleccionada"
				)
	if state.locked_team_id > 0:
		return "Respondió %s · %s" % [ShowConfig.get_team_name(state.locked_team_id), _feedback_summary(state)]
	if state.active_team_id > 0 and state.active_team_id != AppState.selected_team_id:
		return "Turno reservado para %s." % ShowConfig.get_team_name(state.active_team_id)
	if state.active_team_id == AppState.selected_team_id and can_answer:
		return "SU TURNO — Respondan ahora."
	if can_answer:
		return "RESPONDAN AHORA — La primera respuesta cierra la mesa."
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
	var buttons: Array[Button] = [answer_a, answer_b, answer_c, answer_d]
	var tw := _make_tween()
	tw.set_parallel(true)
	for btn: Button in buttons:
		tw.tween_property(btn, "modulate:a", 0.6, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
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

		# Flash the answer buttons too
		var buttons: Array[Button] = [answer_a, answer_b, answer_c, answer_d]
		for btn: Button in buttons:
			btn.modulate.a = 0.3
		var tw3 := _make_tween()
		tw3.set_parallel(true)
		for btn: Button in buttons:
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
