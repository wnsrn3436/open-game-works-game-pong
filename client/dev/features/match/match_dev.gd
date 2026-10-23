class_name MatchDev
extends RefCounted
## DEV registration of the match feature: the bot, the screen commands, the invariants, the content state and the
## telemetry marks. The lambdas hold the one `MatchBot` of this boot until QACore releases them.


static func register() -> void:
	var bot: MatchBot = MatchBot.new()
	QACore.register_command("match.bot_next_input", "Returns the next input of the bot player: start, play and rematch.",
		PackedStringArray(), func(args: PackedStringArray) -> RunCommandResult: return bot.next_input(args))
	QACore.register_command("match.open_match", "Opens the match scene with its HUD; a new match starts.", PackedStringArray(),
		func(args: PackedStringArray) -> RunCommandResult: return await bot.open_match(args))
	QACore.register_command("match.open_result", "Opens the result panel of a won match over the match scene.",
		PackedStringArray(), func(args: PackedStringArray) -> RunCommandResult: return await bot.open_result(args))
	QACore.register_command("match.open_result_unsaved",
		"Opens the result panel of a lost match the server did not count over the match scene.", PackedStringArray(),
		func(args: PackedStringArray) -> RunCommandResult: return await bot.open_result_unsaved(args))
	QACore.register_command("match.open_pause", "Opens the pause popup over a running match.", PackedStringArray(),
		func(args: PackedStringArray) -> RunCommandResult: return await bot.open_pause(args))
	QACore.register_invariant("match.scores_in_range", func() -> bool: return bot.scores_in_range())
	QACore.register_invariant("match.paddles_in_court", func() -> bool: return bot.paddles_in_court())
	QACore.set_content_state(func() -> String: return MatchDev.content_state())
	EventCore.subscribe(MatchPointLostEvent, bot.on_point_lost)
	EventCore.subscribe(MatchPointWonEvent, bot.on_point_won)
	EventCore.subscribe(MatchServedEvent, bot.on_served)
	EventCore.subscribe(MatchWonEvent, bot.on_won)
	EventCore.subscribe(MatchRespondedEvent, bot.on_responded)


## The stored match record: what a restart keeps.
static func content_state() -> String:
	return JSON.stringify({
		"wins": CommonMatchRecord.wins(),
		"losses": CommonMatchRecord.losses(),
		"best_rally": CommonMatchRecord.best_rally(),
		"win_streak": CommonMatchRecord.win_streak(),
	})
