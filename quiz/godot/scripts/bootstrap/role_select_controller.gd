extends Control

signal role_selected(role: int, team_id: int)

@onready var presenter_button: Button = $PanelContainer/MarginContainer/VBoxContainer/PresenterButton
@onready var contestant_button: Button = $PanelContainer/MarginContainer/VBoxContainer/ContestantButton
@onready var display_button: Button = $PanelContainer/MarginContainer/VBoxContainer/DisplayButton
@onready var team_selector: OptionButton = $PanelContainer/MarginContainer/VBoxContainer/TeamSelector
@onready var status_label: Label = $PanelContainer/MarginContainer/VBoxContainer/StatusLabel


func _ready() -> void:
	for team_id in [1, 2, 3]:
		team_selector.add_item("Equipo %d" % team_id, team_id)
	team_selector.select(0)

	presenter_button.pressed.connect(_on_presenter_pressed)
	contestant_button.pressed.connect(_on_contestant_pressed)
	display_button.pressed.connect(_on_display_pressed)
	status_label.text = "Elegí un rol para iniciar el scaffold offline."


func _on_presenter_pressed() -> void:
	emit_signal("role_selected", Enums.AppRole.PRESENTER, 0)


func _on_contestant_pressed() -> void:
	var team_id: int = team_selector.get_selected_id()
	emit_signal("role_selected", Enums.AppRole.CONTESTANT, team_id)


func _on_display_pressed() -> void:
	emit_signal("role_selected", Enums.AppRole.DISPLAY, 0)
