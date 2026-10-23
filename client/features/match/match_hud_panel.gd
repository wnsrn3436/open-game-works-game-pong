class_name MatchHudPanel
extends UIPanel
## Root panel of the match: both scores, the rally count, match point, the serve and start states and the control
## hint. It draws `MatchStateChangedEvent`. A back input or the `pause` action asks the match scene to pause. The UI
## keeps running while the match world is stopped (step mode between steps), so a `pause` press there is not lost.

@export var player_score_label: Label
@export var cpu_score_label: Label
@export var player_name_label: Label
@export var cpu_name_label: Label
@export var rally_label: Label
@export var match_point_label: Label
@export var status_label: Label
@export var hint_label: Label

const _PAUSE: StringName = &"pause"

var _format_args: FormatArgs = FormatArgs.new()
var _player_score: int = -1
var _cpu_score: int = -1
var _rally: int = -1


func prepare(_reason: UICore.PanelOpenReason, _cache: UIPanelCache) -> bool:
	LocalizationCore.bind_text(player_name_label, ReservedString.match_you())
	LocalizationCore.bind_text(cpu_name_label, ReservedString.match_cpu())
	LocalizationCore.bind_text(match_point_label, ReservedString.match_point())
	LocalizationCore.bind_text(hint_label, ReservedString.match_controls_hint())
	player_score_label.pivot_offset = player_score_label.size * 0.5
	cpu_score_label.pivot_offset = cpu_score_label.size * 0.5
	EventCore.subscribe(MatchStateChangedEvent, _on_state_changed)
	EventCore.subscribe(InputPromptChangedEvent, _on_input_prompt_changed)
	_write_scores(0, 0)
	_write_rally(0)
	match_point_label.visible = false
	hint_label.visible = false
	status_label.visible = false
	return true


func on_back() -> void:
	EventCore.publish(EventCore.acquire(MatchPauseRequestedEvent))


func _exit_tree() -> void:
	EventCore.unsubscribe_all(self)


func _process(_delta: float) -> void:
	if InputCore.is_just_pressed(_PAUSE):
		EventCore.publish(EventCore.acquire(MatchPauseRequestedEvent))


func _on_state_changed(event: MatchStateChangedEvent) -> void:
	var player_up: bool = _player_score >= 0 and event.player_score > _player_score
	var cpu_up: bool = _cpu_score >= 0 and event.cpu_score > _cpu_score
	_write_scores(event.player_score, event.cpu_score)
	if player_up:
		TweenCore.play_preset(ResourceKey.TWEEN__MATCH__SCORE_POP, scope, player_score_label)
	if cpu_up:
		TweenCore.play_preset(ResourceKey.TWEEN__MATCH__SCORE_POP, scope, cpu_score_label)
	_write_rally(event.rally)
	match_point_label.visible = event.match_point and not event.starting
	hint_label.visible = event.show_hint
	if event.starting:
		LocalizationCore.bind_text(status_label, ReservedString.match_starting())
		status_label.visible = true
	elif event.serving:
		LocalizationCore.bind_text(status_label, ReservedString.match_ready())
		status_label.visible = true
	else:
		status_label.visible = false


func _on_input_prompt_changed(_event: InputPromptChangedEvent) -> void:
	_write_rally(_rally)


func _write_scores(player_score: int, cpu_score: int) -> void:
	if player_score != _player_score:
		_player_score = player_score
		player_score_label.text = str(player_score)
	if cpu_score != _cpu_score:
		_cpu_score = cpu_score
		cpu_score_label.text = str(cpu_score)


func _write_rally(rally: int) -> void:
	_rally = rally
	rally_label.visible = rally >= 2
	if not rally_label.visible:
		return
	_format_args.clear()
	_format_args.set_int("count", rally)
	rally_label.text = LocalizationCore.format(ReservedString.match_rally(), _format_args)
