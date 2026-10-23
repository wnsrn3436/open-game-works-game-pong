class_name MatchPausePopup
extends UIPopup
## Pause popup over the match: resume, or leave the match for the menu. A back input resumes.

@export var title_label: Label
@export var resume_button: Button
@export var quit_button: Button
@export var resume_click: UIButton
@export var quit_click: UIButton

var _param: MatchPauseParam = null


func accepts_param(param: UIParam) -> bool:
	return param is MatchPauseParam


func prepare() -> bool:
	_param = popup_param as MatchPauseParam
	LocalizationCore.bind_text(title_label, ReservedString.match_pause_title())
	LocalizationCore.bind_text(resume_button, ReservedString.match_resume())
	LocalizationCore.bind_text(quit_button, ReservedString.match_quit())
	resume_click.set_on_click(_on_resume)
	quit_click.set_on_click(_on_quit)
	return true


func on_back() -> void:
	_on_resume()


func _on_resume() -> void:
	UICore.close_popup(self, _param.on_resume)


func _on_quit() -> void:
	UICore.close_popup(self, _param.on_quit)
