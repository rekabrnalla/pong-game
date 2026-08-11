class_name RobotOctopus
extends Node2D

## A procedural robot octopus made entirely from Godot drawing commands.
##
## Sine waves repeat smoothly between -1 and 1. Giving every tentacle a
## different phase (starting place in the wave) makes them wiggle as a group
## without looking like one stiff object.

const BODY_RADIUS := 23.0
const CRASH_GRAVITY := 1050.0
const CRASH_GROUND_Y := 685.0
const CRASH_LINGER_SECONDS := 0.60
const BLAST_FLASH_SECONDS := 0.24

var animation_time := 0.0
var travel_tilt := 0.0
var crashing := false
var crash_time := 0.0
var ground_crash_time := -1.0
var crash_velocity := Vector2.ZERO
var crash_angular_velocity := 0.0


## Advances the robot's wiggle clock and any active crash animation.
func _process(delta: float) -> void:
	animation_time += delta
	if crashing:
		move_crashing_alien(delta)

	queue_redraw()


## Changes a normal flying robot into spinning wreckage after a ball hit.
func start_destroy_animation(blast_direction: Vector2 = Vector2.RIGHT) -> void:
	# The ball supplies the sideways part of the launch. The robot explosion adds
	# an upward kick, then gravity bends the path down toward the floor.
	var safe_direction := blast_direction.normalized()
	if safe_direction == Vector2.ZERO:
		safe_direction = Vector2.RIGHT

	crashing = true
	crash_time = 0.0
	ground_crash_time = -1.0
	crash_velocity = Vector2(safe_direction.x * 125.0, -235.0 + safe_direction.y * 35.0)
	var spin_direction: float = sign(safe_direction.x)
	if is_zero_approx(spin_direction):
		spin_direction = 1.0
	crash_angular_velocity = spin_direction * 11.5
	z_index = 2


## Applies gravity, ground bounce, and cleanup to the broken robot.
func move_crashing_alien(delta: float) -> void:
	crash_time += delta
	crash_velocity.y += CRASH_GRAVITY * delta
	position += crash_velocity * delta
	rotation += crash_angular_velocity * delta

	if ground_crash_time < 0.0 and position.y >= CRASH_GROUND_Y:
		# The body makes one small, messy ground bounce before its wreckage fades.
		position.y = CRASH_GROUND_Y
		crash_velocity.y = -abs(crash_velocity.y) * 0.18
		crash_velocity.x *= 0.40
		crash_angular_velocity *= 0.32
		ground_crash_time = 0.0
	elif ground_crash_time >= 0.0:
		ground_crash_time += delta
		if position.y > CRASH_GROUND_Y:
			position.y = CRASH_GROUND_Y
			crash_velocity.y = 0.0
		if ground_crash_time >= CRASH_LINGER_SECONDS:
			queue_free()


## Chooses between drawing the healthy robot and its damaged version.
func _draw() -> void:
	if crashing:
		draw_crashing_alien()
		return

	draw_set_transform(Vector2.ZERO, travel_tilt)
	draw_tentacles()
	draw_robot_body()
	draw_set_transform(Vector2.ZERO)


## Draws four jointed tentacles whose sine waves begin at different phases.
func draw_tentacles() -> void:
	var metal := Color(0.72, 0.82, 0.86)
	var joint := Color(0.12, 0.16, 0.18)
	var anchors := [-18.0, -6.0, 6.0, 18.0]

	for i in range(anchors.size()):
		var phase := animation_time * 7.0 + float(i) * 1.35
		var first_bend := sin(phase) * 6.0
		var second_bend := sin(phase + 1.1) * 8.0
		var points := PackedVector2Array([
			Vector2(anchors[i], 9.0),
			Vector2(anchors[i] + first_bend, 20.0),
			Vector2(anchors[i] + second_bend, 32.0),
		])
		draw_polyline(points, joint, 7.0, true)
		draw_polyline(points, metal, 4.0, true)
		draw_circle(points[1], 3.2, Color(0.98, 0.35, 0.65))
		draw_circle(points[2], 4.0, metal)


## Builds the robot's dome, face, eyes, and optional antenna from simple shapes.
func draw_robot_body(include_antenna: bool = true) -> void:
	var outline := Color(0.025, 0.04, 0.055)
	var mint := Color(0.30, 0.95, 0.68)
	var metal := Color(0.72, 0.82, 0.86)
	var pink := Color(1.0, 0.25, 0.62)
	var eye_pulse := 0.72 + sin(animation_time * 10.0) * 0.28

	# Antenna first, so its lower end disappears behind the dome.
	if include_antenna:
		draw_line(Vector2(0.0, -25.0), Vector2(0.0, -34.0), metal, 3.0)
		draw_circle(Vector2(0.0, -37.0), 4.0, pink)

	# Layered circles make a readable metal dome with a dark outline.
	draw_circle(Vector2.ZERO, BODY_RADIUS + 2.0, outline)
	draw_circle(Vector2.ZERO, BODY_RADIUS, mint)
	draw_rect(Rect2(Vector2(-22.0, 3.0), Vector2(44.0, 16.0)), outline, true)
	draw_rect(Rect2(Vector2(-19.0, 5.0), Vector2(38.0, 11.0)), metal, true)

	# The eyes pulse at the same kind of repeating rhythm used by arcade sounds.
	for eye_x in [-8.0, 8.0]:
		draw_circle(Vector2(eye_x, -7.0), 5.0, outline)
		draw_circle(Vector2(eye_x, -7.0), 3.2, Color(pink.r, pink.g, pink.b, eye_pulse))

	draw_arc(Vector2.ZERO, 17.0, PI + 0.25, TAU - 0.25, 24, Color(0.82, 1.0, 0.94, 0.8), 2.0)


## Draws cracks, loose pieces, blast light, and landing dust during a crash.
func draw_crashing_alien() -> void:
	# The dome stays recognizable while four tentacles, the antenna, and a loose
	# eye spread away from it. Their offsets use time squared for a gravity-like
	# downward bend, while the whole Node2D spins around its center.
	draw_robot_body(false)
	draw_line(Vector2(-14.0, -16.0), Vector2(5.0, 15.0), Color(0.04, 0.08, 0.09), 3.0)
	draw_line(Vector2(2.0, -20.0), Vector2(13.0, 3.0), Color(0.04, 0.08, 0.09), 2.0)
	draw_blasted_parts()

	if crash_time < BLAST_FLASH_SECONDS:
		var progress: float = crash_time / BLAST_FLASH_SECONDS
		var flash_alpha: float = 1.0 - progress
		var burst_radius: float = 12.0 + progress * 46.0
		for i in range(8):
			var direction := Vector2.RIGHT.rotated(TAU * float(i) / 8.0)
			draw_line(
				direction * burst_radius * 0.45,
				direction * burst_radius,
				Color(1.0, 0.94, 0.30, flash_alpha),
				4.0
			)

	if ground_crash_time >= 0.0:
		var dust_alpha: float = 1.0 - min(ground_crash_time / CRASH_LINGER_SECONDS, 1.0)
		draw_arc(Vector2.ZERO, 34.0 + ground_crash_time * 45.0, PI, TAU, 24, Color(0.75, 0.82, 0.86, dust_alpha), 4.0)


## Moves each detached robot part along its own small projectile path.
func draw_blasted_parts() -> void:
	var metal := Color(0.72, 0.82, 0.86)
	var joint := Color(0.12, 0.16, 0.18)
	var pink := Color(1.0, 0.25, 0.62)
	var spread_time: float = min(crash_time, 0.75)
	var anchors := [-18.0, -6.0, 6.0, 18.0]

	for i in range(anchors.size()):
		var side: float = -1.0 if i < 2 else 1.0
		var part_velocity := Vector2(side * (38.0 + float(i % 2) * 22.0), -32.0 + float(i) * 13.0)
		var offset := part_velocity * spread_time + Vector2(0.0, 95.0 * spread_time * spread_time)
		var start := Vector2(anchors[i], 11.0) + offset
		var points := PackedVector2Array([
			start,
			start + Vector2(side * 4.0, 11.0),
			start + Vector2(-side * 3.0, 22.0),
		])
		draw_polyline(points, joint, 7.0, true)
		draw_polyline(points, metal, 4.0, true)
		draw_circle(points[2], 4.0, metal)

	var antenna_offset := Vector2(54.0, -58.0) * spread_time + Vector2(0.0, 80.0 * spread_time * spread_time)
	draw_line(Vector2(0.0, -25.0) + antenna_offset, Vector2(0.0, -37.0) + antenna_offset, metal, 3.0)
	draw_circle(Vector2(0.0, -40.0) + antenna_offset, 4.0, pink)

	var eye_offset := Vector2(-62.0, -38.0) * spread_time + Vector2(0.0, 110.0 * spread_time * spread_time)
	draw_circle(Vector2(8.0, -7.0) + eye_offset, 4.0, joint)
	draw_circle(Vector2(8.0, -7.0) + eye_offset, 2.5, pink)
