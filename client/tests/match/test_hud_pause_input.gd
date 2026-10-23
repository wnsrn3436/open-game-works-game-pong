extends UnitTestCase
## The `pause` action on the match HUD: the HUD asks the match to pause also while the match world is stopped (as in
## step mode between steps, when the world does not process frames), because the UI keeps running, and for a key tap
## shorter than a frame.

var _pause_requests: int = 0


func after_each() -> void:
	super()
	BootstrapCoreDev.shutdown()


func open_hud() -> void:
	assert_true(LogCore.init(), "LogCore.init")
	assert_true(EventCore.init(), "EventCore.init")
	assert_true(TimeCore.init(), "TimeCore.init")
	assert_true(LocalDataCore.init(), "LocalDataCore.init")
	assert_true(LocalDataCore.load_device_file(), "LocalDataCore.load_device_file")
	assert_true(ResourceCore.init(), "ResourceCore.init")
	assert_true(PoolCore.init(), "PoolCore.init")
	assert_true(DataCore.init(), "DataCore.init")
	assert_true(UserStateCore.init(), "UserStateCore.init")
	assert_true(ResolutionCore.init(), "ResolutionCore.init")
	assert_true(SafeAreaCore.init(), "SafeAreaCore.init")
	assert_true(InputBlockCore.init(), "InputBlockCore.init")
	assert_true(InputCore.init(), "InputCore.init")
	assert_true(LocalizationCore.init(), "LocalizationCore.init")
	assert_true(SoundCore.init(), "SoundCore.init")
	assert_true(TweenCore.init(), "TweenCore.init")
	assert_true(UICore.init(), "UICore.init")
	assert_true(MessageCore.init(), "MessageCore.init")
	assert_true(await DataCore.load(null), "DataCore.load")
	LocalizationCore.resolve_language()
	assert_true(await LocalizationCore.load_translation([]), "LocalizationCore.load_translation")
	assert_true(await UICore.prepare(), "UICore.prepare")
	assert_true(await MessageCore.prepare(), "MessageCore.prepare")
	assert_true(await UICore.open_panel(ResourceKey.PREFAB__MATCH__HUD_PANEL, null, false), "open the HUD")
	await UnitTestCore.wait_frames(1)
	_pause_requests = 0
	EventCore.subscribe(MatchPauseRequestedEvent, _on_pause_requested)


func _on_pause_requested(_event: MatchPauseRequestedEvent) -> void:
	_pause_requests += 1


func press_pause() -> void:
	InputCore.inject_action(&"pause", true, 1.0)
	await UnitTestCore.wait_frames(2)
	InputCore.inject_action(&"pause", false, 0.0)
	await UnitTestCore.wait_frames(2)


func test_the_pause_action_asks_the_match_to_pause() -> void:
	await open_hud()
	await press_pause()
	assert_eq(_pause_requests, 1)


func test_the_pause_action_asks_the_match_to_pause_while_the_world_is_stopped() -> void:
	await open_hud()
	TimeCore.set_paused(true)
	await press_pause()
	TimeCore.set_paused(false)
	assert_eq(_pause_requests, 1)


## The press and the release of `P` reach the engine before the next frame, so `pause` is never held in a frame.
func test_a_pause_key_tap_within_one_frame_asks_the_match_to_pause() -> void:
	await open_hud()
	for pressed: bool in [true, false]:
		var key: InputEventKey = InputEventKey.new()
		key.keycode = KEY_P
		key.pressed = pressed
		Input.parse_input_event(key)
	Input.flush_buffered_events()
	await UnitTestCore.wait_frames(2)
	assert_eq(_pause_requests, 1)
