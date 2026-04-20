extends Control

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var phase_label: Label = $MarginContainer/VBoxContainer/PhaseLabel
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var question_label: Label = $MarginContainer/VBoxContainer/QuestionLabel
@onready var lock_label: Label = $MarginContainer/VBoxContainer/LockLabel
@onready var team_locks_label: Label = $MarginContainer/VBoxContainer/TeamLocksLabel
@onready var feedback_label: Label = $MarginContainer/VBoxContainer/FeedbackLabel
@onready var option_a: Label = $MarginContainer/VBoxContainer/OptionsVBox/OptionALabel
@onready var option_b: Label = $MarginContainer/VBoxContainer/OptionsVBox/OptionBLabel
@onready var option_c: Label = $MarginContainer/VBoxContainer/OptionsVBox/OptionCLabel
@onready var option_d: Label = $MarginContainer/VBoxContainer/OptionsVBox/OptionDLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel


func _ready() -> void:
	title_label.text = "Pantalla principal"
	AppState.game_state_changed.connect(_render_state)
	AppState.scores_changed.connect(_render_scores)
	_render_state(AppState.current_state)
	_render_scores(AppState.current_state.scores)


func _render_state(state: GameState) -> void:
	phase_label.text = _phase_summary(state)
	status_label.text = "Estado: %s" % state.status_text
	question_label.text = state.current_question.text if not state.current_question.text.is_empty() else "En instantes aparece la próxima pregunta."
	lock_label.text = _lock_summary(state)
	team_locks_label.text = _team_locks_summary(state)
	feedback_label.text = _feedback_summary(state)
	var options: PackedStringArray = state.current_question.options
	option_a.text = _option_text("A", options, 0, state)
	option_b.text = _option_text("B", options, 1, state)
	option_c.text = _option_text("C", options, 2, state)
	option_d.text = _option_text("D", options, 3, state)


func _render_scores(scores: Dictionary) -> void:
	score_label.text = "Marcador · E1: %d | E2: %d | E3: %d" % [
		int(scores.get(1, 0)),
		int(scores.get(2, 0)),
		int(scores.get(3, 0)),
	]


func _option_text(letter: String, options: PackedStringArray, index: int, state: GameState) -> String:
	var text: String = "%s) --" % letter
	if index < options.size():
		text = "%s) %s" % [letter, options[index]]
	if state.locked_team_id > 0 and state.last_selected_option == letter:
		text += "  %s" % _locked_option_marker(state)
	if state.phase == Enums.GamePhase.REVEAL and state.revealed_correct_option == letter:
		if state.answer_feedback_status == Enums.AnswerFeedbackStatus.CORRECT and state.last_selected_option == letter:
			return text
		text += "  ✅"
	return text


func _phase_summary(state: GameState) -> String:
	if state.phase == Enums.GamePhase.LOCKED:
		return "RESPUESTA TOMADA"
	if state.phase == Enums.GamePhase.QUESTION and state.answers_enabled:
		return "PREGUNTA ABIERTA"
	if state.phase == Enums.GamePhase.REVEAL:
		return "RESPUESTA REVELADA"
	return Enums.phase_name(state.phase).to_upper()


func _lock_summary(state: GameState) -> String:
	if state.phase == Enums.GamePhase.REVEAL:
		return "Correcta: %s · Respondió: %s" % [
			state.revealed_correct_option if not state.revealed_correct_option.is_empty() else "--",
			_locked_team_text(state),
		]
	if state.locked_team_id > 0:
		return "Respondió equipo %d con %s" % [
			state.locked_team_id,
			state.last_selected_option if not state.last_selected_option.is_empty() else "--",
		]
	if state.active_team_id > 0:
		return "Turno reservado para el equipo %d" % state.active_team_id
	if state.answers_enabled:
		return "Esperando la primera respuesta válida."
	return "Todavía no respondió ningún equipo."


func _locked_team_text(state: GameState) -> String:
	if state.locked_team_id <= 0:
		return "nadie"
	return "Equipo %d (%s)" % [
		state.locked_team_id,
		state.last_selected_option if not state.last_selected_option.is_empty() else "sin opción",
	]


func _feedback_summary(state: GameState) -> String:
	if state.locked_team_id <= 0:
		return "Aguardando respuesta de un equipo."
	match state.answer_feedback_status:
		Enums.AnswerFeedbackStatus.CORRECT:
			return "Resultado: equipo %d CORRECTO." % state.locked_team_id
		Enums.AnswerFeedbackStatus.INCORRECT:
			return "Resultado: equipo %d INCORRECTO." % state.locked_team_id
		Enums.AnswerFeedbackStatus.PENDING:
			return "Resultado pendiente: equipo %d espera corrección." % state.locked_team_id
		_:
			return "Esperando decisión del presentador."


func _team_locks_summary(state: GameState) -> String:
	var summary: String = ""
	for team_id in [1, 2, 3]:
		if not summary.is_empty():
			summary += " · "
		summary += "E%d %s" % [team_id, Enums.team_lock_state_name(state.team_lock_state(team_id)).to_lower()]
	return "Equipos: %s" % summary


func _locked_option_marker(state: GameState) -> String:
	match state.answer_feedback_status:
		Enums.AnswerFeedbackStatus.CORRECT:
			return "✅"
		Enums.AnswerFeedbackStatus.INCORRECT:
			return "❌"
		Enums.AnswerFeedbackStatus.PENDING:
			return "⏳"
		_:
			return "🔒"
