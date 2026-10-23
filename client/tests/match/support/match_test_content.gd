class_name MatchTestContent
extends ContentEntry
## Content entry of the match regression tests: the boot has no login, so it gives the network a test session, and
## the first scene is the match.


func _init() -> void:
	CommonVariantParser.warm()


func content_init() -> bool:
	NetworkCore.set_session_provider(MatchTestSessionProvider.new())
	return true


func content_release() -> void:
	pass


func select_first_scene() -> String:
	return ResourceKey.SCENE__MATCH__MATCH
