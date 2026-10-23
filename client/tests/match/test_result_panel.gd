extends UnitTestCase
## The result panel: it shows the match result and the record from its param, the rematch button closes the panel
## before it starts the next match, and the menu button leaves for the menu.

var _rematches: int = 0
var _menus: int = 0


func after_each() -> void:
	super()
	BootstrapCoreDev.shutdown()


## Inits the modules the panel uses in module list order, loads the data and translation and prepares the UI.
func prepare_ui() -> void:
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
	assert_true(await DataCore.load(null), "DataCore.load")
	LocalizationCore.resolve_language()
	assert_true(await LocalizationCore.load_translation([]), "LocalizationCore.load_translation")
	assert_true(await UICore.prepare(), "UICore.prepare")


func won_param() -> MatchResultParam:
	var param: MatchResultParam = MatchResultParam.new()
	param.won = true
	param.saved = true
	param.player_score = GameSetting.points_to_win()
	param.cpu_score = 4
	param.longest_rally = 17
	param.longest_rally_player = 9
	param.new_best = true
	param.wins = 3
	param.losses = 2
	param.win_streak = 2
	param.on_rematch = func() -> void: _rematches += 1
	param.on_menu = func() -> void: _menus += 1
	return param


func open_panel(param: MatchResultParam) -> MatchResultPanel:
	assert_true(await UICore.open_panel(ResourceKey.PREFAB__MATCH__RESULT_PANEL, param, false), "open the result panel")
	await UnitTestCore.wait_frames(1)
	var panel: MatchResultPanel = find_panel(UICore.get_layer(UICore.UILayer.PANEL))
	assert_not_null(panel, "the result panel instance")
	return panel


func find_panel(node: Node) -> MatchResultPanel:
	if node is MatchResultPanel:
		return node as MatchResultPanel
	for child: Node in node.get_children():
		var found: MatchResultPanel = find_panel(child)
		if found != null:
			return found
	return null


func formatted(key: String, names: PackedStringArray, values: PackedInt64Array) -> String:
	var args: FormatArgs = FormatArgs.new()
	for i: int in names.size():
		args.set_int(names[i], values[i])
	return LocalizationCore.format(key, args)


func test_the_panel_shows_the_result_and_the_record_of_its_param() -> void:
	await prepare_ui()
	var param: MatchResultParam = won_param()
	var panel: MatchResultPanel = await open_panel(param)
	assert_eq(panel.title_label.text, LocalizationCore.get_text(ReservedString.result_win()))
	assert_eq(panel.score_label.text, formatted(ReservedString.result_score(), PackedStringArray(["player", "cpu"]), PackedInt64Array([param.player_score, 4])))
	assert_eq(panel.rally_label.text, formatted(ReservedString.result_longest_rally_hits(), PackedStringArray(["rally", "player", "cpu"]), PackedInt64Array([17, 9, 8])))
	assert_true(panel.best_label.visible, "a new best rally shows")
	assert_eq(panel.best_label.text, LocalizationCore.get_text(ReservedString.result_new_best()))
	assert_eq(panel.record_label.text, formatted(ReservedString.result_record(), PackedStringArray(["wins", "losses"]), PackedInt64Array([3, 2])))


## A match the server did not count (for example its play session expired) says so on the record line with the record
## before it, and shows no best line.
func test_an_unsaved_match_says_it_was_not_counted_and_hides_the_best_line() -> void:
	await prepare_ui()
	var param: MatchResultParam = won_param()
	param.saved = false
	param.new_best = false
	var panel: MatchResultPanel = await open_panel(param)
	assert_eq(panel.title_label.text, LocalizationCore.get_text(ReservedString.result_win()))
	assert_false(panel.best_label.visible, "no best line when the match was not saved")
	assert_true(panel.record_label.visible, "the record line shows")
	assert_eq(panel.record_label.text, formatted(ReservedString.result_record_unsaved(), PackedStringArray(["wins", "losses"]), PackedInt64Array([3, 2])))


func test_rematch_closes_the_panel_and_then_starts_the_next_match_once() -> void:
	await prepare_ui()
	await open_panel(won_param())
	assert_true(UnitTestCore.tap_anchor("result_rematch"), "tap rematch")
	UnitTestCore.tap_anchor("result_rematch")
	await UnitTestCore.wait_frames(30)
	assert_eq(_rematches, 1)
	assert_eq(UICore.get_current_panel_key(), "")


func test_menu_leaves_for_the_menu_once() -> void:
	await prepare_ui()
	await open_panel(won_param())
	assert_true(UnitTestCore.tap_anchor("result_menu"), "tap menu")
	await UnitTestCore.wait_frames(3)
	assert_eq(_menus, 1)
