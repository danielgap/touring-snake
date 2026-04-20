class_name GameState
extends RefCounted

var phase: int = Enums.GamePhase.IDLE
var current_question: Question = Question.new()
var scores: Dictionary = {1: 0, 2: 0, 3: 0}
var answers_enabled: bool = false
var active_team_id: int = 0
var locked_team_id: int = 0
var locked_out_team_ids: Dictionary = {1: false, 2: false, 3: false}
var revealed_correct_option: String = ""
var last_selected_option: String = ""
var answer_feedback_status: int = Enums.AnswerFeedbackStatus.NONE
var correction_applied: bool = false
var status_text: String = "Esperando inicialización"


func to_dict() -> Dictionary:
	return {
		"phase": phase,
		"current_question": current_question.to_dict(),
		"scores": scores.duplicate(true),
		"answers_enabled": answers_enabled,
		"active_team_id": active_team_id,
		"locked_team_id": locked_team_id,
		"locked_out_team_ids": locked_out_team_ids.duplicate(true),
		"revealed_correct_option": revealed_correct_option,
		"last_selected_option": last_selected_option,
		"answer_feedback_status": answer_feedback_status,
		"correction_applied": correction_applied,
		"status_text": status_text,
	}


static func from_dict(data: Dictionary) -> GameState:
	var state: GameState = GameState.new()
	state.phase = int(data.get("phase", Enums.GamePhase.IDLE))
	state.current_question = Question.from_dict(Dictionary(data.get("current_question", {})))
	state.scores = _normalize_scores(Dictionary(data.get("scores", {1: 0, 2: 0, 3: 0})))
	state.answers_enabled = bool(data.get("answers_enabled", false))
	state.active_team_id = int(data.get("active_team_id", 0))
	state.locked_team_id = int(data.get("locked_team_id", 0))
	state.locked_out_team_ids = _normalize_locked_out_team_ids(Dictionary(data.get("locked_out_team_ids", {1: false, 2: false, 3: false})))
	state.revealed_correct_option = String(data.get("revealed_correct_option", ""))
	state.last_selected_option = String(data.get("last_selected_option", ""))
	state.answer_feedback_status = int(data.get("answer_feedback_status", Enums.AnswerFeedbackStatus.NONE))
	state.correction_applied = bool(data.get("correction_applied", false))
	state.status_text = String(data.get("status_text", "Esperando inicialización"))
	return state


func duplicate_state() -> GameState:
	return GameState.from_dict(to_dict())


func is_team_locked_out(team_id: int) -> bool:
	return bool(locked_out_team_ids.get(team_id, false))


func team_lock_state(team_id: int) -> int:
	if phase == Enums.GamePhase.LOCKED:
		if team_id == active_team_id and active_team_id > 0:
			return Enums.TeamLockState.ACTIVE
		return Enums.TeamLockState.FROZEN
	if team_id == active_team_id and active_team_id > 0:
		return Enums.TeamLockState.ACTIVE
	if is_team_locked_out(team_id):
		return Enums.TeamLockState.LOCKED_OUT
	return Enums.TeamLockState.READY


func can_team_answer(team_id: int) -> bool:
	if team_id <= 0 or phase != Enums.GamePhase.QUESTION or not answers_enabled:
		return false
	if is_team_locked_out(team_id):
		return false
	if active_team_id > 0 and active_team_id != team_id:
		return false
	return locked_team_id == 0 and last_selected_option.is_empty()


static func _normalize_scores(raw_scores: Dictionary) -> Dictionary:
	var normalized: Dictionary = {1: 0, 2: 0, 3: 0}
	for key in raw_scores.keys():
		normalized[int(key)] = int(raw_scores[key])
	return normalized


static func _normalize_locked_out_team_ids(raw_locked_out_teams: Dictionary) -> Dictionary:
	var normalized: Dictionary = {1: false, 2: false, 3: false}
	for key in raw_locked_out_teams.keys():
		normalized[int(key)] = bool(raw_locked_out_teams[key])
	return normalized
