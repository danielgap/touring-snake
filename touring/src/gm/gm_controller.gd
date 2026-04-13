class_name GMController
extends Control

var _overlay: ColorRect
var _is_open: bool = false
var _restart_confirm_pending: bool = false
var _restart_button: Button

func _ready() -> void:
	EventBus.gm_trigger_menu.connect(_toggle_menu)
	EventBus.gm_reset_all.connect(_close_menu)

func _toggle_menu() -> void:
	if _is_open:
		_close_menu()
	else:
		_open_menu()

func _open_menu() -> void:
	if _is_open:
		return
	_is_open = true
	
	_overlay = ColorRect.new()
	_overlay.color = Color(0.039, 0.039, 0.059, 0.8)
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	add_child(_overlay)
	
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(760, 350)
	vbox.add_theme_constant_override("separation", 20)
	_overlay.add_child(vbox)
	
	var title := Label.new()
	title.text = "GM CONTROLS"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("#00DDFF"))
	title.position = Vector2(860, 280)
	_overlay.add_child(title)
	
	_add_menu_button(vbox, "Saltar Snake", _on_skip_snake)
	_add_menu_button(vbox, "Saltar Password", _on_skip_password)
	
	_restart_button = Button.new()
	_restart_button.text = "Reiniciar Todo"
	_restart_button.custom_minimum_size = Vector2(200, 60)
	_restart_button.add_theme_font_size_override("font_size", 20)
	_restart_button.add_theme_color_override("font_color", Color("#FF2244"))
	_restart_button.pressed.connect(_on_restart_pressed)
	vbox.add_child(_restart_button)
	
	_add_menu_button(vbox, "Cerrar", _close_menu)

func _add_menu_button(container: VBoxContainer, text: String, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(200, 60)
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(callback)
	container.add_child(btn)

func _close_menu() -> void:
	if _overlay and _overlay.is_inside_tree():
		_overlay.queue_free()
	_is_open = false
	_restart_confirm_pending = false

func _on_skip_snake() -> void:
	EventBus.gm_skip_snake.emit()
	_close_menu()

func _on_skip_password() -> void:
	EventBus.gm_skip_password.emit()
	_close_menu()

func _on_restart_pressed() -> void:
	if not _restart_confirm_pending:
		_restart_confirm_pending = true
		_restart_button.text = "¿Confirmar? Toca de nuevo"
		await get_tree().create_timer(2.0).timeout
		_restart_confirm_pending = false
		if _restart_button and _restart_button.is_inside_tree():
			_restart_button.text = "Reiniciar Todo"
	else:
		EventBus.gm_reset_all.emit()
		_close_menu()
