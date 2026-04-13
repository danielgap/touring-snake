class_name StateMachine
extends Node

signal state_changed(from_state: StringName, to_state: StringName)

@export var initial_state: NodePath

var current_state: Node = null
var states: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child.has_method("enter") and child.has_method("exit"):
			states[child.name] = child
			child.set("state_machine", self)
			child.process_mode = Node.PROCESS_MODE_DISABLED
	
	if initial_state:
		var node := get_node_or_null(initial_state)
		if node:
			current_state = node
			current_state.process_mode = Node.PROCESS_MODE_INHERIT
			current_state.call("enter")

func _process(delta: float) -> void:
	if current_state and current_state.has_method("update"):
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state and current_state.has_method("physics_update"):
		current_state.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
	if current_state and current_state.has_method("handle_input"):
		current_state.handle_input(event)

func transition_to(state_name: StringName, msg: Dictionary = {}) -> void:
	if not states.has(state_name):
		push_error("StateMachine: State '%s' not found" % state_name)
		return
	
	var prev := current_state
	if prev:
		prev.call("exit")
		prev.process_mode = Node.PROCESS_MODE_DISABLED
	
	current_state = states[state_name]
	current_state.process_mode = Node.PROCESS_MODE_INHERIT
	current_state.call("enter", msg)
	
	var prev_name: StringName = &"" if not prev else StringName(prev.name)
	state_changed.emit(prev_name, StringName(current_state.name))
