class_name MatchSim
extends RefCounted
## One match against the CPU as an integer simulation on fixed ticks. Positions are court units (1/100 of a court
## pixel) from the court center, y down. The player paddle is on the left, the CPU paddle on the right. The caller
## runs `step` once per `[sim_tick]` with the player's paddle direction and reads `events` after the steps of a frame.

enum Phase { SERVE_WAIT, PLAYING, FINISHED }

## `events` bits: what happened since the caller last cleared `events`.
const EVENT_SERVE: int = 1
const EVENT_HIT_PLAYER: int = EVENT_SERVE * 2
const EVENT_HIT_CPU: int = EVENT_HIT_PLAYER * 2
const EVENT_WALL: int = EVENT_HIT_CPU * 2
const EVENT_POINT_PLAYER: int = EVENT_WALL * 2
const EVENT_POINT_CPU: int = EVENT_POINT_PLAYER * 2
const EVENT_MATCH_END: int = EVENT_POINT_CPU * 2

## Side of a serve: toward the player (left) or the CPU (right).
const SIDE_PLAYER: int = -1
const SIDE_CPU: int = 1

const _PERMILLE: int = MatchConstants.PERMILLE
const _PURPOSE: String = "play_session_simulation"

var phase: Phase = Phase.SERVE_WAIT
var tick: int = 0
var events: int = 0

var player_y: int = 0
var cpu_y: int = 0
var ball_x: int = 0
var ball_y: int = 0
var ball_vx: int = 0
var ball_vy: int = 0
## Horizontal ball speed in units per tick; it grows by `[ball_speed_step]` per paddle hit.
var ball_speed: int = 0
## Positions before the last step, for drawing between two ticks.
var prev_player_y: int = 0
var prev_cpu_y: int = 0
var prev_ball_x: int = 0
var prev_ball_y: int = 0

var player_score: int = 0
var cpu_score: int = 0
## Where the ball met the paddle at the last paddle hit: from the paddle center, y down, within the paddle.
var hit_offset: int = 0
## Paddle hits of the current rally; 0 from the serve on.
var rally: int = 0
## Player paddle hits of the current rally.
var rally_player: int = 0
var longest_rally: int = 0
## Player paddle hits of the longest rally; the CPU hit the rest of it.
var longest_rally_player: int = 0
## Ticks until the serve while `phase` is `SERVE_WAIT`.
var serve_ticks_left: int = 0
var serve_to: int = SIDE_PLAYER
## Vertical speed the next serve leaves with. It is chosen when the serve wait starts, so the screen can show the
## serve direction during the wait.
var serve_vy: int = 0
## Horizontal speed of a serve.
var serve_speed: int = 0

var court_half_w: int = 0
var court_half_h: int = 0
var paddle_half_h: int = 0
var paddle_half_w: int = 0
var ball_half: int = 0
var player_face_x: int = 0
var cpu_face_x: int = 0

var _points_to_win: int = 0
var _paddle_speed: int = 0
var _paddle_speed_start: int = 0
var _paddle_ramp_ticks: int = 0
var _paddle_carry_ticks: int = 0
## Ticks the player paddle has moved since it last stood still longer than `[paddle_carry]`.
var _player_move_ticks: int = 0
## Ticks the player paddle has stood still in a row.
var _player_still_ticks: int = 0
var _speed_start: int = 0
var _speed_step: int = 0
var _speed_max: int = 0
var _bounce_vy_permille: int = 0
var _serve_vy_permille: int = 0
var _serve_wait_ticks: int = 0
var _first_serve_wait_ticks: int = 0
var _cpu_speed: int = 0
var _cpu_drift_permille: int = 0
var _cpu_reaction_ticks: int = 0
var _cpu_error_base: int = 0
var _cpu_error_vy_permille: int = 0
var _cpu_error_speed_permille: int = 0
var _cpu_aim_offset: int = 0
var _cpu_target_y: int = 0
var _cpu_wait_ticks: int = 0
var _random: UtilRandom = null


## A new match: scores 0, paddles centered, the first serve toward the player after the first serve wait, which is
## longer than the wait after a point. `seed_value` fixes the CPU's choices and the serve angles.
func _init(seed_value: int) -> void:
	var tick_ms: int = maxi(GameSetting.sim_tick(), 1)
	_points_to_win = GameSetting.points_to_win()
	court_half_w = UtilCore.floor_div(GameSetting.court_width(), 2)
	court_half_h = UtilCore.floor_div(GameSetting.court_height(), 2)
	paddle_half_h = UtilCore.floor_div(GameSetting.paddle_height(), 2)
	paddle_half_w = UtilCore.floor_div(GameSetting.paddle_width(), 2)
	ball_half = UtilCore.floor_div(GameSetting.ball_size(), 2)
	player_face_x = -court_half_w + GameSetting.paddle_inset() + paddle_half_w
	cpu_face_x = court_half_w - GameSetting.paddle_inset() - paddle_half_w
	_paddle_speed = GameSetting.paddle_speed()
	_paddle_speed_start = mini(GameSetting.paddle_speed_start(), _paddle_speed)
	_paddle_ramp_ticks = UtilCore.floor_div(GameSetting.paddle_ramp(), tick_ms)
	_paddle_carry_ticks = UtilCore.floor_div(GameSetting.paddle_carry(), tick_ms)
	_speed_start = GameSetting.ball_speed_start()
	_speed_step = GameSetting.ball_speed_step()
	_speed_max = GameSetting.ball_speed_max()
	_bounce_vy_permille = GameSetting.bounce_vy_max_permille()
	_serve_vy_permille = GameSetting.serve_vy_max_permille()
	serve_speed = GameSetting.serve_speed()
	_serve_wait_ticks = maxi(UtilCore.floor_div(GameSetting.serve_delay(), tick_ms), 1)
	_first_serve_wait_ticks = maxi(UtilCore.floor_div(GameSetting.first_serve_delay(), tick_ms), 1)
	_cpu_speed = GameSetting.cpu_speed()
	_cpu_drift_permille = GameSetting.cpu_drift_permille()
	_cpu_reaction_ticks = UtilCore.floor_div(GameSetting.cpu_reaction(), tick_ms)
	_cpu_error_base = GameSetting.cpu_error_base()
	_cpu_error_vy_permille = GameSetting.cpu_error_vy_permille()
	_cpu_error_speed_permille = GameSetting.cpu_error_speed_permille()
	_cpu_aim_offset = GameSetting.cpu_aim_offset()
	_random = UtilCore.create_random(UtilCore.make_purpose_seed(_PURPOSE, seed_value))
	_wait_serve(SIDE_PLAYER, _first_serve_wait_ticks)


## One tick. `input_dir` is the player's paddle direction: -1 up, 1 down, 0 still. Other values count as 0.
func step(input_dir: int) -> void:
	tick += 1
	prev_player_y = player_y
	prev_cpu_y = cpu_y
	prev_ball_x = ball_x
	prev_ball_y = ball_y
	var dir: int = input_dir if input_dir == -1 or input_dir == 1 else 0
	player_y = clampi(player_y + dir * player_speed(dir), -paddle_limit(), paddle_limit())
	if dir == 0:
		_player_still_ticks += 1
		if _player_still_ticks > _paddle_carry_ticks:
			_player_move_ticks = 0
	else:
		_player_still_ticks = 0
		_player_move_ticks += 1
	_move_cpu()
	if phase == Phase.SERVE_WAIT:
		serve_ticks_left -= 1
		if serve_ticks_left <= 0:
			_serve()
	elif phase == Phase.PLAYING:
		_move_ball()


## The player paddle speed of the next tick held toward `dir`: it starts at `[paddle_speed_start]` from standing
## still and grows evenly to `[paddle_speed]` over `[paddle_ramp]`, so a short tap moves the paddle a little. A
## direction change, or a stop no longer than `[paddle_carry]`, keeps the speed reached, so a last moment correction is
## not slow.
func player_speed(dir: int) -> int:
	if dir == 0:
		return 0
	var held: int = _player_move_ticks
	if held >= _paddle_ramp_ticks:
		return _paddle_speed
	return _paddle_speed_start + UtilCore.floor_div((_paddle_speed - _paddle_speed_start) * held, _paddle_ramp_ticks)


## The farthest a paddle center goes from the court center line.
func paddle_limit() -> int:
	return court_half_h - paddle_half_h


## Whether one side needs one point to win while the match goes on.
func is_match_point() -> bool:
	return phase != Phase.FINISHED and (player_score == _points_to_win - 1 or cpu_score == _points_to_win - 1)


func points_to_win() -> int:
	return _points_to_win


## The y where the ball center meets the vertical line `face_x` on its current path with wall bounces. The ball
## y if it moves away from that line.
func predict_y(face_x: int) -> int:
	var edge: int = face_x - ball_half if ball_vx > 0 else face_x + ball_half
	var dx: int = edge - ball_x
	if ball_vx == 0 or (dx > 0) != (ball_vx > 0):
		return ball_y
	var raw: int = ball_y + _div(ball_vy * dx, ball_vx)
	return _fold(raw)


## Where the ball center may go between the walls.
func ball_limit() -> int:
	return court_half_h - ball_half


func _wait_serve(side: int, wait_ticks: int) -> void:
	phase = Phase.SERVE_WAIT
	serve_ticks_left = wait_ticks
	serve_to = side
	var max_vy: int = UtilCore.floor_div(serve_speed * _serve_vy_permille, _PERMILLE)
	serve_vy = UtilCore.range_int(_random, -max_vy, max_vy)
	rally = 0
	rally_player = 0
	ball_x = 0
	ball_y = 0
	ball_vx = 0
	ball_vy = 0
	ball_speed = serve_speed


## The serve leaves at `[serve_speed]`, slower than the rally start, along the direction chosen for the wait.
func _serve() -> void:
	phase = Phase.PLAYING
	ball_speed = serve_speed
	ball_x = 0
	ball_y = 0
	ball_vx = serve_to * ball_speed
	ball_vy = serve_vy
	prev_ball_x = ball_x
	prev_ball_y = ball_y
	events |= EVENT_SERVE
	if serve_to == SIDE_CPU:
		_plan_cpu()


func _move_ball() -> void:
	var nx: int = ball_x + ball_vx
	var ny: int = ball_y + ball_vy
	var top: int = -ball_limit()
	var bottom: int = ball_limit()
	if ny < top:
		ny = 2 * top - ny
		ball_vy = -ball_vy
		events |= EVENT_WALL
	elif ny > bottom:
		ny = 2 * bottom - ny
		ball_vy = -ball_vy
		events |= EVENT_WALL
	if ball_vx < 0 and ball_x - ball_half >= player_face_x and nx - ball_half < player_face_x:
		if _try_hit(nx, ny, player_face_x + ball_half, player_y, 1):
			events |= EVENT_HIT_PLAYER
			_plan_cpu()
			return
	elif ball_vx > 0 and ball_x + ball_half <= cpu_face_x and nx + ball_half > cpu_face_x:
		if _try_hit(nx, ny, cpu_face_x - ball_half, cpu_y, -1):
			events |= EVENT_HIT_CPU
			return
	ball_x = nx
	ball_y = ny
	if ball_x + ball_half < -court_half_w:
		_score(false)
	elif ball_x - ball_half > court_half_w:
		_score(true)


## Hits the ball back from the paddle at `paddle_y` when the ball center reaches `contact_x` within the paddle. The
## return leaves toward `out_dir` faster by `[ball_speed_step]` (from at least `[ball_speed_start]`, so a hit of the
## slower serve goes on as a rally from the start speed), steeper the farther from the paddle center it hits.
func _try_hit(nx: int, ny: int, contact_x: int, paddle_y: int, out_dir: int) -> bool:
	var dx: int = nx - ball_x
	var cross_y: int = ny
	if dx != 0:
		cross_y = ball_y + _div((ny - ball_y) * (contact_x - ball_x), dx)
	var reach: int = paddle_half_h + ball_half
	var offset: int = cross_y - paddle_y
	if absi(offset) > reach:
		return false
	rally += 1
	if out_dir == 1:
		rally_player += 1
	if rally > longest_rally:
		longest_rally = rally
		longest_rally_player = rally_player
	ball_speed = mini(maxi(ball_speed, _speed_start) + _speed_step, _speed_max)
	var offset_permille: int = clampi(UtilCore.floor_div(offset * _PERMILLE, reach), -_PERMILLE, _PERMILLE)
	ball_vx = out_dir * ball_speed
	ball_vy = UtilCore.floor_div(ball_speed * offset_permille * _bounce_vy_permille, _PERMILLE * _PERMILLE)
	hit_offset = clampi(offset, -paddle_half_h, paddle_half_h)
	ball_x = contact_x
	ball_y = clampi(cross_y, -ball_limit(), ball_limit())
	return true


func _score(by_player: bool) -> void:
	if by_player:
		player_score += 1
		events |= EVENT_POINT_PLAYER
	else:
		cpu_score += 1
		events |= EVENT_POINT_CPU
	if player_score >= _points_to_win or cpu_score >= _points_to_win:
		phase = Phase.FINISHED
		rally = 0
		rally_player = 0
		ball_vx = 0
		ball_vy = 0
		events |= EVENT_MATCH_END
		return
	_wait_serve(SIDE_PLAYER if not by_player else SIDE_CPU, _serve_wait_ticks)


## Chooses where the CPU paddle goes for a ball coming at it: the predicted meeting point with an error that grows
## with the vertical ball speed and with the ball speed above the start speed, and an aim offset so its returns are not
## always flat. It moves after a reaction wait.
func _plan_cpu() -> void:
	var meet: int = predict_y(cpu_face_x)
	var error_range: int = _cpu_error_base + UtilCore.floor_div(absi(ball_vy) * _cpu_error_vy_permille, _PERMILLE) \
		+ UtilCore.floor_div(maxi(ball_speed - _speed_start, 0) * _cpu_error_speed_permille, _PERMILLE)
	var error: int = UtilCore.range_int(_random, -error_range, error_range)
	var aim: int = UtilCore.range_int(_random, -_cpu_aim_offset, _cpu_aim_offset)
	_cpu_target_y = clampi(meet + error + aim, -paddle_limit(), paddle_limit())
	_cpu_wait_ticks = _cpu_reaction_ticks


func _move_cpu() -> void:
	var coming: bool = phase == Phase.PLAYING and ball_vx > 0
	var speed: int = _cpu_speed
	var target: int = _cpu_target_y
	if not coming:
		target = 0
		speed = UtilCore.floor_div(_cpu_speed * _cpu_drift_permille, _PERMILLE)
	elif _cpu_wait_ticks > 0:
		_cpu_wait_ticks -= 1
		return
	var diff: int = target - cpu_y
	cpu_y += clampi(diff, -speed, speed)


## `a` divided by `b` rounded down, for a `b` of either sign. `UtilCore.floor_div` takes a positive divisor only.
func _div(a: int, b: int) -> int:
	if b < 0:
		return UtilCore.floor_div(-a, -b)
	return UtilCore.floor_div(a, b)


## `raw` folded into the space between the walls the way the ball bounces.
func _fold(raw: int) -> int:
	var top: int = -ball_limit()
	var span: int = 2 * ball_limit()
	if span <= 0:
		return 0
	var m: int = UtilCore.floor_mod(raw - top, 2 * span)
	if m <= span:
		return top + m
	return top + 2 * span - m
