class_name MatchTestClock
extends Node
## Moves the test clock every frame as real time would pass, so a match test can wait for an event while the boot,
## the loading screen and the match run on the clock.

## Clock time of one frame, in ms.
const FRAME_MS: int = 16


func _process(_delta: float) -> void:
	UnitTestCore.advance_clock(FRAME_MS, false)
