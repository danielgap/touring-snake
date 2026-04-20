extends Node

signal questions_loaded(count: int)
signal content_missing(path: String)
signal content_error(message: String)

const QUESTIONS_PATH: String = "res://data/preguntas.json"

var questions: Array[Question] = []
var last_error: String = ""


func _ready() -> void:
	load_questions()


func load_questions() -> Array[Question]:
	questions.clear()
	last_error = ""

	if not FileAccess.file_exists(QUESTIONS_PATH):
		last_error = "Questions file not found: %s" % QUESTIONS_PATH
		emit_signal("content_missing", QUESTIONS_PATH)
		emit_signal("questions_loaded", 0)
		return questions

	var file: FileAccess = FileAccess.open(QUESTIONS_PATH, FileAccess.READ)
	if file == null:
		last_error = "Unable to open questions file: %s" % QUESTIONS_PATH
		emit_signal("content_error", last_error)
		emit_signal("questions_loaded", 0)
		return questions

	var raw_text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_ARRAY:
		last_error = "Questions JSON must be an array"
		emit_signal("content_error", last_error)
		emit_signal("questions_loaded", 0)
		return questions

	for entry in parsed:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		questions.append(Question.from_dict(entry))

	emit_signal("questions_loaded", questions.size())
	return questions


func get_question(index: int) -> Question:
	if index < 0 or index >= questions.size():
		return Question.new()
	return questions[index]


func get_question_by_id(question_id: int) -> Question:
	for question in questions:
		if question.id == question_id:
			return question
	return Question.new()


func get_rounds() -> PackedStringArray:
	var rounds: PackedStringArray = PackedStringArray([])
	var seen: Dictionary = {}
	for question in questions:
		var round_label: String = _round_label_for(question)
		if seen.has(round_label):
			continue
		seen[round_label] = true
		rounds.append(round_label)
	return rounds


func get_questions_for_round(round_name: String) -> Array[Question]:
	var filtered: Array[Question] = []
	for question in questions:
		if _round_label_for(question) == round_name:
			filtered.append(question)
	return filtered


func get_question_count() -> int:
	return questions.size()


func _round_label_for(question: Question) -> String:
	return question.round_name.strip_edges() if not question.round_name.strip_edges().is_empty() else "Sin ronda"
