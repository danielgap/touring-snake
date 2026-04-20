class_name MessageCodec
extends RefCounted


static func encode_json(payload: Variant) -> String:
	return JSON.stringify(payload)


static func decode_json(payload: String) -> Variant:
	var parsed: Variant = JSON.parse_string(payload)
	return parsed if parsed != null else {}


static func question_to_wire(question: Question) -> Dictionary:
	return question.to_dict()


static func question_from_wire(payload: Dictionary) -> Question:
	return Question.from_dict(payload)


static func game_state_to_wire(state: GameState) -> Dictionary:
	var payload: Dictionary = state.to_dict()
	payload["current_question"] = state.current_question.to_public_dict()
	return payload


static func game_state_from_wire(payload: Dictionary) -> GameState:
	return GameState.from_dict(payload)
