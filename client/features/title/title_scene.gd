class_name TitleScene
extends SceneBase
## Title scene of the boot: the game name and its tagline over the court colors while the game signs in.

@export var title_label: Label
@export var tagline_label: Label


func _ready() -> void:
	LocalizationCore.bind_text(title_label, ReservedString.title_name())
	LocalizationCore.bind_text(tagline_label, ReservedString.title_tagline())
