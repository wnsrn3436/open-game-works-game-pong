extends UnitTestCase
## The match simulation: the same seed and inputs give the same match, the serve, paddle hits that speed the ball up
## and steepen it toward the paddle edge, points, the match end at `[points_to_win]`, and a bot player that beats the
## CPU while the CPU returns balls.

const _SEED: int = 4242
const _BOT_SEEDS: int = 4
const _BOT_TICK_LIMIT: int = 400000
## The bot reads the match every few ticks, as the automation channel does.
const _BOT_READ_TICKS: int = 3
## Flat returns per speed in the CPU miss test, and the height step between them in court units.
const _FLAT_SEEDS: int = 40
const _FLAT_HEIGHT_STRIDE: int = 7919


func before_each() -> void:
	assert_true(LogCore.init(), "LogCore.init")
	assert_true(EventCore.init(), "EventCore.init")
	assert_true(TimeCore.init(), "TimeCore.init")
	assert_true(LocalDataCore.init(), "LocalDataCore.init")
	assert_true(LocalDataCore.load_device_file(), "LocalDataCore.load_device_file")
	assert_true(ResourceCore.init(), "ResourceCore.init")
	assert_true(PoolCore.init(), "PoolCore.init")
	assert_true(DataCore.init(), "DataCore.init")
	assert_true(await DataCore.load(null), "DataCore.load")


func after_each() -> void:
	super()
	BootstrapCoreDev.shutdown()


func serve_ticks() -> int:
	return UtilCore.floor_div(GameSetting.serve_delay(), GameSetting.sim_tick())


func first_serve_ticks() -> int:
	return UtilCore.floor_div(GameSetting.first_serve_delay(), GameSetting.sim_tick())


func run_until(sim: MatchSim, dir: int, limit: int, done: Callable) -> int:
	for i: int in limit:
		sim.step(dir)
		if done.call():
			return i + 1
	return -1


func snapshot(sim: MatchSim) -> PackedInt64Array:
	return PackedInt64Array([sim.tick, sim.phase, sim.player_y, sim.cpu_y, sim.ball_x, sim.ball_y, sim.ball_vx, sim.ball_vy,
		sim.ball_speed, sim.player_score, sim.cpu_score, sim.rally, sim.longest_rally, sim.events, sim.hit_offset,
		sim.rally_player, sim.longest_rally_player])


func test_the_same_seed_and_inputs_give_the_same_match() -> void:
	var a: MatchSim = MatchSim.new(_SEED)
	var b: MatchSim = MatchSim.new(_SEED)
	for i: int in 6000:
		var dir: int = UtilCore.floor_mod(UtilCore.floor_div(i, 37), 3) - 1
		a.step(dir)
		b.step(dir)
	assert_eq(snapshot(a), snapshot(b))
	assert_gt(a.cpu_score + a.player_score, 0, "points were scored")


## The first serve of a match waits `[first_serve_delay]`, longer than the serve after a point, so the ready state
## shows once the match opens. It leaves at `[serve_speed]` along the direction known from the start of the wait.
## A short tap moves the paddle less than the full speed would: the paddle starts at `[paddle_speed_start]` from
## standing still and reaches `[paddle_speed]` after `[paddle_ramp]`. A stop longer than `[paddle_carry]` starts the
## ramp again.
func test_the_paddle_speeds_up_from_the_start_speed_while_a_direction_is_held() -> void:
	var sim: MatchSim = MatchSim.new(_SEED)
	var ramp_ticks: int = UtilCore.floor_div(GameSetting.paddle_ramp(), GameSetting.sim_tick())
	var carry_ticks: int = UtilCore.floor_div(GameSetting.paddle_carry(), GameSetting.sim_tick())
	assert_gt(ramp_ticks, 1, "the ramp takes several ticks")
	assert_lt(GameSetting.paddle_speed_start(), GameSetting.paddle_speed(), "the start speed is slower")
	sim.step(1)
	assert_eq(sim.player_y, GameSetting.paddle_speed_start(), "the first tick moves at the start speed")
	var before: int = sim.player_y
	sim.step(1)
	var second: int = sim.player_y - before
	assert_gt(second, GameSetting.paddle_speed_start(), "the second tick is faster")
	assert_lt(second, GameSetting.paddle_speed(), "the second tick is not yet at full speed")
	for i: int in ramp_ticks:
		sim.step(1)
	before = sim.player_y
	sim.step(1)
	assert_eq(sim.player_y - before, GameSetting.paddle_speed(), "full speed after the ramp")
	for i: int in carry_ticks + 1:
		sim.step(0)
	before = sim.player_y
	sim.step(-1)
	assert_eq(before - sim.player_y, GameSetting.paddle_speed_start(), "a stop longer than the carry starts the ramp again")


## A direction change, or a stop no longer than `[paddle_carry]`, keeps the speed reached, so a last moment correction
## is as fast as the move before it.
func test_a_direction_change_or_a_short_stop_keeps_the_paddle_speed() -> void:
	var sim: MatchSim = MatchSim.new(_SEED)
	var ramp_ticks: int = UtilCore.floor_div(GameSetting.paddle_ramp(), GameSetting.sim_tick())
	var carry_ticks: int = UtilCore.floor_div(GameSetting.paddle_carry(), GameSetting.sim_tick())
	assert_gt(carry_ticks, 0, "the carry is at least one tick")
	for i: int in ramp_ticks + 1:
		sim.step(-1)
	var before: int = sim.player_y
	sim.step(1)
	assert_eq(sim.player_y - before, GameSetting.paddle_speed(), "a direction change goes on at full speed")
	for i: int in carry_ticks:
		sim.step(0)
	before = sim.player_y
	sim.step(-1)
	assert_eq(before - sim.player_y, GameSetting.paddle_speed(), "a stop of the carry goes on at full speed")


func test_the_first_serve_goes_toward_the_player_after_the_first_serve_wait_along_the_shown_direction() -> void:
	var sim: MatchSim = MatchSim.new(_SEED)
	assert_gt(first_serve_ticks(), serve_ticks(), "the first serve waits longer than a later serve")
	assert_eq(sim.phase, MatchSim.Phase.SERVE_WAIT)
	var shown_vy: int = sim.serve_vy
	for i: int in first_serve_ticks() - 1:
		sim.step(0)
	assert_eq(sim.phase, MatchSim.Phase.SERVE_WAIT)
	assert_eq(sim.serve_vy, shown_vy, "the serve direction stays during the wait")
	sim.step(0)
	assert_eq(sim.phase, MatchSim.Phase.PLAYING)
	assert_true(sim.events & MatchSim.EVENT_SERVE != 0, "serve event")
	assert_eq(sim.ball_vx, -GameSetting.serve_speed())
	assert_eq(sim.ball_vy, shown_vy, "the ball leaves along the shown direction")
	var max_vy: int = UtilCore.floor_div(GameSetting.serve_speed() * GameSetting.serve_vy_max_permille(), 1000)
	assert_true(absi(sim.ball_vy) <= max_vy, "serve angle within the data limit")


## The serve is slower than the rally start speed; the first paddle hit after it goes on at the start speed plus one
## step, as a rally from the start speed would.
func test_the_serve_is_slower_than_the_rally_and_the_first_hit_speeds_up_from_the_start_speed() -> void:
	assert_lt(GameSetting.serve_speed(), GameSetting.ball_speed_start(), "the serve is slower than the rally start")
	var sim: MatchSim = MatchSim.new(_SEED)
	run_until(sim, 0, first_serve_ticks(), func() -> bool: return sim.phase == MatchSim.Phase.PLAYING)
	assert_eq(sim.ball_speed, GameSetting.serve_speed())
	sim.ball_vy = 0
	sim.ball_y = 0
	sim.player_y = 0
	var ticks: int = run_until(sim, 0, 1000, func() -> bool: return sim.events & MatchSim.EVENT_HIT_PLAYER != 0)
	assert_gt(ticks, 0, "the paddle hit the ball")
	assert_eq(sim.ball_speed, GameSetting.ball_speed_start() + GameSetting.ball_speed_step())


func test_a_paddle_hit_speeds_the_ball_up_and_counts_the_rally() -> void:
	var sim: MatchSim = MatchSim.new(_SEED)
	run_until(sim, 0, first_serve_ticks(), func() -> bool: return sim.phase == MatchSim.Phase.PLAYING)
	sim.ball_vy = 0
	sim.ball_y = 0
	sim.player_y = 0
	var ticks: int = run_until(sim, 0, 1000, func() -> bool: return sim.events & MatchSim.EVENT_HIT_PLAYER != 0)
	assert_gt(ticks, 0, "the paddle hit the ball")
	assert_eq(sim.rally, 1)
	assert_eq(sim.ball_speed, GameSetting.ball_speed_start() + GameSetting.ball_speed_step())
	assert_eq(sim.ball_vx, sim.ball_speed)
	assert_eq(sim.ball_vy, 0, "a center hit returns flat")


## The longest rally keeps how many of its hits were the player's, so the result can say who hit how often.
func test_the_longest_rally_keeps_the_player_hits_of_it() -> void:
	var sim: MatchSim = MatchSim.new(_SEED)
	run_until(sim, 0, first_serve_ticks(), func() -> bool: return sim.phase == MatchSim.Phase.PLAYING)
	sim.ball_vy = 0
	sim.ball_y = 0
	sim.player_y = 0
	run_until(sim, 0, 1000, func() -> bool: return sim.events & MatchSim.EVENT_HIT_PLAYER != 0)
	assert_eq(sim.rally_player, 1, "the player hit once")
	sim.ball_vy = 0
	sim.cpu_y = sim.ball_y
	var ticks: int = run_until(sim, 0, 1000, func() -> bool: return sim.events & MatchSim.EVENT_HIT_CPU != 0)
	assert_gt(ticks, 0, "the CPU hit the ball")
	assert_eq(sim.rally, 2)
	assert_eq(sim.rally_player, 1, "a CPU hit is not a player hit")
	assert_eq(sim.longest_rally, 2)
	assert_eq(sim.longest_rally_player, 1)
	sim.ball_vy = 0
	sim.ball_y = sim.ball_limit()
	sim.player_y = -sim.paddle_limit()
	run_until(sim, -1, 2000, func() -> bool: return sim.events & MatchSim.EVENT_POINT_CPU != 0)
	assert_eq(sim.cpu_score, 1, "the player missed")
	assert_eq(sim.rally_player, 0, "a new rally starts with no hits")
	assert_eq(sim.longest_rally_player, 1, "the longest rally keeps its player hits")


func test_a_hit_near_the_paddle_edge_returns_steeper_than_a_center_hit() -> void:
	var center: MatchSim = MatchSim.new(_SEED)
	var edge: MatchSim = MatchSim.new(_SEED)
	var sims: Array[MatchSim] = [center, edge]
	for sim: MatchSim in sims:
		run_until(sim, 0, first_serve_ticks(), func() -> bool: return sim.phase == MatchSim.Phase.PLAYING)
		sim.ball_vy = 0
		sim.ball_y = 0
	edge.player_y = -UtilCore.floor_div(edge.paddle_half_h * 9, 10)
	for sim: MatchSim in sims:
		run_until(sim, 0, 1000, func() -> bool: return sim.events & MatchSim.EVENT_HIT_PLAYER != 0)
	assert_eq(center.ball_vy, 0)
	assert_gt(edge.ball_vy, 0, "a hit below the center goes down")
	assert_gt(absi(edge.ball_vy), UtilCore.floor_div(edge.ball_speed, 2), "an edge hit is steep")


## A hit halfway from the paddle center to its edge returns at least 35 degrees steep (vertical speed 0.7 of the
## horizontal one), and a hit at the edge steeper than 45 degrees, so the angle difference reads on screen.
func test_a_hit_halfway_to_the_edge_is_clearly_steep_and_an_edge_hit_is_steeper_than_45_degrees() -> void:
	var half: MatchSim = MatchSim.new(_SEED)
	var edge: MatchSim = MatchSim.new(_SEED)
	var sims: Array[MatchSim] = [half, edge]
	for sim: MatchSim in sims:
		run_until(sim, 0, first_serve_ticks(), func() -> bool: return sim.phase == MatchSim.Phase.PLAYING)
		sim.ball_vy = 0
		sim.ball_y = 0
	var reach: int = half.paddle_half_h + half.ball_half
	half.player_y = -UtilCore.floor_div(reach, 2)
	edge.player_y = -edge.paddle_half_h
	for sim: MatchSim in sims:
		run_until(sim, 0, 1000, func() -> bool: return sim.events & MatchSim.EVENT_HIT_PLAYER != 0)
		assert_eq(sim.rally, 1, "the paddle hit the ball")
	assert_true(half.ball_vy * 1000 >= half.ball_vx * 700, "halfway: vy %d, vx %d" % [half.ball_vy, half.ball_vx])
	assert_gt(edge.ball_vy, edge.ball_vx, "edge: vy %d, vx %d" % [edge.ball_vy, edge.ball_vx])


## A hit keeps where the ball met the paddle, from the paddle center and on the paddle, so the screen can mark it.
func test_a_hit_keeps_where_the_ball_met_the_paddle() -> void:
	var center: MatchSim = MatchSim.new(_SEED)
	var off: MatchSim = MatchSim.new(_SEED)
	var edge: MatchSim = MatchSim.new(_SEED)
	var sims: Array[MatchSim] = [center, off, edge]
	for sim: MatchSim in sims:
		run_until(sim, 0, first_serve_ticks(), func() -> bool: return sim.phase == MatchSim.Phase.PLAYING)
		sim.ball_vy = 0
		sim.ball_y = 0
	var shift: int = UtilCore.floor_div(off.paddle_half_h, 3)
	off.player_y = shift
	edge.player_y = edge.paddle_half_h + edge.ball_half
	for sim: MatchSim in sims:
		run_until(sim, 0, 1000, func() -> bool: return sim.events & MatchSim.EVENT_HIT_PLAYER != 0)
		assert_eq(sim.rally, 1, "the paddle hit the ball")
	assert_eq(center.hit_offset, 0, "center")
	assert_eq(off.hit_offset, -shift, "above the center")
	assert_eq(edge.hit_offset, -edge.paddle_half_h, "past the edge: on the paddle edge")


func test_a_missed_ball_scores_for_the_cpu_and_serves_again_toward_the_player() -> void:
	var sim: MatchSim = MatchSim.new(_SEED)
	run_until(sim, 0, first_serve_ticks(), func() -> bool: return sim.phase == MatchSim.Phase.PLAYING)
	sim.ball_vy = 0
	sim.ball_y = 0
	sim.player_y = -sim.paddle_limit()
	var ticks: int = run_until(sim, -1, 2000, func() -> bool: return sim.events & MatchSim.EVENT_POINT_CPU != 0)
	assert_gt(ticks, 0, "the CPU scored")
	assert_eq(sim.cpu_score, 1)
	assert_eq(sim.player_score, 0)
	assert_eq(sim.phase, MatchSim.Phase.SERVE_WAIT)
	assert_eq(sim.serve_to, MatchSim.SIDE_PLAYER)
	assert_eq(sim.serve_ticks_left, serve_ticks(), "a serve after a point waits `[serve_delay]`")
	assert_eq(sim.rally, 0)


func test_the_match_ends_when_one_side_reaches_the_target_score() -> void:
	var sim: MatchSim = MatchSim.new(_SEED)
	var ticks: int = run_until(sim, -1, _BOT_TICK_LIMIT, func() -> bool: return sim.phase == MatchSim.Phase.FINISHED)
	assert_gt(ticks, 0, "the match ended")
	assert_eq(maxi(sim.player_score, sim.cpu_score), GameSetting.points_to_win())
	assert_true(sim.events & MatchSim.EVENT_MATCH_END != 0, "match end event")
	assert_false(sim.is_match_point())
	var frozen: PackedInt64Array = snapshot(sim)
	sim.step(0)
	assert_eq(sim.player_score, frozen[9])
	assert_eq(sim.cpu_score, frozen[10])


func test_the_meeting_point_follows_the_wall_bounces_on_both_sides() -> void:
	var sim: MatchSim = MatchSim.new(_SEED)
	run_until(sim, 0, first_serve_ticks(), func() -> bool: return sim.phase == MatchSim.Phase.PLAYING)
	for vx: int in [-GameSetting.ball_speed_start(), GameSetting.ball_speed_start()]:
		sim.ball_x = 0
		sim.ball_y = 0
		sim.ball_vx = vx
		sim.ball_vy = UtilCore.floor_div(GameSetting.ball_speed_start(), 2)
		var face: int = sim.player_face_x if vx < 0 else sim.cpu_face_x
		var predicted: int = sim.predict_y(face)
		var contact: int = face + sim.ball_half if vx < 0 else face - sim.ball_half
		var guard: int = 0
		while (sim.ball_x > contact if vx < 0 else sim.ball_x < contact) and guard < 1000:
			var next_x: int = sim.ball_x + sim.ball_vx
			if (next_x <= contact if vx < 0 else next_x >= contact):
				break
			sim.ball_x = next_x
			sim.ball_y += sim.ball_vy
			if absi(sim.ball_y) > sim.ball_limit():
				sim.ball_y = signi(sim.ball_y) * 2 * sim.ball_limit() - sim.ball_y
				sim.ball_vy = -sim.ball_vy
			guard += 1
		assert_true(absi(predicted - sim.ball_y) <= absi(sim.ball_vy), "side %d: predicted %d near %d" % [vx, predicted, sim.ball_y])


func test_match_point_shows_when_one_side_needs_one_point() -> void:
	var sim: MatchSim = MatchSim.new(_SEED)
	sim.cpu_score = GameSetting.points_to_win() - 1
	assert_true(sim.is_match_point())
	sim.cpu_score = 0
	sim.player_score = GameSetting.points_to_win() - 2
	assert_false(sim.is_match_point())


## Flat returns from the player paddle center at `speed_before`, one per seed from different heights: how many the
## CPU misses.
func cpu_misses_of_flat_returns(speed_before: int) -> int:
	var misses: int = 0
	for s: int in _FLAT_SEEDS:
		var sim: MatchSim = MatchSim.new(_SEED + s)
		run_until(sim, 0, first_serve_ticks(), func() -> bool: return sim.phase == MatchSim.Phase.PLAYING)
		var y: int = UtilCore.floor_mod(s * _FLAT_HEIGHT_STRIDE, 2 * sim.paddle_limit()) - sim.paddle_limit()
		sim.player_y = y
		sim.ball_y = y
		sim.ball_vy = 0
		sim.ball_speed = speed_before
		sim.ball_vx = -speed_before
		sim.ball_x = sim.player_face_x + sim.ball_half + UtilCore.floor_div(speed_before, 2)
		sim.events = 0
		var ticks: int = run_until(sim, 0, 2000,
			func() -> bool: return sim.events & (MatchSim.EVENT_HIT_CPU | MatchSim.EVENT_POINT_PLAYER | MatchSim.EVENT_POINT_CPU) != 0)
		assert_gt(ticks, 0, "seed %d: the return ended" % s)
		assert_true(sim.events & MatchSim.EVENT_HIT_PLAYER != 0, "seed %d: the player hit the ball" % s)
		if sim.events & MatchSim.EVENT_POINT_PLAYER != 0:
			misses += 1
	return misses


func test_the_cpu_misses_flat_returns_more_often_at_top_speed_than_at_the_start_speed() -> void:
	var at_start: int = cpu_misses_of_flat_returns(GameSetting.ball_speed_start())
	var at_top: int = cpu_misses_of_flat_returns(GameSetting.ball_speed_max())
	assert_gt(at_top, at_start, "top speed misses %d, start speed misses %d" % [at_top, at_start])
	assert_lt(at_top, _FLAT_SEEDS, "the CPU still returns some flat balls at top speed")


func test_the_bot_player_beats_the_cpu_and_the_cpu_returns_balls() -> void:
	var bot_wins: int = 0
	var cpu_hits: int = 0
	for s: int in _BOT_SEEDS:
		var sim: MatchSim = MatchSim.new(_SEED + s)
		var dir: int = 0
		for i: int in _BOT_TICK_LIMIT:
			if UtilCore.floor_mod(i, _BOT_READ_TICKS) == 0:
				dir = MatchBotPolicy.direction(sim)
			sim.step(dir)
			if sim.events & MatchSim.EVENT_HIT_CPU != 0:
				cpu_hits += 1
			sim.events = 0
			if sim.phase == MatchSim.Phase.FINISHED:
				break
		assert_eq(sim.phase, MatchSim.Phase.FINISHED, "match %d ended" % s)
		if sim.player_score > sim.cpu_score:
			bot_wins += 1
	assert_eq(bot_wins, _BOT_SEEDS, "the bot won every match")
	assert_gt(cpu_hits, _BOT_SEEDS * GameSetting.points_to_win(), "the CPU returned balls")
