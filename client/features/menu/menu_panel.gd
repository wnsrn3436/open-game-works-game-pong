class_name MenuPanel
extends UIPanel
## Root panel of the menu: the game name, the rule, the record against the CPU, the start button and the option
## button. The start button is the first focus, so one confirm input starts a match.

@export var title_label: Label
@export var rule_label: Label
@export var record_label: Label
@export var detail_label: Label
@export var play_button: Button
@export var option_button: Button
@export var play_click: UIButton
@export var option_click: UIButton

var _format_args: FormatArgs = FormatArgs.new()
var _starting: bool = false


func prepare(_reason: UICore.PanelOpenReason, _cache: UIPanelCache) -> bool:
	LocalizationCore.bind_text(title_label, ReservedString.title_name())
	LocalizationCore.bind_text(rule_label, ReservedString.menu_rule())
	LocalizationCore.bind_text(play_button, ReservedString.menu_play())
	LocalizationCore.bind_text(option_button, ReservedString.menu_options())
	play_click.set_on_click(_on_play)
	option_click.set_on_click(_on_option)
	EventCore.subscribe(UserStateChangedEvent, _on_user_state_changed)
	EventCore.subscribe(InputPromptChangedEvent, _on_input_prompt_changed)
	_write_record()
	return true


func _exit_tree() -> void:
	EventCore.unsubscribe_all(self)


func _on_play() -> void:
	if _starting:
		return
	_starting = true
	SceneCore.change_scene(ResourceKey.SCENE__MATCH__MATCH, null)


func _on_option() -> void:
	UICore.open_panel(ResourceKey.PREFAB__MENU__OPTION_PANEL, null, false)


func _on_user_state_changed(event: UserStateChangedEvent) -> void:
	if event.kind == GameContract.MatchRecordUserState:
		_write_record()


func _on_input_prompt_changed(_event: InputPromptChangedEvent) -> void:
	_write_record()


func _write_record() -> void:
	var wins: int = CommonMatchRecord.wins()
	var losses: int = CommonMatchRecord.losses()
	if wins + losses == 0:
		record_label.text = LocalizationCore.get_text(ReservedString.menu_no_record())
		detail_label.visible = false
		return
	_format_args.clear()
	_format_args.set_int("wins", wins)
	_format_args.set_int("losses", losses)
	record_label.text = LocalizationCore.format(ReservedString.menu_record(), _format_args)
	detail_label.visible = true
	var streak: int = CommonMatchRecord.win_streak()
	_format_args.clear()
	if streak >= 2:
		_format_args.set_int("streak", streak)
		detail_label.text = LocalizationCore.format(ReservedString.menu_win_streak(), _format_args)
	else:
		_format_args.set_int("rally", CommonMatchRecord.best_rally())
		detail_label.text = LocalizationCore.format(ReservedString.menu_best_rally(), _format_args)
