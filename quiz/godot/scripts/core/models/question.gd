class_name Question
extends RefCounted

var id: int = 0
var round_name: String = ""
var category: String = ""
var text: String = ""
var options: PackedStringArray = PackedStringArray([])
var correct_option: String = ""
var trivia: String = ""
var timeout_seconds: int = 15
var difficulty: String = ""
var images: PackedStringArray = PackedStringArray([])


func to_dict() -> Dictionary:
	return {
		"id": id,
		"round": round_name,
		"category": category,
		"text": text,
		"options": Array(options),
		"correct": correct_option,
		"dato_curioso": trivia,
		"timeout": timeout_seconds,
		"difficulty": difficulty,
		"imagenes": Array(images),
	}


func to_public_dict() -> Dictionary:
	return {
		"id": id,
		"round": round_name,
		"category": category,
		"text": text,
		"options": Array(options),
		"difficulty": difficulty,
		"imagenes": Array(images),
	}


static func from_dict(data: Dictionary) -> Question:
	var question: Question = Question.new()
	question.id = int(data.get("id", 0))
	question.round_name = str(data.get("round", data.get("ronda", "")))
	question.category = str(data.get("category", data.get("categoria", "")))
	question.text = str(data.get("text", data.get("texto", data.get("pregunta", ""))))
	question.correct_option = str(data.get("correct", data.get("correcta", "")))
	question.trivia = str(data.get("dato_curioso", data.get("trivia", data.get("dato", ""))))
	question.timeout_seconds = int(data.get("timeout", data.get("tiempo", 15)))
	question.difficulty = str(data.get("difficulty", data.get("dificultad", "")))

	var raw_options: Variant = data.get("options", data.get("opciones", []))
	if typeof(raw_options) == TYPE_ARRAY:
		for option in raw_options:
			question.options.append(str(option))

	var raw_images: Variant = data.get("imagenes", data.get("images", []))
	if typeof(raw_images) == TYPE_ARRAY:
		for img in raw_images:
			question.images.append(str(img))

	return question
