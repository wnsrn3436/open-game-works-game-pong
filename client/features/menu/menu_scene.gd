class_name MenuScene
extends SceneBase
## Menu scene after sign-in. Its root panel holds the start and option buttons and the record. It plays the menu BGM.


func on_start() -> void:
	SoundCore.play_bgm(ResourceKey.BGM__MENU, scope)
