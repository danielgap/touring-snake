class_name GameState
extends RefCounted

var phase: int = Enums.GamePhase.IDLE
var current_question: Question = Question.new()
var current_minigame: MiniGame = MiniGame.new()
var scores: Dictionary = {}
var answers_enabled: bool = false
var answer_authority_team_id: int = 0
var active_team_id: int = 0
var locked_team_id: int = 0
var locked_out_team_ids: Dictionary = {}
var revealed_correct_option: String = ""
var last_selected_option: String = ""
var answer_feedback_status: int = Enums.AnswerFeedbackStatus.NONE
var correction_applied: bool = false
var buzzer_winner_team_id: int = 0
var rebote_excluded_team_ids: Dictionary = {}
var score_before_judgment: Dictionary = {}
var status_text: String = "Esperando inicialización"


func to_dict() -> Dictionary:
	return {
		"phase": phase,
		"current_question": current_question.to_dict(),
		"current_minigame": current_minigame.to_dict(),
		"scores": scores.duplicate(true),
		"answers_enabled": answers_enabled,
		"answer_authority_team_id": answer_authority_team_id,
		"active_team_id": answer_authority_team_id,
		"locked_team_id": locked_team_id,
		"locked_out_team_ids": locked_out_team_ids.duplicate(true),
		"revealed_correct_option": revealed_correct_option,
		"last_selected_option": last_selected_option,
		"answer_feedback_status": answer_feedback_status,
		"correction_applied": correction_applied,
		"buzzer_winner_team_id": buzzer_winner_team_id,
		"rebote_excluded_team_ids": rebote_excluded_team_ids.duplicate(true),
		"score_before_judgment": score_before_judgment.duplicate(true),
		"status_text": status_text,
	}


static func from_dict(data: Dictionary) -> GameState:
	var state: GameState = GameState.new()
	state.phase = int(data.get("phase", Enums.GamePhase.IDLE))
	state.current_question = Question.from_dict(Dictionary(data.get("current_question", {})))
	state.current_minigame = MiniGame.from_dict(Dictionary(data.get("current_minigame", {})))
	state.scores = _normalize_scores(Dictionary(data.get("scores", {})))
	state.answers_enabled = bool(data.get("answers_enabled", false))
	var authority_team_id: int = int(data.get("answer_authority_team_id", data.get("active_team_id", data.get("buzzer_winner_team_id", 0))))
	if state.phase != Enums.GamePhase.QUESTION:
		authority_team_id = 0
	state.answer_authority_team_id = authority_team_id
	state.active_team_id = authority_team_id
	state.locked_team_id = int(data.get("locked_team_id", 0))
	state.locked_out_team_ids = _normalize_locked_out_team_ids(Dictionary(data.get("locked_out_team_ids", {})))
	state.revealed_correct_option = String(data.get("revealed_correct_option", ""))
	state.last_selected_option = String(data.get("last_selected_option", ""))
	state.answer_feedback_status = int(data.get("answer_feedback_status", Enums.AnswerFeedbackStatus.NONE))
	state.correction_applied = bool(data.get("correction_applied", false))
	state.buzzer_winner_team_id = int(data.get("buzzer_winner_team_id", 0))
	state.rebote_excluded_team_ids = _normalize_rebote_excluded(Dictionary(data.get("rebote_excluded_team_ids", {})))
	var raw_sbj: Dictionary = Dictionary(data.get("score_before_judgment", {}))
	for k: Variant in raw_sbj:
		state.score_before_judgment[int(k)] = int(raw_sbj[k])
	if authority_team_id > 0:
		state.rebote_excluded_team_ids.erase(authority_team_id)
	state.status_text = String(data.get("status_text", "Esperando inicialización"))
	return state


func duplicate_state() -> GameState:
	return GameState.from_dict(to_dict())


func is_team_locked_out(team_id: int) -> bool:
	return bool(locked_out_team_ids.get(team_id, false))


func team_lock_state(team_id: int) -> int:
	var has_live_authority: bool = phase == Enums.GamePhase.QUESTION and answer_authority_team_id > 0
	if phase == Enums.GamePhase.LOCKED:
		if has_live_authority and team_id == answer_authority_team_id:
			return Enums.TeamLockState.ACTIVE
		return Enums.TeamLockState.FROZEN
	if has_live_authority and team_id == answer_authority_team_id:
		return Enums.TeamLockState.ACTIVE
	if is_team_locked_out(team_id):
		return Enums.TeamLockState.LOCKED_OUT
	if is_team_excluded_from_rebote(team_id):
		return Enums.TeamLockState.LOCKED_OUT
	return Enums.TeamLockState.READY


func can_team_answer(team_id: int) -> bool:
	if team_id <= 0 or phase != Enums.GamePhase.QUESTION or not answers_enabled:
		return false
	if is_team_locked_out(team_id):
		return false
	if is_team_excluded_from_rebote(team_id):
		return false
	if answer_authority_team_id != team_id:
		return false
	return locked_team_id == 0 and last_selected_option.is_empty()


func is_team_excluded_from_rebote(team_id: int) -> bool:
	return bool(rebote_excluded_team_ids.get(team_id, false))


static func _normalize_scores(raw_scores: Dictionary) -> Dictionary:
	var normalized: Dictionary = {}
	for key in raw_scores.keys():
		normalized[int(key)] = int(raw_scores[key])
	return normalized


static func _normalize_locked_out_team_ids(raw_locked_out_teams: Dictionary) -> Dictionary:
	var normalized: Dictionary = {}
	for key in raw_locked_out_teams.keys():
		normalized[int(key)] = bool(raw_locked_out_teams[key])
	return normalized


static func _normalize_rebote_excluded(raw_excluded: Dictionary) -> Dictionary:
	var normalized: Dictionary = {}
	for key in raw_excluded.keys():
		normalized[int(key)] = bool(raw_excluded[key])
	return normalized
