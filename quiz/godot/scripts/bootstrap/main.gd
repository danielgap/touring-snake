extends Control

const PRESENTER_SCENE: PackedScene = preload("res://scenes/presenter/presenter_root.tscn")
const CONTESTANT_SCENE: PackedScene = preload("res://scenes/contestant/contestant_root.tscn")
const DISPLAY_SCENE: PackedScene = preload("res://scenes/display/display_root.tscn")

@onready var role_select = $RoleSelect
@onready var active_root: Control = $ActiveRoot

var _current_role_scene: Control = null
var _e2e_role: String = ""
var _e2e_team_id: int = 1
var _e2e_answer_sent: bool = false


func _ready() -> void:
	role_select.role_selected.connect(_on_role_selected)
	AppState.game_state_changed.connect(_on_game_state_changed)
	GameService.answer_received.connect(_on_presenter_answer_received)
	MqttBus.connected.connect(_on_mqtt_connected)
	MqttBus.disconnected.connect(_on_mqtt_disconnected)
	MqttBus.connection_error.connect(_on_mqtt_error)
	_try_start_e2e_from_args()


func _on_role_selected(role: int, team_id: int) -> void:
	_swap_role_scene(role)
	GameService.initialize_role(role, team_id)
	role_select.visible = false


func _swap_role_scene(role: int) -> void:
	if _current_role_scene != null:
		_current_role_scene.queue_free()

	var scene: PackedScene = _scene_for_role(role)
	_current_role_scene = scene.instantiate() as Control
	active_root.add_child(_current_role_scene)


func _scene_for_role(role: int) -> PackedScene:
	match role:
		Enums.AppRole.PRESENTER:
			return PRESENTER_SCENE
		Enums.AppRole.CONTESTANT:
			return CONTESTANT_SCENE
		Enums.AppRole.DISPLAY:
			return DISPLAY_SCENE
		_:
			return DISPLAY_SCENE


func _try_start_e2e_from_args() -> void:
	var args: Dictionary = _parse_user_args(OS.get_cmdline_user_args())
	if not args.has("role"):
		return

	_e2e_role = String(args.get("role", "")).to_lower()
	_e2e_team_id = int(args.get("team", 1))
	print("E2E bootstrap role=%s team=%d" % [_e2e_role, _e2e_team_id])

	match _e2e_role:
		"presenter":
			_on_role_selected(Enums.AppRole.PRESENTER, 0)
			_run_presenter_e2e()
		"contestant":
			_on_role_selected(Enums.AppRole.CONTESTANT, _e2e_team_id)
			_schedule_quit(8000)
		"display":
			_on_role_selected(Enums.AppRole.DISPLAY, 0)
			_schedule_quit(8000)
		_:
			push_warning("Unknown E2E role: %s" % _e2e_role)


func _parse_user_args(args: PackedStringArray) -> Dictionary:
	var parsed: Dictionary = {}
	var index: int = 0
	while index < args.size():
		var token: String = args[index]
		if token.begins_with("--") and index + 1 < args.size():
			parsed[token.trim_prefix("--")] = args[index + 1]
			index += 2
		else:
			index += 1
	return parsed


func _run_presenter_e2e() -> void:
	await get_tree().create_timer(1.5).timeout
	print("E2E presenter: start_next_question")
	GameService.start_next_question()
	await get_tree().create_timer(2.5).timeout
	print("E2E presenter: reveal_current_answer")
	GameService.reveal_current_answer()
	await get_tree().create_timer(0.5).timeout
	print("E2E presenter: adjust_score team=1 delta=100")
	GameService.adjust_score(1, 100)
	await get_tree().create_timer(1.0).timeout
	_schedule_quit(0)


func _schedule_quit(delay_ms: int) -> void:
	if delay_ms > 0:
		await get_tree().create_timer(float(delay_ms) / 1000.0).timeout
	print("E2E exiting role=%s" % _e2e_role)
	get_tree().quit()


func _on_game_state_changed(state: GameState) -> void:
	if _e2e_role.is_empty():
		return

	print(
		"E2E state role=%s phase=%s locked_team=%d enabled=%s revealed=%s status=%s score1=%d" % [
			_e2e_role,
			Enums.phase_name(state.phase),
			state.locked_team_id,
			str(state.answers_enabled),
			state.revealed_correct_option,
			state.status_text,
			int(state.scores.get(1, 0)),
		]
	)

	if _e2e_role == "contestant" and state.phase == Enums.GamePhase.QUESTION and state.answers_enabled and not _e2e_answer_sent:
		_e2e_answer_sent = true
		print("E2E contestant: submit_answer A")
		GameService.submit_answer("A")


func _on_presenter_answer_received(team_id: int, option: String) -> void:
	if _e2e_role == "presenter":
		print("E2E presenter received answer team=%d option=%s" % [team_id, option])


func _on_mqtt_connected() -> void:
	if not _e2e_role.is_empty():
		print("E2E mqtt connected role=%s" % _e2e_role)


func _on_mqtt_disconnected() -> void:
	if not _e2e_role.is_empty():
		print("E2E mqtt disconnected role=%s" % _e2e_role)


func _on_mqtt_error(reason: String) -> void:
	if not _e2e_role.is_empty():
		print("E2E mqtt error role=%s reason=%s" % [_e2e_role, reason])
