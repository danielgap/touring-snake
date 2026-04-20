extends Node

signal questions_loaded(count: int)
signal minigames_loaded(count: int)
signal content_missing(path: String)
signal content_error(message: String)

const QUESTIONS_PATH: String = "res://data/preguntas.json"
const MINIGAMES_PATH: String = "res://data/minijuegos.json"

var questions: Array[Question] = []
var minigames: Array[MiniGame] = []
var last_error: String = ""


func _ready() -> void:
	load_questions()
	load_minigames()
	# If ShowConfig overrides questions file, use that
	if ShowConfig:
		var configured_path: String = ShowConfig.get_questions_file()
		if not configured_path.is_empty() and configured_path != QUESTIONS_PATH:
			if FileAccess.file_exists(configured_path):
				_load_questions_from(configured_path)
		ShowConfig.questions_file_changed.connect(_on_questions_file_changed)
		ShowConfig.minigames_file_changed.connect(_on_minigames_file_changed)


func load_questions() -> Array[Question]:
	var path: String = QUESTIONS_PATH
	if ShowConfig:
		var configured_path: String = ShowConfig.get_questions_file()
		if not configured_path.is_empty():
			path = configured_path
	return _load_questions_from(path)


func _load_questions_from(path: String) -> Array[Question]:
	questions.clear()
	last_error = ""

	if not FileAccess.file_exists(path):
		last_error = "Questions file not found: %s" % path
		emit_signal("content_missing", path)
		emit_signal("questions_loaded", 0)
		return questions

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_error = "Unable to open questions file: %s" % path
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


func _on_questions_file_changed(path: String) -> void:
	_load_questions_from(path)


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


# ═══════════════════════════════════════════════════════════════════
#  Minigames (loaded by sub-agent)
# ═══════════════════════════════════════════════════════════════════

func load_minigames() -> Array[MiniGame]:
	var path: String = MINIGAMES_PATH
	if ShowConfig:
		var configured_path: String = ShowConfig.get_minigames_file()
		if not configured_path.is_empty():
			path = configured_path
	return _load_minigames_from(path)


func _load_minigames_from(path: String) -> Array[MiniGame]:
	minigames.clear()

	if not FileAccess.file_exists(path):
		emit_signal("minigames_loaded", 0)
		return minigames

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		emit_signal("minigames_loaded", 0)
		return minigames

	var raw_text: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		emit_signal("minigames_loaded", 0)
		return minigames

	var mg_array: Variant = parsed.get("minijuegos", [])
	if typeof(mg_array) != TYPE_ARRAY:
		emit_signal("minigames_loaded", 0)
		return minigames

	for entry in mg_array:
		if typeof(entry) == TYPE_DICTIONARY:
			minigames.append(MiniGame.from_dict(entry))

	emit_signal("minigames_loaded", minigames.size())
	return minigames


func _on_minigames_file_changed(path: String) -> void:
	_load_minigames_from(path)


func get_minigame_by_id(mg_id: int) -> MiniGame:
	for mg in minigames:
		if mg.id == mg_id:
			return mg
	return MiniGame.new()


func get_minigame_categories() -> PackedStringArray:
	var categories: PackedStringArray = PackedStringArray([])
	var seen: Dictionary = {}
	for mg in minigames:
		var cat: String = mg.categoria.strip_edges()
		if cat.is_empty() or seen.has(cat):
			continue
		seen[cat] = true
		categories.append(cat)
	return categories


func get_minigames_for_category(category: String) -> Array[MiniGame]:
	if category.is_empty():
		return minigames
	var filtered: Array[MiniGame] = []
	for mg in minigames:
		if mg.categoria == category:
			filtered.append(mg)
	return filtered


func get_minigame_count() -> int:
	return minigames.size()
