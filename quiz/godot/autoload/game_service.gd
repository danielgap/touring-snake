extends Node

signal role_initialized(role: int)
signal answer_received(team_id: int, option: String)
signal presenter_selector_changed(round_name: String, question_id: int)
signal used_questions_changed()

const MQTT_HOST: String = "127.0.0.1"
const MQTT_PORT: int = 1883
const SNAPSHOT_QOS: int = 1
const COMMAND_QOS: int = 1
const SNAPSHOT_RETAIN: bool = true
const PRESENTER_SESSION_SAVE_PATH: String = "user://presenter_session.json"
const TEAM_IDS: Array[int] = [1, 2, 3]

var _current_question_index: int = -1
var _selected_round_name: String = ""
var _selected_question_id: int = 0
var _used_question_ids: Dictionary = {}
var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _can_persist_presenter_session: bool = false
var _pending_presenter_snapshot_publish: bool = false


func _ready() -> void:
	_random.randomize()
	MqttBus.message_received.connect(_on_mqtt_message_received)
	MqttBus.connected.connect(_on_mqtt_connected)
	ContentRepo.questions_loaded.connect(_on_questions_loaded)
	ContentRepo.content_missing.connect(_on_content_missing)


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
	if ShowConfig:
		return ShowConfig.get_points_incorrect()
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
	emit_signal("role_initialized", role)


func start_next_question() -> void:
	load_random_question_from_selected_round()


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


func load_random_question_from_selected_round() -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	if not _ensure_presenter_selection():
		_publish_empty_presenter_state("No hay preguntas cargadas todavía.")
		return
	var questions_in_round: Array[Question] = ContentRepo.get_questions_for_round(_selected_round_name)
	if questions_in_round.is_empty():
		_publish_empty_presenter_state("La ronda seleccionada no tiene preguntas disponibles.")
		return
	var selected_question: Question = _pick_random_question(questions_in_round)
	_update_presenter_selector(_selected_round_name, selected_question.id)
	_apply_presenter_question(selected_question, "Pregunta aleatoria cargada de %s" % _selected_round_name)


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
	if AppState.current_state.phase == Enums.GamePhase.LOCKED \
		and AppState.current_state.locked_team_id > 0 \
		and not AppState.current_state.correction_applied:
		var blocked_state: GameState = AppState.current_state.duplicate_state()
		blocked_state.status_text = "Primero marcá la respuesta tomada como correcta o incorrecta."
		AppState.apply_game_state(blocked_state)
		return

	var state: GameState = AppState.current_state.duplicate_state()
	state.phase = Enums.GamePhase.REVEAL
	state.answers_enabled = false
	state.revealed_correct_option = state.current_question.correct_option
	state.status_text = "Respuesta correcta mostrada en pantalla"
	AppState.apply_game_state(state)
	_save_presenter_session()
	_publish_state(state)


func mark_locked_answer_correct() -> void:
	_set_locked_answer_feedback(Enums.AnswerFeedbackStatus.CORRECT)


func mark_locked_answer_incorrect() -> void:
	_set_locked_answer_feedback(Enums.AnswerFeedbackStatus.INCORRECT)


func reopen_current_question() -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	if AppState.current_state.current_question.text.is_empty():
		return
	var state: GameState = AppState.current_state.duplicate_state()
	state.phase = Enums.GamePhase.QUESTION
	state.answers_enabled = true
	state.active_team_id = 0
	state.locked_team_id = 0
	state.revealed_correct_option = ""
	state.last_selected_option = ""
	state.answer_feedback_status = Enums.AnswerFeedbackStatus.NONE
	state.correction_applied = false
	state.status_text = "Ronda reabierta. Se limpió la respuesta tomada."
	AppState.apply_game_state(state)
	_save_presenter_session()
	_publish_state(state)


func reset_team_locks() -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	var state: GameState = AppState.current_state.duplicate_state()
	for team_id in TEAM_IDS:
		state.locked_out_team_ids[team_id] = false
	state.active_team_id = 0
	state.locked_team_id = 0
	state.last_selected_option = ""
	state.answer_feedback_status = Enums.AnswerFeedbackStatus.NONE
	state.correction_applied = false
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
	if next_locked and state.active_team_id == team_id:
		state.active_team_id = 0
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
	if state.active_team_id == team_id:
		state.active_team_id = 0
		state.status_text = "Turno manual liberado. Pregunta abierta para todos."
		AppState.apply_game_state(state)
		_save_presenter_session()
		_publish_state(state)
		return
	if state.is_team_locked_out(team_id):
		state.locked_out_team_ids[team_id] = false
	state.active_team_id = team_id
	state.answers_enabled = true
	state.status_text = "Turno manual reservado para el equipo %d." % team_id
	AppState.apply_game_state(state)
	_save_presenter_session()
	_publish_state(state)


func adjust_score(team_id: int, delta: int) -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return

	var state: GameState = AppState.current_state.duplicate_state()
	var total: int = int(state.scores.get(team_id, 0)) + delta
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
			if typeof(payload) != TYPE_DICTIONARY:
				return
			var state: GameState = AppState.current_state.duplicate_state()
			var team_id: int = int(payload.get("equipo", 0))
			state.scores[team_id] = int(payload.get("total", 0))
			AppState.apply_game_state(state)
		MessageTopics.ANSWER:
			if AppState.selected_role != Enums.AppRole.PRESENTER:
				return
			if typeof(payload) != TYPE_DICTIONARY:
				return
			var state: GameState = AppState.current_state.duplicate_state()
			if state.phase != Enums.GamePhase.QUESTION or not state.answers_enabled or not state.last_selected_option.is_empty():
				return
			state.locked_team_id = int(payload.get("equipo", 0))
			if state.locked_team_id <= 0:
				return
			if not state.can_team_answer(state.locked_team_id):
				return
			state.phase = Enums.GamePhase.LOCKED
			state.answers_enabled = false
			state.active_team_id = state.locked_team_id
			state.last_selected_option = String(payload.get("opcion", ""))
			state.answer_feedback_status = Enums.AnswerFeedbackStatus.PENDING
			state.correction_applied = false
			state.status_text = "Equipo %d respondió primero. Pregunta cerrada hasta corrección." % state.locked_team_id
			AppState.apply_game_state(state)
			emit_signal("answer_received", state.locked_team_id, state.last_selected_option)
			_save_presenter_session()
			_publish_state(state)
		MessageTopics.TABLET_LOCK:
			if typeof(payload) != TYPE_BOOL:
				return
			var lock_state: GameState = AppState.current_state.duplicate_state()
			lock_state.answers_enabled = not payload
			if payload and lock_state.phase == Enums.GamePhase.QUESTION:
				lock_state.status_text = "Respuesta en tablets pausada por comando externo."
			elif lock_state.phase == Enums.GamePhase.QUESTION:
				lock_state.status_text = "Respuesta en tablets reabierta por comando externo."
			AppState.apply_game_state(lock_state)


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
	state.active_team_id = 0
	state.locked_team_id = 0
	state.locked_out_team_ids = {1: false, 2: false, 3: false}
	state.answers_enabled = true
	state.revealed_correct_option = ""
	state.last_selected_option = ""
	state.answer_feedback_status = Enums.AnswerFeedbackStatus.NONE
	state.correction_applied = false
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
	_used_question_ids.clear()

	if FileAccess.file_exists(PRESENTER_SESSION_SAVE_PATH):
		var file: FileAccess = FileAccess.open(PRESENTER_SESSION_SAVE_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				var payload: Dictionary = parsed
				_selected_round_name = String(payload.get("selected_round_name", ""))
				_selected_question_id = int(payload.get("selected_question_id", 0))
				for question_id in payload.get("used_question_ids", []):
					var normalized_id: int = int(question_id)
					if normalized_id > 0:
						_used_question_ids[normalized_id] = true
				restored_state = GameState.from_dict(Dictionary(payload.get("game_state", {})))
				did_restore = true

	_sync_persisted_question_reference(restored_state)
	AppState.apply_game_state(restored_state)
	_ensure_presenter_selection()
	emit_signal("presenter_selector_changed", _selected_round_name, _selected_question_id)
	emit_signal("used_questions_changed")

	if did_restore:
		if restored_state.status_text.is_empty():
			restored_state.status_text = "Sesión local recuperada"
		else:
			restored_state.status_text = "Sesión local recuperada · %s" % restored_state.status_text
		AppState.apply_game_state(restored_state)
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
		"used_question_ids": _used_question_ids.keys(),
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


func _set_locked_answer_feedback(feedback_status: int) -> void:
	if AppState.selected_role != Enums.AppRole.PRESENTER:
		return
	var state: GameState = AppState.current_state.duplicate_state()
	if state.phase != Enums.GamePhase.LOCKED or state.locked_team_id <= 0:
		return
	state.answer_feedback_status = feedback_status
	state.correction_applied = true
	state.status_text = "Equipo %d marcado %s" % [
		state.locked_team_id,
		Enums.answer_feedback_name(feedback_status).to_lower(),
	]
	AppState.apply_game_state(state)
	_save_presenter_session()
	_publish_state(state)


func _is_valid_team_id(team_id: int) -> bool:
	return TEAM_IDS.has(team_id)
