extends Node2D
## Expanding ring burst at the position where the snake eats an item.
## Auto-frees when the animation completes.

var _center: Vector2 = Vector2.ZERO
var _time: float = 0.0
const DURATION := 0.4
const RING_COLOR := Color("#D66CFF")

func setup(pos: Vector2) -> void:
	_center = pos
	set_process(true)

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _time >= DURATION:
		queue_free()

func _draw() -> void:
	var t := _time / DURATION

	# Wave 1: outer expanding glow
	var r1 := 55.0 * t
	var a1 := (1.0 - t) * 0.25
	draw_circle(_center, r1, Color(RING_COLOR, a1))

	# Wave 2: inner expanding ring
	var r2 := 35.0 * t
	var a2 := (1.0 - t) * 0.4
	draw_circle(_center, r2, Color(RING_COLOR, a2))

	# Center flash (first 25% of duration)
	if t < 0.25:
		var ft := t / 0.25
		draw_circle(_center, 18.0 * (1.0 - ft), Color(1, 1, 1, 0.7 * (1.0 - ft)))
