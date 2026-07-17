extends Node2D

const SCREEN_SIZE := Vector2(1280, 720)
const PADDLE_SIZE := Vector2(22, 130)
const BALL_SIZE := Vector2(34, 34)
const PADDLE_SPEED := 520.0
const START_BALL_SPEED := 420.0
const MAX_BALL_SPEED := 980.0
const PADDLE_HIT_SPEED_BOOST := 24.0
const RACKET_POWER := 0.12
const MAX_SPIN := 18.0
const SPIN_FROM_SWING := 0.028
const SPIN_FROM_HIT_SPOT := 3.0
const SPIN_CURVE_FORCE := 20.0
const SPIN_WALL_GRIP := 0.75
const SPIN_PADDLE_GRIP := 0.10
const SPIN_DECAY := 0.995
const ROUND_BALL_EDGE_LIFT := 0.35
const CONTROLLED_BOUNCE_WOBBLE := 0.08
const DOUBLE_TAP_WINDOW := 0.30
const SPRINT_MULTIPLIER := 1.65
const SPRINT_SECONDS := 2.0
const SPRINT_COOLDOWN_SECONDS := 5.0
const MOTION_BLUR_POINTS := 9
const MOTION_BLUR_ALPHA := 0.22
const WINNING_SCORE := 7

var left_score := 0
var right_score := 0
var ball_speed := START_BALL_SPEED
var ball_velocity := Vector2.ZERO
var ball_spin := 0.0
var ball_rotation := 0.0
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
var ball_trail: Array[Vector2] = []
var left_touch_active := false
var right_touch_active := false
var left_touch_index := -1
var right_touch_index := -1
var left_touch_target_y := 0.0
var right_touch_target_y := 0.0
var touch_controls_seen := false
var game_over := false

var left_paddle: ColorRect
var right_paddle: ColorRect
var ball: Node2D
var score_label: Label
var help_label: Label
var paddle_sound: AudioStreamPlayer
var wall_sound: AudioStreamPlayer
var score_sound: AudioStreamPlayer
var win_sound: AudioStreamPlayer


func _ready() -> void:
	create_game_objects()
	reset_round()


func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_R):
		new_game()

	if game_over:
		return

	move_paddles(delta)
	move_ball(delta)
	spin_ball(delta)
	check_ball_collisions()
	update_help_text()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		handle_touch_press(event)

	if event is InputEventScreenDrag:
		handle_touch_drag(event)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), Color(0.05, 0.06, 0.08), true)
	draw_touch_guides()
	draw_ball_motion_blur()

	var dash_height := 24.0
	var gap := 16.0
	var x := SCREEN_SIZE.x / 2.0 - 2.0
	var y := 0.0
	while y < SCREEN_SIZE.y:
		draw_rect(Rect2(Vector2(x, y), Vector2(4, dash_height)), Color(0.7, 0.75, 0.8, 0.5), true)
		y += dash_height + gap


func draw_touch_guides() -> void:
	if left_touch_active:
		draw_rect(Rect2(Vector2.ZERO, Vector2(SCREEN_SIZE.x / 2.0, SCREEN_SIZE.y)), Color(0.2, 0.8, 1.0, 0.08), true)
		draw_line(Vector2(0.0, left_touch_target_y), Vector2(SCREEN_SIZE.x / 2.0, left_touch_target_y), Color(0.2, 0.8, 1.0, 0.35), 2.0)

	if right_touch_active:
		draw_rect(Rect2(Vector2(SCREEN_SIZE.x / 2.0, 0.0), Vector2(SCREEN_SIZE.x / 2.0, SCREEN_SIZE.y)), Color(1.0, 0.35, 0.35, 0.08), true)
		draw_line(Vector2(SCREEN_SIZE.x / 2.0, right_touch_target_y), Vector2(SCREEN_SIZE.x, right_touch_target_y), Color(1.0, 0.35, 0.35, 0.35), 2.0)


func draw_ball_motion_blur() -> void:
	for i in range(ball_trail.size()):
		var age := float(i + 1) / float(MOTION_BLUR_POINTS + 1)
		var radius := BALL_SIZE.x / 2.0 * (1.0 - age * 0.35)
		var alpha := MOTION_BLUR_ALPHA * (1.0 - age)
		draw_circle(ball_trail[i], radius, Color(1.0, 0.94, 0.16, alpha))


func create_game_objects() -> void:
	left_paddle = make_rect("LeftPaddle", PADDLE_SIZE, Color(0.2, 0.8, 1.0))
	right_paddle = make_rect("RightPaddle", PADDLE_SIZE, Color(1.0, 0.35, 0.35))
	ball = SpinningBall.new()
	ball.name = "Ball"
	add_child(ball)
	create_sound_players()

	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.position = Vector2(0, 20)
	score_label.size = Vector2(SCREEN_SIZE.x, 60)
	score_label.add_theme_font_size_override("font_size", 42)
	add_child(score_label)

	help_label = Label.new()
	help_label.name = "HelpLabel"
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_label.position = Vector2(0, SCREEN_SIZE.y - 42)
	help_label.size = Vector2(SCREEN_SIZE.x, 30)
	help_label.add_theme_font_size_override("font_size", 18)
	update_help_text()
	add_child(help_label)


func make_rect(node_name: String, rect_size: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = node_name
	rect.size = rect_size
	rect.color = color
	add_child(rect)
	return rect


func create_sound_players() -> void:
	paddle_sound = make_sound_player("PaddleSound", 720.0, 0.07, 0.35)
	wall_sound = make_sound_player("WallSound", 420.0, 0.05, 0.25)
	score_sound = make_sound_player("ScoreSound", 180.0, 0.22, 0.35)
	win_sound = make_sound_player("WinSound", 920.0, 0.35, 0.30)


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


func play_sound(player: AudioStreamPlayer) -> void:
	player.stop()
	player.play()


func handle_touch_press(event: InputEventScreenTouch) -> void:
	touch_controls_seen = true
	var touch_position := event.position
	var is_left_side := touch_position.x < SCREEN_SIZE.x / 2.0

	if event.pressed:
		if is_left_side:
			left_touch_active = true
			left_touch_index = event.index
			left_touch_target_y = touch_position.y
		else:
			right_touch_active = true
			right_touch_index = event.index
			right_touch_target_y = touch_position.y
	else:
		if event.index == left_touch_index:
			left_touch_active = false
			left_touch_index = -1

		if event.index == right_touch_index:
			right_touch_active = false
			right_touch_index = -1


func handle_touch_drag(event: InputEventScreenDrag) -> void:
	touch_controls_seen = true
	if event.index == left_touch_index:
		left_touch_target_y = event.position.y

	if event.index == right_touch_index:
		right_touch_target_y = event.position.y


func move_paddles(delta: float) -> void:
	update_sprint_timers(delta)
	check_sprint_taps()

	var left_direction := 0.0
	var right_direction := 0.0

	var left_speed := PADDLE_SPEED
	if left_sprint_time_left > 0.0:
		left_speed *= SPRINT_MULTIPLIER

	var right_speed := PADDLE_SPEED
	if right_sprint_time_left > 0.0:
		right_speed *= SPRINT_MULTIPLIER

	if left_touch_active:
		move_paddle_to_touch(left_paddle, left_touch_target_y, delta, true)
	else:
		if Input.is_key_pressed(KEY_W):
			left_direction -= 1.0
		if Input.is_key_pressed(KEY_S):
			left_direction += 1.0
		left_paddle_velocity = left_direction * left_speed
		left_paddle.position.y += left_paddle_velocity * delta

	if right_touch_active:
		move_paddle_to_touch(right_paddle, right_touch_target_y, delta, false)
	else:
		if Input.is_key_pressed(KEY_UP):
			right_direction -= 1.0
		if Input.is_key_pressed(KEY_DOWN):
			right_direction += 1.0
		right_paddle_velocity = right_direction * right_speed
		right_paddle.position.y += right_paddle_velocity * delta


	left_paddle.position.y = clamp(left_paddle.position.y, 0.0, SCREEN_SIZE.y - PADDLE_SIZE.y)
	right_paddle.position.y = clamp(right_paddle.position.y, 0.0, SCREEN_SIZE.y - PADDLE_SIZE.y)


func move_paddle_to_touch(paddle: ColorRect, target_y: float, delta: float, is_left_paddle: bool) -> void:
	var old_y := paddle.position.y
	var new_y: float = clamp(target_y - PADDLE_SIZE.y / 2.0, 0.0, SCREEN_SIZE.y - PADDLE_SIZE.y)
	paddle.position.y = new_y

	if delta > 0.0:
		var touch_velocity := (new_y - old_y) / delta
		if is_left_paddle:
			left_paddle_velocity = touch_velocity
		else:
			right_paddle_velocity = touch_velocity


func update_sprint_timers(delta: float) -> void:
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
	var now := Time.get_ticks_msec() / 1000.0
	var left_up_is_down := Input.is_key_pressed(KEY_W)
	var left_down_is_down := Input.is_key_pressed(KEY_S)
	var right_up_is_down := Input.is_key_pressed(KEY_UP)
	var right_down_is_down := Input.is_key_pressed(KEY_DOWN)

	if left_up_is_down and not left_up_was_down:
		check_left_sprint_tap(now)

	if left_down_is_down and not left_down_was_down:
		check_left_sprint_tap(now)

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


func move_ball(delta: float) -> void:
	save_ball_trail_point()

	var curve := Vector2(-ball_velocity.y, ball_velocity.x).normalized() * ball_spin * SPIN_CURVE_FORCE
	ball_velocity += curve * delta
	ball_speed = clamp(ball_velocity.length(), START_BALL_SPEED, MAX_BALL_SPEED)
	ball_velocity = ball_velocity.normalized() * ball_speed
	ball.position += ball_velocity * delta

	if ball.position.y - BALL_SIZE.y / 2.0 <= 0.0:
		ball.position.y = BALL_SIZE.y / 2.0
		bounce_from_wall()
		play_sound(wall_sound)

	if ball.position.y + BALL_SIZE.y / 2.0 >= SCREEN_SIZE.y:
		ball.position.y = SCREEN_SIZE.y - BALL_SIZE.y / 2.0
		bounce_from_wall()
		play_sound(wall_sound)

	if ball.position.x < -BALL_SIZE.x:
		right_score += 1
		after_score()

	if ball.position.x > SCREEN_SIZE.x:
		left_score += 1
		after_score()


func save_ball_trail_point() -> void:
	ball_trail.push_front(ball.position)
	if ball_trail.size() > MOTION_BLUR_POINTS:
		ball_trail.pop_back()


func spin_ball(delta: float) -> void:
	ball_spin *= pow(SPIN_DECAY, delta * 60.0)
	ball_rotation += ball_spin * delta
	ball.rotation = ball_rotation


func bounce_from_wall() -> void:
	ball_velocity.y *= -1.0
	ball_velocity.x += ball_spin * SPIN_WALL_GRIP
	ball_velocity = ball_velocity.normalized() * ball_speed
	ball_spin *= 0.92


func check_ball_collisions() -> void:
	var left_box := Rect2(left_paddle.position, PADDLE_SIZE)
	var right_box := Rect2(right_paddle.position, PADDLE_SIZE)

	if ball_velocity.x < 0.0 and circle_hits_rect(ball.position, BALL_SIZE.x / 2.0, left_box):
		bounce_from_paddle(left_paddle, left_paddle_velocity, 1.0)

	if ball_velocity.x > 0.0 and circle_hits_rect(ball.position, BALL_SIZE.x / 2.0, right_box):
		bounce_from_paddle(right_paddle, right_paddle_velocity, -1.0)


func circle_hits_rect(circle_center: Vector2, radius: float, rect: Rect2) -> bool:
	var closest_x: float = clamp(circle_center.x, rect.position.x, rect.position.x + rect.size.x)
	var closest_y: float = clamp(circle_center.y, rect.position.y, rect.position.y + rect.size.y)
	var closest_point := Vector2(closest_x, closest_y)
	return circle_center.distance_squared_to(closest_point) <= radius * radius


func bounce_from_paddle(paddle: ColorRect, paddle_velocity: float, x_direction: float) -> void:
	var paddle_center := paddle.position.y + PADDLE_SIZE.y / 2.0
	var ball_center := ball.position.y
	var hit_spot := (ball_center - paddle_center) / (PADDLE_SIZE.y / 2.0)
	var round_edge_effect: float = sign(hit_spot) * hit_spot * hit_spot * ROUND_BALL_EDGE_LIFT
	var swing_push := paddle_velocity / PADDLE_SPEED * 0.45
	var spin_push := ball_spin * SPIN_PADDLE_GRIP
	var wobble := randf_range(-CONTROLLED_BOUNCE_WOBBLE, CONTROLLED_BOUNCE_WOBBLE)
	var bounce_angle: float = clamp(hit_spot + round_edge_effect + swing_push + spin_push + wobble, -1.25, 1.25)

	var swing_power: float = abs(paddle_velocity) * RACKET_POWER
	ball_speed = min(ball_speed + PADDLE_HIT_SPEED_BOOST + swing_power, MAX_BALL_SPEED)
	ball_spin = clamp(ball_spin + paddle_velocity * SPIN_FROM_SWING + (hit_spot + round_edge_effect) * SPIN_FROM_HIT_SPOT, -MAX_SPIN, MAX_SPIN)
	ball_velocity = Vector2(x_direction, bounce_angle).normalized() * ball_speed
	play_sound(paddle_sound)

	if x_direction > 0.0:
		ball.position.x = paddle.position.x + PADDLE_SIZE.x + BALL_SIZE.x / 2.0
	else:
		ball.position.x = paddle.position.x - BALL_SIZE.x / 2.0


func after_score() -> void:
	update_score_text()
	play_sound(score_sound)

	if left_score >= WINNING_SCORE or right_score >= WINNING_SCORE:
		game_over = true
		var winner := "Left"
		if right_score > left_score:
			winner = "Right"
		help_label.text = winner + " player wins! Press R to play again."
		play_sound(win_sound)
	else:
		reset_round()


func reset_round() -> void:
	left_paddle.position = Vector2(48, SCREEN_SIZE.y / 2.0 - PADDLE_SIZE.y / 2.0)
	right_paddle.position = Vector2(SCREEN_SIZE.x - 48 - PADDLE_SIZE.x, SCREEN_SIZE.y / 2.0 - PADDLE_SIZE.y / 2.0)
	ball.position = SCREEN_SIZE / 2.0
	ball_speed = START_BALL_SPEED
	ball_spin = 0.0
	ball_rotation = 0.0
	ball.rotation = 0.0
	ball_trail.clear()
	left_paddle_velocity = 0.0
	right_paddle_velocity = 0.0

	var x_direction := 1.0
	if randf() < 0.5:
		x_direction = -1.0
	var y_direction := randf_range(-0.6, 0.6)
	ball_velocity = Vector2(x_direction, y_direction).normalized() * ball_speed
	update_score_text()


func update_score_text() -> void:
	score_label.text = str(left_score) + "     " + str(right_score)


func update_help_text() -> void:
	if touch_controls_seen:
		help_label.text = "Touch: drag your side to move the paddle    Computer: W/S and Up/Down"
	else:
		help_label.text = "W/S  " + sprint_status(left_sprint_time_left, left_sprint_cooldown_left) + "    Up/Down  " + sprint_status(right_sprint_time_left, right_sprint_cooldown_left) + "    R restart"


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
	left_touch_active = false
	right_touch_active = false
	left_touch_index = -1
	right_touch_index = -1


func new_game() -> void:
	left_score = 0
	right_score = 0
	game_over = false
	reset_sprints()
	update_help_text()
	reset_round()


class SpinningBall:
	extends Node2D

	func _draw() -> void:
		var radius := BALL_SIZE.x / 2.0
		draw_circle(Vector2(2.0, 2.0), radius, Color(0.0, 0.0, 0.0, 0.32))
		draw_circle(Vector2.ZERO, radius, Color(0.08, 0.08, 0.08))
		draw_circle(Vector2.ZERO, radius - 2.0, Color(1.0, 0.94, 0.16))
		draw_circle(Vector2(-radius * 0.32, -radius * 0.35), radius * 0.28, Color(1.0, 1.0, 0.55, 0.55))
		draw_arc(Vector2.ZERO, radius * 0.58, -1.35, 1.35, 32, Color(0.1, 0.13, 0.07), 3.0)
		draw_arc(Vector2.ZERO, radius * 0.58, PI - 1.35, PI + 1.35, 32, Color(0.1, 0.13, 0.07), 3.0)
		draw_arc(Vector2.ZERO, radius - 1.5, 0.0, TAU, 64, Color(1.0, 1.0, 0.72, 0.35), 1.5)
