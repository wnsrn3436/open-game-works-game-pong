extends UnitTestCase
## The pause popup of the match: the `pause` action opens it, the match (simulation and paddles) stops while it is
## open and goes on after resume. Game time is paused while it is open.

const _SERVER_TIME: int = 1710000000000
const _START: String = "core/StartPlaySession"
## Frames a test lets pass while it checks that the match stays or moves.
const _RUN_FRAMES: int = 12


func after_each() -> void:
	super()
	BootstrapCoreDev.shutdown()


func start_response() -> PackedByteArray:
	var env: CoreContract.ResponseEnvelope = CoreContract.ResponseEnvelope.new()
	env.server_time_at = _SERVER_TIME
	var body: CoreContract.StartPlaySessionResponse = CoreContract.StartPlaySessionResponse.new()
	body.play_session_id = "play-session-1"
	body.started_at = _SERVER_TIME
	env.body = body.encode()
	return UnitTestCore.make_response(env)


## Boots the game without login into the match scene, with the test clock moving every frame, and waits for the
## first serve: the match runs.
func open_match() -> MatchScene:
	UnitTestCore.add_result(_START, NetworkCore.TransferResult.DONE, 200, start_response())
	var modules: Array[CoreModuleEntry] = []
	for entry: CoreModuleEntry in CoreModules.modules():
		if entry.name != "AuthCore":
			modules.append(entry)
	var served: UnitTestLatch = UnitTestCore.latch_event(MatchServedEvent)
	add_child_autofree(MatchTestClock.new())
	UnitTestCore.start_test_boot(MatchTestContent.new(), modules)
	await UnitTestCore.wait_latch(served)
	var match_scene: MatchScene = find_match(get_tree().root)
	assert_not_null(match_scene, "the match scene")
	assert_true(match_scene.is_running(), "the match runs")
	return match_scene


func find_match(node: Node) -> MatchScene:
	if node is MatchScene:
		return node as MatchScene
	for child: Node in node.get_children():
		var found: MatchScene = find_match(child)
		if found != null:
			return found
	return null


func pause(match_scene: MatchScene) -> void:
	var opened: UnitTestLatch = UnitTestCore.latch_event(UIOpenedEvent)
	# The serve latch ends inside the match frame, after the HUD read its input. `pause` is put in at the start of the
	# next frame, where a press lands, so the HUD sees it in the frame it is pressed (`InputCore.is_just_pressed`).
	await UnitTestCore.wait_frames(1)
	InputCore.inject_action(&"pause", true, 1.0)
	await UnitTestCore.wait_frames(2)
	InputCore.inject_action(&"pause", false, 0.0)
	await UnitTestCore.wait_latch(opened)
	assert_true(UICore.get_open_popups().has(ResourceKey.PREFAB__MATCH__PAUSE_POPUP), "the pause popup opened")
	assert_true(match_scene.is_paused(), "the match is paused")


func test_the_match_and_game_time_stop_while_the_pause_popup_is_open() -> void:
	var match_scene: MatchScene = await open_match()
	await pause(match_scene)
	var paused_tick: int = match_scene.get_sim().tick
	var game_time: int = TimeCore.get_game_time()
	await UnitTestCore.wait_frames(_RUN_FRAMES)
	assert_true(TimeCore.is_paused(), "game time is paused")
	assert_eq(TimeCore.get_game_time(), game_time, "game time did not move")
	assert_eq(match_scene.get_sim().tick, paused_tick, "the match did not move")


func test_the_match_goes_on_after_resume() -> void:
	var match_scene: MatchScene = await open_match()
	await pause(match_scene)
	var paused_tick: int = match_scene.get_sim().tick
	# The popup lays its buttons out and ends its open motion in the frames after it opens.
	await UnitTestCore.wait_frames(_RUN_FRAMES)
	var closed: UnitTestLatch = UnitTestCore.latch_event(UIClosedEvent)
	assert_true(UnitTestCore.tap_anchor("pause_resume"), "tap resume")
	await UnitTestCore.wait_latch(closed)
	await UnitTestCore.wait_frames(_RUN_FRAMES)
	assert_false(match_scene.is_paused(), "the match is not paused")
	assert_false(TimeCore.is_paused(), "game time is not paused")
	assert_gt(match_scene.get_sim().tick, paused_tick, "the match moved")
