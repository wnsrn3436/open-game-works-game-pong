class_name MatchResultParam
extends UIParam
## Param of the result panel: the finished match, the record after it, and the two ways on.

var won: bool = false
## The server counted the match in the record.
var saved: bool = false
var player_score: int = 0
var cpu_score: int = 0
var longest_rally: int = 0
## Player paddle hits of the longest rally; the CPU hit the rest of it.
var longest_rally_player: int = 0
## The longest rally of this match beat the best rally of the record before it.
var new_best: bool = false
var wins: int = 0
var losses: int = 0
var win_streak: int = 0
## Called after the panel closed for a new match.
var on_rematch: Callable = Callable()
## Called for the menu.
var on_menu: Callable = Callable()
