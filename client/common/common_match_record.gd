class_name CommonMatchRecord
extends RefCounted
## The match record of the user, read from the `MatchRecordUserState` cache. Every value is 0 before the first
## finished match.


static func wins() -> int:
	var state: GameContract.MatchRecordUserState = _state()
	return 0 if state == null else state.wins


static func losses() -> int:
	var state: GameContract.MatchRecordUserState = _state()
	return 0 if state == null else state.losses


static func best_rally() -> int:
	var state: GameContract.MatchRecordUserState = _state()
	return 0 if state == null else state.best_rally


static func win_streak() -> int:
	var state: GameContract.MatchRecordUserState = _state()
	return 0 if state == null else state.win_streak


static func _state() -> GameContract.MatchRecordUserState:
	return UserStateCore.get_single(GameContract.MatchRecordUserState) as GameContract.MatchRecordUserState
