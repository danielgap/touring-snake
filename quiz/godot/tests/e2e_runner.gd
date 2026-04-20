extends SceneTree

var _role: String = ""
var _team_id: int = 0
var _answer_sent: bool = false
var _start_time: int = 0


func _app_state() -> Node:
	return root.get_node("AppState")


func _game_service() -> Node:
	return root.get_node("GameService")


func _mqtt_bus() -> Node:
	return root.get_node("MqttBus")


func _initialize() -> void:
	_start_time = Time.get_ticks_msec()
	var args: Dictionary = _parse_args(OS.get_cmdline_user_args())
	_role = String(args.get("role", "")).to_lower()
	_team_id = int(args.get("team", 1))

	print("E2E runner starting role=%s team=%d" % [_role, _team_id])

	if _role.is_empty():
		push_error("Missing --role argument")
		quit(2)
		return

	_app_state().game_state_changed.connect(_on_game_state_changed)
	_game_service().answer_received.connect(_on_presenter_answer_received)
	_mqtt_bus().connected.connect(_on_connected)
	_mqtt_bus().disconnected.connect(_on_disconnected)
	_mqtt_bus().connection_error.connect(_on_connection_error)

	match _role:
		"presenter":
			_game_service().initialize_role(Enums.AppRole.PRESENTER, 0)
			call_deferred("_run_presenter_flow")
		"contestant":
			_game_service().initialize_role(Enums.AppRole.CONTESTANT, _team_id)
			call_deferred("_schedule_timeout", 8000)
		"display":
			_game_service().initialize_role(Enums.AppRole.DISPLAY, 0)
			call_deferred("_schedule_timeout", 8000)
		_:
			push_error("Unknown role: %s" % _role)
			quit(2)


func _parse_args(args: PackedStringArray) -> Dictionary:
	var parsed: Dictionary = {}
	var i: int = 0
	while i < args.size():
		var token: String = args[i]
		if token.begins_with("--") and i + 1 < args.size():
			parsed[token.trim_prefix("--")] = args[i + 1]
			i += 2
		else:
			i += 1
	return parsed


func _run_presenter_flow() -> void:
	await create_timer(1.5).timeout
	print("PRESENTER: starting next question")
	_game_service().start_next_question()
	await create_timer(2.5).timeout
	print("PRESENTER: revealing answer")
	_game_service().reveal_current_answer()
	await create_timer(0.5).timeout
	print("PRESENTER: adding score to team 1")
	_game_service().adjust_score(1, 100)
	await create_timer(1.0).timeout
	_schedule_timeout(0)


func _on_game_state_changed(state: GameState) -> void:
	print(
		"STATE role=%s phase=%s locked_team=%d answers_enabled=%s revealed=%s status=%s score1=%d" % [
			_role,
			Enums.phase_name(state.phase),
			state.locked_team_id,
			str(state.answers_enabled),
			state.revealed_correct_option,
			state.status_text,
			int(state.scores.get(1, 0)),
		]
	)

	if _role == "contestant" and state.phase == Enums.GamePhase.QUESTION and state.answers_enabled and not _answer_sent:
		_answer_sent = true
		print("CONTESTANT: submitting answer A")
		_game_service().submit_answer("A")


func _on_presenter_answer_received(team_id: int, option: String) -> void:
	print("PRESENTER: received answer team=%d option=%s" % [team_id, option])


func _on_connected() -> void:
	print("MQTT connected role=%s" % _role)


func _on_disconnected() -> void:
	print("MQTT disconnected role=%s" % _role)


func _on_connection_error(reason: String) -> void:
	print("MQTT error role=%s reason=%s" % [_role, reason])


func _schedule_timeout(delay_ms: int) -> void:
	if delay_ms > 0:
		await create_timer(float(delay_ms) / 1000.0).timeout
	var elapsed: int = Time.get_ticks_msec() - _start_time
	print("E2E runner exiting role=%s elapsed_ms=%d" % [_role, elapsed])
	quit()
