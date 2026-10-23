class_name MatchStateChangedEvent
extends EventBase
## Content event: a value the match HUD shows changed. The match scene publishes it with the whole HUD state.

var player_score: int = 0
var cpu_score: int = 0
## Paddle hits of the current rally.
var rally: int = 0
## One side needs one more point to win.
var match_point: bool = false
## The control hint shows: the player has not moved the paddle in this scene yet.
var show_hint: bool = false
## The match waits for the server before it starts.
var starting: bool = false
## The ball waits at the center for its serve.
var serving: bool = false
