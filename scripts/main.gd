extends Node2D

# These scripts separate reusable objects from the rules of the whole match.
const BallStateData := preload("res://scripts/ball_state_data.gd")
const SpinningBall := preload("res://scripts/spinning_ball.gd")
const RobotOctopus := preload("res://scripts/robot_octopus.gd")

# --- Court and paddle tuning -------------------------------------------------
# Named constants are the game's control knobs. A learner can change one value
# here and observe its effect without hunting through the physics functions.
const SCREEN_SIZE := Vector2(1280, 720)
const PADDLE_SIZE := Vector2(22, 130)
const BALL_SIZE := Vector2(34, 34)
const LEFT_PADDLE_X := 48.0
const RIGHT_PADDLE_X := SCREEN_SIZE.x - 48.0 - PADDLE_SIZE.x
const PADDLE_SPEED := 520.0
const START_BALL_SPEED := 420.0
const MAX_BALL_SPEED := 980.0
const PADDLE_HIT_SPEED_BOOST := 24.0
const RACKET_POWER := 0.12
const MAX_SPIN := 19.8
const SPIN_SURFACE_SPEED := 28.0
const PADDLE_BRUSH_TO_SPIN := 0.0198
const PADDLE_BRUSH_TO_ANGLE := 0.00055
const HIT_SPOT_TO_SPIN := 2.2
const SPIN_CURVE_FORCE := 20.0
const WALL_SQUISHINESS := 0.55
const WALL_SURFACE_FRICTION := 0.16
const WALL_FRICTION_TO_SPIN := 0.0495
const WALL_SPIN_LOSS := 0.88
const WALL_SPEED_RETENTION := 0.995
const MULTIBALL_WALL_SPEED_RETENTION := 0.985
const MIN_RALLY_BALL_SPEED := 300.0
const MIN_MULTIBALL_RALLY_SPEED := 185.0
const MIN_SIDEWAYS_SPEED := 70.0
const SIDEWAYS_STALL_SECONDS := 1.25
const DRIBBLE_GRAVITY := 1150.0
const DRIBBLE_BOUNCE_RETENTION := 0.55
const DRIBBLE_GROUND_FRICTION := 0.82
const DRIBBLE_STOP_VERTICAL_SPEED := 58.0
const BALL_RETURN_SPEED := 190.0
const RETURN_BOUNCE_GRAVITY := 950.0
const RETURN_BOUNCE_MIN_SPEED := 165.0
const RETURN_BOUNCE_MAX_SPEED := 215.0

# --- Spin and collision tuning ----------------------------------------------
const SPIN_PADDLE_GRIP := 0.10
const SPIN_DECAY := 0.995
const VISUAL_SPIN_MULTIPLIER := 2.0
const ROUND_BALL_EDGE_LIFT := 0.35
const CONTROLLED_BOUNCE_WOBBLE := 0.08
const PADDLE_FRONT_PHYSICS_BLEND := 0.30
const PADDLE_END_PHYSICS_BLEND := 0.82
const PADDLE_MIN_AWAY_COMPONENT := 0.28
const PADDLE_SEPARATION_DISTANCE := 0.5
const MAX_BALL_STEP_DISTANCE := 8.0

# --- Slam, serve, sprint, touch, and drawing tuning -------------------------
const SLAM_LUNGE_DISTANCE := 18.0
const SLAM_LUNGE_SECONDS := 0.22
const SLAM_POWER_MULTIPLIER := 2.35
const SLAM_BALL_SPEED_MULTIPLIER := 1.22
const SLAM_SPIN_MULTIPLIER := 1.65
const SLAM_SHUDDER_DISTANCE := 5.0
const SLAM_SHUDDER_SECONDS := 0.34
const SLAM_SHUDDER_FREQUENCY := 24.0
const SERVE_SWING_TO_ANGLE := 0.75
const SERVE_HIT_SPOT_TO_ANGLE := 0.25
const SERVE_RANDOM_ANGLE := 0.05
const DOUBLE_TAP_WINDOW := 0.30
const SPRINT_MULTIPLIER := 1.65
const SPRINT_SECONDS := 2.0
const SPRINT_COOLDOWN_SECONDS := 5.0
const TOUCH_TAP_MAX_SECONDS := 0.22
const TOUCH_TAP_MOVE_MAX_DISTANCE := 24.0
const TOUCH_PADDLE_GRAB_PADDING := 70.0
const TAP_TARGET_STOP_DISTANCE := 3.0
const MOTION_BLUR_POINTS := 12
const MOTION_BLUR_ALPHA := 0.22
const MOTION_BLUR_CLEAR_DISTANCE := 22.0
const PADDLE_MOTION_BLUR_POINTS := 8
const PADDLE_MOTION_BLUR_ALPHA := 0.22
const SCORE_TOUCH_SIZE := Vector2(220.0, 58.0)
const WINNING_SCORE := 7

# --- Robot octopus and multiball tuning -------------------------------------
const ALIEN_MIN_DELAY := 8.0
const ALIEN_MAX_DELAY := 17.0
const ALIEN_SPEED := 220.0
const ALIEN_WOBBLE_SPEED := 4.5
const ALIEN_WOBBLE_TURN_RATE := deg_to_rad(8.0)
const ALIEN_COLLISION_RADIUS := 27.0
const ALIEN_EDGE_PADDING := 35.0
const ALIEN_ROAM_MIN_X := SCREEN_SIZE.x / 3.0 + ALIEN_COLLISION_RADIUS
const ALIEN_ROAM_MAX_X := SCREEN_SIZE.x * 2.0 / 3.0 - ALIEN_COLLISION_RADIUS
const ALIEN_ROAM_SECONDS := 20.0
const ALIEN_STEER_RADIUS := 280.0
const ALIEN_STEER_RATE := deg_to_rad(12.0)
const ALIEN_RICOCHET_ANGLE := deg_to_rad(13.0)
const ALIEN_MOMENTUM_SHARE := 0.40
const ALIEN_EXPLOSION_SPEED_BOOST := 45.0
const ALIEN_EXPLOSION_HORIZONTAL_SHARE := 0.78
const ALIEN_OFFSCREEN_MARGIN := 80.0

enum BallMode { PLAYING, DRIBBLING, BOUNCING_BACK, HELD }

# Match state is shared by every ball. State such as velocity and spin lives in
# BallStateData because two balls must be able to disagree about those values.
var left_score := 0
var right_score := 0
var active_balls: Array[BallStateData] = []
var left_both_was_down := false
var right_both_was_down := false
var left_slam_time_left := 0.0
var right_slam_time_left := 0.0
var left_slam_shudder_left := 0.0
var right_slam_shudder_left := 0.0
var left_paddle_velocity := 0.0
var right_paddle_velocity := 0.0
var left_last_sprint_tap_time := -10.0
var right_last_sprint_tap_time := -10.0
var left_sprint_time_left := 0.0
var right_sprint_time_left := 0.0
var left_sprint_cooldown_left := 0.0
var right_sprint_cooldown_left := 0.0
var left_up_was_down := false
var left_down_was_down := false
var right_up_was_down := false
var right_down_was_down := false
var left_touch_active := false
var right_touch_active := false
var left_touch_index := -1
var right_touch_index := -1
var left_touch_target_y := 0.0
var right_touch_target_y := 0.0
var left_touch_start_position := Vector2.ZERO
var right_touch_start_position := Vector2.ZERO
var left_touch_press_time := 0.0
var right_touch_press_time := 0.0
var left_touch_can_drag := false
var right_touch_can_drag := false
var left_touch_direct_mode := false
var right_touch_direct_mode := false
var left_touch_grab_offset_y := PADDLE_SIZE.y / 2.0
var right_touch_grab_offset_y := PADDLE_SIZE.y / 2.0
var left_tap_move_active := false
var right_tap_move_active := false
var left_tap_move_target_y := 0.0
var right_tap_move_target_y := 0.0
var left_paddle_trail: Array[Vector2] = []
var right_paddle_trail: Array[Vector2] = []
var touch_controls_seen := false
var game_over := false
var restart_confirm_open := false
var last_score_click_time := -10.0

# Alien timing is shared match state. The countdown pauses whenever there is
# not exactly one normally playing ball, so an alien can never create ball #3.
var alien: RobotOctopus
var alien_velocity := Vector2.ZERO
var alien_flight_time := 0.0
var alien_countdown := 0.0
var alien_is_exiting := false

var left_paddle: Panel
var right_paddle: Panel
var ball_layer: Node2D
var score_label: Label
var help_label: Label
var popup_layer: CanvasLayer
var popup_overlay: Control
var popup_panel: Panel
var popup_title_label: Label
var popup_message_label: Label
var popup_restart_button: Button
var popup_cancel_button: Button
var paddle_sound: AudioStreamPlayer
var wall_sound: AudioStreamPlayer
var score_sound: AudioStreamPlayer
var win_sound: AudioStreamPlayer
var slam_sound: AudioStreamPlayer
var alien_sound: AudioStreamPlayer
var alien_hit_sound: AudioStreamPlayer


# --- Main game loop ----------------------------------------------------------

func _ready() -> void:
	# _ready runs once after Godot has placed this scene in the game tree.
	create_game_objects()
	reset_round()


func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_R):
		new_game()

	if restart_confirm_open:
		queue_redraw()
		return

	if game_over:
		# A winning score stops the paddles and balls, but an alien already present
		# finishes its own timer and exit flight behind the game-over interface.
		update_alien(delta)
		queue_redraw()
		return

	# Frame order matters: input moves paddles first, then the alien and balls use
	# those fresh paddle positions for collision tests. Drawing happens last.
	update_slam_controls(delta)
	move_paddles(delta)
	update_paddle_slam_positions()
	update_alien(delta)
	move_balls(delta)
	spin_balls(delta)
	update_help_text()
	queue_redraw()


func _input(event: InputEvent) -> void:
	# Event input is best for taps and drags because it preserves which finger
	# moved. Held keyboard keys are checked every frame in move_paddles().
	if restart_confirm_open or game_over:
		return

	if event is InputEventScreenTouch:
		handle_touch_press(event)

	if event is InputEventScreenDrag:
		handle_touch_drag(event)


# --- Procedural court drawing ------------------------------------------------

func _draw() -> void:
	# _draw does not change physics. It paints the latest state calculated by
	# _process, starting with the background and ending with the center line.
	draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), Color(0.05, 0.06, 0.08), true)
	draw_touch_guides()
	draw_paddle_motion_blur(left_paddle_trail, Color(0.2, 0.8, 1.0), left_paddle_velocity)
	draw_paddle_motion_blur(right_paddle_trail, Color(1.0, 0.35, 0.35), right_paddle_velocity)
	draw_ball_motion_blurs()

	var dash_height := 24.0
	var gap := 16.0
	var x := SCREEN_SIZE.x / 2.0 - 2.0
	var y := 0.0
	while y < SCREEN_SIZE.y:
		draw_rect(Rect2(Vector2(x, y), Vector2(4, dash_height)), Color(0.7, 0.75, 0.8, 0.5), true)
		y += dash_height + gap


func draw_touch_guides() -> void:
	# The screen halves use the paddle colors to show which finger controls which
	# player without adding permanent mobile buttons over the court.
	if left_touch_active or left_tap_move_active:
		var guide_y := left_touch_target_y
		if left_tap_move_active:
			guide_y = left_tap_move_target_y
		draw_rect(Rect2(Vector2.ZERO, Vector2(SCREEN_SIZE.x / 2.0, SCREEN_SIZE.y)), Color(0.2, 0.8, 1.0, 0.08), true)
		draw_line(Vector2(0.0, guide_y), Vector2(SCREEN_SIZE.x / 2.0, guide_y), Color(0.2, 0.8, 1.0, 0.35), 2.0)

	if right_touch_active or right_tap_move_active:
		var guide_y := right_touch_target_y
		if right_tap_move_active:
			guide_y = right_tap_move_target_y
		draw_rect(Rect2(Vector2(SCREEN_SIZE.x / 2.0, 0.0), Vector2(SCREEN_SIZE.x / 2.0, SCREEN_SIZE.y)), Color(1.0, 0.35, 0.35, 0.08), true)
		draw_line(Vector2(SCREEN_SIZE.x / 2.0, guide_y), Vector2(SCREEN_SIZE.x, guide_y), Color(1.0, 0.35, 0.35, 0.35), 2.0)


func draw_ball_motion_blurs() -> void:
	# Each ball owns a separate trail. Otherwise ball #2 would connect its blur
	# to ball #1, drawing a confusing yellow streak across the court.
	for ball_state in active_balls:
		for i in range(ball_state.trail.size()):
			if ball_state.trail[i].distance_to(ball_state.node.position) < MOTION_BLUR_CLEAR_DISTANCE:
				continue

			var age := float(i + 1) / float(MOTION_BLUR_POINTS + 1)
			var radius := BALL_SIZE.x / 2.0 * (1.0 - age * 0.35)
			var alpha := MOTION_BLUR_ALPHA * (1.0 - age)
			draw_circle(ball_state.trail[i], radius, Color(1.0, 0.94, 0.16, alpha))


func draw_paddle_motion_blur(paddle_trail: Array[Vector2], color: Color, paddle_velocity: float) -> void:
	var speed_alpha: float = clamp(abs(paddle_velocity) / (PADDLE_SPEED * SPRINT_MULTIPLIER), 0.0, 1.0)
	for i in range(paddle_trail.size()):
		var age := float(i + 1) / float(PADDLE_MOTION_BLUR_POINTS + 1)
		var alpha: float = PADDLE_MOTION_BLUR_ALPHA * speed_alpha * pow(1.0 - age, 1.35)
		draw_paddle_shape(paddle_trail[i], Color(color.r, color.g, color.b, alpha))


func draw_paddle_shape(draw_position: Vector2, color: Color) -> void:
	var radius := PADDLE_SIZE.x / 2.0
	draw_rect(
		Rect2(draw_position + Vector2(0.0, radius), Vector2(PADDLE_SIZE.x, PADDLE_SIZE.y - radius * 2.0)),
		color,
		true
	)
	draw_circle(draw_position + Vector2(radius, radius), radius, color)
	draw_circle(draw_position + Vector2(radius, PADDLE_SIZE.y - radius), radius, color)


# --- Scene objects, interface, and generated sounds -------------------------

func create_game_objects() -> void:
	# Most objects are made in code so a learner can see how a scene can be built
	# from nodes. The popup uses a CanvasLayer so it always appears above play.
	left_paddle = make_paddle("LeftPaddle", Color(0.2, 0.8, 1.0))
	right_paddle = make_paddle("RightPaddle", Color(1.0, 0.35, 0.35))
	ball_layer = Node2D.new()
	ball_layer.name = "BallAndAlienLayer"
	add_child(ball_layer)
	create_sound_players()

	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# The label used to be 420 pixels wide, so mobile taps far from the visible
	# numbers could open restart confirmation. This tighter box still comfortably
	# fits both scores without claiming a large strip of playable court.
	score_label.position = Vector2(
		SCREEN_SIZE.x / 2.0 - SCORE_TOUCH_SIZE.x / 2.0,
		20.0
	)
	score_label.size = SCORE_TOUCH_SIZE
	score_label.add_theme_font_size_override("font_size", 42)
	score_label.mouse_filter = Control.MOUSE_FILTER_STOP
	score_label.gui_input.connect(_on_score_label_gui_input)
	add_child(score_label)

	help_label = Label.new()
	help_label.name = "HelpLabel"
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_label.position = Vector2(0, SCREEN_SIZE.y - 42)
	help_label.size = Vector2(SCREEN_SIZE.x, 30)
	help_label.add_theme_font_size_override("font_size", 18)
	update_help_text()
	add_child(help_label)

	create_popup()


func create_popup() -> void:
	popup_layer = CanvasLayer.new()
	popup_layer.layer = 10
	add_child(popup_layer)

	popup_overlay = Control.new()
	popup_overlay.name = "PopupOverlay"
	popup_overlay.size = SCREEN_SIZE
	popup_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_layer.add_child(popup_overlay)

	popup_panel = Panel.new()
	popup_panel.size = Vector2(470, 220)
	popup_panel.position = SCREEN_SIZE / 2.0 - popup_panel.size / 2.0
	popup_overlay.add_child(popup_panel)

	popup_title_label = Label.new()
	popup_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_title_label.position = Vector2(24, 24)
	popup_title_label.size = Vector2(popup_panel.size.x - 48, 42)
	popup_title_label.add_theme_font_size_override("font_size", 32)
	popup_panel.add_child(popup_title_label)

	popup_message_label = Label.new()
	popup_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	popup_message_label.position = Vector2(30, 78)
	popup_message_label.size = Vector2(popup_panel.size.x - 60, 58)
	popup_message_label.add_theme_font_size_override("font_size", 20)
	popup_panel.add_child(popup_message_label)

	popup_restart_button = Button.new()
	popup_restart_button.text = "Restart"
	popup_restart_button.position = Vector2(95, 155)
	popup_restart_button.size = Vector2(125, 42)
	popup_restart_button.pressed.connect(_on_popup_restart_pressed)
	popup_panel.add_child(popup_restart_button)

	popup_cancel_button = Button.new()
	popup_cancel_button.text = "Keep Playing"
	popup_cancel_button.position = Vector2(250, 155)
	popup_cancel_button.size = Vector2(125, 42)
	popup_cancel_button.pressed.connect(_on_popup_cancel_pressed)
	popup_panel.add_child(popup_cancel_button)

	popup_layer.visible = false


func make_paddle(node_name: String, color: Color) -> Panel:
	# A StyleBoxFlat supplies rounded corners. Its matching physics shape is a
	# capsule, calculated later by circle_paddle_contact().
	var paddle := Panel.new()
	paddle.name = node_name
	paddle.size = PADDLE_SIZE
	paddle.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	var corner_radius := int(PADDLE_SIZE.x / 2.0)
	style.bg_color = color
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	paddle.add_theme_stylebox_override("panel", style)
	add_child(paddle)
	return paddle


func create_sound_players() -> void:
	# These simple sounds are arrays of speaker positions calculated in code.
	# Frequency means how many times a wave repeats in one second.
	paddle_sound = make_sound_player("PaddleSound", 720.0, 0.07, 0.35)
	wall_sound = make_sound_player("WallSound", 420.0, 0.05, 0.25)
	score_sound = make_sound_player("ScoreSound", 180.0, 0.22, 0.35)
	win_sound = make_sound_player("WinSound", 920.0, 0.35, 0.30)
	slam_sound = AudioStreamPlayer.new()
	slam_sound.name = "SlamSound"
	slam_sound.stream = make_slam_boom()
	add_child(slam_sound)

	alien_sound = AudioStreamPlayer.new()
	alien_sound.name = "AlienSound"
	alien_sound.stream = make_alien_doodle()
	add_child(alien_sound)

	alien_hit_sound = AudioStreamPlayer.new()
	alien_hit_sound.name = "AlienHitSound"
	alien_hit_sound.stream = make_alien_hit_zap()
	add_child(alien_hit_sound)


func make_sound_player(node_name: String, frequency: float, seconds: float, volume: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.stream = make_tone(frequency, seconds, volume)
	add_child(player)
	return player


func make_tone(frequency: float, seconds: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * seconds)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var time := float(i) / float(sample_rate)
		var fade_out: float = clamp(float(sample_count - i) / 500.0, 0.0, 1.0)
		var wave := sin(TAU * frequency * time)
		var sample := int(wave * 32767.0 * volume * fade_out)
		data.encode_s16(i * 2, sample)

	var tone := AudioStreamWAV.new()
	tone.format = AudioStreamWAV.FORMAT_16_BITS
	tone.mix_rate = sample_rate
	tone.stereo = false
	tone.data = data
	return tone


func make_slam_boom() -> AudioStreamWAV:
	var sample_rate := 22050
	var seconds := 0.58
	var sample_count := int(sample_rate * seconds)
	var data := PackedByteArray()
	var phase := 0.0
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var time := float(i) / float(sample_rate)
		var progress := time / seconds
		var frequency: float = lerp(105.0, 38.0, progress)
		phase += TAU * frequency / float(sample_rate)
		var body := sin(phase) * exp(-time * 5.2)
		var sub := sin(phase * 0.48) * exp(-time * 3.8) * 0.58
		var crackle := randf_range(-1.0, 1.0) * exp(-time * 28.0) * 0.34
		var sample_value: float = clamp((body + sub + crackle) * 0.72, -1.0, 1.0)
		data.encode_s16(i * 2, int(sample_value * 32767.0))

	var boom := AudioStreamWAV.new()
	boom.format = AudioStreamWAV.FORMAT_16_BITS
	boom.mix_rate = sample_rate
	boom.stereo = false
	boom.data = data
	return boom


func make_alien_doodle() -> AudioStreamWAV:
	var sample_rate := 22050
	var seconds := 1.20
	var sample_count := int(sample_rate * seconds)
	var data := PackedByteArray()
	var phase := 0.0
	var notes := [220.0, 277.0, 330.0, 247.0]
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var time := float(i) / float(sample_rate)
		var note_index := int(time / 0.15) % notes.size()
		var frequency: float = notes[note_index]
		phase += TAU * frequency / float(sample_rate)
		# Adding a quiet second wave makes the sound metallic and arcade-like.
		var wave := sin(phase) * 0.34 + sin(phase * 2.03) * 0.12
		var pulse := 0.72 + sin(time * TAU * 6.0) * 0.28
		data.encode_s16(i * 2, int(clamp(wave * pulse, -1.0, 1.0) * 32767.0))

	var doodle := AudioStreamWAV.new()
	doodle.format = AudioStreamWAV.FORMAT_16_BITS
	doodle.mix_rate = sample_rate
	doodle.stereo = false
	doodle.data = data
	doodle.loop_mode = AudioStreamWAV.LOOP_FORWARD
	doodle.loop_begin = 0
	doodle.loop_end = sample_count
	return doodle


func make_alien_hit_zap() -> AudioStreamWAV:
	var sample_rate := 22050
	var seconds := 0.24
	var sample_count := int(sample_rate * seconds)
	var data := PackedByteArray()
	var phase := 0.0
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var time := float(i) / float(sample_rate)
		var progress := time / seconds
		var frequency: float = lerp(760.0, 95.0, progress)
		phase += TAU * frequency / float(sample_rate)
		var envelope := 1.0 - progress
		var wave := (sin(phase) * 0.55 + randf_range(-0.18, 0.18)) * envelope
		data.encode_s16(i * 2, int(clamp(wave, -1.0, 1.0) * 32767.0))

	var zap := AudioStreamWAV.new()
	zap.format = AudioStreamWAV.FORMAT_16_BITS
	zap.mix_rate = sample_rate
	zap.stereo = false
	zap.data = data
	return zap


func play_sound(player: AudioStreamPlayer) -> void:
	player.stop()
	player.play()


# --- Robot octopus timing, movement, and multiball --------------------------

func roll_next_alien_delay() -> void:
	# The random roll is a countdown in seconds. Keeping a minimum prevents two
	# aliens from appearing almost on top of each other.
	alien_countdown = randf_range(ALIEN_MIN_DELAY, ALIEN_MAX_DELAY)


func alien_spawn_is_eligible() -> bool:
	return (
		alien == null
		and active_balls.size() == 1
		and active_balls[0].mode == BallMode.PLAYING
	)


func update_alien(delta: float) -> void:
	if alien != null:
		move_roaming_alien(delta)
		return

	# Pausing instead of counting down during multiball means the alien does not
	# wait just offscreen and jump out the instant the second ball disappears.
	if not alien_spawn_is_eligible():
		return

	alien_countdown -= delta
	if alien_countdown <= 0.0:
		spawn_alien()


func spawn_alien() -> void:
	# The alien begins just inside the top edge. A random sideways component keeps
	# its first trip across the court from looking identical every time.
	var direction := Vector2(randf_range(-0.65, 0.65), 1.0).normalized()

	alien = RobotOctopus.new()
	alien.name = "RobotOctopus"
	alien_velocity = direction * ALIEN_SPEED
	alien_flight_time = 0.0
	alien_is_exiting = false
	alien.position = Vector2(
		randf_range(ALIEN_ROAM_MIN_X, ALIEN_ROAM_MAX_X),
		ALIEN_EDGE_PADDING
	)
	alien.travel_tilt = direction.x * 0.22
	ball_layer.add_child(alien)
	alien_sound.play()


func move_roaming_alien(delta: float) -> void:
	# For 20 seconds the middle third and the top/bottom edges act like bumpers.
	# After that, the alien chooses the nearer vertical exit. Traveling straight
	# up or down keeps it away from both paddles during its exit.
	alien_flight_time += delta
	if not alien_is_exiting and alien_flight_time >= ALIEN_ROAM_SECONDS:
		alien_is_exiting = true
		var exit_y_direction := -1.0 if alien.position.y <= SCREEN_SIZE.y / 2.0 else 1.0
		alien_velocity = Vector2(0.0, exit_y_direction * ALIEN_SPEED)

	if not alien_is_exiting:
		steer_alien_toward_ball(delta)

		# A tiny repeating turn makes the path wobble without changing its speed.
		var wobble_turn: float = sin(alien_flight_time * ALIEN_WOBBLE_SPEED) * ALIEN_WOBBLE_TURN_RATE * delta
		alien_velocity = alien_velocity.rotated(wobble_turn).normalized() * ALIEN_SPEED

	alien.position += alien_velocity * delta
	alien.travel_tilt = clamp(alien_velocity.x / ALIEN_SPEED, -1.0, 1.0) * 0.22

	if alien_is_exiting:
		if alien_is_outside_court():
			# This removes only the alien. It does not score, reset, or serve a ball.
			remove_alien(false)
		return

	bounce_alien_off_court_edges()


func steer_alien_toward_ball(delta: float) -> void:
	# Steering only happens near the one legal target ball. We aim a short way in
	# front of the ball, like leading a moving target, but cap the turn at only 12
	# degrees per second so the alien never feels like a heat-seeking missile.
	if active_balls.size() != 1 or active_balls[0].mode != BallMode.PLAYING:
		return

	var ball_state := active_balls[0]
	var distance_to_ball := alien.position.distance_to(ball_state.node.position)
	if distance_to_ball <= 0.001 or distance_to_ball >= ALIEN_STEER_RADIUS:
		return

	var look_ahead_seconds: float = min(
		distance_to_ball / max(ball_state.speed, 1.0),
		0.35
	)
	var target_position := ball_state.node.position + ball_state.velocity * look_ahead_seconds * 0.35
	var target_direction := alien.position.direction_to(target_position)
	var current_direction := alien_velocity.normalized()
	var closeness: float = 1.0 - distance_to_ball / ALIEN_STEER_RADIUS
	var maximum_turn: float = ALIEN_STEER_RATE * closeness * delta
	var turn: float = clamp(current_direction.angle_to(target_direction), -maximum_turn, maximum_turn)
	alien_velocity = current_direction.rotated(turn) * ALIEN_SPEED


func bounce_alien_off_court_edges() -> void:
	# Reflecting one velocity component is the same mirror rule used by a ball:
	# the invisible middle-third walls flip x, while top/bottom walls flip y.
	# The radius inset keeps the alien's whole collision circle in the safe zone.
	if alien.position.x < ALIEN_ROAM_MIN_X:
		alien.position.x = ALIEN_ROAM_MIN_X
		alien_velocity.x = abs(alien_velocity.x)
	elif alien.position.x > ALIEN_ROAM_MAX_X:
		alien.position.x = ALIEN_ROAM_MAX_X
		alien_velocity.x = -abs(alien_velocity.x)

	if alien.position.y < ALIEN_EDGE_PADDING:
		alien.position.y = ALIEN_EDGE_PADDING
		alien_velocity.y = abs(alien_velocity.y)
	elif alien.position.y > SCREEN_SIZE.y - ALIEN_EDGE_PADDING:
		alien.position.y = SCREEN_SIZE.y - ALIEN_EDGE_PADDING
		alien_velocity.y = -abs(alien_velocity.y)

	alien_velocity = alien_velocity.normalized() * ALIEN_SPEED


func alien_is_outside_court() -> bool:
	return (
		alien.position.x < -ALIEN_OFFSCREEN_MARGIN
		or alien.position.x > SCREEN_SIZE.x + ALIEN_OFFSCREEN_MARGIN
		or alien.position.y < -ALIEN_OFFSCREEN_MARGIN
		or alien.position.y > SCREEN_SIZE.y + ALIEN_OFFSCREEN_MARGIN
	)


func remove_alien(play_destroy_animation: bool, blast_direction: Vector2 = Vector2.ZERO) -> void:
	if alien == null:
		return

	var old_alien := alien
	alien = null
	alien_is_exiting = false
	alien_sound.stop()
	if play_destroy_animation:
		old_alien.start_destroy_animation(blast_direction)
	else:
		old_alien.queue_free()
	roll_next_alien_delay()


func check_alien_collision(ball_state: BallStateData) -> void:
	if alien == null or active_balls.size() != 1:
		return

	var combined_radius := BALL_SIZE.x / 2.0 + ALIEN_COLLISION_RADIUS
	if ball_state.node.position.distance_squared_to(alien.position) > combined_radius * combined_radius:
		return

	split_ball_on_alien(ball_state)


func split_ball_on_alien(ball_state: BallStateData) -> void:
	# A normalized vector describes direction only. The original ball keeps that
	# direction when it already has enough x motion. A nearly vertical hit is
	# flattened so the explosion cannot create two up-and-down-only balls.
	var incoming_direction := ball_state.velocity.normalized()
	var split_side := -1.0 if randf() < 0.5 else 1.0
	var forward_direction := direction_with_minimum_horizontal_share(
		incoming_direction,
		ALIEN_EXPLOSION_HORIZONTAL_SHARE,
		split_side
	)
	var reflected_direction := direction_with_minimum_horizontal_share(
		(-incoming_direction).rotated(ALIEN_RICOCHET_ANGLE * split_side),
		ALIEN_EXPLOSION_HORIZONTAL_SHARE,
		-split_side
	)
	# A glancing rotation can flip an almost-vertical vector to either side. Pin
	# the ricochet's x sign opposite the forward ball so they cannot leave the
	# explosion heading toward the same player.
	reflected_direction.x = -sign(forward_direction.x) * abs(reflected_direction.x)
	# Every ball has the same mass, so 40% of speed means 40% of momentum size.
	# Direction is handled separately above. The robot adds a fixed kick, while
	# its crashing body and loose debris visually carry the remaining momentum.
	var split_speed: float = min(
		ball_state.speed * ALIEN_MOMENTUM_SHARE + ALIEN_EXPLOSION_SPEED_BOOST,
		MAX_BALL_SPEED
	)
	var separation_axis := Vector2(-incoming_direction.y, incoming_direction.x) * split_side
	var split_position := ball_state.node.position
	var original_spin := ball_state.spin

	remove_alien(true, incoming_direction)
	play_sound(alien_hit_sound)

	ball_state.node.position = split_position + forward_direction * 6.0 + separation_axis * 3.0
	ball_state.velocity = forward_direction * split_speed
	ball_state.speed = split_speed
	ball_state.spin = original_spin
	ball_state.trail.clear()
	ball_state.sideways_stall_time = 0.0

	# The new ball travels generally back toward the side it came from, like a
	# glancing ricochet. Reversed spin helps the two balls look different too.
	var reflected_ball := create_ball(
		split_position - incoming_direction * 6.0 - separation_axis * 3.0,
		reflected_direction * split_speed,
		-original_spin * 0.80
	)
	reflected_ball.last_hitter_direction = ball_state.last_hitter_direction


func direction_with_minimum_horizontal_share(
	direction: Vector2,
	minimum_horizontal_share: float,
	fallback_x_sign: float
) -> Vector2:
	# A direction's x and y portions fit on a unit circle. Once x is chosen, the
	# square-root calculation finds a y value that keeps the direction length at
	# exactly 1. This redirects energy instead of creating extra energy.
	var normalized_direction := direction.normalized()
	if abs(normalized_direction.x) >= minimum_horizontal_share:
		return normalized_direction

	var horizontal_sign: float = sign(normalized_direction.x)
	if is_zero_approx(horizontal_sign):
		horizontal_sign = sign(fallback_x_sign)
	if is_zero_approx(horizontal_sign):
		horizontal_sign = 1.0

	var vertical_sign: float = sign(normalized_direction.y)
	var vertical_share: float = sqrt(max(0.0, 1.0 - minimum_horizontal_share * minimum_horizontal_share))
	return Vector2(
		horizontal_sign * minimum_horizontal_share,
		vertical_sign * vertical_share
	).normalized()


func _on_score_label_gui_input(event: InputEvent) -> void:
	# GUI input is handled separately from court input so tapping the score cannot
	# also move a mobile paddle.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			handle_score_click()

	if event is InputEventScreenTouch:
		if event.pressed:
			handle_score_touch()


func handle_score_click() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - last_score_click_time < 0.15:
		return
	last_score_click_time = now

	if game_over:
		new_game()
		return

	if not restart_confirm_open:
		show_restart_confirm()


func handle_score_touch() -> void:
	touch_controls_seen = true
	# Phones may also synthesize a mouse click from this touch. handle_score_click
	# already ignores a duplicate arriving within 0.15 seconds.
	handle_score_click()


func show_restart_confirm() -> void:
	restart_confirm_open = true
	show_popup("Are you sure?", "Restart this game and reset both scores?", true)


func show_game_over_popup(winner: String) -> void:
	restart_confirm_open = false
	show_popup(winner + " Player Wins!", "Click the score to restart.", false)


func show_popup(title: String, message: String, show_buttons: bool) -> void:
	popup_title_label.text = title
	popup_message_label.text = message
	popup_restart_button.visible = show_buttons
	popup_cancel_button.visible = show_buttons
	if show_buttons:
		popup_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		popup_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_layer.visible = true


func hide_popup() -> void:
	restart_confirm_open = false
	popup_layer.visible = false


func _on_popup_restart_pressed() -> void:
	new_game()


func _on_popup_cancel_pressed() -> void:
	hide_popup()


# --- Mobile touch input ------------------------------------------------------

func handle_touch_press(event: InputEventScreenTouch) -> void:
	# A touch beginning near a paddle grabs it directly. A distant tap creates a
	# destination instead, preventing the paddle from teleporting across court.
	touch_controls_seen = true
	var touch_position := event.position
	if event.pressed and score_label.get_global_rect().has_point(touch_position):
		return

	var is_left_side := touch_position.x < SCREEN_SIZE.x / 2.0
	var touch_player_direction := -1.0 if is_left_side else 1.0
	if event.pressed:
		var held_ball := get_held_ball(touch_player_direction)
		if held_ball != null:
			serve_held_ball(held_ball)
			return

	var now := Time.get_ticks_msec() / 1000.0

	if event.pressed:
		if is_left_side:
			left_touch_active = true
			left_touch_index = event.index
			left_touch_target_y = touch_position.y
			left_touch_start_position = touch_position
			left_touch_press_time = now
			left_touch_can_drag = touch_starts_near_paddle(touch_position, left_paddle)
			left_touch_direct_mode = left_touch_can_drag
			left_touch_grab_offset_y = touch_position.y - left_paddle.position.y
			left_tap_move_active = false
		else:
			right_touch_active = true
			right_touch_index = event.index
			right_touch_target_y = touch_position.y
			right_touch_start_position = touch_position
			right_touch_press_time = now
			right_touch_can_drag = touch_starts_near_paddle(touch_position, right_paddle)
			right_touch_direct_mode = right_touch_can_drag
			right_touch_grab_offset_y = touch_position.y - right_paddle.position.y
			right_tap_move_active = false
	else:
		if event.index == left_touch_index:
			finish_left_touch(touch_position, now)
			left_touch_active = false
			left_touch_index = -1
			left_touch_can_drag = false
			left_touch_direct_mode = false

		if event.index == right_touch_index:
			finish_right_touch(touch_position, now)
			right_touch_active = false
			right_touch_index = -1
			right_touch_can_drag = false
			right_touch_direct_mode = false


func handle_touch_drag(event: InputEventScreenDrag) -> void:
	touch_controls_seen = true
	if event.index == left_touch_index:
		left_touch_target_y = event.position.y
		if left_touch_can_drag:
			left_touch_direct_mode = true
			left_tap_move_active = false
		else:
			left_tap_move_target_y = event.position.y
			left_tap_move_active = true

	if event.index == right_touch_index:
		right_touch_target_y = event.position.y
		if right_touch_can_drag:
			right_touch_direct_mode = true
			right_tap_move_active = false
		else:
			right_tap_move_target_y = event.position.y
			right_tap_move_active = true


func finish_left_touch(touch_position: Vector2, now: float) -> void:
	if is_quick_tap(touch_position, left_touch_start_position, now - left_touch_press_time) and not left_touch_direct_mode:
		check_left_sprint_tap(now)
		left_tap_move_target_y = touch_position.y
		left_tap_move_active = true


func finish_right_touch(touch_position: Vector2, now: float) -> void:
	if is_quick_tap(touch_position, right_touch_start_position, now - right_touch_press_time) and not right_touch_direct_mode:
		check_right_sprint_tap(now)
		right_tap_move_target_y = touch_position.y
		right_tap_move_active = true


func is_quick_tap(touch_position: Vector2, start_position: Vector2, press_seconds: float) -> bool:
	return press_seconds <= TOUCH_TAP_MAX_SECONDS and touch_position.distance_to(start_position) <= TOUCH_TAP_MOVE_MAX_DISTANCE


func touch_starts_near_paddle(touch_position: Vector2, paddle: Panel) -> bool:
	var grab_zone := Rect2(
		Vector2(paddle.position.x - TOUCH_PADDLE_GRAB_PADDING, paddle.position.y - TOUCH_PADDLE_GRAB_PADDING),
		PADDLE_SIZE + Vector2(TOUCH_PADDLE_GRAB_PADDING * 2.0, TOUCH_PADDLE_GRAB_PADDING * 2.0)
	)
	return grab_zone.has_point(touch_position)


# --- Paddle movement, sprint, and slam --------------------------------------

func move_paddles(delta: float) -> void:
	# delta is the fraction of a second since the previous frame. Multiplying
	# pixels-per-second by delta keeps movement similar on fast and slow devices.
	update_sprint_timers(delta)
	check_sprint_taps()

	var left_old_position := left_paddle.position
	var right_old_position := right_paddle.position
	var left_direction := 0.0
	var right_direction := 0.0

	var left_speed := PADDLE_SPEED
	if left_sprint_time_left > 0.0:
		left_speed *= SPRINT_MULTIPLIER

	var right_speed := PADDLE_SPEED
	if right_sprint_time_left > 0.0:
		right_speed *= SPRINT_MULTIPLIER

	if left_touch_active:
		if left_touch_direct_mode:
			left_tap_move_active = false
			move_paddle_direct_to_touch(left_paddle, left_touch_target_y, left_touch_grab_offset_y, delta, true)
		elif left_tap_move_active:
			left_tap_move_active = move_paddle_toward_target(left_paddle, left_tap_move_target_y, left_speed, delta, true)
		else:
			left_paddle_velocity = 0.0
	elif left_tap_move_active:
		left_tap_move_active = move_paddle_toward_target(left_paddle, left_tap_move_target_y, left_speed, delta, true)
	else:
		if Input.is_key_pressed(KEY_W):
			left_direction -= 1.0
		if Input.is_key_pressed(KEY_S):
			left_direction += 1.0
		left_paddle_velocity = left_direction * left_speed
		left_paddle.position.y += left_paddle_velocity * delta

	if right_touch_active:
		if right_touch_direct_mode:
			right_tap_move_active = false
			move_paddle_direct_to_touch(right_paddle, right_touch_target_y, right_touch_grab_offset_y, delta, false)
		elif right_tap_move_active:
			right_tap_move_active = move_paddle_toward_target(right_paddle, right_tap_move_target_y, right_speed, delta, false)
		else:
			right_paddle_velocity = 0.0
	elif right_tap_move_active:
		right_tap_move_active = move_paddle_toward_target(right_paddle, right_tap_move_target_y, right_speed, delta, false)
	else:
		if Input.is_key_pressed(KEY_UP):
			right_direction -= 1.0
		if Input.is_key_pressed(KEY_DOWN):
			right_direction += 1.0
		right_paddle_velocity = right_direction * right_speed
		right_paddle.position.y += right_paddle_velocity * delta


	left_paddle.position.y = clamp(left_paddle.position.y, 0.0, SCREEN_SIZE.y - PADDLE_SIZE.y)
	right_paddle.position.y = clamp(right_paddle.position.y, 0.0, SCREEN_SIZE.y - PADDLE_SIZE.y)
	save_paddle_trail_point(left_paddle_trail, left_old_position, left_paddle.position)
	save_paddle_trail_point(right_paddle_trail, right_old_position, right_paddle.position)


func move_paddle_direct_to_touch(paddle: Panel, target_y: float, grab_offset_y: float, delta: float, is_left_paddle: bool) -> void:
	var old_y := paddle.position.y
	var new_y: float = clamp(target_y - grab_offset_y, 0.0, SCREEN_SIZE.y - PADDLE_SIZE.y)
	paddle.position.y = new_y

	if delta > 0.0:
		var touch_velocity := (new_y - old_y) / delta
		if is_left_paddle:
			left_paddle_velocity = touch_velocity
		else:
			right_paddle_velocity = touch_velocity


func move_paddle_toward_target(paddle: Panel, target_y: float, speed: float, delta: float, is_left_paddle: bool) -> bool:
	var old_y := paddle.position.y
	var target_top: float = clamp(target_y - PADDLE_SIZE.y / 2.0, 0.0, SCREEN_SIZE.y - PADDLE_SIZE.y)
	var distance := target_top - old_y
	var max_step := speed * delta
	var new_y := target_top

	if abs(distance) > max_step:
		new_y = old_y + sign(distance) * max_step

	paddle.position.y = new_y

	if delta > 0.0:
		var target_velocity := (new_y - old_y) / delta
		if is_left_paddle:
			left_paddle_velocity = target_velocity
		else:
			right_paddle_velocity = target_velocity

	return abs(target_top - new_y) > TAP_TARGET_STOP_DISTANCE


func update_slam_controls(delta: float) -> void:
	# Pressing opposite movement keys is treated as one special command. An edge
	# check (was down versus is down) prevents a held pair from slamming every frame.
	var left_was_lunging := left_slam_time_left > 0.0
	var right_was_lunging := right_slam_time_left > 0.0
	left_slam_time_left = max(left_slam_time_left - delta, 0.0)
	right_slam_time_left = max(right_slam_time_left - delta, 0.0)

	if left_was_lunging and left_slam_time_left == 0.0 and left_slam_shudder_left == 0.0:
		left_slam_shudder_left = SLAM_SHUDDER_SECONDS
	if right_was_lunging and right_slam_time_left == 0.0 and right_slam_shudder_left == 0.0:
		right_slam_shudder_left = SLAM_SHUDDER_SECONDS

	left_slam_shudder_left = max(left_slam_shudder_left - delta, 0.0)
	right_slam_shudder_left = max(right_slam_shudder_left - delta, 0.0)

	var left_both_down := Input.is_key_pressed(KEY_W) and Input.is_key_pressed(KEY_S)
	var right_both_down := Input.is_key_pressed(KEY_UP) and Input.is_key_pressed(KEY_DOWN)

	if left_both_down and not left_both_was_down:
		handle_both_keys_pressed(-1.0)
	if right_both_down and not right_both_was_down:
		handle_both_keys_pressed(1.0)

	left_both_was_down = left_both_down
	right_both_was_down = right_both_down


func handle_both_keys_pressed(player_direction: float) -> void:
	var held_ball := get_held_ball(player_direction)
	if held_ball != null:
		serve_held_ball(held_ball)
		return

	if not has_normally_playing_ball():
		return

	if player_direction < 0.0:
		left_slam_time_left = SLAM_LUNGE_SECONDS
		left_slam_shudder_left = 0.0
	else:
		right_slam_time_left = SLAM_LUNGE_SECONDS
		right_slam_shudder_left = 0.0


func get_held_ball(player_direction: float) -> BallStateData:
	for ball_state in active_balls:
		if ball_state.mode == BallMode.HELD and ball_state.held_by_direction == player_direction:
			return ball_state
	return null


func has_normally_playing_ball() -> bool:
	for ball_state in active_balls:
		if ball_state.mode == BallMode.PLAYING:
			return true
	return false


func update_paddle_slam_positions() -> void:
	left_paddle.position.x = LEFT_PADDLE_X + slam_visual_offset(left_slam_time_left, left_slam_shudder_left)
	right_paddle.position.x = RIGHT_PADDLE_X - slam_visual_offset(right_slam_time_left, right_slam_shudder_left)


func slam_visual_offset(lunge_time_left: float, shudder_time_left: float) -> float:
	# The first sine wave makes one smooth forward-and-back lunge. The faster,
	# fading sine wave produces the smaller shudder after impact.
	if lunge_time_left > 0.0:
		var lunge_progress := 1.0 - lunge_time_left / SLAM_LUNGE_SECONDS
		return sin(lunge_progress * PI) * SLAM_LUNGE_DISTANCE

	if shudder_time_left > 0.0:
		var shudder_elapsed := SLAM_SHUDDER_SECONDS - shudder_time_left
		var shudder_strength := shudder_time_left / SLAM_SHUDDER_SECONDS
		return sin(shudder_elapsed * SLAM_SHUDDER_FREQUENCY * TAU) * SLAM_SHUDDER_DISTANCE * shudder_strength

	return 0.0


func update_sprint_timers(delta: float) -> void:
	# Sprint and cooldown are countdown clocks. max(..., 0) prevents a timer from
	# becoming negative and makes exact zero checks reliable.
	var left_was_sprinting := left_sprint_time_left > 0.0
	var right_was_sprinting := right_sprint_time_left > 0.0

	left_sprint_time_left = max(left_sprint_time_left - delta, 0.0)
	right_sprint_time_left = max(right_sprint_time_left - delta, 0.0)
	left_sprint_cooldown_left = max(left_sprint_cooldown_left - delta, 0.0)
	right_sprint_cooldown_left = max(right_sprint_cooldown_left - delta, 0.0)

	if left_was_sprinting and left_sprint_time_left == 0.0:
		left_sprint_cooldown_left = SPRINT_COOLDOWN_SECONDS

	if right_was_sprinting and right_sprint_time_left == 0.0:
		right_sprint_cooldown_left = SPRINT_COOLDOWN_SECONDS


func check_sprint_taps() -> void:
	# A double tap is two new key presses inside DOUBLE_TAP_WINDOW. We ignore a
	# simultaneous up+down press here because that combination belongs to slam.
	var now := Time.get_ticks_msec() / 1000.0
	var left_up_is_down := Input.is_key_pressed(KEY_W)
	var left_down_is_down := Input.is_key_pressed(KEY_S)
	var right_up_is_down := Input.is_key_pressed(KEY_UP)
	var right_down_is_down := Input.is_key_pressed(KEY_DOWN)

	if not (left_up_is_down and left_down_is_down):
		if left_up_is_down and not left_up_was_down:
			check_left_sprint_tap(now)
		if left_down_is_down and not left_down_was_down:
			check_left_sprint_tap(now)

	if not (right_up_is_down and right_down_is_down):
		if right_up_is_down and not right_up_was_down:
			check_right_sprint_tap(now)
		if right_down_is_down and not right_down_was_down:
			check_right_sprint_tap(now)

	left_up_was_down = left_up_is_down
	left_down_was_down = left_down_is_down
	right_up_was_down = right_up_is_down
	right_down_was_down = right_down_is_down


func check_left_sprint_tap(now: float) -> void:
	if left_sprint_cooldown_left == 0.0 and left_sprint_time_left == 0.0:
		if now - left_last_sprint_tap_time <= DOUBLE_TAP_WINDOW:
			start_left_sprint()

	left_last_sprint_tap_time = now


func check_right_sprint_tap(now: float) -> void:
	if right_sprint_cooldown_left == 0.0 and right_sprint_time_left == 0.0:
		if now - right_last_sprint_tap_time <= DOUBLE_TAP_WINDOW:
			start_right_sprint()

	right_last_sprint_tap_time = now


func start_left_sprint() -> void:
	left_sprint_time_left = SPRINT_SECONDS
	left_last_sprint_tap_time = -10.0


func start_right_sprint() -> void:
	right_sprint_time_left = SPRINT_SECONDS
	right_last_sprint_tap_time = -10.0


# --- Per-ball movement and recovery states ---------------------------------

func move_balls(delta: float) -> void:
	# Scoring can remove a ball while this loop is running. Iterating over a copy
	# keeps the original collection safe while balls enter or leave the match.
	var balls_this_frame: Array[BallStateData] = active_balls.duplicate()
	for ball_state in balls_this_frame:
		if not active_balls.has(ball_state):
			continue
		move_ball(ball_state, delta)
		if game_over:
			return


func move_ball(ball_state: BallStateData, delta: float) -> void:
	match ball_state.mode:
		BallMode.PLAYING:
			move_playing_ball(ball_state, delta)
		BallMode.DRIBBLING:
			move_dribbling_ball(ball_state, delta)
		BallMode.BOUNCING_BACK:
			move_bouncing_ball_to_server(ball_state, delta)
		BallMode.HELD:
			update_held_ball_position(ball_state)


func move_playing_ball(ball_state: BallStateData, delta: float) -> void:
	save_ball_trail_point(ball_state)

	# A fast ball can jump several pixels in one frame. Small substeps keep it
	# from skipping through a thin paddle or alien between two screen updates.
	var step_count: int = max(1, int(ceil(ball_state.velocity.length() * delta / MAX_BALL_STEP_DISTANCE)))
	var step_delta := delta / float(step_count)

	for _step in range(step_count):
		# A perpendicular force bends the path without intentionally pushing the
		# ball forward or backward. Its direction depends on the sign of spin.
		var curve := Vector2(-ball_state.velocity.y, ball_state.velocity.x).normalized() * ball_state.spin * SPIN_CURVE_FORCE
		ball_state.velocity += curve * step_delta
		ball_state.speed = min(ball_state.velocity.length(), MAX_BALL_SPEED)
		ball_state.velocity = ball_state.velocity.normalized() * ball_state.speed
		ball_state.node.position += ball_state.velocity * step_delta

		if ball_state.node.position.y - BALL_SIZE.y / 2.0 <= 0.0:
			ball_state.node.position.y = BALL_SIZE.y / 2.0
			bounce_from_wall(ball_state, -1.0)
			play_sound(wall_sound)

		if ball_state.node.position.y + BALL_SIZE.y / 2.0 >= SCREEN_SIZE.y:
			ball_state.node.position.y = SCREEN_SIZE.y - BALL_SIZE.y / 2.0
			bounce_from_wall(ball_state, 1.0)
			play_sound(wall_sound)

		check_ball_collisions(ball_state)
		check_alien_collision(ball_state)

		if ball_state.node.position.x < -BALL_SIZE.x:
			score_and_remove_ball(ball_state, false)
			return

		if ball_state.node.position.x > SCREEN_SIZE.x:
			score_and_remove_ball(ball_state, true)
			return

		# Recovery belongs to each ball, not to the rally as a whole. Either ball
		# can lose its sideways motion, dribble, return, and wait on a paddle while
		# the other ball continues playing.
		if ball_should_start_dribbling(ball_state, step_delta):
			begin_dribbling(ball_state)
			return


func move_dribbling_ball(ball_state: BallStateData, delta: float) -> void:
	save_ball_trail_point(ball_state)
	var radius := BALL_SIZE.x / 2.0
	ball_state.velocity.y += DRIBBLE_GRAVITY * delta
	ball_state.node.position += ball_state.velocity * delta
	ball_state.speed = ball_state.velocity.length()

	if ball_state.node.position.y - radius <= 0.0:
		ball_state.node.position.y = radius
		ball_state.velocity.y = abs(ball_state.velocity.y) * DRIBBLE_BOUNCE_RETENTION
		play_sound(wall_sound)

	if ball_state.node.position.y + radius >= SCREEN_SIZE.y:
		ball_state.node.position.y = SCREEN_SIZE.y - radius
		if abs(ball_state.velocity.y) <= DRIBBLE_STOP_VERTICAL_SPEED:
			begin_bouncing_to_server(ball_state)
			return

		# Each bounce loses vertical motion and surface friction removes some
		# sideways motion and spin, like a ball dribbling on a real floor.
		ball_state.velocity.y = -abs(ball_state.velocity.y) * DRIBBLE_BOUNCE_RETENTION
		ball_state.velocity.x *= DRIBBLE_GROUND_FRICTION
		ball_state.spin *= DRIBBLE_GROUND_FRICTION
		play_sound(wall_sound)

	if ball_state.node.position.x < radius:
		ball_state.node.position.x = radius
		ball_state.velocity.x = abs(ball_state.velocity.x) * 0.25
	if ball_state.node.position.x > SCREEN_SIZE.x - radius:
		ball_state.node.position.x = SCREEN_SIZE.x - radius
		ball_state.velocity.x = -abs(ball_state.velocity.x) * 0.25


func move_bouncing_ball_to_server(ball_state: BallStateData, delta: float) -> void:
	save_ball_trail_point(ball_state)
	var radius := BALL_SIZE.x / 2.0
	var server_paddle := get_server_paddle(ball_state)

	if try_collect_returning_ball(ball_state, server_paddle):
		return

	var waiting_x := server_paddle.position.x - radius
	if ball_state.last_hitter_direction < 0.0:
		waiting_x = server_paddle.position.x + PADDLE_SIZE.x + radius

	var distance := waiting_x - ball_state.node.position.x
	var max_step := BALL_RETURN_SPEED * delta
	if abs(distance) <= max_step:
		ball_state.node.position.x = waiting_x
		ball_state.velocity.x = 0.0
	else:
		ball_state.velocity.x = sign(distance) * BALL_RETURN_SPEED
		ball_state.node.position.x += ball_state.velocity.x * delta

	ball_state.velocity.y += RETURN_BOUNCE_GRAVITY * delta
	ball_state.node.position.y += ball_state.velocity.y * delta
	if ball_state.node.position.y + radius >= SCREEN_SIZE.y:
		ball_state.node.position.y = SCREEN_SIZE.y - radius
		ball_state.velocity.y = -randf_range(RETURN_BOUNCE_MIN_SPEED, RETURN_BOUNCE_MAX_SPEED)
		play_sound(wall_sound)

	ball_state.speed = ball_state.velocity.length()
	try_collect_returning_ball(ball_state, server_paddle)


func begin_dribbling(ball_state: BallStateData) -> void:
	ball_state.mode = BallMode.DRIBBLING
	if is_zero_approx(ball_state.last_hitter_direction):
		ball_state.last_hitter_direction = -sign(ball_state.velocity.x)
		if is_zero_approx(ball_state.last_hitter_direction):
			ball_state.last_hitter_direction = -1.0 if randf() < 0.5 else 1.0

	ball_state.velocity.x *= 0.35
	ball_state.sideways_stall_time = 0.0


func begin_bouncing_to_server(ball_state: BallStateData) -> void:
	ball_state.mode = BallMode.BOUNCING_BACK
	ball_state.node.position.y = SCREEN_SIZE.y - BALL_SIZE.y / 2.0
	ball_state.velocity = Vector2(
		ball_state.last_hitter_direction * BALL_RETURN_SPEED,
		-randf_range(RETURN_BOUNCE_MIN_SPEED, RETURN_BOUNCE_MAX_SPEED)
	)
	ball_state.speed = ball_state.velocity.length()
	ball_state.spin = 0.0
	ball_state.sideways_stall_time = 0.0
	ball_state.trail.clear()


func get_server_paddle(ball_state: BallStateData) -> Panel:
	if ball_state.last_hitter_direction < 0.0:
		return left_paddle
	return right_paddle


func try_collect_returning_ball(ball_state: BallStateData, server_paddle: Panel) -> bool:
	var away_direction := -ball_state.last_hitter_direction
	var contact := circle_paddle_contact(ball_state.node.position, BALL_SIZE.x / 2.0, server_paddle, away_direction)
	if contact.is_empty():
		return false

	ball_state.mode = BallMode.HELD
	ball_state.held_by_direction = ball_state.last_hitter_direction
	var paddle_center_y := server_paddle.position.y + PADDLE_SIZE.y / 2.0
	ball_state.held_offset_y = clamp(
		ball_state.node.position.y - paddle_center_y,
		-PADDLE_SIZE.y / 2.0 + BALL_SIZE.y / 2.0,
		PADDLE_SIZE.y / 2.0 - BALL_SIZE.y / 2.0
	)
	ball_state.velocity = Vector2.ZERO
	ball_state.speed = 0.0
	ball_state.spin = 0.0
	ball_state.trail.clear()
	update_held_ball_position(ball_state)
	play_sound(paddle_sound)
	return true


func update_held_ball_position(ball_state: BallStateData) -> void:
	var server_paddle := get_server_paddle(ball_state)
	var radius := BALL_SIZE.x / 2.0
	if ball_state.held_by_direction < 0.0:
		ball_state.node.position.x = server_paddle.position.x + PADDLE_SIZE.x + radius
	else:
		ball_state.node.position.x = server_paddle.position.x - radius

	ball_state.node.position.y = clamp(
		server_paddle.position.y + PADDLE_SIZE.y / 2.0 + ball_state.held_offset_y,
		radius,
		SCREEN_SIZE.y - radius
	)


func serve_held_ball(ball_state: BallStateData) -> void:
	if ball_state.mode != BallMode.HELD:
		return

	var serve_direction := -ball_state.held_by_direction
	var server_paddle_velocity := right_paddle_velocity
	if ball_state.held_by_direction < 0.0:
		server_paddle_velocity = left_paddle_velocity

	# Releasing while the paddle is moving works like brushing a tennis ball:
	# paddle speed becomes launch angle, extra speed, and spin.
	var held_hit_spot: float = clamp(ball_state.held_offset_y / (PADDLE_SIZE.y / 2.0), -1.0, 1.0)
	var swing_angle := server_paddle_velocity / PADDLE_SPEED * SERVE_SWING_TO_ANGLE
	var release_angle: float = clamp(
		swing_angle + held_hit_spot * SERVE_HIT_SPOT_TO_ANGLE + randf_range(-SERVE_RANDOM_ANGLE, SERVE_RANDOM_ANGLE),
		-1.15,
		1.15
	)
	var contact_side := -serve_direction

	ball_state.mode = BallMode.PLAYING
	ball_state.speed = min(START_BALL_SPEED + abs(server_paddle_velocity) * RACKET_POWER, MAX_BALL_SPEED)
	ball_state.spin = clamp(
		contact_side * server_paddle_velocity * PADDLE_BRUSH_TO_SPIN + held_hit_spot * HIT_SPOT_TO_SPIN,
		-MAX_SPIN,
		MAX_SPIN
	)
	ball_state.sideways_stall_time = 0.0
	ball_state.trail.clear()
	ball_state.velocity = Vector2(serve_direction, release_angle).normalized() * ball_state.speed
	play_sound(paddle_sound)


func save_ball_trail_point(ball_state: BallStateData) -> void:
	ball_state.trail.push_front(ball_state.node.position)
	if ball_state.trail.size() > MOTION_BLUR_POINTS:
		ball_state.trail.pop_back()


func save_paddle_trail_point(paddle_trail: Array[Vector2], old_position: Vector2, new_position: Vector2) -> void:
	if old_position.distance_squared_to(new_position) <= 0.25:
		paddle_trail.clear()
		return

	paddle_trail.push_front(old_position)
	if paddle_trail.size() > PADDLE_MOTION_BLUR_POINTS:
		paddle_trail.pop_back()


func spin_balls(delta: float) -> void:
	for ball_state in active_balls:
		spin_ball(ball_state, delta)


func spin_ball(ball_state: BallStateData, delta: float) -> void:
	if ball_state.mode == BallMode.BOUNCING_BACK:
		ball_state.visual_rotation += ball_state.velocity.x / (BALL_SIZE.x / 2.0) * delta
		ball_state.node.rotation = ball_state.visual_rotation
		return

	if ball_state.mode == BallMode.HELD:
		return

	ball_state.spin *= pow(SPIN_DECAY, delta * 60.0)
	ball_state.visual_rotation += ball_state.spin * VISUAL_SPIN_MULTIPLIER * delta
	ball_state.node.rotation = ball_state.visual_rotation


func bounce_from_wall(ball_state: BallStateData, wall_side: float) -> void:
	var old_x_speed := ball_state.velocity.x
	var old_y_speed := ball_state.velocity.y
	var surface_spin_speed := -wall_side * ball_state.spin * SPIN_SURFACE_SPEED
	var relative_surface_speed := old_x_speed + surface_spin_speed
	# Friction acts at the contact point rather than the center. That sideways
	# force changes both travel direction and rotation, just like a real ball.
	var desired_stick_impulse: float = -relative_surface_speed * WALL_SQUISHINESS
	var max_friction_impulse: float = abs(old_y_speed) * WALL_SURFACE_FRICTION
	var friction_impulse: float = clamp(desired_stick_impulse, -max_friction_impulse, max_friction_impulse)

	ball_state.velocity.y *= -1.0
	ball_state.velocity.x += friction_impulse
	# Multiball starts with extra explosion energy, so its wall bounces lose a
	# little more speed. This makes the eventual dribble-and-return visible again.
	var speed_retention := WALL_SPEED_RETENTION
	if active_balls.size() > 1:
		speed_retention = MULTIBALL_WALL_SPEED_RETENTION
	ball_state.speed *= speed_retention
	ball_state.velocity = ball_state.velocity.normalized() * ball_state.speed
	ball_state.spin = clamp(ball_state.spin * WALL_SPIN_LOSS + -wall_side * friction_impulse * WALL_FRICTION_TO_SPIN, -MAX_SPIN, MAX_SPIN)


func ball_should_start_dribbling(ball_state: BallStateData, delta: float) -> bool:
	# Split balls begin with 40% momentum plus the explosion kick. Their lower
	# threshold gives that smaller amount time to play out before recovery begins.
	var minimum_speed := MIN_RALLY_BALL_SPEED
	if active_balls.size() > 1:
		minimum_speed = MIN_MULTIBALL_RALLY_SPEED
	if ball_state.speed < minimum_speed:
		return true

	if abs(ball_state.velocity.x) < MIN_SIDEWAYS_SPEED:
		ball_state.sideways_stall_time += delta
	else:
		ball_state.sideways_stall_time = 0.0

	return ball_state.sideways_stall_time >= SIDEWAYS_STALL_SECONDS


func check_ball_collisions(ball_state: BallStateData) -> void:
	var left_center_x := left_paddle.position.x + PADDLE_SIZE.x / 2.0
	var right_center_x := right_paddle.position.x + PADDLE_SIZE.x / 2.0
	var ball_radius := BALL_SIZE.x / 2.0

	if ball_state.node.position.x >= left_center_x:
		var left_contact := circle_paddle_contact(ball_state.node.position, ball_radius, left_paddle, 1.0)
		if not left_contact.is_empty():
			bounce_from_paddle(ball_state, left_paddle, left_paddle_velocity, 1.0, left_contact)

	if ball_state.node.position.x <= right_center_x:
		var right_contact := circle_paddle_contact(ball_state.node.position, ball_radius, right_paddle, -1.0)
		if not right_contact.is_empty():
			bounce_from_paddle(ball_state, right_paddle, right_paddle_velocity, -1.0, right_contact)


func circle_paddle_contact(circle_center: Vector2, ball_radius: float, paddle: Panel, x_direction: float) -> Dictionary:
	# A vertical capsule is a line segment with a circle swept along it. Finding
	# the closest point on that segment gives flat-side, round-end, and diagonal
	# corner normals from one compact calculation.
	var paddle_radius := PADDLE_SIZE.x / 2.0
	var paddle_center_x := paddle.position.x + paddle_radius
	var cap_top := paddle.position.y + paddle_radius
	var cap_bottom := paddle.position.y + PADDLE_SIZE.y - paddle_radius
	var closest_point := Vector2(paddle_center_x, clamp(circle_center.y, cap_top, cap_bottom))
	var offset := circle_center - closest_point
	var distance_squared := offset.length_squared()
	var combined_radius := ball_radius + paddle_radius

	if distance_squared > combined_radius * combined_radius:
		return {}

	if distance_squared > 0.0001:
		var distance := sqrt(distance_squared)
		return {
			"normal": offset / distance,
			"penetration": combined_radius - distance,
		}

	return {
		"normal": Vector2(x_direction, 0.0),
		"penetration": combined_radius,
	}


func bounce_from_paddle(ball_state: BallStateData, paddle: Panel, paddle_velocity: float, x_direction: float, contact: Dictionary) -> void:
	var contact_normal: Vector2 = contact["normal"]
	var paddle_motion := Vector2(0.0, paddle_velocity)
	var relative_velocity := ball_state.velocity - paddle_motion
	if relative_velocity.dot(contact_normal) >= 0.0:
		return

	var paddle_center := paddle.position.y + PADDLE_SIZE.y / 2.0
	var ball_center := ball_state.node.position.y
	var hit_spot: float = clamp((ball_center - paddle_center) / (PADDLE_SIZE.y / 2.0), -1.0, 1.0)
	var round_edge_effect: float = sign(hit_spot) * hit_spot * hit_spot * ROUND_BALL_EDGE_LIFT
	var contact_side := -x_direction
	var surface_spin_speed := contact_side * ball_state.spin * SPIN_SURFACE_SPEED
	var brush_speed := paddle_velocity - surface_spin_speed
	var swing_push := paddle_velocity / PADDLE_SPEED * 0.35
	var brush_push := brush_speed * PADDLE_BRUSH_TO_ANGLE
	var spin_push := contact_side * ball_state.spin * SPIN_PADDLE_GRIP
	var wobble := randf_range(-CONTROLLED_BOUNCE_WOBBLE, CONTROLLED_BOUNCE_WOBBLE)
	var bounce_angle: float = clamp(hit_spot + round_edge_effect + swing_push + brush_push + spin_push + wobble, -1.25, 1.25)
	var arcade_direction := Vector2(x_direction, bounce_angle).normalized()

	var reflected_relative := relative_velocity - 2.0 * relative_velocity.dot(contact_normal) * contact_normal
	var physical_direction := (reflected_relative + paddle_motion).normalized()
	var front_contact: float = abs(contact_normal.x)
	# Pure physics can make Pong frustrating. This blend keeps rounded-end hits
	# believable while preserving enough arcade aiming to remain playable.
	var physics_blend: float = lerp(PADDLE_END_PHYSICS_BLEND, PADDLE_FRONT_PHYSICS_BLEND, front_contact)
	var bounce_direction := arcade_direction.lerp(physical_direction, physics_blend).normalized()

	if bounce_direction.x * x_direction < PADDLE_MIN_AWAY_COMPONENT:
		bounce_direction.x = x_direction * PADDLE_MIN_AWAY_COMPONENT
		bounce_direction = bounce_direction.normalized()

	var slam_active := left_slam_time_left > 0.0 if x_direction > 0.0 else right_slam_time_left > 0.0
	var hit_multiplier := SLAM_POWER_MULTIPLIER if slam_active else 1.0
	var swing_power: float = abs(paddle_velocity) * RACKET_POWER
	var normal_hit_power := PADDLE_HIT_SPEED_BOOST + swing_power
	var spin_change := contact_side * brush_speed * PADDLE_BRUSH_TO_SPIN + (hit_spot + round_edge_effect) * HIT_SPOT_TO_SPIN
	var incoming_speed: float = max(ball_state.speed, START_BALL_SPEED)
	if slam_active:
		incoming_speed *= SLAM_BALL_SPEED_MULTIPLIER
	ball_state.speed = min(incoming_speed + normal_hit_power * hit_multiplier, MAX_BALL_SPEED)
	ball_state.spin = clamp(ball_state.spin + spin_change * (SLAM_SPIN_MULTIPLIER if slam_active else 1.0), -MAX_SPIN, MAX_SPIN)
	ball_state.velocity = bounce_direction * ball_state.speed
	ball_state.node.position += contact_normal * (float(contact["penetration"]) + PADDLE_SEPARATION_DISTANCE)
	ball_state.last_hitter_direction = -x_direction
	ball_state.sideways_stall_time = 0.0

	if slam_active:
		finish_successful_slam(x_direction)
	else:
		play_sound(paddle_sound)


func finish_successful_slam(x_direction: float) -> void:
	if x_direction > 0.0:
		left_slam_time_left = 0.0
		left_slam_shudder_left = SLAM_SHUDDER_SECONDS
	else:
		right_slam_time_left = 0.0
		right_slam_shudder_left = SLAM_SHUDDER_SECONDS
	play_sound(slam_sound)


# --- Scoring, rally reset, and help text ------------------------------------

func score_and_remove_ball(ball_state: BallStateData, left_player_scored: bool) -> void:
	# A multiball rally scores one ball at a time. Removing this ball does not
	# disturb the other one; only an empty collection starts the next rally.
	active_balls.erase(ball_state)
	ball_state.node.queue_free()
	if active_balls.size() == 1:
		# Give the remaining ball a fresh single-ball recovery timer instead of
		# carrying over time accumulated while it was part of multiball.
		active_balls[0].sideways_stall_time = 0.0
	if left_player_scored:
		left_score += 1
	else:
		right_score += 1

	update_score_text()
	play_sound(score_sound)

	if left_score >= WINNING_SCORE or right_score >= WINNING_SCORE:
		finish_game()
	elif active_balls.is_empty():
		reset_round()


func finish_game() -> void:
	game_over = true
	clear_active_balls()
	var winner := "Left"
	if right_score > left_score:
		winner = "Right"
	help_label.text = winner + " player wins! Click the score to restart."
	show_game_over_popup(winner)
	play_sound(win_sound)


func create_ball(start_position: Vector2, start_velocity: Vector2, start_spin: float = 0.0) -> BallStateData:
	var ball_node: Node2D = SpinningBall.new()
	ball_node.name = "Ball" + str(active_balls.size() + 1)
	ball_node.position = start_position
	ball_layer.add_child(ball_node)

	var ball_state: BallStateData = BallStateData.new(ball_node)
	ball_state.speed = start_velocity.length()
	ball_state.velocity = start_velocity
	ball_state.spin = start_spin
	ball_state.mode = BallMode.PLAYING
	active_balls.append(ball_state)
	return ball_state


func clear_active_balls() -> void:
	for ball_state in active_balls:
		if is_instance_valid(ball_state.node):
			ball_state.node.queue_free()
	active_balls.clear()


func reset_round() -> void:
	# A point starts a new ball, not a new match. An alien already on the court
	# keeps its position, sound, and 20-second timer across this rally reset.
	clear_active_balls()
	left_paddle.position = Vector2(LEFT_PADDLE_X, SCREEN_SIZE.y / 2.0 - PADDLE_SIZE.y / 2.0)
	right_paddle.position = Vector2(RIGHT_PADDLE_X, SCREEN_SIZE.y / 2.0 - PADDLE_SIZE.y / 2.0)
	left_slam_time_left = 0.0
	right_slam_time_left = 0.0
	left_slam_shudder_left = 0.0
	right_slam_shudder_left = 0.0
	left_paddle_trail.clear()
	right_paddle_trail.clear()
	left_paddle_velocity = 0.0
	right_paddle_velocity = 0.0

	var x_direction := 1.0
	if randf() < 0.5:
		x_direction = -1.0
	var y_direction := randf_range(-0.6, 0.6)
	create_ball(SCREEN_SIZE / 2.0, Vector2(x_direction, y_direction).normalized() * START_BALL_SPEED)
	if alien == null:
		roll_next_alien_delay()
	update_score_text()


func update_score_text() -> void:
	score_label.text = str(left_score) + "     " + str(right_score)


func update_help_text() -> void:
	var held_ball := get_any_held_ball()
	if held_ball != null:
		if touch_controls_seen:
			help_label.text = "Tap your side to serve"
		elif held_ball.held_by_direction < 0.0:
			help_label.text = "Left player: press W + S together to serve"
		else:
			help_label.text = "Right player: press Up + Down together to serve"
		return

	if touch_controls_seen:
		help_label.text = "Touch: drag to follow, tap to move, double-tap to sprint"
	else:
		help_label.text = "W/S  " + sprint_status(left_sprint_time_left, left_sprint_cooldown_left) + "    Up/Down  " + sprint_status(right_sprint_time_left, right_sprint_cooldown_left) + "    Together: slam    R restart"


func get_any_held_ball() -> BallStateData:
	for ball_state in active_balls:
		if ball_state.mode == BallMode.HELD:
			return ball_state
	return null


func sprint_status(sprint_time_left: float, cooldown_left: float) -> String:
	if sprint_time_left > 0.0:
		return "SPRINT " + str(snapped(sprint_time_left, 0.1)) + "s"

	if cooldown_left > 0.0:
		return "cooldown " + str(ceil(cooldown_left)) + "s"

	return "double-tap to sprint"


func reset_sprints() -> void:
	left_last_sprint_tap_time = -10.0
	right_last_sprint_tap_time = -10.0
	left_sprint_time_left = 0.0
	right_sprint_time_left = 0.0
	left_sprint_cooldown_left = 0.0
	right_sprint_cooldown_left = 0.0
	left_up_was_down = false
	left_down_was_down = false
	right_up_was_down = false
	right_down_was_down = false
	left_both_was_down = false
	right_both_was_down = false
	left_touch_active = false
	right_touch_active = false
	left_touch_index = -1
	right_touch_index = -1
	left_touch_can_drag = false
	right_touch_can_drag = false
	left_touch_direct_mode = false
	right_touch_direct_mode = false
	left_touch_grab_offset_y = PADDLE_SIZE.y / 2.0
	right_touch_grab_offset_y = PADDLE_SIZE.y / 2.0
	left_tap_move_active = false
	right_tap_move_active = false


func new_game() -> void:
	left_score = 0
	right_score = 0
	game_over = false
	hide_popup()
	reset_sprints()
	update_help_text()
	# Restarting the whole match is different from scoring one point, so it does
	# clear any alien left from the previous match.
	remove_alien(false)
	reset_round()
