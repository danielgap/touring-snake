extends Control

const UiLab = preload("res://src/ui/ui_lab.gd")

var tint: Color = Color(0.03, 0.08, 0.1, 0.88)
var grid_color: Color = Color(UiLab.ACCENT_CYAN, 0.08)
var scanline_color: Color = Color(1, 1, 1, 0.02)
var frame_color: Color = Color(UiLab.BORDER, 0.9)
var highlight_color: Color = Color(UiLab.ACCENT_GREEN, 0.55)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, tint, true)
	_draw_grid(rect)
	_draw_scanlines(rect)
	_draw_frames(rect)
	_draw_data_points(rect)

func _draw_grid(rect: Rect2) -> void:
	var grid_step := 48.0
	for x in range(0, int(rect.size.x) + 1, int(grid_step)):
		draw_line(Vector2(x, 0), Vector2(x, rect.size.y), grid_color, 1.0)
	for y in range(0, int(rect.size.y) + 1, int(grid_step)):
		draw_line(Vector2(0, y), Vector2(rect.size.x, y), grid_color, 1.0)

func _draw_scanlines(rect: Rect2) -> void:
	for y in range(0, int(rect.size.y), 6):
		draw_line(Vector2(0, y), Vector2(rect.size.x, y), scanline_color, 1.0)

func _draw_frames(rect: Rect2) -> void:
	var outer := rect.grow(-26)
	var inner := rect.grow(-68)
	draw_rect(outer, frame_color, false, 2.0)
	draw_rect(inner, Color(frame_color, 0.45), false, 1.0)
	_draw_corner(outer.position + Vector2(18, 18), Vector2(1, 1))
	_draw_corner(Vector2(outer.end.x - 18, outer.position.y + 18), Vector2(-1, 1))
	_draw_corner(Vector2(outer.position.x + 18, outer.end.y - 18), Vector2(1, -1))
	_draw_corner(outer.end - Vector2(18, 18), Vector2(-1, -1))

func _draw_corner(origin: Vector2, direction: Vector2) -> void:
	var length := 42.0
	draw_line(origin, origin + Vector2(length * direction.x, 0), highlight_color, 3.0)
	draw_line(origin, origin + Vector2(0, length * direction.y), highlight_color, 3.0)

func _draw_data_points(rect: Rect2) -> void:
	var points := [
		Vector2(rect.size.x * 0.15, rect.size.y * 0.18),
		Vector2(rect.size.x * 0.78, rect.size.y * 0.22),
		Vector2(rect.size.x * 0.24, rect.size.y * 0.72),
		Vector2(rect.size.x * 0.84, rect.size.y * 0.78)
	]
	for point in points:
		draw_circle(point, 4.0, Color(UiLab.ACCENT_MAGENTA, 0.9))
		draw_circle(point, 10.0, Color(UiLab.ACCENT_MAGENTA, 0.12))
