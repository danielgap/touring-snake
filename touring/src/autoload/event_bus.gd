extends Node

signal game_state_changed(from: StringName, to: StringName)

signal gm_trigger_activate()
signal gm_trigger_menu()
signal gm_skip_snake()
signal gm_reset_all()
signal gm_skip_password()

signal password_submitted(text: String)
signal password_accepted()
signal password_rejected()

signal snake_ate_item()
signal snake_died()
signal snake_victory()

signal transition_complete()

signal state_persisted(state_name: StringName)
signal state_restored(state_name: StringName)
