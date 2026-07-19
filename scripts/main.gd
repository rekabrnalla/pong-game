extends Node2D

const SCREEN_SIZE := Vector2(1280, 720)
const PADDLE_SIZE := Vector2(22, 130)
const BALL_SIZE := Vector2(34, 34)
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
const MIN_RALLY_BALL_SPEED := 300.0
const MIN_SIDEWAYS_SPEED := 70.0
const SIDEWAYS_STALL_SECONDS := 1.25
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
const WINNING_SCORE := 7

var left_score := 0
var right_score := 0
var ball_speed := START_BALL_SPEED
var ball_velocity := Vector2.ZERO
var ball_spin := 0.0
var ball_rotation := 0.0
var sideways_stall_time := 0.0
var last_hitter_direction := 0.0
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

var left_paddle: Panel
var right_paddle: Panel
var ball: Node2D
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


func _ready() -> void:
	create_game_objects()
	reset_round()


func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_R):
		new_game()

	if restart_confirm_open:
		queue_redraw()
		return

	if game_over:
		return

	move_paddles(delta)
	move_ball(delta)
	spin_ball(delta)
	update_help_text()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if restart_confirm_open or game_over:
		return

	if event is InputEventScreenTouch:
		handle_touch_press(event)

	if event is InputEventScreenDrag:
		handle_touch_drag(event)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), Color(0.05, 0.06, 0.08), true)
	draw_touch_guides()
	draw_paddle_motion_blur(left_paddle_trail, Color(0.2, 0.8, 1.0), left_paddle_velocity)
	draw_paddle_motion_blur(right_paddle_trail, Color(1.0, 0.35, 0.35), right_paddle_velocity)
	draw_ball_motion_blur()

	var dash_height := 24.0
	var gap := 16.0
	var x := SCREEN_SIZE.x / 2.0 - 2.0
	var y := 0.0
	while y < SCREEN_SIZE.y:
		draw_rect(Rect2(Vector2(x, y), Vector2(4, dash_height)), Color(0.7, 0.75, 0.8, 0.5), true)
		y += dash_height + gap


func draw_touch_guides() -> void:
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


func draw_ball_motion_blur() -> void:
	for i in range(ball_trail.size()):
		if ball_trail[i].distance_to(ball.position) < MOTION_BLUR_CLEAR_DISTANCE:
			continue

		var age := float(i + 1) / float(MOTION_BLUR_POINTS + 1)
		var radius := BALL_SIZE.x / 2.0 * (1.0 - age * 0.35)
		var alpha := MOTION_BLUR_ALPHA * (1.0 - age)
		draw_circle(ball_trail[i], radius, Color(1.0, 0.94, 0.16, alpha))


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


func create_game_objects() -> void:
	left_paddle = make_paddle("LeftPaddle", Color(0.2, 0.8, 1.0))
	right_paddle = make_paddle("RightPaddle", Color(1.0, 0.35, 0.35))
	ball = SpinningBall.new()
	ball.name = "Ball"
	add_child(ball)
	create_sound_players()

	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.position = Vector2(SCREEN_SIZE.x / 2.0 - 210.0, 20)
	score_label.size = Vector2(420, 60)
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


func _on_score_label_gui_input(event: InputEvent) -> void:
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
	if game_over:
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


func handle_touch_press(event: InputEventScreenTouch) -> void:
	touch_controls_seen = true
	var touch_position := event.position
	if event.pressed and score_label.get_global_rect().has_point(touch_position):
		return

	var is_left_side := touch_position.x < SCREEN_SIZE.x / 2.0
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


func move_paddles(delta: float) -> void:
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

	var step_count: int = max(1, int(ceil(ball_velocity.length() * delta / MAX_BALL_STEP_DISTANCE)))
	var step_delta := delta / float(step_count)

	for _step in range(step_count):
		var curve := Vector2(-ball_velocity.y, ball_velocity.x).normalized() * ball_spin * SPIN_CURVE_FORCE
		ball_velocity += curve * step_delta
		ball_speed = min(ball_velocity.length(), MAX_BALL_SPEED)
		ball_velocity = ball_velocity.normalized() * ball_speed
		ball.position += ball_velocity * step_delta

		if ball.position.y - BALL_SIZE.y / 2.0 <= 0.0:
			ball.position.y = BALL_SIZE.y / 2.0
			bounce_from_wall(-1.0)
			play_sound(wall_sound)

		if ball.position.y + BALL_SIZE.y / 2.0 >= SCREEN_SIZE.y:
			ball.position.y = SCREEN_SIZE.y - BALL_SIZE.y / 2.0
			bounce_from_wall(1.0)
			play_sound(wall_sound)

		check_ball_collisions()

		if ball.position.x < -BALL_SIZE.x:
			right_score += 1
			after_score()
			return

		if ball.position.x > SCREEN_SIZE.x:
			left_score += 1
			after_score()
			return

		if ball_needs_re_serve(step_delta):
			re_serve_to_last_hitter()
			return


func save_ball_trail_point() -> void:
	ball_trail.push_front(ball.position)
	if ball_trail.size() > MOTION_BLUR_POINTS:
		ball_trail.pop_back()


func save_paddle_trail_point(paddle_trail: Array[Vector2], old_position: Vector2, new_position: Vector2) -> void:
	if old_position.distance_squared_to(new_position) <= 0.25:
		paddle_trail.clear()
		return

	paddle_trail.push_front(old_position)
	if paddle_trail.size() > PADDLE_MOTION_BLUR_POINTS:
		paddle_trail.pop_back()


func spin_ball(delta: float) -> void:
	ball_spin *= pow(SPIN_DECAY, delta * 60.0)
	ball_rotation += ball_spin * VISUAL_SPIN_MULTIPLIER * delta
	ball.rotation = ball_rotation


func bounce_from_wall(wall_side: float) -> void:
	var old_x_speed := ball_velocity.x
	var old_y_speed := ball_velocity.y
	var surface_spin_speed := -wall_side * ball_spin * SPIN_SURFACE_SPEED
	var relative_surface_speed := old_x_speed + surface_spin_speed
	var desired_stick_impulse: float = -relative_surface_speed * WALL_SQUISHINESS
	var max_friction_impulse: float = abs(old_y_speed) * WALL_SURFACE_FRICTION
	var friction_impulse: float = clamp(desired_stick_impulse, -max_friction_impulse, max_friction_impulse)

	ball_velocity.y *= -1.0
	ball_velocity.x += friction_impulse
	ball_speed *= WALL_SPEED_RETENTION
	ball_velocity = ball_velocity.normalized() * ball_speed
	ball_spin = clamp(ball_spin * WALL_SPIN_LOSS + -wall_side * friction_impulse * WALL_FRICTION_TO_SPIN, -MAX_SPIN, MAX_SPIN)


func ball_needs_re_serve(delta: float) -> bool:
	if ball_speed < MIN_RALLY_BALL_SPEED:
		return true

	if abs(ball_velocity.x) < MIN_SIDEWAYS_SPEED:
		sideways_stall_time += delta
	else:
		sideways_stall_time = 0.0

	return sideways_stall_time >= SIDEWAYS_STALL_SECONDS


func re_serve_to_last_hitter() -> void:
	var x_direction := last_hitter_direction
	if is_zero_approx(x_direction):
		x_direction = -1.0 if randf() < 0.5 else 1.0

	ball.position = SCREEN_SIZE / 2.0
	ball_speed = START_BALL_SPEED
	ball_spin = 0.0
	ball_rotation = 0.0
	ball.rotation = 0.0
	ball_trail.clear()
	sideways_stall_time = 0.0
	var y_direction := randf_range(-0.45, 0.45)
	ball_velocity = Vector2(x_direction, y_direction).normalized() * ball_speed
	play_sound(paddle_sound)


func check_ball_collisions() -> void:
	var left_center_x := left_paddle.position.x + PADDLE_SIZE.x / 2.0
	var right_center_x := right_paddle.position.x + PADDLE_SIZE.x / 2.0
	var ball_radius := BALL_SIZE.x / 2.0

	if ball.position.x >= left_center_x:
		var left_contact := circle_paddle_contact(ball.position, ball_radius, left_paddle, 1.0)
		if not left_contact.is_empty():
			bounce_from_paddle(left_paddle, left_paddle_velocity, 1.0, left_contact)

	if ball.position.x <= right_center_x:
		var right_contact := circle_paddle_contact(ball.position, ball_radius, right_paddle, -1.0)
		if not right_contact.is_empty():
			bounce_from_paddle(right_paddle, right_paddle_velocity, -1.0, right_contact)


func circle_paddle_contact(circle_center: Vector2, ball_radius: float, paddle: Panel, x_direction: float) -> Dictionary:
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


func bounce_from_paddle(paddle: Panel, paddle_velocity: float, x_direction: float, contact: Dictionary) -> void:
	var contact_normal: Vector2 = contact["normal"]
	var paddle_motion := Vector2(0.0, paddle_velocity)
	var relative_velocity := ball_velocity - paddle_motion
	if relative_velocity.dot(contact_normal) >= 0.0:
		return

	var paddle_center := paddle.position.y + PADDLE_SIZE.y / 2.0
	var ball_center := ball.position.y
	var hit_spot: float = clamp((ball_center - paddle_center) / (PADDLE_SIZE.y / 2.0), -1.0, 1.0)
	var round_edge_effect: float = sign(hit_spot) * hit_spot * hit_spot * ROUND_BALL_EDGE_LIFT
	var contact_side := -x_direction
	var surface_spin_speed := contact_side * ball_spin * SPIN_SURFACE_SPEED
	var brush_speed := paddle_velocity - surface_spin_speed
	var swing_push := paddle_velocity / PADDLE_SPEED * 0.35
	var brush_push := brush_speed * PADDLE_BRUSH_TO_ANGLE
	var spin_push := contact_side * ball_spin * SPIN_PADDLE_GRIP
	var wobble := randf_range(-CONTROLLED_BOUNCE_WOBBLE, CONTROLLED_BOUNCE_WOBBLE)
	var bounce_angle: float = clamp(hit_spot + round_edge_effect + swing_push + brush_push + spin_push + wobble, -1.25, 1.25)
	var arcade_direction := Vector2(x_direction, bounce_angle).normalized()

	var reflected_relative := relative_velocity - 2.0 * relative_velocity.dot(contact_normal) * contact_normal
	var physical_direction := (reflected_relative + paddle_motion).normalized()
	var front_contact: float = abs(contact_normal.x)
	var physics_blend: float = lerp(PADDLE_END_PHYSICS_BLEND, PADDLE_FRONT_PHYSICS_BLEND, front_contact)
	var bounce_direction := arcade_direction.lerp(physical_direction, physics_blend).normalized()

	if bounce_direction.x * x_direction < PADDLE_MIN_AWAY_COMPONENT:
		bounce_direction.x = x_direction * PADDLE_MIN_AWAY_COMPONENT
		bounce_direction = bounce_direction.normalized()

	var swing_power: float = abs(paddle_velocity) * RACKET_POWER
	ball_speed = min(max(ball_speed, START_BALL_SPEED) + PADDLE_HIT_SPEED_BOOST + swing_power, MAX_BALL_SPEED)
	ball_spin = clamp(ball_spin + contact_side * brush_speed * PADDLE_BRUSH_TO_SPIN + (hit_spot + round_edge_effect) * HIT_SPOT_TO_SPIN, -MAX_SPIN, MAX_SPIN)
	ball_velocity = bounce_direction * ball_speed
	ball.position += contact_normal * (float(contact["penetration"]) + PADDLE_SEPARATION_DISTANCE)
	last_hitter_direction = -x_direction
	sideways_stall_time = 0.0
	play_sound(paddle_sound)


func after_score() -> void:
	update_score_text()
	play_sound(score_sound)

	if left_score >= WINNING_SCORE or right_score >= WINNING_SCORE:
		game_over = true
		var winner := "Left"
		if right_score > left_score:
			winner = "Right"
		help_label.text = winner + " player wins! Click the score to restart."
		show_game_over_popup(winner)
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
	sideways_stall_time = 0.0
	last_hitter_direction = 0.0
	ball_trail.clear()
	left_paddle_trail.clear()
	right_paddle_trail.clear()
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
		help_label.text = "Touch: drag to follow, tap to move, double-tap to sprint"
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
	reset_round()


class SpinningBall:
	extends Node2D

	func _draw() -> void:
		var radius := BALL_SIZE.x / 2.0
		var yellow := Color(1.0, 0.94, 0.16)
		var black := Color(0.035, 0.04, 0.035)
		var spin_ring_radius := radius - 6.0
		draw_circle(Vector2(2.0, 2.0), radius, Color(0.0, 0.0, 0.0, 0.32))
		draw_circle(Vector2.ZERO, radius, yellow)
		draw_arc(Vector2.ZERO, spin_ring_radius, 0.0, TAU, 64, black, 3.0)
		draw_line(Vector2(0.0, -spin_ring_radius), Vector2(0.0, spin_ring_radius), black, 3.0)
		draw_arc(Vector2.ZERO, radius - 1.5, 0.0, TAU, 64, Color(1.0, 1.0, 0.72, 0.42), 1.5)
