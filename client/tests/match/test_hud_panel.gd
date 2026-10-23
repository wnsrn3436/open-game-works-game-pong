extends UnitTestCase
## The match HUD prefab: the serve state text sits right above the court center, where the waiting ball and its serve
## direction show, and the control hint sits below the court so it does not cover play.

## The base resolution the HUD fills.
const _SCREEN: Vector2 = Vector2(1920.0, 1080.0)
## The status text is at most this far above the waiting ball, in pixels.
const _NEAR: float = 60.0


func before_each() -> void:
	assert_true(LogCore.init(), "LogCore.init")
	assert_true(EventCore.init(), "EventCore.init")
	assert_true(TimeCore.init(), "TimeCore.init")
	assert_true(LocalDataCore.init(), "LocalDataCore.init")
	assert_true(LocalDataCore.load_device_file(), "LocalDataCore.load_device_file")
	assert_true(ResourceCore.init(), "ResourceCore.init")
	assert_true(PoolCore.init(), "PoolCore.init")
	assert_true(DataCore.init(), "DataCore.init")
	assert_true(ResolutionCore.init(), "ResolutionCore.init")
	assert_true(SafeAreaCore.init(), "SafeAreaCore.init")
	assert_true(InputBlockCore.init(), "InputBlockCore.init")
	assert_true(InputCore.init(), "InputCore.init")
	assert_true(await DataCore.load(null), "DataCore.load")


func after_each() -> void:
	super()
	BootstrapCoreDev.shutdown()


func open_hud() -> MatchHudPanel:
	var scene: PackedScene = await ResourceCore.load(ResourceKey.PREFAB__MATCH__HUD_PANEL,
		ResourceCore.BaseKind.PACKED_SCENE, ResourceCore.get_global_scope()) as PackedScene
	assert_not_null(scene, "the HUD prefab")
	var hud: MatchHudPanel = scene.instantiate() as MatchHudPanel
	assert_not_null(hud, "the HUD root")
	var frame: Control = Control.new()
	frame.size = _SCREEN
	add_child_autofree(frame)
	frame.add_child(hud)
	await UnitTestCore.wait_frames(1)
	return hud


func test_the_status_text_sits_right_above_the_waiting_ball() -> void:
	var hud: MatchHudPanel = await open_hud()
	var rect: Rect2 = hud.status_label.get_rect()
	var serve_point: Vector2 = hud.size * 0.5
	var ball_top: float = serve_point.y - float(GameSetting.ball_size()) / MatchConstants.UNITS_PER_PIXEL * MatchConstants.BALL_GLOW_SCALE * 0.5
	assert_almost_eq(rect.get_center().x, serve_point.x, 2.0, "status center x %s" % rect.get_center().x)
	assert_true(rect.end.y <= ball_top, "status bottom %s above the ball glow top %s" % [rect.end.y, ball_top])
	assert_true(ball_top - rect.end.y <= _NEAR, "status bottom %s near the ball glow top %s" % [rect.end.y, ball_top])


func test_the_control_hint_sits_below_the_court() -> void:
	var hud: MatchHudPanel = await open_hud()
	var court_bottom: float = hud.size.y * 0.5 + float(GameSetting.court_height()) / MatchConstants.UNITS_PER_PIXEL * 0.5 \
		+ MatchConstants.LINE_WIDTH
	var rect: Rect2 = hud.hint_label.get_rect()
	assert_true(rect.position.y >= court_bottom, "hint top %s below the court bottom line %s" % [rect.position.y, court_bottom])
	assert_true(rect.end.y <= hud.size.y, "hint bottom %s on the screen" % rect.end.y)
