extends Node

## ImageLoader — Centralized image loading with cache
## Resolves relative filenames against ShowConfig.images_folder
## Returns Texture2D or null (graceful fallback with push_warning)

const ALLOWED_EXTENSIONS: PackedStringArray = [".png", ".jpg", ".jpeg", ".webp"]

var _cache: Dictionary = {}  # String (absolute path) → Texture2D


func _ready() -> void:
	ShowConfig.images_folder_changed.connect(_on_images_folder_changed)


func _on_images_folder_changed(_path: String) -> void:
	_cache.clear()


func load_image(filename: String) -> Texture2D:
	# 1. Empty images_folder → return null without file access
	var folder: String = ShowConfig.get_images_folder()
	if folder.is_empty():
		return null

	# 2. Check extension whitelist
	var ext: String = filename.get_extension().to_lower()
	if ext == "jpeg":
		ext = ".jpg"
	else:
		ext = "." + ext
	var _valid_ext: bool = false
	for allowed: String in ALLOWED_EXTENSIONS:
		if ext == allowed:
			_valid_ext = true
			break
	if not _valid_ext:
		push_warning("ImageLoader: Extensión no soportada '%s' para '%s'" % [ext, filename])
		return null

	# 3. Resolve path
	var full_path: String = folder.rstrip("/") + "/" + filename

	return _load_from_path(full_path)


func _load_from_path(full_path: String) -> Texture2D:
	# 1. Check cache
	if _cache.has(full_path):
		return _cache[full_path]

	# 2. Load from disk
	var image: Image = Image.new()
	var err: int = image.load(full_path)
	if err != OK:
		push_warning("ImageLoader: No se pudo cargar '%s' (error %d)" % [full_path, err])
		return null

	var texture: ImageTexture = ImageTexture.create_from_image(image)
	if texture == null:
		push_warning("ImageLoader: No se pudo crear textura desde '%s'" % full_path)
		return null

	# 3. Cache and return
	_cache[full_path] = texture
	return texture


func load_image_absolute(absolute_path: String) -> Texture2D:
	# 1. Empty path → return null
	if absolute_path.is_empty():
		return null

	# 2. Check extension whitelist
	var ext: String = absolute_path.get_extension().to_lower()
	if ext == "jpeg":
		ext = ".jpg"
	else:
		ext = "." + ext
	var _valid_ext: bool = false
	for allowed: String in ALLOWED_EXTENSIONS:
		if ext == allowed:
			_valid_ext = true
			break
	if not _valid_ext:
		push_warning("ImageLoader: Extensión no soportada '%s' para '%s'" % [ext, absolute_path])
		return null

	# 3. Load from absolute path (no folder resolution)
	return _load_from_path(absolute_path)


func load_images(filenames: PackedStringArray) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for fname: String in filenames:
		var tex: Texture2D = load_image(fname)
		textures.append(tex)
	return textures


func clear_cache() -> void:
	_cache.clear()
