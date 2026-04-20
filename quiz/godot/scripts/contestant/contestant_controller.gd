extends Control

@onready var role_label: Label = $MarginContainer/VBoxContainer/RoleLabel
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var lock_state_label: Label = $MarginContainer/VBoxContainer/LockStateLabel
@onready var feedback_label: Label = $MarginContainer/VBoxContainer/FeedbackLabel
@onready var question_label: Label = $MarginContainer/VBoxContainer/QuestionLabel
@onready var answer_a: Button = $MarginContainer/VBoxContainer/AnswersGrid/AnswerA
@onready var answer_b: Button = $MarginContainer/VBoxContainer/AnswersGrid/AnswerB
@onready var answer_c: Button = $MarginContainer/VBoxContainer/AnswersGrid/AnswerC
@onready var answer_d: Button = $MarginContainer/VBoxContainer/AnswersGrid/AnswerD


func _ready() -> void:
	answer_a.pressed.connect(func() -> void: GameService.submit_answer("A"))
	answer_b.pressed.connect(func() -> void: GameService.submit_answer("B"))
	answer_c.pressed.connect(func() -> void: GameService.submit_answer("C"))
	answer_d.pressed.connect(func() -> void: GameService.submit_answer("D"))
	AppState.game_state_changed.connect(_render_state)
	AppState.team_id_changed.connect(_render_team)
	_render_team(AppState.selected_team_id)
	_render_state(AppState.current_state)


func _render_team(team_id: int) -> void:
	if team_id > 0:
		role_label.text = "Equipo %d" % team_id
	else:
		role_label.text = "Tablet sin equipo"


func _render_state(state: GameState) -> void:
	status_label.text = "%s · %s" % [_phase_banner(state), state.status_text]
	lock_state_label.text = _team_lock_summary(state)
	question_label.text = state.current_question.text if not state.current_question.text.is_empty() else "Todavía no hay pregunta en juego."

	var options: PackedStringArray = state.current_question.options
	answer_a.text = _button_text("A", options, 0)
	answer_b.text = _button_text("B", options, 1)
	answer_c.text = _button_text("C", options, 2)
	answer_d.text = _button_text("D", options, 3)

	var can_answer: bool = _can_answer(state)
	answer_a.disabled = not can_answer
	answer_b.disabled = not can_answer
	answer_c.disabled = not can_answer
	answer_d.disabled = not can_answer
	feedback_label.text = _feedback_text(state, can_answer)


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
		return "Tablet bloqueada por el presentador. Esperá nueva habilitación."
	if state.phase == Enums.GamePhase.REVEAL:
		if state.locked_team_id == AppState.selected_team_id:
			return "Ronda cerrada · %s · Correcta: %s." % [
				_feedback_summary(state),
				state.revealed_correct_option if not state.revealed_correct_option.is_empty() else "--",
			]
		return "Correcta en pantalla: %s · %s" % [
			state.revealed_correct_option if not state.revealed_correct_option.is_empty() else "--",
			_feedback_summary(state),
		]
	if state.locked_team_id == AppState.selected_team_id:
		match state.answer_feedback_status:
			Enums.AnswerFeedbackStatus.CORRECT:
				return "¡BIEN! Su respuesta %s fue marcada correcta." % (
					state.last_selected_option if not state.last_selected_option.is_empty() else "una opción"
				)
			Enums.AnswerFeedbackStatus.INCORRECT:
				return "No era esa · Su respuesta %s fue marcada incorrecta." % (
					state.last_selected_option if not state.last_selected_option.is_empty() else "una opción"
				)
			_:
				return "Respuesta enviada: %s. Esperando fallo del presentador." % (
					state.last_selected_option if not state.last_selected_option.is_empty() else "seleccionada"
				)
	if state.locked_team_id > 0:
		return "Respondió el equipo %d · %s" % [state.locked_team_id, _feedback_summary(state)]
	if state.active_team_id > 0 and state.active_team_id != AppState.selected_team_id:
		return "Turno reservado para el equipo %d. Esperen reapertura." % state.active_team_id
	if state.active_team_id == AppState.selected_team_id and can_answer:
		return "¡SU TURNO! Respondan ahora. La ronda se cierra al tocar una opción."
	if can_answer:
		return "¡RESPONDAN AHORA! La primera respuesta válida cierra la mesa."
	if state.current_question.text.is_empty():
		return "Esperando que el presentador publique una pregunta."
	return "Todavía no pueden responder. Esperen habilitación."


func _phase_banner(state: GameState) -> String:
	if state.phase == Enums.GamePhase.QUESTION and _can_answer(state):
		return "Mesa abierta"
	if state.phase == Enums.GamePhase.LOCKED:
		return "Respuesta tomada"
	if state.phase == Enums.GamePhase.REVEAL:
		return "Correcta revelada"
	return Enums.phase_name(state.phase)


func _feedback_summary(state: GameState) -> String:
	match state.answer_feedback_status:
		Enums.AnswerFeedbackStatus.CORRECT:
			return "El presentador la dio por correcta."
		Enums.AnswerFeedbackStatus.INCORRECT:
			return "El presentador la dio por incorrecta."
		Enums.AnswerFeedbackStatus.PENDING:
			return "La respuesta quedó enviada y espera corrección."
		_:
			return "Esperando decisión del presentador."


func _team_lock_summary(state: GameState) -> String:
	if AppState.selected_team_id <= 0:
		return "Estado del equipo: sin asignar"
	return "Estado del equipo: %s" % Enums.team_lock_state_name(state.team_lock_state(AppState.selected_team_id))
