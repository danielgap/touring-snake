extends RefCounted

const BG := Color("#071218")
const SURFACE := Color("#0D1A23")
const SURFACE_ALT := Color("#11242E")
const SURFACE_SOFT := Color(0.07, 0.12, 0.16, 0.84)
const BORDER := Color("#214852")
const BORDER_SOFT := Color("#17333A")
const TEXT := Color("#E4F6F3")
const MUTED := Color("#7D959B")
const ACCENT_CYAN := Color("#32D6F4")
const ACCENT_GREEN := Color("#68E6A6")
const ACCENT_MAGENTA := Color("#C962FF")
const DANGER := Color("#FF5C7A")
const WARNING := Color("#F7C15B")

static func panel_style(fill: Color = SURFACE, border: Color = BORDER, radius: int = 14, border_width: int = 2, shadow_alpha: float = 0.2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0, 0, 0, shadow_alpha)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 4)
	return style

static func apply_panel(panel: PanelContainer, fill: Color = SURFACE, border: Color = BORDER, radius: int = 14, border_width: int = 2) -> void:
	panel.add_theme_stylebox_override("panel", panel_style(fill, border, radius, border_width))

static func apply_button_style(button: Button, accent: Color = ACCENT_CYAN, fill: Color = SURFACE_ALT) -> void:
	var normal := panel_style(fill, Color(accent, 0.55), 10, 2, 0.12)
	var hover := panel_style(fill.lightened(0.06), accent, 10, 2, 0.18)
	var pressed := panel_style(fill.darkened(0.1), accent.lightened(0.12), 10, 2, 0.18)
	var focus := panel_style(Color(accent, 0.1), accent, 10, 2, 0.0)
	var disabled := panel_style(fill.darkened(0.15), BORDER_SOFT, 10, 2, 0.0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", TEXT)
	button.add_theme_color_override("font_pressed_color", TEXT)
	button.add_theme_color_override("font_focus_color", TEXT)
	button.add_theme_color_override("font_disabled_color", MUTED)

static func make_label(text: String, font_size: int = 18, color: Color = TEXT, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

static func make_tag(text: String, accent: Color = ACCENT_CYAN, fill: Color = Color(ACCENT_CYAN, 0.08)) -> PanelContainer:
	var panel := PanelContainer.new()
	apply_panel(panel, fill, Color(accent, 0.75), 8, 1)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)
	var label := make_label(text, 14, accent, HORIZONTAL_ALIGNMENT_CENTER)
	margin.add_child(label)
	return panel

static func make_divider(color: Color = BORDER_SOFT, height: int = 2) -> ColorRect:
	var divider := ColorRect.new()
	divider.color = color
	divider.custom_minimum_size = Vector2(0, height)
	return divider
