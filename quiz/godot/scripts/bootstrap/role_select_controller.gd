extends Control

signal role_selected(role: int, team_id: int)

## ── Broadcast palette ────────────────────────────────────────────
const CORNER_RADIUS := 14
const CARD_BG := Color("#0f1623")
const ACCENT_BLUE := Color("#0ea5e9")
const ACCENT_AMBER := Color("#f59e0b")
const ACCENT_PURPLE := Color("#a855f7")
const STATUS_GREEN := Color("#22c55e")
const TEAM1_COLOR := Color("#3b82f6")
const TEAM2_COLOR := Color("#f59e0b")
const TEAM3_COLOR := Color("#ef4444")

## ── Nodes ─────────────────────────────────────────────────────────
@onready var presenter_button: Button = %PresenterButton
@onready var team1_btn: Button = %Team1Btn
@onready var team2_btn: Button = %Team2Btn
@onready var team3_btn: Button = %Team3Btn
@onready var display_button: Button = %DisplayButton
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	_apply_styles()
	_wire_config_values()
	_update_team_visibility()
	presenter_button.pressed.connect(_on_presenter_pressed)
	team1_btn.pressed.connect(func() -> void: _on_team_pressed(1))
	team2_btn.pressed.connect(func() -> void: _on_team_pressed(2))
	team3_btn.pressed.connect(func() -> void: _on_team_pressed(3))
	display_button.pressed.connect(_on_display_pressed)
	ShowConfig.config_changed.connect(_on_config_changed)
	_setup_focus_navigation()


func _setup_focus_navigation() -> void:
	# D-pad navigation: left/right between 3 cards
	# Presenter ← → Team1 ← → Team2 ← → Team3 ← → Display
	presenter_button.focus_neighbor_left = display_button.get_path()
	presenter_button.focus_neighbor_right = team1_btn.get_path()
	team1_btn.focus_neighbor_left = presenter_button.get_path()
	team1_btn.focus_neighbor_right = team2_btn.get_path()
	team2_btn.focus_neighbor_left = team1_btn.get_path()
	team2_btn.focus_neighbor_right = team3_btn.get_path()
	team3_btn.focus_neighbor_left = team2_btn.get_path()
	team3_btn.focus_neighbor_right = display_button.get_path()
	display_button.focus_neighbor_left = team3_btn.get_path()
	display_button.focus_neighbor_right = presenter_button.get_path()
	# Auto-focus first button for D-pad / remote control
	presenter_button.grab_focus()


func _wire_config_values() -> void:
	# Title from config
	var title_label: Label = get_node_or_null("CenterVBox/TitleLabel")
	if title_label != null:
		title_label.text = ShowConfig.get_show_name().to_upper()

	# Subtitle — show if non-empty, otherwise keep default
	var subtitle_label: Label = get_node_or_null("CenterVBox/SubtitleLabel")
	if subtitle_label != null:
		var sub: String = ShowConfig.get_subtitle()
		if not sub.is_empty():
			subtitle_label.text = sub

	# Team button text — from config
	team1_btn.text = ShowConfig.get_team_name(1)
	team2_btn.text = ShowConfig.get_team_name(2)
	team3_btn.text = ShowConfig.get_team_name(3)

	# Logo from config
	var logo_rect: TextureRect = get_node_or_null("CenterVBox/LogoRect")
	if logo_rect != null:
		var logo_path: String = ShowConfig.get_logo_path()
		if not logo_path.is_empty():
			var tex: Texture2D = ImageLoader.load_image_absolute(logo_path)
			if tex != null:
				logo_rect.texture = tex
				logo_rect.visible = true
			else:
				logo_rect.visible = false
		else:
			logo_rect.visible = false


func _on_config_changed() -> void:
	_wire_config_values()
	_update_team_visibility()


func _update_team_visibility() -> void:
	var count: int = ShowConfig.get_team_count()
	team2_btn.visible = count >= 2
	team3_btn.visible = count >= 3


func _apply_styles() -> void:
	# Team colors from config (fallback to defaults)
	var tc1: Color = ShowConfig.get_team_color(1)
	var tc2: Color = ShowConfig.get_team_color(2)
	var tc3: Color = ShowConfig.get_team_color(3)

	# Presenter card — blue glow
	%PresenterCard.add_theme_stylebox_override("panel", _make_glow_card(Color("#081525"), ACCENT_BLUE, 2, ACCENT_BLUE, 8))
	_apply_entry_button(presenter_button, ACCENT_BLUE)

	# Team card — amber glow
	%TeamCard.add_theme_stylebox_override("panel", _make_glow_card(Color("#1a1500"), ACCENT_AMBER, 2, ACCENT_AMBER, 8))

	# Team buttons — team-colored from config
	_apply_team_button(team1_btn, tc1)
	_apply_team_button(team2_btn, tc2)
	_apply_team_button(team3_btn, tc3)

	# Display card — purple glow
	%DisplayCard.add_theme_stylebox_override("panel", _make_glow_card(Color("#150a25"), ACCENT_PURPLE, 2, ACCENT_PURPLE, 8))
	_apply_entry_button(display_button, ACCENT_PURPLE)


func _make_glow_card(bg: Color, border: Color, border_w: int, glow_color: Color, glow_size: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_w)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.shadow_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.35)
	style.shadow_size = glow_size
	return style


func _apply_entry_button(btn: Button, accent: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(accent.r * 0.3, accent.g * 0.3, accent.b * 0.3, 1.0)
	normal.border_color = Color(accent.r * 0.5, accent.g * 0.5, accent.b * 0.5, 1.0)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(CORNER_RADIUS)
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(accent.r * 0.5, accent.g * 0.5, accent.b * 0.5, 1.0)
	hover.border_color = accent
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(CORNER_RADIUS)
	hover.shadow_color = Color(accent.r, accent.g, accent.b, 0.4)
	hover.shadow_size = 10
	hover.content_margin_top = 12
	hover.content_margin_bottom = 12

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focused", hover)
	btn.add_theme_color_override("font_color", accent)
	btn.add_theme_color_override("font_hover_color", Color("#ffffff"))
	btn.add_theme_color_override("font_focus_color", Color("#ffffff"))


func _apply_team_button(btn: Button, team_color: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(team_color.r * 0.2, team_color.g * 0.2, team_color.b * 0.2, 1.0)
	normal.border_color = Color(team_color.r * 0.4, team_color.g * 0.4, team_color.b * 0.4, 1.0)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(CORNER_RADIUS)
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(team_color.r * 0.4, team_color.g * 0.4, team_color.b * 0.4, 1.0)
	hover.border_color = team_color
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(CORNER_RADIUS)
	hover.shadow_color = Color(team_color.r, team_color.g, team_color.b, 0.5)
	hover.shadow_size = 10
	hover.content_margin_top = 12
	hover.content_margin_bottom = 12

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focused", hover)
	btn.add_theme_color_override("font_color", team_color)
	btn.add_theme_color_override("font_hover_color", Color("#ffffff"))
	btn.add_theme_color_override("font_focus_color", Color("#ffffff"))


# ═══════════════════════════════════════════════════════════════════
#  Actions
# ═══════════════════════════════════════════════════════════════════

func _on_presenter_pressed() -> void:
	status_label.text = "Entrando como presentador..."
	status_label.add_theme_color_override("font_color", STATUS_GREEN)
	role_selected.emit(Enums.AppRole.PRESENTER, 0)


func _on_team_pressed(team_id: int) -> void:
	status_label.text = "Entrando como %s..." % ShowConfig.get_team_name(team_id)
	status_label.add_theme_color_override("font_color", STATUS_GREEN)
	role_selected.emit(Enums.AppRole.CONTESTANT, team_id)


func _on_display_pressed() -> void:
	status_label.text = "Entrando como pantalla..."
	status_label.add_theme_color_override("font_color", STATUS_GREEN)
	role_selected.emit(Enums.AppRole.DISPLAY, 0)
