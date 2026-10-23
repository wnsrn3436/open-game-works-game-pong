class_name ContentBoot
extends ContentEntry
## Content entry of the game. The game registers no core hook. A user who has not finished a match yet starts in the
## match instead of the menu, so the first play needs no start press.


func _init() -> void:
	CommonVariantParser.warm()


func content_init() -> bool:
	return true


func content_release() -> void:
	pass


func select_first_scene() -> String:
	if CommonMatchRecord.wins() + CommonMatchRecord.losses() == 0:
		return ResourceKey.SCENE__MATCH__MATCH
	return BootstrapCore.get_first_scene()
