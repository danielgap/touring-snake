class_name Main
extends Control

const UiLab = preload("res://src/ui/ui_lab.gd")

@onready var state_machine = $StateMachine
@onready var content: Control = $Content
@onready var background: ColorRect = $Background

static func _get_main() -> Control:
	return Engine.get_main_loop().root.find_child("Main", true, false) as Control

func _ready() -> void:
	background.color = UiLab.BG
	EventBus.gm_reset_all.connect(_on_gm_reset)
	# Connect StateMachine signal by string name (avoids type inference issues)
	state_machine.connect("state_changed", _on_state_machine_changed)
	_try_restore_state()

func get_content() -> Control:
	return content

func _on_state_machine_changed(from: StringName, to: StringName) -> void:
	EventBus.game_state_changed.emit(from, to)
	match to:
		&"SnakeState":
			_save_milestone("PASSWORD_UNLOCKED")
		&"VictoryState":
			_save_milestone("VICTORY_REACHED")
		&"InitState":
			_clear_milestone()

func _on_gm_reset() -> void:
	_clear_milestone()
	state_machine.transition_to(&"InitState")

func _save_milestone(milestone: String) -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "milestone", milestone)
	config.set_value("progress", "timestamp", Time.get_unix_time_from_system())
	config.save("user://room_state.cfg")
	EventBus.state_persisted.emit(StringName(milestone))

func _clear_milestone() -> void:
	var dir := DirAccess.open("user://")
	if dir and dir.file_exists("room_state.cfg"):
		dir.remove("room_state.cfg")

func _try_restore_state() -> void:
	var config := ConfigFile.new()
	if config.load("user://room_state.cfg") != OK:
		return
	var milestone: String = config.get_value("progress", "milestone", "")
	match milestone:
		"PASSWORD_UNLOCKED":
			state_machine.transition_to(&"SnakeState")
			EventBus.state_restored.emit(&"SnakeState")
		"VICTORY_REACHED":
			state_machine.transition_to(&"VictoryState")
			EventBus.state_restored.emit(&"VictoryState")
