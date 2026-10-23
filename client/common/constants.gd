class_name CommonConstants
extends RefCounted
## Values the shared content code uses. Gameplay values are in `game_setting`.

## Permille of a whole.
const PERMILLE: int = 1000 # unit conversion, not a tunable value
const PERMILLE_F: float = 1000.0 # unit conversion, not a tunable value
## Text color of the terms hint while an agree toggle is off (highlight) and once both are on (secondary text).
const TERMS_HINT_WAITING_COLOR: Color = Color(1.0, 0.827, 0.302, 1.0) # color of the drawing only; no rule reads it
const TERMS_HINT_DONE_COLOR: Color = Color(0.62, 0.659, 0.749, 1.0) # color of the drawing only; no rule reads it
