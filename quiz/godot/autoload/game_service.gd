extends Node

signal role_initialized(role: int)
signal answer_received(team_id: int, option: String)
signal presenter_selector_changed(round_name: String, question_id: int)
signal presenter_minigame_selector_changed(minigame_id: int)
signal used_questions_changed()
const MQTT_HOST: String = "127.0.0.1"
const MQTT_PORT: int = 1883
const SNAPSHOT_QOS: int = 1
const COMMAND_QOS: int = 1
const SNAPSHOT_RETAIN: bool = true
const PRESENTER_SESSION_SAVE_PATH: String = "user://presenter_session.json"

var _current_question_index: int = -1
var _selected_round_name: String = ""
var _selected_question_id: int = 0
var _selected_minigame_id: int = 0
var _used_question_ids: Dictionary = {}
var _used_minigame_ids: Dictionary = {}
var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _can_persist_presenter_session: bool = false
var _pending_presenter_snapshot_publish: bool = false


func _ready() -> void:
	_random.randomize()
	MqttBus.message_received.connect(_on_mqtt_message_received)
	MqttBus.connected.connect(_on_mqtt_connected)
	ContentRepo.questions_loaded.connect(_on_questions_loaded)
	ContentRepo.content_missing.connect(_on_content_missing)
	ContentRepo.minigames_loaded.connect(_on_minigames_loaded)


func _get_team_ids() -> Array[int]:
	var count: int = ShowConfig.get_team_count() if ShowConfig else 3
	var ids: Array[int] = []
	for i in range(1, count + 1):
		ids.append(i)
	return ids


func _build_default_locks() -> Dictionary:
	var locks: Dictionary = {}
	for team_id in _get_team_ids():
		locks[team_id] = false
	return locks


func _get_mqtt_host() -> String:
	if ShowConfig:
		var host: String = ShowConfig.get_mqtt_host()
		if not host.is_empty():
			return host
	return MQTT_HOST


func _get_mqtt_port() -> int:
	if ShowConfig:
		return ShowConfig.get_mqtt_port()
	return MQTT_PORT


func _get_points_correct() -> int:
	if ShowConfig:
		return ShowConfig.get_points_correct()
	return 100


func _get_points_incorrect() -> int:
	# Always returns negative — positive config values mean "penalty of N points"
	if ShowConfig:
		return -abs(ShowConfig.get_points_incorrect())
	return 0


func initialize_role(role: int, team_id: int = 0) -> void:
	AppState.set_role(role)
	AppState.set_team_id(team_id)
	if role == Enums.AppRole.PRESENTER:
		_can_persist_presenter_session = false
		_restore_presenter_session()
		_can_persist_presenter_session = true
	else:
		_can_persist_presenter_session = false
		_pending_presenter_snapshot_publish = false
	MqttBus.connect_to_broker(_get_mqtt_host(), _get_mqtt_port())
	MqttBus.subscribe_topic(MessageTopics.STATE, SNAPSHOT_QOS)
	MqttBus.subscribe_topic(MessageTopics.ANSWER, COMMAND_QOS)
	MqttBus.subscribe_topic(MessageTopics.POINTS, COMMAND_QOS)
	MqttBus.subscribe_topic(MessageTopics.TABLET_LOCK, COMMAND_QOS)
	MqttBus.subscribe_topic(MessageTopics.BUZZER, COMMAND_QOS)
	emit_signal("role_initialized", role)


func start_next_question() -> void:
	load_random_question()


func set_presenter_round(round_name: String) -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	var available_rounds: PackedStringArray = ContentRepo.get_rounds()
	if available_rounds.is_empty():
		_update_presenter_selector("", 0)
		return
	var resolved_round: String = round_name
	if not available_rounds.has(resolved_round):
		resolved_round = available_rounds[0]
	var questions_in_round: Array[Question] = ContentRepo.get_questions_for_round(resolved_round)
	var resolved_question_id: int = _selected_question_id
	if questions_in_round.is_empty():
		resolved_question_id = 0
	elif _question_index_in(questions_in_round, resolved_question_id) == -1:
		resolved_question_id = questions_in_round[0].id
	_update_presenter_selector(resolved_round, resolved_question_id)


func set_presenter_question(question_id: int) -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	var questions_in_round: Array[Question] = ContentRepo.get_questions_for_round(_selected_round_name)
	if questions_in_round.is_empty():
		_update_presenter_selector(_selected_round_name, 0)
		return
	var resolved_question_id: int = question_id
	if _question_index_in(questions_in_round, resolved_question_id) == -1:
		resolved_question_id = questions_in_round[0].id
	_update_presenter_selector(_selected_round_name, resolved_question_id)


func load_selected_question() -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	if not _ensure_presenter_selection():
		_publish_empty_presenter_state("No hay preguntas cargadas todavía.")
		return
	var selected_question: Question = ContentRepo.get_question_by_id(_selected_question_id)
	if selected_question.text.is_empty():
		_publish_empty_presenter_state("La pregunta seleccionada ya no está disponible.")
		return
	_apply_presenter_question(selected_question, "Pregunta seleccionada por el presentador")


func load_random_question() -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	var all_questions: Array[Question] = ContentRepo.questions
	if all_questions.is_empty():
		_publish_empty_presenter_state("No hay preguntas cargadas todavía.")
		return
	var unused_questions: Array[Question] = []
	for q: Question in all_questions:
		if not is_question_used(q.id):
			unused_questions.append(q)
	if unused_questions.is_empty():
		# All questions used — reset and reuse all
		unused_questions = all_questions
	var selected_question: Question = _pick_random_question(unused_questions)
	var round_name: String = ContentRepo.get_rounds()[0] if ContentRepo.get_rounds().size() > 0 else ""
	_update_presenter_selector(round_name, selected_question.id)
	_apply_presenter_question(selected_question, "Pregunta aleatoria cargada")


func skip_current_question() -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	var state: GameState = AppState.current_state
	if state.current_question.id > 0:
		_used_question_ids[state.current_question.id] = true
		emit_signal("used_questions_changed")
		_save_presenter_session()
	load_random_question()


func get_selected_round_name() -> String:
	return _selected_round_name


func get_selected_question_id() -> int:
	return _selected_question_id


func get_selected_question() -> Question:
	if _selected_question_id <= 0:
		return Question.new()
	return ContentRepo.get_question_by_id(_selected_question_id)


func has_persisted_presenter_session() -> bool:
	return FileAccess.file_exists(PRESENTER_SESSION_SAVE_PATH)


func is_question_used(question_id: int) -> bool:
	return question_id > 0 and _used_question_ids.has(question_id)


func reset_used_questions() -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	if _used_question_ids.is_empty():
		emit_signal("used_questions_changed")
		return
	_used_question_ids.clear()
	emit_signal("used_questions_changed")
	_save_presenter_session()


func clear_persisted_presenter_session() -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	_used_question_ids.clear()
	_used_minigame_ids.clear()
	_current_question_index = -1
	_update_presenter_selector("", 0)
	_ensure_presenter_selection()
	var cleared_state: GameState = GameState.new()
	cleared_state.status_text = "Sesión local borrada en este dispositivo"
	AppState.apply_game_state(cleared_state)
	emit_signal("used_questions_changed")
	_delete_presenter_session_file()
	_publish_or_defer_presenter_state(cleared_state)


func reveal_current_answer() -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	if AppState.current_state.current_question.text.is_empty():
		return

	var state: GameState = AppState.current_state.duplicate_state()
	state.phase = Enums.GamePhase.REVEAL
	state.answers_enabled = false
	_set_answer_authority(state, 0)
	state.revealed_correct_option = state.current_question.correct_option.to_upper()
	state.status_text = "Respuesta correcta mostrada en pantalla"
	# Apply pending score deltas (deferred from auto-judge)
	for team_id_key: Variant in state.pending_score_delta:
		var tid: int = int(team_id_key)
		var delta: int = int(state.pending_score_delta[team_id_key])
		var new_total: int = maxi(0, int(state.scores.get(tid, 0)) + delta)
		state.scores[tid] = new_total
		MqttBus.publish_json(MessageTopics.POINTS, {"equipo": tid, "total": new_total}, false, COMMAND_QOS)
	state.pending_score_delta = {}
	AppState.apply_game_state(state)
	_save_presenter_session()
	_publish_state(state)


func dismiss_reveal() -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	if AppState.current_state.phase != Enums.GamePhase.REVEAL:
		return
	var state: GameState = AppState.current_state.duplicate_state()
	state.phase = Enums.GamePhase.IDLE
	state.current_question = Question.new()
	state.current_minigame = MiniGame.new()
	state.locked_team_id = 0
	state.last_selected_option = ""
	state.revealed_correct_option = ""
	state.answer_feedback_status = Enums.AnswerFeedbackStatus.NONE
	state.correction_applied = false
	state.buzzer_winner_team_id = 0
	state.pending_score_delta = {}
	state.locked_out_team_ids = _build_default_locks()
	_set_answer_authority(state, 0)
	state.answers_enabled = false
	state.rebote_excluded_team_ids = {}
	state.status_text = "Respuesta cerrada — Elije siguiente pregunta"
	AppState.apply_game_state(state)
	_save_presenter_session()
	_publish_state(state)


func reopen_current_question() -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	if AppState.current_state.current_question.text.is_empty():
		return
	var state: GameState = AppState.current_state.duplicate_state()
	state.phase = Enums.GamePhase.QUESTION
	state.answers_enabled = true
	_set_answer_authority(state, 0)
	state.locked_team_id = 0
	state.revealed_correct_option = ""
	state.last_selected_option = ""
	state.answer_feedback_status = Enums.AnswerFeedbackStatus.NONE
	state.correction_applied = false
	state.buzzer_winner_team_id = 0
	state.rebote_excluded_team_ids = {}
	state.pending_score_delta = {}
	state.status_text = "Ronda reabierta. Se limpió la respuesta tomada."
	AppState.apply_game_state(state)
	_save_presenter_session()
	_publish_state(state)


func reset_team_locks() -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	var state: GameState = AppState.current_state.duplicate_state()
	for team_id in _get_team_ids():
		state.locked_out_team_ids[team_id] = false
	_set_answer_authority(state, 0)
	state.locked_team_id = 0
	state.last_selected_option = ""
	state.answer_feedback_status = Enums.AnswerFeedbackStatus.NONE
	state.correction_applied = false
	state.buzzer_winner_team_id = 0
	state.rebote_excluded_team_ids = {}
	state.revealed_correct_option = ""
	if not state.current_question.text.is_empty():
		state.phase = Enums.GamePhase.QUESTION
		state.answers_enabled = true
		state.status_text = "Jugada reiniciada. Todos los equipos pueden volver a responder."
	else:
		state.status_text = "Bloqueos de equipos reiniciados."
	AppState.apply_game_state(state)
	_save_presenter_session()
	_publish_state(state)


func reset_game() -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	# Reset all state to fresh game
	var fresh_state: GameState = GameState.new()
	var count: int = ShowConfig.get_team_count() if ShowConfig else 3
	for team_id in range(1, count + 1):
		fresh_state.scores[team_id] = 0
	fresh_state.phase = Enums.GamePhase.IDLE
	fresh_state.status_text = "Partida reiniciada"
	AppState.apply_game_state(fresh_state)
	# Clear used questions
	_used_question_ids.clear()
	_used_minigame_ids.clear()
	_current_question_index = -1
	_selected_round_name = ""
	_selected_question_id = 0
	_selected_minigame_id = 0
	emit_signal("presenter_selector_changed", _selected_round_name, _selected_question_id)
	emit_signal("used_questions_changed")
	# Delete session so next start is clean
	_delete_presenter_session_file()
	_publish_state(fresh_state)


func toggle_team_lock(team_id: int) -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	if not _is_valid_team_id(team_id):
		return
	if AppState.current_state.current_question.text.is_empty() or AppState.current_state.phase != Enums.GamePhase.QUESTION:
		return
	var state: GameState = AppState.current_state.duplicate_state()
	var next_locked: bool = not state.is_team_locked_out(team_id)
	state.locked_out_team_ids[team_id] = next_locked
	if next_locked and state.answer_authority_team_id == team_id:
		_set_answer_authority(state, 0)
		if state.buzzer_winner_team_id == team_id:
			state.buzzer_winner_team_id = 0
	state.status_text = "Equipo %d %s por decisión del presentador." % [
		team_id,
		"bloqueado" if next_locked else "rehabilitado",
	]
	AppState.apply_game_state(state)
	_save_presenter_session()
	_publish_state(state)


func force_active_team(team_id: int) -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	if not _is_valid_team_id(team_id):
		return
	if AppState.current_state.current_question.text.is_empty() or AppState.current_state.phase != Enums.GamePhase.QUESTION:
		return
	var state: GameState = AppState.current_state.duplicate_state()
	if state.answer_authority_team_id == team_id:
		_set_answer_authority(state, 0)
		if state.buzzer_winner_team_id == team_id:
			state.buzzer_winner_team_id = 0
		state.status_text = "Turno manual liberado. Pregunta abierta para todos."
		AppState.apply_game_state(state)
		_save_presenter_session()
		_publish_state(state)
		return
	if state.is_team_locked_out(team_id):
		state.locked_out_team_ids[team_id] = false
	_set_answer_authority(state, team_id)
	state.answers_enabled = true
	state.status_text = "Turno manual reservado para el equipo %d." % team_id
	AppState.apply_game_state(state)
	_save_presenter_session()
	_publish_state(state)


func adjust_score(team_id: int, delta: int) -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return

	var state: GameState = AppState.current_state.duplicate_state()
	var total: int = maxi(0, int(state.scores.get(team_id, 0)) + delta)
	state.scores[team_id] = total
	AppState.apply_game_state(state)
	MqttBus.publish_json(
		MessageTopics.POINTS,
		{"equipo": team_id, "total": total},
		false,
		COMMAND_QOS
	)
	_save_presenter_session()
	_publish_state(state)


func set_presenter_minigame(minigame_id: int) -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	var resolved_id: int = minigame_id
	var mg: MiniGame = ContentRepo.get_minigame_by_id(resolved_id)
	if mg.id <= 0:
		var all_minigames: Array[MiniGame] = ContentRepo.minigames
		if not all_minigames.is_empty():
			resolved_id = all_minigames[0].id
		else:
			resolved_id = 0
	if _selected_minigame_id == resolved_id:
		return
	_selected_minigame_id = resolved_id
	emit_signal("presenter_minigame_selector_changed", _selected_minigame_id)
	_save_presenter_session()


func load_selected_minigame() -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	var mg: MiniGame = ContentRepo.get_minigame_by_id(_selected_minigame_id)
	if mg.id <= 0:
		_publish_empty_presenter_state("No hay minijuegos cargados.")
		return
	var state: GameState = AppState.current_state.duplicate_state()
	state.phase = Enums.GamePhase.MINIGAME
	state.current_minigame = mg
	_set_answer_authority(state, 0)
	state.locked_team_id = 0
	state.locked_out_team_ids = _build_default_locks()
	state.answers_enabled = false
	state.revealed_correct_option = ""
	state.last_selected_option = ""
	state.answer_feedback_status = Enums.AnswerFeedbackStatus.NONE
	state.correction_applied = false
	state.buzzer_winner_team_id = 0
	state.rebote_excluded_team_ids = {}
	state.status_text = "Minijuego activo: %s" % mg.nombre
	_used_minigame_ids[mg.id] = true
	AppState.apply_game_state(state)
	_save_presenter_session()
	_publish_state(state)


func load_random_minigame() -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	var all_minigames: Array[MiniGame] = ContentRepo.minigames
	if all_minigames.is_empty():
		_publish_empty_presenter_state("No hay minijuegos cargados.")
		return
	var unused_minigames: Array[MiniGame] = []
	for mg_candidate: MiniGame in all_minigames:
		if not _used_minigame_ids.has(mg_candidate.id):
			unused_minigames.append(mg_candidate)
	var candidates: Array[MiniGame] = unused_minigames if not unused_minigames.is_empty() else all_minigames
	var random_index: int = _random.randi_range(0, candidates.size() - 1)
	var mg: MiniGame = candidates[random_index]
	_selected_minigame_id = mg.id
	emit_signal("presenter_minigame_selector_changed", _selected_minigame_id)
	var state: GameState = AppState.current_state.duplicate_state()
	state.phase = Enums.GamePhase.MINIGAME
	state.current_minigame = mg
	_set_answer_authority(state, 0)
	state.locked_team_id = 0
	state.locked_out_team_ids = _build_default_locks()
	state.answers_enabled = false
	state.revealed_correct_option = ""
	state.last_selected_option = ""
	state.answer_feedback_status = Enums.AnswerFeedbackStatus.NONE
	state.correction_applied = false
	state.buzzer_winner_team_id = 0
	state.rebote_excluded_team_ids = {}
	state.status_text = "Minijuego aleatorio: %s" % mg.nombre
	_used_minigame_ids[mg.id] = true
	AppState.apply_game_state(state)
	_save_presenter_session()
	_publish_state(state)


func is_minigame_used(mg_id: int) -> bool:
	return mg_id > 0 and _used_minigame_ids.has(mg_id)


func end_current_minigame() -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	var state: GameState = AppState.current_state.duplicate_state()
	state.phase = Enums.GamePhase.IDLE
	state.current_minigame = MiniGame.new()
	state.current_question = Question.new()
	state.answers_enabled = false
	state.answer_authority_team_id = 0
	state.active_team_id = 0
	state.locked_team_id = 0
	state.last_selected_option = ""
	state.revealed_correct_option = ""
	state.answer_feedback_status = Enums.AnswerFeedbackStatus.NONE
	state.correction_applied = false
	state.buzzer_winner_team_id = 0
	state.rebote_excluded_team_ids = {}
	state.status_text = "Minijuego finalizado"
	AppState.apply_game_state(state)
	_save_presenter_session()
	_publish_state(state)


func activate_rebote() -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	var state: GameState = AppState.current_state.duplicate_state()
	if state.phase != Enums.GamePhase.LOCKED:
		return
	if state.answer_feedback_status != Enums.AnswerFeedbackStatus.INCORRECT:
		return
	if _teams_available_for_rebote(state) == 0:
		return
	state.phase = Enums.GamePhase.QUESTION
	state.answers_enabled = true
	_set_answer_authority(state, 0)
	state.locked_team_id = 0
	state.last_selected_option = ""
	state.revealed_correct_option = ""
	state.answer_feedback_status = Enums.AnswerFeedbackStatus.NONE
	state.correction_applied = false
	state.buzzer_winner_team_id = 0
	state.pending_score_delta = {}
	state.status_text = "🔄 Rebote activado — equipos excluidos no pueden pulsar."
	AppState.apply_game_state(state)
	_save_presenter_session()
	_publish_state(state)


func get_selected_minigame_id() -> int:
	return _selected_minigame_id


func get_selected_minigame() -> MiniGame:
	if _selected_minigame_id <= 0:
		return MiniGame.new()
	return ContentRepo.get_minigame_by_id(_selected_minigame_id)


func submit_answer(option: String) -> void:
	if AppState.selected_role != Enums.AppRole.CONTESTANT:
		return
	if AppState.selected_team_id <= 0:
		return
	if not AppState.current_state.can_team_answer(AppState.selected_team_id):
		return

	MqttBus.publish_json(
		MessageTopics.ANSWER,
		{
			"equipo": AppState.selected_team_id,
			"opcion": option,
		},
		false,
		COMMAND_QOS
	)


func submit_buzzer() -> void:
	if AppState.selected_role != Enums.AppRole.CONTESTANT:
		return
	if AppState.selected_team_id <= 0:
		return
	if not _can_buzz():
		return

	MqttBus.publish_json(
		MessageTopics.BUZZER,
		{"equipo": AppState.selected_team_id},
		false,
		COMMAND_QOS
	)


func _publish_state(state: GameState) -> void:
	_pending_presenter_snapshot_publish = false
	MqttBus.publish_json(
		MessageTopics.STATE,
		MessageCodec.game_state_to_wire(state),
		SNAPSHOT_RETAIN,
		SNAPSHOT_QOS
	)


func _on_mqtt_message_received(topic: String, payload: Variant) -> void:
	match topic:
		MessageTopics.STATE:
			if AppState.selected_role == Enums.AppRole.PRESENTER:
				return
			if typeof(payload) == TYPE_DICTIONARY:
				AppState.apply_game_state(MessageCodec.game_state_from_wire(payload))
		MessageTopics.POINTS:
			if AppState.selected_role == Enums.AppRole.PRESENTER:
				return
			if typeof(payload) != TYPE_DICTIONARY:
				return
			var team_id: int = int(payload.get("equipo", 0))
			if not _is_valid_team_id(team_id):
				push_warning("POINTS: equipo inválido (%d) — descartado" % team_id)
				return
			var state: GameState = AppState.current_state.duplicate_state()
			state.scores[team_id] = maxi(0, int(payload.get("total", 0)))
			AppState.apply_game_state(state)
		MessageTopics.ANSWER:
			if AppState.selected_role != Enums.AppRole.PRESENTER:
				return
			if typeof(payload) != TYPE_DICTIONARY:
				return
			var state: GameState = AppState.current_state.duplicate_state()
			if state.phase != Enums.GamePhase.QUESTION or not state.answers_enabled:
				return
			var answering_team_id: int = int(payload.get("equipo", 0))
			if not _is_valid_team_id(answering_team_id):
				push_warning("ANSWER: equipo inválido (%d) — descartado" % answering_team_id)
				return
			if not state.can_team_answer(answering_team_id):
				return
			var selected_option: String = String(payload.get("opcion", "")).to_upper()
			if selected_option.is_empty():
				return

			# ── Auto-judge ─────────────────────────────────────────
			var correct_option: String = state.current_question.correct_option.to_upper()
			var is_correct: bool = false
			if correct_option.is_empty():
				# Malformed question — skip auto-judge, let presenter decide
				is_correct = false
				state.correction_applied = false
				state.status_text = "⚠️ Pregunta sin respuesta correcta definida — corregir manualmente"
			else:
				is_correct = (selected_option == correct_option)
				state.correction_applied = true

			state.phase = Enums.GamePhase.LOCKED
			state.answers_enabled = false
			_set_answer_authority(state, 0)
			state.locked_team_id = answering_team_id
			state.last_selected_option = selected_option

			if is_correct:
				state.answer_feedback_status = Enums.AnswerFeedbackStatus.CORRECT
				var points: int = _get_points_correct()
				state.pending_score_delta[answering_team_id] = points
				state.status_text = "✅ Equipo %d respondió %s — CORRECTA (+%d)" % [answering_team_id, selected_option, points]
				AppState.apply_game_state(state)
				_save_presenter_session()
				_publish_state(state)
				emit_signal("answer_received", answering_team_id, selected_option)
			else:
				state.answer_feedback_status = Enums.AnswerFeedbackStatus.INCORRECT
				state.rebote_excluded_team_ids[answering_team_id] = true
				var penalty: int = _get_points_incorrect()
				if penalty != 0:
					state.pending_score_delta[answering_team_id] = penalty
				state.status_text = "❌ Equipo %d respondió %s — INCORRECTA (correcta: %s)" % [answering_team_id, selected_option, correct_option]
				AppState.apply_game_state(state)
				_save_presenter_session()
				_publish_state(state)
				emit_signal("answer_received", answering_team_id, selected_option)
		MessageTopics.TABLET_LOCK:
			if AppState.selected_role == Enums.AppRole.PRESENTER:
				return
			if typeof(payload) != TYPE_BOOL:
				return
			var lock_state: GameState = AppState.current_state.duplicate_state()
			lock_state.answers_enabled = not payload
			if payload and lock_state.phase == Enums.GamePhase.QUESTION:
				lock_state.status_text = "Respuesta en tablets pausada por comando externo."
			elif lock_state.phase == Enums.GamePhase.QUESTION:
				lock_state.status_text = "Respuesta en tablets reabierta por comando externo."
			AppState.apply_game_state(lock_state)
		MessageTopics.BUZZER:
			_on_buzzer_message(payload)


func _on_questions_loaded(_count: int) -> void:
	_ensure_presenter_selection()
	if AppState.selected_role == Enums.AppRole.PRESENTER:
		_sync_persisted_question_reference()
		if AppState.current_state.current_question.text.is_empty():
			var state: GameState = AppState.current_state.duplicate_state()
			state.status_text = "%d preguntas listas en %d rondas" % [
				ContentRepo.get_question_count(),
				ContentRepo.get_rounds().size(),
			]
			AppState.apply_game_state(state)
		return
	if AppState.current_state.status_text.is_empty():
		var state: GameState = AppState.current_state.duplicate_state()
		state.status_text = "Contenido listo" if ContentRepo.get_question_count() > 0 else "Esperando preguntas"
		AppState.apply_game_state(state)


func _on_content_missing(_path: String) -> void:
	var state: GameState = AppState.current_state.duplicate_state()
	state.status_text = "No se encontró preguntas.json; se muestra contenido vacío"
	AppState.apply_game_state(state)
	_update_presenter_selector("", 0)


func _on_minigames_loaded(_count: int) -> void:
	if AppState.selected_role == Enums.AppRole.PRESENTER:
		if _selected_minigame_id > 0:
			var mg: MiniGame = ContentRepo.get_minigame_by_id(_selected_minigame_id)
			if mg.id <= 0:
				_selected_minigame_id = 0
				emit_signal("presenter_minigame_selector_changed", 0)


func _ensure_presenter_selection() -> bool:
	var available_rounds: PackedStringArray = ContentRepo.get_rounds()
	if available_rounds.is_empty():
		_update_presenter_selector("", 0)
		return false
	var resolved_round: String = _selected_round_name
	if not available_rounds.has(resolved_round):
		resolved_round = available_rounds[0]
	var questions_in_round: Array[Question] = ContentRepo.get_questions_for_round(resolved_round)
	if questions_in_round.is_empty():
		_update_presenter_selector(resolved_round, 0)
		return false
	var resolved_question_id: int = _selected_question_id
	if _question_index_in(questions_in_round, resolved_question_id) == -1:
		resolved_question_id = questions_in_round[0].id
	_update_presenter_selector(resolved_round, resolved_question_id)
	return true


func _question_index_in(questions_in_round: Array[Question], question_id: int) -> int:
	for index in range(questions_in_round.size()):
		if questions_in_round[index].id == question_id:
			return index
	return -1


func _update_presenter_selector(round_name: String, question_id: int) -> void:
	if _selected_round_name == round_name and _selected_question_id == question_id:
		return
	_selected_round_name = round_name
	_selected_question_id = question_id
	emit_signal("presenter_selector_changed", _selected_round_name, _selected_question_id)
	_save_presenter_session()


func _publish_empty_presenter_state(message: String) -> void:
	var empty_state: GameState = GameState.new()
	empty_state.phase = Enums.GamePhase.IDLE
	empty_state.status_text = message
	AppState.apply_game_state(empty_state)
	_save_presenter_session()
	_publish_state(empty_state)


func _apply_presenter_question(question: Question, status_text: String) -> void:
	var state: GameState = AppState.current_state.duplicate_state()
	state.phase = Enums.GamePhase.QUESTION
	state.current_question = question
	_set_answer_authority(state, 0)
	state.locked_team_id = 0
	state.locked_out_team_ids = _build_default_locks()
	state.answers_enabled = true
	state.revealed_correct_option = ""
	state.last_selected_option = ""
	state.answer_feedback_status = Enums.AnswerFeedbackStatus.NONE
	state.correction_applied = false
	state.buzzer_winner_team_id = 0
	state.rebote_excluded_team_ids = {}
	state.pending_score_delta = {}
	state.status_text = status_text
	if question.id > 0:
		_used_question_ids[question.id] = true
	_current_question_index = _selected_question_id
	AppState.apply_game_state(state)
	emit_signal("used_questions_changed")
	_save_presenter_session()
	_publish_state(state)


func _pick_random_question(questions_in_round: Array[Question]) -> Question:
	var unused_questions: Array[Question] = []
	for question in questions_in_round:
		if not is_question_used(question.id):
			unused_questions.append(question)
	var candidate_questions: Array[Question] = unused_questions if not unused_questions.is_empty() else questions_in_round
	var random_index: int = _random.randi_range(0, candidate_questions.size() - 1)
	return candidate_questions[random_index]


func _restore_presenter_session() -> void:
	var restored_state: GameState = GameState.new()
	var did_restore: bool = false
	_current_question_index = -1
	_selected_round_name = ""
	_selected_question_id = 0
	_selected_minigame_id = 0
	_used_question_ids.clear()
	_used_minigame_ids.clear()

	if FileAccess.file_exists(PRESENTER_SESSION_SAVE_PATH):
		var file: FileAccess = FileAccess.open(PRESENTER_SESSION_SAVE_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				var payload: Dictionary = parsed
				_selected_round_name = String(payload.get("selected_round_name", ""))
				_selected_question_id = int(payload.get("selected_question_id", 0))
				_selected_minigame_id = int(payload.get("selected_minigame_id", 0))
				for question_id in payload.get("used_question_ids", []):
					var normalized_id: int = int(question_id)
					if normalized_id > 0:
						_used_question_ids[normalized_id] = true
				for mg_id in payload.get("used_minigame_ids", []):
					var normalized_mg_id: int = int(mg_id)
					if normalized_mg_id > 0:
						_used_minigame_ids[normalized_mg_id] = true
				restored_state = GameState.from_dict(Dictionary(payload.get("game_state", {})))
				did_restore = true

	_sync_persisted_question_reference(restored_state)

	if did_restore:
		if restored_state.status_text.is_empty():
			restored_state.status_text = "Sesión local recuperada"
		else:
			restored_state.status_text = "Sesión local recuperada · %s" % restored_state.status_text

	AppState.apply_game_state(restored_state)
	_ensure_presenter_selection()
	emit_signal("presenter_selector_changed", _selected_round_name, _selected_question_id)
	emit_signal("used_questions_changed")

	if did_restore:
		_publish_or_defer_presenter_state(restored_state)


func _save_presenter_session() -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	if not _can_persist_presenter_session:
		return
	var file: FileAccess = FileAccess.open(PRESENTER_SESSION_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo persistir la sesión del presentador en %s" % PRESENTER_SESSION_SAVE_PATH)
		return
	file.store_string(JSON.stringify(_presenter_session_to_dict()))


func _presenter_session_to_dict() -> Dictionary:
	return {
		"version": 1,
		"selected_round_name": _selected_round_name,
		"selected_question_id": _selected_question_id,
		"selected_minigame_id": _selected_minigame_id,
		"used_question_ids": _used_question_ids.keys(),
		"used_minigame_ids": _used_minigame_ids.keys(),
		"game_state": AppState.current_state.to_dict(),
	}


func _delete_presenter_session_file() -> void:
	if not FileAccess.file_exists(PRESENTER_SESSION_SAVE_PATH):
		return
	var user_dir: DirAccess = DirAccess.open("user://")
	if user_dir == null:
		return
	user_dir.remove("presenter_session.json")


func _publish_or_defer_presenter_state(state: GameState) -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	if MqttBus.is_broker_connected():
		_publish_state(state)
		return
	_pending_presenter_snapshot_publish = true


func _on_mqtt_connected() -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER or not _pending_presenter_snapshot_publish:
		return
	_publish_state(AppState.current_state)


func _sync_persisted_question_reference(state: GameState = AppState.current_state) -> void:
	if state.current_question.id <= 0:
		return
	var repo_question: Question = ContentRepo.get_question_by_id(state.current_question.id)
	if repo_question.text.is_empty():
		return
	state.current_question = repo_question
	# Caller is responsible for calling apply_game_state()


func teams_available_for_rebote() -> int:
	return _teams_available_for_rebote(AppState.current_state)


func _is_valid_team_id(team_id: int) -> bool:
	return _get_team_ids().has(team_id)


func _teams_available_for_rebote(state: GameState) -> int:
	var count: int = 0
	for tid in _get_team_ids():
		if not state.is_team_excluded_from_rebote(tid) and not state.is_team_locked_out(tid):
			count += 1
	return count


func _can_buzz() -> bool:
	return AppState.current_state.phase == Enums.GamePhase.QUESTION \
		and AppState.current_state.answers_enabled \
		and AppState.current_state.answer_authority_team_id == 0 \
		and not AppState.current_state.is_team_locked_out(AppState.selected_team_id) \
		and not AppState.current_state.is_team_excluded_from_rebote(AppState.selected_team_id) \
		and AppState.current_state.locked_team_id == 0


func _on_buzzer_message(payload: Variant) -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	if typeof(payload) != TYPE_DICTIONARY:
		return
	var state: GameState = AppState.current_state.duplicate_state()
	if state.phase != Enums.GamePhase.QUESTION or not state.answers_enabled or state.answer_authority_team_id != 0:
		return
	var team_id: int = int(payload.get("equipo", 0))
	if not _is_valid_team_id(team_id):
		return
	if state.is_team_locked_out(team_id):
		return
	if state.is_team_excluded_from_rebote(team_id):
		return
	state.buzzer_winner_team_id = team_id
	_set_answer_authority(state, team_id)
	state.status_text = "Equipo %d pulsó primero. Esperando respuesta." % team_id
	AppState.apply_game_state(state)
	_save_presenter_session()
	_publish_state(state)


func _set_answer_authority(state: GameState, team_id: int) -> void:
	if team_id > 0:
		state.rebote_excluded_team_ids.erase(team_id)
	state.answer_authority_team_id = team_id
	state.active_team_id = team_id
