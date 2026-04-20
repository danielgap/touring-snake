extends Control

@onready var role_label: Label = $MarginContainer/VBoxContainer/RoleLabel
@onready var phase_label: Label = $MarginContainer/VBoxContainer/PhaseLabel
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var current_question_label: Label = $MarginContainer/VBoxContainer/CurrentQuestionLabel
@onready var lock_label: Label = $MarginContainer/VBoxContainer/LockLabel
@onready var team_state_label: Label = $MarginContainer/VBoxContainer/TeamStateLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var round_selector: OptionButton = $MarginContainer/VBoxContainer/SelectorPanel/RoundRow/RoundSelector
@onready var question_selector: OptionButton = $MarginContainer/VBoxContainer/SelectorPanel/QuestionRow/QuestionSelector
@onready var load_selected_button: Button = $MarginContainer/VBoxContainer/SelectorPanel/SelectorActionsRow/LoadSelectedButton
@onready var random_button: Button = $MarginContainer/VBoxContainer/SelectorPanel/SelectorActionsRow/LoadRandomButton
@onready var reset_used_button: Button = $MarginContainer/VBoxContainer/SelectorPanel/SelectorActionsRow/ResetUsedButton
@onready var clear_session_button: Button = $MarginContainer/VBoxContainer/SelectorPanel/SelectorActionsRow/ClearSessionButton
@onready var preview_label: Label = $MarginContainer/VBoxContainer/SelectorPanel/PreviewLabel
@onready var refresh_button: Button = $MarginContainer/VBoxContainer/ActionsRow/RefreshContentButton
@onready var start_button: Button = $MarginContainer/VBoxContainer/ActionsRow/StartQuestionButton
@onready var reopen_button: Button = $MarginContainer/VBoxContainer/ActionsRow/ReopenQuestionButton
@onready var reset_locks_button: Button = $MarginContainer/VBoxContainer/ActionsRow/ResetLocksButton
@onready var mark_correct_button: Button = $MarginContainer/VBoxContainer/ActionsRow/MarkCorrectButton
@onready var mark_incorrect_button: Button = $MarginContainer/VBoxContainer/ActionsRow/MarkIncorrectButton
@onready var reveal_button: Button = $MarginContainer/VBoxContainer/ActionsRow/RevealAnswerButton
@onready var team_1_lock_button: Button = $MarginContainer/VBoxContainer/ArbitrationPanel/Team1LockRow/Team1LockButton
@onready var team_1_force_button: Button = $MarginContainer/VBoxContainer/ArbitrationPanel/Team1LockRow/Team1ForceButton
@onready var team_2_lock_button: Button = $MarginContainer/VBoxContainer/ArbitrationPanel/Team2LockRow/Team2LockButton
@onready var team_2_force_button: Button = $MarginContainer/VBoxContainer/ArbitrationPanel/Team2LockRow/Team2ForceButton
@onready var team_3_lock_button: Button = $MarginContainer/VBoxContainer/ArbitrationPanel/Team3LockRow/Team3LockButton
@onready var team_3_force_button: Button = $MarginContainer/VBoxContainer/ArbitrationPanel/Team3LockRow/Team3ForceButton
@onready var team_1_subtract_button: Button = $MarginContainer/VBoxContainer/ScoreControls/Team1Row/Team1SubtractButton
@onready var team_1_add_button: Button = $MarginContainer/VBoxContainer/ScoreControls/Team1Row/Team1AddButton
@onready var team_2_subtract_button: Button = $MarginContainer/VBoxContainer/ScoreControls/Team2Row/Team2SubtractButton
@onready var team_2_add_button: Button = $MarginContainer/VBoxContainer/ScoreControls/Team2Row/Team2AddButton
@onready var team_3_subtract_button: Button = $MarginContainer/VBoxContainer/ScoreControls/Team3Row/Team3SubtractButton
@onready var team_3_add_button: Button = $MarginContainer/VBoxContainer/ScoreControls/Team3Row/Team3AddButton

var _round_values: Array[String] = []
var _question_ids: Array[int] = []
var _selector_syncing: bool = false


func _ready() -> void:
	refresh_button.pressed.connect(ContentRepo.load_questions)
	start_button.pressed.connect(GameService.load_random_question_from_selected_round)
	reopen_button.pressed.connect(GameService.reopen_current_question)
	reset_locks_button.pressed.connect(GameService.reset_team_locks)
	load_selected_button.pressed.connect(GameService.load_selected_question)
	random_button.pressed.connect(GameService.load_random_question_from_selected_round)
	reset_used_button.pressed.connect(GameService.reset_used_questions)
	clear_session_button.pressed.connect(GameService.clear_persisted_presenter_session)
	mark_correct_button.pressed.connect(GameService.mark_locked_answer_correct)
	mark_incorrect_button.pressed.connect(GameService.mark_locked_answer_incorrect)
	reveal_button.pressed.connect(GameService.reveal_current_answer)
	round_selector.item_selected.connect(_on_round_selected)
	question_selector.item_selected.connect(_on_question_selected)
	team_1_lock_button.pressed.connect(func() -> void: GameService.toggle_team_lock(1))
	team_1_force_button.pressed.connect(func() -> void: GameService.force_active_team(1))
	team_2_lock_button.pressed.connect(func() -> void: GameService.toggle_team_lock(2))
	team_2_force_button.pressed.connect(func() -> void: GameService.force_active_team(2))
	team_3_lock_button.pressed.connect(func() -> void: GameService.toggle_team_lock(3))
	team_3_force_button.pressed.connect(func() -> void: GameService.force_active_team(3))
	team_1_subtract_button.pressed.connect(func() -> void: GameService.adjust_score(1, -100))
	team_1_add_button.pressed.connect(func() -> void: GameService.adjust_score(1, 100))
	team_2_subtract_button.pressed.connect(func() -> void: GameService.adjust_score(2, -100))
	team_2_add_button.pressed.connect(func() -> void: GameService.adjust_score(2, 100))
	team_3_subtract_button.pressed.connect(func() -> void: GameService.adjust_score(3, -100))
	team_3_add_button.pressed.connect(func() -> void: GameService.adjust_score(3, 100))
	AppState.game_state_changed.connect(_render_state)
	AppState.scores_changed.connect(_render_scores)
	ContentRepo.questions_loaded.connect(_on_questions_loaded)
	GameService.presenter_selector_changed.connect(_on_selector_changed)
	GameService.used_questions_changed.connect(_on_used_questions_changed)
	_sync_selector_controls()
	_render_state(AppState.current_state)
	_render_scores(AppState.current_state.scores)


func _render_state(state: GameState) -> void:
	role_label.text = "Control del presentador"
	phase_label.text = "Estado de ronda: %s" % _phase_summary(state)
	status_label.text = "%s · Banco: %d preguntas" % [state.status_text, ContentRepo.get_question_count()]
	if state.current_question.text.is_empty():
		current_question_label.text = "Pregunta al aire: ninguna.\nRecargá contenido o abrí una nueva pregunta cuando quieras salir al aire."
	else:
		current_question_label.text = "Pregunta al aire\n%s" % _question_summary(state)
	lock_label.text = _lock_summary(state)
	team_state_label.text = _team_states_summary(state)
	_render_preview()
	_reveal_button_state(state)
	_update_score_controls(state)
	_update_arbitration_controls(state)


func _render_scores(scores: Dictionary) -> void:
	score_label.text = "Marcador en vivo · E1: %d | E2: %d | E3: %d" % [
		int(scores.get(1, 0)),
		int(scores.get(2, 0)),
		int(scores.get(3, 0)),
	]


func _on_questions_loaded(count: int) -> void:
	status_label.text = "Preguntas actualizadas · %d disponibles" % count
	_sync_selector_controls()


func _on_selector_changed(_round_name: String, _question_id: int) -> void:
	_sync_selector_controls()


func _on_used_questions_changed() -> void:
	_sync_selector_controls()


func _on_round_selected(index: int) -> void:
	if _selector_syncing or index < 0 or index >= _round_values.size():
		return
	GameService.set_presenter_round(_round_values[index])


func _on_question_selected(index: int) -> void:
	if _selector_syncing or index < 0 or index >= _question_ids.size():
		return
	GameService.set_presenter_question(_question_ids[index])


func _sync_selector_controls() -> void:
	_selector_syncing = true
	_round_values.clear()
	_question_ids.clear()
	round_selector.clear()
	question_selector.clear()

	var rounds: PackedStringArray = ContentRepo.get_rounds()
	for round_name in rounds:
		_round_values.append(round_name)
		round_selector.add_item(round_name)

	var selected_round: String = GameService.get_selected_round_name()
	var selected_round_index: int = _find_round_index(selected_round)
	if selected_round_index >= 0:
		round_selector.select(selected_round_index)

	var questions_in_round: Array[Question] = ContentRepo.get_questions_for_round(selected_round)
	for question in questions_in_round:
		_question_ids.append(question.id)
		question_selector.add_item(_question_option_label(question))

	var selected_question_index: int = _find_question_index(GameService.get_selected_question_id())
	if selected_question_index >= 0:
		question_selector.select(selected_question_index)

	_selector_syncing = false
	_render_preview()
	_update_selector_buttons()


func _render_preview() -> void:
	var selected_question: Question = GameService.get_selected_question()
	if selected_question.text.is_empty():
		preview_label.text = "Vista previa privada: elegí una ronda y una pregunta para revisar correcta y tiempo."
		return
	preview_label.text = "Vista previa privada · Correcta: %s · Tiempo: %ds\n%s" % [
		selected_question.correct_option if not selected_question.correct_option.is_empty() else "--",
		selected_question.timeout_seconds,
		_question_summary_from_question(selected_question),
	]


func _update_selector_buttons() -> void:
	var has_questions: bool = ContentRepo.get_question_count() > 0
	var has_round_questions: bool = _question_ids.size() > 0
	round_selector.disabled = not has_questions
	question_selector.disabled = not has_round_questions
	load_selected_button.disabled = not has_round_questions
	random_button.disabled = not has_round_questions
	reset_used_button.disabled = not has_questions
	clear_session_button.disabled = not GameService.has_persisted_presenter_session()
	start_button.disabled = not has_round_questions or AppState.current_state.phase in [Enums.GamePhase.QUESTION, Enums.GamePhase.LOCKED]


func _question_summary(state: GameState) -> String:
	return _question_summary_from_question(state.current_question)


func _question_summary_from_question(question: Question) -> String:
	var metadata: Array[String] = []
	if not question.round_name.is_empty():
		metadata.append(question.round_name)
	if not question.category.is_empty():
		metadata.append(question.category)
	var header: String = "Q%d" % question.id if question.id > 0 else "Pregunta activa"
	if metadata.size() > 0:
		var metadata_text: String = metadata[0]
		for index in range(1, metadata.size()):
			metadata_text += " / %s" % metadata[index]
		header += " · %s" % metadata_text
	return "%s\n%s" % [header, question.text]


func _phase_summary(state: GameState) -> String:
	var phase_name: String = Enums.phase_name(state.phase)
	if state.phase == Enums.GamePhase.QUESTION and state.answers_enabled:
		return "%s · mesa abierta" % phase_name
	if state.phase == Enums.GamePhase.LOCKED:
		return "%s · %s" % [phase_name, Enums.answer_feedback_name(state.answer_feedback_status)]
	if state.phase == Enums.GamePhase.REVEAL:
		return "%s · correcta visible" % phase_name
	return phase_name


func _lock_summary(state: GameState) -> String:
	if state.phase == Enums.GamePhase.REVEAL:
		return "Cierre de ronda · Correcta: %s · Fallo: %s · Último bloqueo: %s" % [
			state.revealed_correct_option if not state.revealed_correct_option.is_empty() else "--",
			Enums.answer_feedback_name(state.answer_feedback_status),
			_locked_team_text(state),
		]
	if state.locked_team_id > 0:
		return "Respuesta tomada · Equipo %d eligió %s · %s" % [
			state.locked_team_id,
			state.last_selected_option if not state.last_selected_option.is_empty() else "--",
			Enums.answer_feedback_name(state.answer_feedback_status),
		]
	if state.active_team_id > 0:
		return "Turno reservado · Equipo %d con prioridad; el resto espera." % state.active_team_id
	if state.answers_enabled:
		return "Mesa abierta · esperando la primera respuesta válida."
	return "Aún no hay respuesta tomada."


func _locked_team_text(state: GameState) -> String:
	if state.locked_team_id <= 0:
		return "ninguno"
	return "Equipo %d (%s)" % [
		state.locked_team_id,
		state.last_selected_option if not state.last_selected_option.is_empty() else "sin opción",
	]


func _reveal_button_state(state: GameState) -> void:
	_update_selector_buttons()
	var needs_correction: bool = state.phase == Enums.GamePhase.LOCKED \
		and state.locked_team_id > 0 \
		and not state.correction_applied
	mark_correct_button.disabled = state.phase != Enums.GamePhase.LOCKED or state.locked_team_id <= 0
	mark_incorrect_button.disabled = mark_correct_button.disabled
	reopen_button.disabled = state.current_question.text.is_empty() or state.phase not in [Enums.GamePhase.LOCKED, Enums.GamePhase.REVEAL]
	reset_locks_button.disabled = state.current_question.text.is_empty()
	reveal_button.disabled = state.current_question.text.is_empty() \
		or state.phase not in [Enums.GamePhase.QUESTION, Enums.GamePhase.LOCKED] \
		or needs_correction


func _update_score_controls(state: GameState) -> void:
	var scoring_enabled: bool = not state.current_question.text.is_empty() and state.phase in [Enums.GamePhase.LOCKED, Enums.GamePhase.REVEAL]
	team_1_subtract_button.disabled = not scoring_enabled
	team_1_add_button.disabled = not scoring_enabled
	team_2_subtract_button.disabled = not scoring_enabled
	team_2_add_button.disabled = not scoring_enabled
	team_3_subtract_button.disabled = not scoring_enabled
	team_3_add_button.disabled = not scoring_enabled


func _update_arbitration_controls(state: GameState) -> void:
	var question_open: bool = not state.current_question.text.is_empty() and state.phase == Enums.GamePhase.QUESTION
	team_1_lock_button.text = "Habilitar" if state.is_team_locked_out(1) else "Bloquear"
	team_2_lock_button.text = "Habilitar" if state.is_team_locked_out(2) else "Bloquear"
	team_3_lock_button.text = "Habilitar" if state.is_team_locked_out(3) else "Bloquear"
	team_1_force_button.text = "Turno activo" if state.active_team_id == 1 else "Dar turno"
	team_2_force_button.text = "Turno activo" if state.active_team_id == 2 else "Dar turno"
	team_3_force_button.text = "Turno activo" if state.active_team_id == 3 else "Dar turno"
	team_1_lock_button.disabled = not question_open
	team_2_lock_button.disabled = not question_open
	team_3_lock_button.disabled = not question_open
	team_1_force_button.disabled = not question_open or state.is_team_locked_out(1)
	team_2_force_button.disabled = not question_open or state.is_team_locked_out(2)
	team_3_force_button.disabled = not question_open or state.is_team_locked_out(3)


func _team_states_summary(state: GameState) -> String:
	var summary: String = ""
	for team_id in [1, 2, 3]:
		if not summary.is_empty():
			summary += " · "
		summary += "E%d: %s" % [team_id, Enums.team_lock_state_name(state.team_lock_state(team_id))]
	return "Resumen de equipos · %s" % summary


func _find_round_index(round_name: String) -> int:
	for index in range(_round_values.size()):
		if _round_values[index] == round_name:
			return index
	return -1


func _find_question_index(question_id: int) -> int:
	for index in range(_question_ids.size()):
		if _question_ids[index] == question_id:
			return index
	return -1


func _question_option_label(question: Question) -> String:
	var summary: String = question.text.strip_edges()
	if summary.length() > 72:
		summary = "%s…" % summary.substr(0, 72)
	var category_suffix: String = ""
	if not question.category.is_empty():
		category_suffix = " · %s" % question.category
	var usage_prefix: String = "[Usada]" if GameService.is_question_used(question.id) else "[Nueva]"
	return "%s Q%d%s — %s" % [usage_prefix, question.id, category_suffix, summary]
