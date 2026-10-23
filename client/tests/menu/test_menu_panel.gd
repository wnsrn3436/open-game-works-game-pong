extends UnitTestCase
## The menu panel: a new user sees the first-match line, the record follows the `MatchRecordUserState` delta, a win
## streak of two or more replaces the best rally line. The boot opens the match for a user without a finished match
## and the menu once the record has one.

const _SERVER_TIME: int = 1710000000000
const _RESYNC: String = "core/Resync"


func after_each() -> void:
	super()
	BootstrapCoreDev.shutdown()


func open_menu_panel() -> MenuPanel:
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
	assert_true(NetworkCore.init(), "NetworkCore.init")
	assert_true(await DataCore.load(null), "DataCore.load")
	LocalizationCore.resolve_language()
	assert_true(await LocalizationCore.load_translation([]), "LocalizationCore.load_translation")
	assert_true(await UICore.prepare(), "UICore.prepare")
	assert_true(await MessageCore.prepare(), "MessageCore.prepare")
	assert_true(NetworkCore.set_server_info("http://127.0.0.1", "1.0.0", CoreBuildInfo.platform), "set_server_info")
	NetworkCore.set_session_provider(MenuTestSessionProvider.new())
	LogCore.clear_sender()
	assert_true(await UICore.open_panel(ResourceKey.PREFAB__MENU__MENU_PANEL, null, false), "open the menu panel")
	await UnitTestCore.wait_frames(1)
	var panel: MenuPanel = find_panel(UICore.get_layer(UICore.UILayer.PANEL))
	assert_not_null(panel, "the menu panel instance")
	return panel


func find_panel(node: Node) -> MenuPanel:
	if node is MenuPanel:
		return node as MenuPanel
	for child: Node in node.get_children():
		var found: MenuPanel = find_panel(child)
		if found != null:
			return found
	return null


## A full resync response whose UserState is one `MatchRecordUserState`.
func record_response(wins: int, losses: int, best_rally: int, win_streak: int) -> PackedByteArray:
	var env: CoreContract.ResponseEnvelope = CoreContract.ResponseEnvelope.new()
	env.server_time_at = _SERVER_TIME
	env.user_state = CoreContract.UserStateDelta.new()
	env.user_state.full = true
	var state: GameContract.MatchRecordUserState = GameContract.MatchRecordUserState.new()
	state.wins = wins
	state.losses = losses
	state.best_rally = best_rally
	state.win_streak = win_streak
	var entry: CoreContract.UserStateEntry = CoreContract.UserStateEntry.new()
	entry.kind = "MatchRecordUserState"
	entry.value = state.encode()
	env.user_state.entries.append(entry)
	env.body = CoreContract.ResyncResponse.new().encode()
	return UnitTestCore.make_response(env)


func receive_record(wins: int, losses: int, best_rally: int, win_streak: int) -> void:
	UnitTestCore.add_result(_RESYNC, NetworkCore.TransferResult.DONE, 200, record_response(wins, losses, best_rally, win_streak))
	var changed: UnitTestLatch = UnitTestCore.latch_event(UserStateChangedEvent)
	NetworkCore.resync()
	await UnitTestCore.wait_latch(changed)


func formatted(key: String, names: PackedStringArray, values: PackedInt64Array) -> String:
	var args: FormatArgs = FormatArgs.new()
	for i: int in names.size():
		args.set_int(names[i], values[i])
	return LocalizationCore.format(key, args)


func test_a_new_user_sees_the_first_match_line() -> void:
	var panel: MenuPanel = await open_menu_panel()
	assert_eq(panel.record_label.text, LocalizationCore.get_text(ReservedString.menu_no_record()))
	assert_false(panel.detail_label.visible, "no detail line before the first match")


func test_the_record_follows_the_match_record_delta() -> void:
	var panel: MenuPanel = await open_menu_panel()
	await receive_record(3, 5, 14, 1)
	assert_eq(panel.record_label.text, formatted(ReservedString.menu_record(), PackedStringArray(["wins", "losses"]), PackedInt64Array([3, 5])))
	assert_true(panel.detail_label.visible, "the detail line shows")
	assert_eq(panel.detail_label.text, formatted(ReservedString.menu_best_rally(), PackedStringArray(["rally"]), PackedInt64Array([14])))


func test_a_win_streak_of_two_or_more_shows_instead_of_the_best_rally() -> void:
	var panel: MenuPanel = await open_menu_panel()
	await receive_record(4, 1, 9, 3)
	assert_eq(panel.detail_label.text, formatted(ReservedString.menu_win_streak(), PackedStringArray(["streak"]), PackedInt64Array([3])))


func test_the_boot_opens_the_match_until_the_first_finished_match() -> void:
	await open_menu_panel()
	var boot: ContentBoot = ContentBoot.new()
	assert_eq(boot.select_first_scene(), ResourceKey.SCENE__MATCH__MATCH, "no record: the match")
	await receive_record(0, 1, 2, 0)
	assert_eq(boot.select_first_scene(), BootstrapCore.get_first_scene(), "one finished match: the menu")
	assert_eq(BootstrapCore.get_first_scene(), ResourceKey.SCENE__MENU__MENU, "the game settings first scene is the menu")
