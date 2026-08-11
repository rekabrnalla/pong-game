class_name SpinningBall
extends Node2D

## The ball is drawn from circles and a line instead of using an image file.
## Rotating this Node2D rotates only the crisp black markings. The yellow blur
## is drawn separately by the main game at older ball positions.

const RADIUS := 17.0


## Draws the yellow ball and crisp black marks that make rotation visible.
func _draw() -> void:
	var yellow := Color(1.0, 0.94, 0.16)
	var black := Color(0.035, 0.04, 0.035)
	var spin_ring_radius := RADIUS - 6.0

	# A slightly offset transparent circle acts like a simple shadow.
	draw_circle(Vector2(2.0, 2.0), RADIUS, Color(0.0, 0.0, 0.0, 0.32))
	draw_circle(Vector2.ZERO, RADIUS, yellow)
	draw_arc(Vector2.ZERO, spin_ring_radius, 0.0, TAU, 64, black, 3.0)
	draw_line(Vector2(0.0, -spin_ring_radius), Vector2(0.0, spin_ring_radius), black, 3.0)
	draw_arc(Vector2.ZERO, RADIUS - 1.5, 0.0, TAU, 64, Color(1.0, 1.0, 0.72, 0.42), 1.5)
