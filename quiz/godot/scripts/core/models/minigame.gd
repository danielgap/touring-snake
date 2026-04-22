class_name MiniGame
extends RefCounted


var id: int = 0
var nombre: String = ""
var categoria: String = ""
var descripcion: String = ""
var material: Array[String] = []
var participantes: String = ""
var reglas: String = ""
var tiempo: int = 60
var dificultad: int = 1
var images: PackedStringArray = PackedStringArray([])


func to_dict() -> Dictionary:
	return {
		"id": id,
		"nombre": nombre,
		"categoria": categoria,
		"descripcion": descripcion,
		"material": material,
		"participantes": participantes,
		"reglas": reglas,
		"tiempo": tiempo,
		"dificultad": dificultad,
		"imagenes": Array(images),
	}


static func from_dict(data: Dictionary) -> MiniGame:
	var mg: MiniGame = MiniGame.new()
	mg.id = int(data.get("id", 0))
	mg.nombre = str(data.get("nombre", ""))
	mg.categoria = str(data.get("categoria", ""))
	mg.descripcion = str(data.get("descripcion", ""))
	mg.participantes = str(data.get("participantes", ""))
	mg.reglas = str(data.get("reglas", ""))
	mg.tiempo = int(data.get("tiempo", 60))
	mg.dificultad = int(data.get("dificultad", 1))
	var raw_material: Variant = data.get("material", [])
	if typeof(raw_material) == TYPE_ARRAY:
		for item in raw_material:
			mg.material.append(str(item))

	var raw_images: Variant = data.get("imagenes", data.get("images", []))
	if typeof(raw_images) == TYPE_ARRAY:
		for img in raw_images:
			mg.images.append(str(img))

	return mg
