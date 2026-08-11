class_name StartupSplash
extends Control

## The opening screen is drawn and animated with the same game objects used on
## the court. Reusing them means a learner only has one robot and one ball
## design to understand and maintain.

signal finished

const RobotOctopus := preload("res://scripts/robot_octopus.gd")
const SpinningBall := preload("res://scripts/spinning_ball.gd")

const DESIGN_SIZE := Vector2(1280.0, 720.0)
const AUTO_DISMISS_SECONDS := 5.0
const FADE_SECONDS := 0.35
const MINIMUM_SKIP_SECONDS := 0.35
const SLOW_MOTION_SCALE := 0.32
const BALL_START := Vector2(235.0, 470.0)
const BALL_TARGET := Vector2(735.0, 365.0)

var elapsed := 0.0
var has_finished := false
var robot: RobotOctopus
var ball: SpinningBall


## Builds the splash objects once when this screen enters the scene tree.
func _ready() -> void:
	# MOUSE_FILTER_STOP prevents a splash-screen click from also moving a paddle
	# or opening the score's restart dialog underneath it.
	size = DESIGN_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	create_words()
	create_preview_characters()
	queue_redraw()


## Advances the slow-motion preview and closes the splash after five seconds.
func _process(delta: float) -> void:
	elapsed += delta
	animate_preview()

	# During the final fraction of a second, the whole CanvasItem becomes
	# transparent. "modulate" also affects child labels, the robot, and the ball.
	var fade_start := AUTO_DISMISS_SECONDS - FADE_SECONDS
	if elapsed > fade_start:
		modulate.a = clamp((AUTO_DISMISS_SECONDS - elapsed) / FADE_SECONDS, 0.0, 1.0)

	if elapsed >= AUTO_DISMISS_SECONDS:
		finish()

	queue_redraw()


## Checks whether a keyboard, mouse, touch, or controller press should skip ahead.
func try_skip(event: InputEvent) -> bool:
	# A brief lockout stops the same click that focused the web game from
	# instantly hiding the splash. After that, any normal "press" can continue.
	if elapsed < MINIMUM_SKIP_SECONDS:
		return false

	var pressed := false
	if event is InputEventKey:
		pressed = event.pressed and not event.echo
	elif event is InputEventMouseButton:
		pressed = event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	elif event is InputEventScreenTouch:
		pressed = event.pressed
	elif event is InputEventJoypadButton:
		pressed = event.pressed

	if pressed:
		finish()
	return pressed


## Announces that the splash is done exactly once.
func finish() -> void:
	# The guard matters because a click and the automatic timer can finish on the
	# same frame. Emitting once keeps the main scene's cleanup predictable.
	if has_finished:
		return
	has_finished = true
	finished.emit()


## Creates the title, copyright, and Godot attribution labels.
func create_words() -> void:
	var title := make_label(
		"SPIN PONG",
		Vector2(0.0, 62.0),
		Vector2(DESIGN_SIZE.x, 112.0),
		86,
		Color(1.0, 0.94, 0.16)
	)
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.025, 0.95))

	make_label(
		"Copyright (c) 2026 Allan Baker",
		Vector2(0.0, DESIGN_SIZE.y - 68.0),
		Vector2(DESIGN_SIZE.x, 30.0),
		17,
		Color(0.72, 0.76, 0.78)
	)

	make_label(
		"Godot Engine: godotengine.org/license",
		Vector2(0.0, DESIGN_SIZE.y - 36.0),
		Vector2(DESIGN_SIZE.x, 20.0),
		13,
		Color(0.52, 0.58, 0.61)
	)


## Makes one consistently aligned label and returns it for optional extra styling.
func make_label(label_text: String, label_position: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = label_text
	label.position = label_position
	label.size = label_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label


## Adds reusable versions of the game's robot and spinning ball to the splash.
func create_preview_characters() -> void:
	robot = RobotOctopus.new()
	robot.name = "SplashRobotOctopus"
	robot.position = Vector2(805.0, 385.0)
	robot.scale = Vector2.ONE * 3.0
	# The normal robot updates its own animation every frame. The splash controls
	# that clock manually so its tentacles also participate in slow motion.
	robot.set_process(false)
	add_child(robot)

	ball = SpinningBall.new()
	ball.name = "SplashSpinningBall"
	ball.position = BALL_START
	ball.scale = Vector2.ONE * 1.4
	add_child(ball)


## Calculates the current slow-motion positions from elapsed time.
func animate_preview() -> void:
	# Five seconds advances the shot through exactly half of its complete path.
	# smoothstep removes abrupt starts while preserving that exact halfway point.
	var time_progress: float = clamp(elapsed / AUTO_DISMISS_SECONDS, 0.0, 1.0)
	var travel_progress := smoothstep(0.0, 1.0, time_progress) * 0.5
	ball.position = BALL_START.lerp(BALL_TARGET, travel_progress)
	ball.position.y += sin(travel_progress * PI) * -42.0
	ball.rotation = elapsed * 3.2

	# Every robot motion reads from the same slowed clock. This includes the body
	# wobble, the hover, the blinking eyes, and all four mechanical tentacles.
	var slow_time := elapsed * SLOW_MOTION_SCALE
	robot.animation_time = slow_time
	robot.rotation = sin(slow_time * 2.4) * 0.055
	robot.position.y = 385.0 + sin(slow_time * 3.0) * 7.0
	robot.queue_redraw()


## Draws the title-screen background and court markings behind its child nodes.
func _draw() -> void:
	# The splash is full-screen rather than a card so it reads as a real opening
	# title. Thin court markings connect it visually to the game that follows.
	draw_rect(Rect2(Vector2.ZERO, DESIGN_SIZE), Color(0.035, 0.045, 0.055), true)
	draw_line(Vector2(0.0, 222.0), Vector2(DESIGN_SIZE.x, 222.0), Color(0.20, 0.80, 1.0, 0.34), 2.0)
	draw_line(Vector2(0.0, 626.0), Vector2(DESIGN_SIZE.x, 626.0), Color(1.0, 0.35, 0.62, 0.34), 2.0)

	var dash_y := 244.0
	while dash_y < 615.0:
		draw_rect(Rect2(Vector2(DESIGN_SIZE.x / 2.0 - 2.0, dash_y), Vector2(4.0, 20.0)), Color(0.72, 0.78, 0.82, 0.24), true)
		dash_y += 34.0

	draw_ball_trail()


## Draws a curved yellow trail that hints at both high speed and spin.
func draw_ball_trail() -> void:
	# Only yellow circles trail the ball. The crisp black spin marks are drawn by
	# SpinningBall itself, matching the motion-blur rule used during gameplay.
	var flight_direction := (BALL_TARGET - BALL_START).normalized()
	# A spinning ball pushes air sideways. That sideways Magnus force bends its
	# route, so older trail dots drift gently away from a perfectly straight line.
	var spin_curve_normal := -flight_direction.orthogonal()
	for i in range(1, 13):
		var trail_age := float(i) / 13.0
		var distance_back := float(i) * 28.0
		var radius := 21.0 - float(i) * 1.05
		var alpha := 0.34 * (1.0 - trail_age)
		var spin_curve := spin_curve_normal * pow(trail_age, 1.6) * 26.0
		var trail_position := ball.position - flight_direction * distance_back + spin_curve
		draw_circle(trail_position, radius, Color(1.0, 0.94, 0.16, alpha))
