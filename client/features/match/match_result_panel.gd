class_name MatchResultPanel
extends UIPanel
## Result panel over the match: win or loss, the score, the longest rally of the match with the hits of each side, the
## record (or that the match was not counted in it), and the rematch and menu buttons. Rematch is the first focus so one
## input starts the next match. A back input goes to the menu.

@export var title_label: Label
@export var score_label: Label
@export var rally_label: Label
@export var best_label: Label
@export var record_label: Label
@export var rematch_button: Button
@export var menu_button: Button
@export var rematch_click: UIButton
@export var menu_click: UIButton

var _param: MatchResultParam = null
var _format_args: FormatArgs = FormatArgs.new()
var _leaving: bool = false


func accepts_param(param: UIParam) -> bool:
	return param is MatchResultParam


func prepare(_reason: UICore.PanelOpenReason, _cache: UIPanelCache) -> bool:
	_param = panel_param as MatchResultParam
	LocalizationCore.bind_text(title_label, ReservedString.result_win() if _param.won else ReservedString.result_lose())
	title_label.modulate = MatchConstants.PLAYER_COLOR if _param.won else MatchConstants.CPU_COLOR
	LocalizationCore.bind_text(rematch_button, ReservedString.result_rematch())
	LocalizationCore.bind_text(menu_button, ReservedString.result_menu())
	rematch_click.set_on_click(_on_rematch)
	menu_click.set_on_click(_on_menu)
	EventCore.subscribe(InputPromptChangedEvent, _on_input_prompt_changed)
	_write_texts()
	return true


func on_back() -> void:
	_on_menu()


func _exit_tree() -> void:
	EventCore.unsubscribe_all(self)


func _on_input_prompt_changed(_event: InputPromptChangedEvent) -> void:
	_write_texts()


func _write_texts() -> void:
	_format_args.clear()
	_format_args.set_int("player", _param.player_score)
	_format_args.set_int("cpu", _param.cpu_score)
	score_label.text = LocalizationCore.format(ReservedString.result_score(), _format_args)
	_format_args.clear()
	_format_args.set_int("rally", _param.longest_rally)
	_format_args.set_int("player", _param.longest_rally_player)
	_format_args.set_int("cpu", _param.longest_rally - _param.longest_rally_player)
	rally_label.text = LocalizationCore.format(ReservedString.result_longest_rally_hits(), _format_args)
	best_label.visible = _param.saved and (_param.new_best or (_param.won and _param.win_streak >= 2))
	if _param.new_best:
		best_label.text = LocalizationCore.get_text(ReservedString.result_new_best())
	elif best_label.visible:
		_format_args.clear()
		_format_args.set_int("streak", _param.win_streak)
		best_label.text = LocalizationCore.format(ReservedString.result_win_streak(), _format_args)
	_format_args.clear()
	_format_args.set_int("wins", _param.wins)
	_format_args.set_int("losses", _param.losses)
	var record_key: String = ReservedString.result_record() if _param.saved else ReservedString.result_record_unsaved()
	record_label.text = LocalizationCore.format(record_key, _format_args)


func _on_rematch() -> void:
	if _leaving:
		return
	_leaving = true
	MatchResultPanel._close_then(_param.on_rematch)


func _on_menu() -> void:
	if _leaving:
		return
	_leaving = true
	_param.on_menu.call()


static func _close_then(next: Callable) -> void:
	if await UICore.close_panel():
		next.call()
