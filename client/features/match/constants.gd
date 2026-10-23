class_name MatchConstants
extends RefCounted
## Drawing values of the match feature. Gameplay values are in `game_setting`.

## Court units (`MatchSim`) per drawn pixel.
const UNITS_PER_PIXEL: float = 100.0 # unit conversion, not a tunable value
## Background, court lines and the center net.
const BACKGROUND_COLOR: Color = Color(0.043, 0.059, 0.102, 1.0) # color of the drawing only; no rule reads it
const COURT_COLOR: Color = Color(0.067, 0.09, 0.149, 1.0) # color of the drawing only; no rule reads it
const LINE_COLOR: Color = Color(0.91, 0.925, 0.957, 0.85) # color of the drawing only; no rule reads it
const NET_COLOR: Color = Color(0.91, 0.925, 0.957, 0.28) # color of the drawing only; no rule reads it
## Background rect half size in pixels: it covers the widest game area.
const BACKGROUND_HALF: Vector2 = Vector2(1400.0, 700.0) # layout of the drawing only; no rule reads it
const LINE_WIDTH: float = 6.0 # look of the drawing only; no rule reads it
const NET_DASH: float = 26.0 # look of the drawing only; no rule reads it
const NET_GAP: float = 18.0 # look of the drawing only; no rule reads it
const NET_WIDTH: float = 6.0 # look of the drawing only; no rule reads it
## Paddle colors: the player is cyan, the CPU is coral, so the sides differ by place and by color.
const PLAYER_COLOR: Color = Color(0.302, 0.824, 1.0, 1.0) # color of the drawing only; no rule reads it
const CPU_COLOR: Color = Color(1.0, 0.361, 0.478, 1.0) # color of the drawing only; no rule reads it
## Ball color at the start speed and at the top speed.
const BALL_SLOW_COLOR: Color = Color(0.96, 0.97, 1.0, 1.0) # color of the drawing only; no rule reads it
const BALL_FAST_COLOR: Color = Color(1.0, 0.827, 0.302, 1.0) # color of the drawing only; no rule reads it
## Opacity of the newest trail dot; older dots fade to 0.
const TRAIL_OPACITY: float = 0.45 # look of the drawing only; no rule reads it
## Glow ring around the ball as a part of its size, and its opacity.
const BALL_GLOW_SCALE: float = 1.9 # look of the drawing only; no rule reads it
const BALL_GLOW_OPACITY: float = 0.18 # look of the drawing only; no rule reads it
## The waiting ball before a serve: its opacity, and the serve direction mark (dot distances from the ball center,
## dot radius, arrow head tip distance, length and half width, opacity), in pixels.
const WAITING_BALL_OPACITY: float = 0.55 # look of the drawing only; no rule reads it
const SERVE_AIM_DOTS: PackedFloat32Array = [40.0, 64.0, 88.0] # look of the drawing only; no rule reads it
const SERVE_AIM_DOT_RADIUS: float = 5.0 # look of the drawing only; no rule reads it
const SERVE_AIM_TIP: float = 128.0 # look of the drawing only; no rule reads it
const SERVE_AIM_HEAD_LENGTH: float = 22.0 # look of the drawing only; no rule reads it
const SERVE_AIM_HEAD_HALF_WIDTH: float = 13.0 # look of the drawing only; no rule reads it
const SERVE_AIM_OPACITY: float = 0.8 # look of the drawing only; no rule reads it
## The paddle hit mark: its height, how far it sticks out on each side of the paddle, in pixels, and its color.
const CONTACT_MARK_HEIGHT: float = 10.0 # look of the drawing only; no rule reads it
const CONTACT_MARK_OVERHANG: float = 8.0 # look of the drawing only; no rule reads it
const CONTACT_MARK_COLOR: Color = Color(0.96, 0.97, 1.0, 1.0) # color of the drawing only; no rule reads it
## Frames of catch-up ticks at most in one frame, so a long frame does not freeze the game.
const MAX_TICKS_PER_FRAME: int = 12 # frame budget, not a gameplay value
## Size of the oldest trail dot as a part of the ball size.
const TRAIL_MIN_SCALE: float = 0.4 # look of the drawing only; no rule reads it
## Permille of a whole.
const PERMILLE: int = 1000 # unit conversion, not a tunable value
const PERMILLE_F: float = 1000.0 # unit conversion, not a tunable value
## The DEV bot player meets the ball this far off its paddle center, as a part of the paddle half height.
const BOT_LEAN_PERMILLE: int = 600 # DEV bot play style; no game rule reads it
## The DEV bot player stops when its paddle is this close to its target, in court units.
const BOT_DEAD_ZONE: int = 1800 # DEV bot play style; no game rule reads it
## Frames a DEV screen command waits for the match to start or the popup to open.
const DEV_WAIT_FRAMES: int = 600 # DEV command time limit; no game rule reads it
## Values of the result panel the DEV screen command opens for the UI check.
const PREVIEW_LONGEST_RALLY: int = 23 # DEV preview text only; no game rule reads it
const PREVIEW_LONGEST_RALLY_PLAYER: int = 12 # DEV preview text only; no game rule reads it
const PREVIEW_WINS: int = 12 # DEV preview text only; no game rule reads it
const PREVIEW_LOSSES: int = 9 # DEV preview text only; no game rule reads it
const PREVIEW_STREAK: int = 3 # DEV preview text only; no game rule reads it
