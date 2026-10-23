class_name MatchBotPolicy
extends RefCounted
## The paddle direction a bot player chooses from the match simulation: it meets the ball off the paddle center so
## the return goes steep, away from the CPU paddle; while the ball goes away it moves back to the center.



static func target_y(sim: MatchSim) -> int:
	if sim.phase != MatchSim.Phase.PLAYING or sim.ball_vx >= 0:
		return 0
	var meet: int = sim.predict_y(sim.player_face_x)
	var lean: int = UtilCore.floor_div(sim.paddle_half_h * MatchConstants.BOT_LEAN_PERMILLE, MatchConstants.PERMILLE)
	var target: int = meet + lean if sim.cpu_y >= 0 else meet - lean
	return clampi(target, -sim.paddle_limit(), sim.paddle_limit())


## -1 up, 1 down, 0 still.
static func direction(sim: MatchSim) -> int:
	var diff: int = target_y(sim) - sim.player_y
	if absi(diff) <= MatchConstants.BOT_DEAD_ZONE:
		return 0
	return 1 if diff > 0 else -1
