extends Node

## ShowConfig — Configuración del programa de concurso
## Load order: res://data/show_config.json (defaults) → user://show_config.json (overrides)
## Saves always go to user://show_config.json (survives re-exports)

signal config_changed()
signal questions_file_changed(path: String)
signal minigames_file_changed(path: String)
signal images_folder_changed(path: String)

const RES_CONFIG_PATH: String = "res://data/show_config.json"
const USER_CONFIG_PATH: String = "user://show_config.json"
const CONFIG_VERSION: int = 1

## ── Config state ─────────────────────────────────────────────────
var _config: Dictionary = {}
var _defaults: Dictionary = {}


func _ready() -> void:
	_load_config()


# ═══════════════════════════════════════════════════════════════════
#  Load / Save
# ═══════════════════════════════════════════════════════════════════

func _load_config() -> void:
	# 1. Load defaults from res://
	_defaults = _read_json_file(RES_CONFIG_PATH)
	if _defaults.is_empty():
		_defaults = _get_hardcoded_defaults()

	# 2. Load user overrides from user://
	var user_overrides: Dictionary = _read_json_file(USER_CONFIG_PATH)

	# 3. Merge: user overrides on top of defaults
	_config = _defaults.duplicate(true)
	if not user_overrides.is_empty():
		_merge_dict(_config, user_overrides)


func save_config() -> void:
	var file: FileAccess = FileAccess.open(USER_CONFIG_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("ShowConfig: No se pudo guardar config en %s" % USER_CONFIG_PATH)
		return
	_config["version"] = CONFIG_VERSION
	file.store_string(JSON.stringify(_config, "\t"))
	emit_signal("config_changed")


func reset_to_defaults() -> void:
	_config = _defaults.duplicate(true)
	_delete_user_config()
	emit_signal("config_changed")


func _delete_user_config() -> void:
	if FileAccess.file_exists(USER_CONFIG_PATH):
		DirAccess.open("user://").remove("show_config.json")


func _read_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _merge_dict(base: Dictionary, overlay: Dictionary) -> void:
	for key in overlay:
		if base.has(key) and typeof(base[key]) == TYPE_DICTIONARY and typeof(overlay[key]) == TYPE_DICTIONARY:
			_merge_dict(base[key], overlay[key])
		else:
			base[key] = overlay[key]


func _get_hardcoded_defaults() -> Dictionary:
	return {
		"show_name": "Quiz Offline",
		"subtitle": "",
		"team_count": 3,
		"teams": [
			{"id": 1, "name": "Equipo 1", "color": "#3b82f6"},
			{"id": 2, "name": "Equipo 2", "color": "#f59e0b"},
			{"id": 3, "name": "Equipo 3", "color": "#ef4444"},
		],
		"points_correct": 100,
		"points_incorrect": 0,
		"questions_file": "res://data/preguntas.json",
		"minigames_file": "res://data/minijuegos.json",
		"mqtt_host": "127.0.0.1",
		"mqtt_port": 1883,
		"images_folder": "",
		"logo_path": "",
		"buzzer_mode_enabled": false,
	}


# ═══════════════════════════════════════════════════════════════════
#  Getters — typed access to config values
# ═══════════════════════════════════════════════════════════════════

func get_show_name() -> String:
	return String(_config.get("show_name", "Quiz Offline"))


func get_subtitle() -> String:
	return String(_config.get("subtitle", ""))


func get_team_count() -> int:
	return int(_config.get("team_count", 3))


func get_team_name(team_id: int) -> String:
	for team in _config.get("teams", []):
		if typeof(team) == TYPE_DICTIONARY and int(team.get("id", 0)) == team_id:
			return String(team.get("name", "Equipo %d" % team_id))
	return "Equipo %d" % team_id


func get_team_color(team_id: int) -> Color:
	for team in _config.get("teams", []):
		if typeof(team) == TYPE_DICTIONARY and int(team.get("id", 0)) == team_id:
			var color_str: String = String(team.get("color", "#ffffff"))
			return Color.from_string(color_str, Color.WHITE)
	match team_id:
		1: return Color("#3b82f6")
		2: return Color("#f59e0b")
		3: return Color("#ef4444")
		_: return Color.WHITE


func get_team_short(team_id: int) -> String:
	var team_name: String = get_team_name(team_id)
	return team_name.substr(0, 3).to_upper() if team_name.length() >= 3 else team_name.to_upper()


func get_points_correct() -> int:
	return int(_config.get("points_correct", 100))


func get_points_incorrect() -> int:
	return int(_config.get("points_incorrect", 0))


func get_questions_file() -> String:
	return String(_config.get("questions_file", "res://data/preguntas.json"))


func get_minigames_file() -> String:
	return String(_config.get("minigames_file", "res://data/minijuegos.json"))


func get_mqtt_host() -> String:
	return String(_config.get("mqtt_host", "127.0.0.1"))


func get_mqtt_port() -> int:
	return int(_config.get("mqtt_port", 1883))


func get_images_folder() -> String:
	return String(_config.get("images_folder", ""))


func set_images_folder(value: String) -> void:
	var old: String = String(_config.get("images_folder", ""))
	_config["images_folder"] = value
	if old != value:
		emit_signal("images_folder_changed", value)


func get_logo_path() -> String:
	return String(_config.get("logo_path", ""))


func set_logo_path(value: String) -> void:
	_config["logo_path"] = value


func get_buzzer_mode_enabled() -> bool:
	return bool(_config.get("buzzer_mode_enabled", false))


func set_buzzer_mode_enabled(value: bool) -> void:
	_config["buzzer_mode_enabled"] = value


func get_raw_config() -> Dictionary:
	return _config.duplicate(true)


# ═══════════════════════════════════════════════════════════════════
#  Setters — called from settings panel
# ═══════════════════════════════════════════════════════════════════

func set_show_name(value: String) -> void:
	_config["show_name"] = value


func set_subtitle(value: String) -> void:
	_config["subtitle"] = value


func set_team_count(count: int) -> void:
	_config["team_count"] = clampi(count, 2, 3)


func set_team_name(team_id: int, team_name: String) -> void:
	var teams: Array = _config.get("teams", [])
	for team in teams:
		if typeof(team) == TYPE_DICTIONARY and int(team.get("id", 0)) == team_id:
			team["name"] = team_name
			return


func set_team_color(team_id: int, color: Color) -> void:
	var teams: Array = _config.get("teams", [])
	for team in teams:
		if typeof(team) == TYPE_DICTIONARY and int(team.get("id", 0)) == team_id:
			team["color"] = "#" + color.to_html(false)
			return


func set_points_correct(value: int) -> void:
	_config["points_correct"] = value


func set_points_incorrect(value: int) -> void:
	_config["points_incorrect"] = value


func set_questions_file(path: String) -> void:
	var old: String = String(_config.get("questions_file", ""))
	_config["questions_file"] = path
	if old != path:
		emit_signal("questions_file_changed", path)


func set_minigames_file(path: String) -> void:
	var old: String = String(_config.get("minigames_file", ""))
	_config["minigames_file"] = path
	if old != path:
		emit_signal("minigames_file_changed", path)


func set_mqtt_host(value: String) -> void:
	_config["mqtt_host"] = value


func set_mqtt_port(value: int) -> void:
	_config["mqtt_port"] = value


## Ensure team array matches team_count (add/remove as needed)
func sync_teams_to_count() -> void:
	var count: int = get_team_count()
	var teams: Array = _config.get("teams", [])
	var default_colors: PackedStringArray = ["#3b82f6", "#f59e0b", "#ef4444", "#a855f7", "#14b8a6", "#f97316"]

	# Add missing teams
	while teams.size() < count:
		var new_id: int = teams.size() + 1
		teams.append({
			"id": new_id,
			"name": "Equipo %d" % new_id,
			"color": default_colors[new_id - 1] if new_id <= default_colors.size() else "#ffffff",
		})

	# Remove excess teams (keep first `count`)
	if teams.size() > count:
		teams = teams.slice(0, count - 1)

	_config["teams"] = teams
