class_name MenuDev
extends RefCounted
## DEV registration of the menu feature: the screen commands and the record invariant.


static func register() -> void:
	QACore.register_command("menu.open_menu", "Opens the menu scene with its root panel on top.", PackedStringArray(),
		func(_args: PackedStringArray) -> RunCommandResult: return await MenuDev.open_menu())
	QACore.register_command("menu.open_option", "Opens the option panel over the menu.", PackedStringArray(),
		func(_args: PackedStringArray) -> RunCommandResult: return await MenuDev.open_option())
	QACore.register_invariant("menu.record_not_negative", func() -> bool: return MenuDev.record_not_negative())


static func open_menu() -> RunCommandResult:
	UICore.close_all_popups()
	if SceneCore.current_scene_key() != ResourceKey.SCENE__MENU__MENU:
		if not await SceneCore.change_scene(ResourceKey.SCENE__MENU__MENU, null):
			return _result(false)
	return _result(await UICore.close_panels_to(ResourceKey.PREFAB__MENU__MENU_PANEL))


static func open_option() -> RunCommandResult:
	var menu: RunCommandResult = await open_menu()
	if not menu.ok:
		return menu
	return _result(await UICore.open_panel(ResourceKey.PREFAB__MENU__OPTION_PANEL, null, false))


static func record_not_negative() -> bool:
	return CommonMatchRecord.wins() >= 0 and CommonMatchRecord.losses() >= 0 and CommonMatchRecord.best_rally() >= 0 \
		and CommonMatchRecord.win_streak() >= 0


static func _result(ok: bool) -> RunCommandResult:
	var out: RunCommandResult = RunCommandResult.new()
	out.ok = ok
	out.result = "" if ok else "\"the screen did not open\""
	return out
