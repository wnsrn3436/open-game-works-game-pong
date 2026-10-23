class_name MatchScene
extends SceneBase
## The match against the CPU. It starts a play session on the server, runs `MatchSim` on fixed ticks from game time
## with the player's paddle input, draws the court, plays the hit and score feedback, and when the match ends sends
## the result with `FinishPlaySession` and opens the result panel. The HUD is the root panel; it follows
## `MatchStateChangedEvent`. The pause popup pauses game time with `TimeCore.set_paused` while it is open.

enum Stage { STARTING, PLAYING, ENDING, SAVING, RESULT, LEAVING }

const _UP: StringName = &"move_up"
const _DOWN: StringName = &"move_down"

@export var camera: Camera2D
@export var court: MatchCourtView
@export var player_paddle: MatchPaddleView
@export var cpu_paddle: MatchPaddleView
@export var ball: MatchBallView

var _stage: Stage = Stage.STARTING
var _sim: MatchSim = null
var _play_session_id: String = ""
var _tick_ms: int = 1
var _acc_ms: int = 0
var _end_wait_ms: int = 0
var _input_dir: int = 0
var _paused: bool = false
var _moved: bool = false
var _best_before: int = 0
var _speed_start: int = 0
var _speed_max: int = 0
var _fast_permille: int = 0
var _flash: TweenDefinition = null
var _send_finish: Callable = Callable()
var _shown_player_score: int = -1
var _shown_cpu_score: int = -1
var _shown_rally: int = -1
var _shown_match_point: bool = false
var _shown_hint: bool = false
var _shown_starting: bool = false
var _shown_serving: bool = false


func on_preload(preload_request: PreloadRequest, _prefill_items: Array[PrefillItem]) -> void:
	for key: String in _sound_keys():
		preload_request.add_item(key, ResourceCore.BaseKind.AUDIO_STREAM)
	var tween_kind: int = TweenCore.get_preset_kind()
	preload_request.add_item(ResourceKey.TWEEN__MATCH__PADDLE_HIT, tween_kind)
	preload_request.add_item(ResourceKey.TWEEN__MATCH__CONTACT_MARK, tween_kind)
	preload_request.add_item(ResourceKey.TWEEN__MATCH__SCORE_FLASH, tween_kind)
	preload_request.add_item(ResourceKey.TWEEN__MATCH__SCORE_POP, tween_kind)


func on_prepare() -> bool:
	_tick_ms = maxi(GameSetting.sim_tick(), 1)
	_speed_start = GameSetting.ball_speed_start()
	_speed_max = GameSetting.ball_speed_max()
	_fast_permille = GameSetting.fast_ball_permille()
	var units: float = MatchConstants.UNITS_PER_PIXEL
	var court_size: Vector2 = Vector2(float(GameSetting.court_width()), float(GameSetting.court_height())) / units
	var paddle_size: Vector2 = Vector2(float(GameSetting.paddle_width()), float(GameSetting.paddle_height())) / units
	var ball_side: float = float(GameSetting.ball_size()) / units
	court.setup(court_size, ball_side, GameSetting.trail_length())
	player_paddle.set_look(paddle_size, MatchConstants.PLAYER_COLOR)
	cpu_paddle.set_look(paddle_size, MatchConstants.CPU_COLOR)
	ball.set_look(ball_side, MatchConstants.BALL_SLOW_COLOR)
	_send_finish = _finish_match
	return CameraCore.attach_camera(camera)


func on_start() -> void:
	SoundCore.stop_bgm()
	_flash = ResourceCore.get_loaded(ResourceKey.TWEEN__MATCH__SCORE_FLASH, TweenCore.get_preset_kind(), scope) as TweenDefinition
	EventCore.subscribe(MatchPauseRequestedEvent, _on_pause_requested)
	_begin_match()


func on_exit() -> void:
	EventCore.unsubscribe_all(self)
	_set_paused(false)
	GameUpdateCore.set_in_play(false)
	CameraCore.detach_camera()


## The simulation of the match on screen. `null` before the first match starts.
func get_sim() -> MatchSim:
	return _sim


## Whether the match runs: the server started its play session and the match has not ended.
func is_running() -> bool:
	return _stage == Stage.PLAYING


## Whether the pause popup holds the match.
func is_paused() -> bool:
	return _paused


## Starts a new match: a new simulation and a new play session on the server. The match runs once the server answers.
func _begin_match() -> void:
	_stage = Stage.STARTING
	_sim = MatchSim.new(TimeCore.get_device_time())
	_acc_ms = 0
	_input_dir = 0
	court.clear_trail()
	_draw_sim(0.0)
	_publish_state(true)
	var request: CoreContract.StartPlaySessionRequest = CoreContract.StartPlaySessionRequest.new()
	request.mode_id = ReservedId.match_mode()
	request.level_id = 0
	NetworkCore.send(request, _on_started, _on_start_failed)


func _on_started(response: ContractMessage) -> void:
	var started: CoreContract.StartPlaySessionResponse = response as CoreContract.StartPlaySessionResponse
	if started == null or _stage != Stage.STARTING:
		return
	_play_session_id = started.play_session_id
	GameUpdateCore.set_in_play(true)
	_stage = Stage.PLAYING
	_publish_state(true)


func _on_start_failed(_failure: RequestFailure) -> bool:
	if _stage == Stage.STARTING:
		_leave_to_menu()
	return false


func _process(_delta: float) -> void:
	if (_stage != Stage.PLAYING and _stage != Stage.ENDING) or _paused:
		return
	var held_dir: int = _input_dir
	var dir: int = _read_input()
	if dir != held_dir:
		_settle_held_input(held_dir)
	var frame_ms: int = TimeCore.get_game_frame_ms()
	_acc_ms += frame_ms
	var ticks: int = 0
	while _acc_ms >= _tick_ms and ticks < MatchConstants.MAX_TICKS_PER_FRAME:
		_sim.step(dir)
		_acc_ms -= _tick_ms
		ticks += 1
	if _acc_ms >= _tick_ms:
		_acc_ms = 0
	_handle_events()
	_draw_sim(clampf(float(_acc_ms) / float(_tick_ms), 0.0, 1.0))
	if _stage == Stage.PLAYING and _sim.phase == MatchSim.Phase.FINISHED:
		_stage = Stage.ENDING
		_end_wait_ms = GameSetting.match_end_delay()
	elif _stage == Stage.ENDING:
		_end_wait_ms -= frame_ms
		if _end_wait_ms <= 0:
			_stage = Stage.SAVING
			_send_finish.call_deferred()


## The paddle direction of the held move actions. A change is the first visible answer to that input.
func _read_input() -> int:
	var dir: int = 0
	if InputCore.is_pressed(_UP):
		dir -= 1
	if InputCore.is_pressed(_DOWN):
		dir += 1
	if dir != _input_dir:
		_input_dir = dir
		EventCore.publish(EventCore.acquire(MatchRespondedEvent))
		if dir != 0 and not _moved:
			_moved = true
			_publish_state(false)
	return dir


## The time since the last tick was played with the input held before this frame. When it is at least half a tick, one
## more tick runs with that input, so the paddle stops within half a tick of where it was drawn (see `_draw_sim`).
func _settle_held_input(held_dir: int) -> void:
	if held_dir == 0 or _acc_ms * 2 < _tick_ms:
		return
	_sim.step(held_dir)
	_acc_ms -= _tick_ms


func _handle_events() -> void:
	var events: int = _sim.events
	_sim.events = 0
	if events == 0:
		return
	if events & MatchSim.EVENT_SERVE:
		_play_sound(ReservedSound.match_serve())
		court.clear_trail()
		EventCore.publish(EventCore.acquire(MatchServedEvent))
	if events & MatchSim.EVENT_WALL:
		_play_sound(ReservedSound.match_wall_bounce())
	if events & MatchSim.EVENT_HIT_PLAYER:
		_on_paddle_hit(player_paddle)
	if events & MatchSim.EVENT_HIT_CPU:
		_on_paddle_hit(cpu_paddle)
	if events & MatchSim.EVENT_POINT_PLAYER:
		_on_point(ReservedSound.match_score_player())
		EventCore.publish(EventCore.acquire(MatchPointWonEvent))
	if events & MatchSim.EVENT_POINT_CPU:
		_on_point(ReservedSound.match_score_cpu())
		EventCore.publish(EventCore.acquire(MatchPointLostEvent))
	if events & MatchSim.EVENT_MATCH_END:
		_play_sound(ReservedSound.match_win() if _sim.player_score > _sim.cpu_score else ReservedSound.match_lose())
	_publish_state(false)


func _on_paddle_hit(paddle: MatchPaddleView) -> void:
	_play_sound(ReservedSound.match_paddle_hit())
	paddle.mark_contact(float(_sim.hit_offset) / MatchConstants.UNITS_PER_PIXEL, scope)
	TweenCore.play_preset(ResourceKey.TWEEN__MATCH__PADDLE_HIT, scope, paddle)
	CameraCore.shake(GameSetting.shake_paddle_hit_fast() if _speed_permille() >= _fast_permille else GameSetting.shake_paddle_hit())


func _on_point(sound_key: String) -> void:
	_play_sound(sound_key)
	court.clear_trail()
	CameraCore.shake(GameSetting.shake_score())
	if _flash != null:
		ScreenEffectCore.play_preset(ScreenEffectCore.ScreenEffectChannel.WORLD, self, _flash)


func _play_sound(key: String) -> void:
	SoundCore.play(key, SoundCore.SoundBus.SFX, scope)


## How far the ball speed is from the start speed to the top speed, in permille.
func _speed_permille() -> int:
	var span: int = _speed_max - _speed_start
	if span <= 0:
		return 0
	return clampi(UtilCore.floor_div((_sim.ball_speed - _speed_start) * MatchConstants.PERMILLE, span), 0, MatchConstants.PERMILLE)


## Draws the match `weight` of a tick after the last tick. The CPU paddle and the ball are drawn between the last two
## ticks. The player paddle is drawn ahead from the last tick with the held input, so it answers the input without the
## one tick delay of drawing between ticks and does not slide on after the input is released.
func _draw_sim(weight: float) -> void:
	var units: float = MatchConstants.UNITS_PER_PIXEL
	var limit: float = float(_sim.paddle_limit())
	var ahead: float = float(_input_dir * _sim.player_speed(_input_dir)) * weight
	var player_y: float = clampf(float(_sim.player_y) + ahead, -limit, limit) / units
	var cpu_y: float = lerpf(float(_sim.prev_cpu_y), float(_sim.cpu_y), weight) / units
	player_paddle.position = Vector2(float(_sim.player_face_x - _sim.paddle_half_w) / units, player_y)
	cpu_paddle.position = Vector2(float(_sim.cpu_face_x + _sim.paddle_half_w) / units, cpu_y)
	var waiting: bool = _sim.phase == MatchSim.Phase.SERVE_WAIT
	var in_play: bool = _sim.phase == MatchSim.Phase.PLAYING
	ball.visible = in_play or waiting
	if waiting:
		var dim: Color = MatchConstants.BALL_SLOW_COLOR
		dim.a = MatchConstants.WAITING_BALL_OPACITY
		ball.position = Vector2.ZERO
		ball.set_look(ball.side, dim)
		ball.set_aim(Vector2(float(_sim.serve_to * _sim.serve_speed), float(_sim.serve_vy)).normalized())
		return
	ball.set_aim(Vector2.ZERO)
	if not in_play:
		return
	var at: Vector2 = Vector2(
		lerpf(float(_sim.prev_ball_x), float(_sim.ball_x), weight),
		lerpf(float(_sim.prev_ball_y), float(_sim.ball_y), weight)) / units
	ball.position = at
	var ball_color: Color = MatchConstants.BALL_SLOW_COLOR.lerp(MatchConstants.BALL_FAST_COLOR, float(_speed_permille()) / MatchConstants.PERMILLE_F)
	ball.set_look(ball.side, ball_color)
	court.push_trail(at, ball_color)


## Publishes the HUD state when a value changed since the last publish, or always when `always`.
func _publish_state(always: bool) -> void:
	var starting: bool = _stage == Stage.STARTING
	var serving: bool = _sim.phase == MatchSim.Phase.SERVE_WAIT
	var hint: bool = not _moved and _stage != Stage.RESULT
	var match_point: bool = _sim.is_match_point()
	var changed: bool = always or _sim.player_score != _shown_player_score or _sim.cpu_score != _shown_cpu_score \
		or _sim.rally != _shown_rally or match_point != _shown_match_point or hint != _shown_hint \
		or starting != _shown_starting or serving != _shown_serving
	if not changed:
		return
	_shown_match_point = match_point
	_shown_hint = hint
	_shown_starting = starting
	_shown_serving = serving
	_shown_player_score = _sim.player_score
	_shown_cpu_score = _sim.cpu_score
	_shown_rally = _sim.rally
	var event: MatchStateChangedEvent = EventCore.acquire(MatchStateChangedEvent) as MatchStateChangedEvent
	event.player_score = _sim.player_score
	event.cpu_score = _sim.cpu_score
	event.rally = _sim.rally
	event.match_point = match_point
	event.show_hint = hint
	event.starting = starting
	event.serving = serving
	EventCore.publish(event)


## Sends the finished match. The result panel opens when the server answers, or with the result unsaved when it
## refuses it.
func _finish_match() -> void:
	if _stage != Stage.SAVING:
		return
	var result: GameContract.PlaySessionResult = GameContract.PlaySessionResult.new()
	result.player_score = _sim.player_score
	result.cpu_score = _sim.cpu_score
	result.longest_rally = _sim.longest_rally
	var request: CoreContract.FinishPlaySessionRequest = CoreContract.FinishPlaySessionRequest.new()
	request.play_session_id = _play_session_id
	request.result = result.encode()
	_best_before = CommonMatchRecord.best_rally()
	NetworkCore.send(request, _on_finished, _on_finish_failed)


func _on_finished(_response: ContractMessage) -> void:
	GameUpdateCore.set_in_play(false)
	_show_result(true)


## A play session the server can no longer count (it expired, for example after a long pause) is answered here: the
## result panel says the match was not counted. Other failures keep the core error handling.
func _on_finish_failed(failure: RequestFailure) -> bool:
	GameUpdateCore.set_in_play(false)
	_show_result(false)
	return MatchScene.is_uncounted(failure)


## Whether `failure` of `FinishPlaySession` means the server will never count this match: the play session expired or
## is unknown.
static func is_uncounted(failure: RequestFailure) -> bool:
	if failure.kind != NetworkCore.FailureKind.SERVER_ERROR:
		return false
	return failure.error_code == CoreContract.CoreError.CORE_ERROR_PLAY_SESSION_EXPIRED \
		or failure.error_code == CoreContract.CoreError.CORE_ERROR_PLAY_SESSION_NOT_FOUND


func _show_result(saved: bool) -> void:
	if _stage != Stage.SAVING:
		return
	_stage = Stage.RESULT
	var won: bool = _sim.player_score > _sim.cpu_score
	var param: MatchResultParam = MatchResultParam.new()
	param.won = won
	param.saved = saved
	param.player_score = _sim.player_score
	param.cpu_score = _sim.cpu_score
	param.longest_rally = _sim.longest_rally
	param.longest_rally_player = _sim.longest_rally_player
	param.new_best = saved and _sim.longest_rally > _best_before and _best_before > 0
	param.wins = CommonMatchRecord.wins()
	param.losses = CommonMatchRecord.losses()
	param.win_streak = CommonMatchRecord.win_streak()
	param.on_rematch = _begin_match
	param.on_menu = _leave_to_menu
	_publish_state(false)
	UICore.open_panel(ResourceKey.PREFAB__MATCH__RESULT_PANEL, param, false)
	var finished: MatchFinishedEvent = EventCore.acquire(MatchFinishedEvent) as MatchFinishedEvent
	finished.won = won
	EventCore.publish(finished)
	if won and saved:
		EventCore.publish(EventCore.acquire(MatchWonEvent))


func _on_pause_requested(_event: MatchPauseRequestedEvent) -> void:
	if _stage != Stage.PLAYING or _paused:
		return
	_set_paused(true)
	var param: MatchPauseParam = MatchPauseParam.new()
	param.on_resume = _on_resume
	param.on_quit = _on_quit
	UICore.open_popup(ResourceKey.PREFAB__MATCH__PAUSE_POPUP, param, Callable())


func _on_resume() -> void:
	_set_paused(false)


func _on_quit() -> void:
	_set_paused(false)
	GameUpdateCore.set_in_play(false)
	_leave_to_menu()


## Holds the match and game time while the pause popup is open.
func _set_paused(paused: bool) -> void:
	if paused == _paused:
		return
	_paused = paused
	TimeCore.set_paused(paused)


func _leave_to_menu() -> void:
	if _stage == Stage.LEAVING:
		return
	_stage = Stage.LEAVING
	SceneCore.change_scene(ResourceKey.SCENE__MENU__MENU, null)


static func _sound_keys() -> PackedStringArray:
	return PackedStringArray([
		ReservedSound.match_paddle_hit(), ReservedSound.match_wall_bounce(), ReservedSound.match_serve(),
		ReservedSound.match_score_player(), ReservedSound.match_score_cpu(), ReservedSound.match_win(),
		ReservedSound.match_lose()])
