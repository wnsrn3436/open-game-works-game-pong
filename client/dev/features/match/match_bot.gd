class_name MatchBot
extends RefCounted
## The bot player and the `open_<screen>` commands of the match feature. In the menu it starts a match, in the match
## it moves the paddle with held keys by `MatchBotPolicy`, on the result panel it starts the next match, and on the
## pause popup it resumes. It releases a held key before it leaves the match play.

const _KEY_UP: String = "W"
const _KEY_DOWN: String = "S"
const _ANCHOR_PLAY: String = "menu_play"
const _ANCHOR_REMATCH: String = "result_rematch"
const _ANCHOR_RESUME: String = "pause_resume"

## The key the bot holds now; empty for none.
var _held: String = ""
## A point the CPU scored waits for its next serve to count as a restart.
var _restart_pending: bool = false


## `match.bot_next_input`: the next input command, or `null` while a transition runs or nothing changes.
func next_input(_args: PackedStringArray) -> RunCommandResult:
	if SceneCore.is_transitioning() or UICore.is_panel_transitioning() or UICore.is_system_popup_visible():
		return _release_or("")
	var scene: String = SceneCore.current_scene_key()
	if scene == ResourceKey.SCENE__MENU__MENU:
		if UICore.get_current_panel_key() == ResourceKey.PREFAB__MENU__MENU_PANEL:
			return _release_or(_ANCHOR_PLAY)
		return _release_or("")
	if scene != ResourceKey.SCENE__MATCH__MATCH:
		return _release_or("")
	if UICore.get_open_popups().has(ResourceKey.PREFAB__MATCH__PAUSE_POPUP):
		return _release_or(_ANCHOR_RESUME)
	if UICore.get_current_panel_key() == ResourceKey.PREFAB__MATCH__RESULT_PANEL:
		return _release_or(_ANCHOR_REMATCH)
	var match_scene: MatchScene = find_match_scene()
	if match_scene == null or not match_scene.is_running():
		return _release_or("")
	return _steer(MatchBotPolicy.direction(match_scene.get_sim()))


func on_point_lost(_event: MatchPointLostEvent) -> void:
	_restart_pending = true
	QACore.mark(QACore.MarkKind.FAIL)


## A point of the player is the short-cycle reward of the match. It has no ID value.
func on_point_won(_event: MatchPointWonEvent) -> void:
	QACore.mark(QACore.MarkKind.REWARD)


func on_served(_event: MatchServedEvent) -> void:
	if _restart_pending:
		_restart_pending = false
		QACore.mark(QACore.MarkKind.RESTART)


func on_won(_event: MatchWonEvent) -> void:
	QACore.mark(QACore.MarkKind.GOAL)


func on_responded(_event: MatchRespondedEvent) -> void:
	QACore.mark(QACore.MarkKind.RESPONSE)


## Scores stay between 0 and `[points_to_win]` in a match on screen.
func scores_in_range() -> bool:
	var match_scene: MatchScene = find_match_scene()
	if match_scene == null or match_scene.get_sim() == null:
		return true
	var sim: MatchSim = match_scene.get_sim()
	var top: int = sim.points_to_win()
	return sim.player_score >= 0 and sim.player_score <= top and sim.cpu_score >= 0 and sim.cpu_score <= top


## Both paddles stay inside the court.
func paddles_in_court() -> bool:
	var match_scene: MatchScene = find_match_scene()
	if match_scene == null or match_scene.get_sim() == null:
		return true
	var sim: MatchSim = match_scene.get_sim()
	return absi(sim.player_y) <= sim.paddle_limit() and absi(sim.cpu_y) <= sim.paddle_limit()


## A match on screen is kept only while its HUD is on top without a popup and the match is not paused; otherwise
## (another scene, the result panel, the pause popup) the match scene opens again with a new match.
func open_match(_args: PackedStringArray) -> RunCommandResult:
	var match_scene: MatchScene = find_match_scene()
	var keep: bool = SceneCore.current_scene_key() == ResourceKey.SCENE__MATCH__MATCH \
		and UICore.get_current_panel_key() == ResourceKey.PREFAB__MATCH__HUD_PANEL \
		and UICore.get_open_popups().is_empty() and match_scene != null and not match_scene.is_paused()
	UICore.close_all_popups()
	if not keep:
		if not await SceneCore.change_scene(ResourceKey.SCENE__MATCH__MATCH, null):
			return _result(false, "\"the match scene did not open\"")
	var ok: bool = await UICore.close_panels_to(ResourceKey.PREFAB__MATCH__HUD_PANEL)
	return _result(ok, "")


func open_result(args: PackedStringArray) -> RunCommandResult:
	return await _open_result_preview(args, true)


func open_result_unsaved(args: PackedStringArray) -> RunCommandResult:
	return await _open_result_preview(args, false)


## A won and saved match, or a lost match the server did not count, on the result panel over the match scene.
func _open_result_preview(args: PackedStringArray, saved: bool) -> RunCommandResult:
	var opened: RunCommandResult = await open_match(args)
	if not opened.ok:
		return opened
	var match_scene: MatchScene = find_match_scene()
	if match_scene == null:
		return _result(false, "\"no match scene\"")
	var param: MatchResultParam = MatchResultParam.new()
	param.won = saved
	param.saved = saved
	param.player_score = GameSetting.points_to_win() if saved else GameSetting.points_to_win() - 2
	param.cpu_score = GameSetting.points_to_win() - 2 if saved else GameSetting.points_to_win()
	param.longest_rally = MatchConstants.PREVIEW_LONGEST_RALLY
	param.longest_rally_player = MatchConstants.PREVIEW_LONGEST_RALLY_PLAYER
	param.new_best = saved
	param.wins = MatchConstants.PREVIEW_WINS
	param.losses = MatchConstants.PREVIEW_LOSSES
	param.win_streak = MatchConstants.PREVIEW_STREAK
	param.on_rematch = func() -> void: pass
	param.on_menu = func() -> void: SceneCore.change_scene(ResourceKey.SCENE__MENU__MENU, null)
	return _result(await UICore.open_panel(ResourceKey.PREFAB__MATCH__RESULT_PANEL, param, false), "")


func open_pause(args: PackedStringArray) -> RunCommandResult:
	var opened: RunCommandResult = await open_match(args)
	if not opened.ok:
		return opened
	var match_scene: MatchScene = find_match_scene()
	for i: int in MatchConstants.DEV_WAIT_FRAMES:
		if match_scene == null or match_scene.is_running():
			break
		await (Engine.get_main_loop() as SceneTree).process_frame
	if match_scene == null or not match_scene.is_running():
		return _result(false, "\"the match did not start\"")
	EventCore.publish(EventCore.acquire(MatchPauseRequestedEvent))
	for i: int in MatchConstants.DEV_WAIT_FRAMES:
		if UICore.get_open_popups().has(ResourceKey.PREFAB__MATCH__PAUSE_POPUP):
			return _result(true, "")
		await (Engine.get_main_loop() as SceneTree).process_frame
	return _result(false, "\"the pause popup did not open\"")


## The match scene on screen, or `null`.
func find_match_scene() -> MatchScene:
	var root: Node = (Engine.get_main_loop() as SceneTree).root
	return _find(root)


func _find(node: Node) -> MatchScene:
	if node is MatchScene:
		return node as MatchScene
	for child: Node in node.get_children():
		var found: MatchScene = _find(child)
		if found != null:
			return found
	return null


## The key command that moves the paddle toward `dir`: release a key going the other way first, then hold the key.
func _steer(dir: int) -> RunCommandResult:
	var want: String = ""
	if dir < 0:
		want = _KEY_UP
	elif dir > 0:
		want = _KEY_DOWN
	if want == _held:
		return _result(true, "null")
	if not _held.is_empty():
		var released: String = _held
		_held = ""
		return _input("key_up", released)
	_held = want
	return _input("key_down", want)


## Releases a held key first; then taps `anchor`, or returns `null` for an empty anchor.
func _release_or(anchor: String) -> RunCommandResult:
	if not _held.is_empty():
		var released: String = _held
		_held = ""
		return _input("key_up", released)
	if anchor.is_empty():
		return _result(true, "null")
	return _input("tap_anchor", anchor)


func _input(command: String, arg: String) -> RunCommandResult:
	return _result(true, JSON.stringify({"command": command, "args": [arg]}))


func _result(ok: bool, result: String) -> RunCommandResult:
	var out: RunCommandResult = RunCommandResult.new()
	out.ok = ok
	out.result = result
	return out
