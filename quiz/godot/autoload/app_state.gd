extends Node

signal role_changed(role: int)
signal team_id_changed(team_id: int)
signal game_state_changed(game_state: GameState)
signal scores_changed(scores: Dictionary)

var selected_role: int = Enums.AppRole.NONE
var selected_team_id: int = 0
var current_state: GameState = GameState.new()


func _ready() -> void:
	current_state = GameState.new()


func set_role(role: int) -> void:
	if selected_role == role:
		return
	selected_role = role
	emit_signal("role_changed", selected_role)


func set_team_id(team_id: int) -> void:
	if selected_team_id == team_id:
		return
	selected_team_id = team_id
	emit_signal("team_id_changed", selected_team_id)


func apply_game_state(game_state: GameState) -> void:
	current_state = game_state
	emit_signal("game_state_changed", current_state)
	emit_signal("scores_changed", current_state.scores.duplicate(true))


func reset_scores() -> void:
	current_state.scores = {1: 0, 2: 0, 3: 0}
	emit_signal("scores_changed", current_state.scores.duplicate(true))
	emit_signal("game_state_changed", current_state)


func set_score(team_id: int, total: int) -> void:
	current_state.scores[team_id] = total
	emit_signal("scores_changed", current_state.scores.duplicate(true))
	emit_signal("game_state_changed", current_state)
