extends SceneTree

const SCENES: PackedStringArray = [
	"res://scenes/presenter/presenter_root.tscn",
	"res://scenes/contestant/contestant_root.tscn",
	"res://scenes/display/display_root.tscn",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_path in SCENES:
		var packed_scene: PackedScene = load(scene_path)
		if packed_scene == null:
			push_error("Smoke: no se pudo cargar %s" % scene_path)
			quit(1)
			return
		var instance: Node = packed_scene.instantiate()
		root.add_child(instance)
		await process_frame
		instance.queue_free()
		await process_frame
	print("Smoke OK: presenter/contestant/display scenes instantiated")
	quit()
