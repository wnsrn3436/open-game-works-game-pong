class_name MatchCourtView
extends Node2D
## The court around the origin: background, top and bottom walls, the dashed center net and the ball trail. The
## match scene sets the court size and pushes ball positions into the trail.

var court_size: Vector2 = Vector2.ZERO
var trail_side: float = 0.0
var trail_color: Color = Color.WHITE

var _trail: PackedVector2Array = PackedVector2Array()
var _trail_count: int = 0
var _trail_head: int = 0


func setup(size_pixels: Vector2, ball_side: float, trail_length: int) -> void:
	court_size = size_pixels
	trail_side = ball_side
	_trail.resize(maxi(trail_length, 1))
	clear_trail()


func clear_trail() -> void:
	_trail_count = 0
	_trail_head = 0
	queue_redraw()


func push_trail(at: Vector2, ball_color: Color) -> void:
	_trail[_trail_head] = at
	_trail_head = (_trail_head + 1) % _trail.size()
	_trail_count = mini(_trail_count + 1, _trail.size())
	trail_color = ball_color
	queue_redraw()


func _draw() -> void:
	var bg_half: Vector2 = MatchConstants.BACKGROUND_HALF
	draw_rect(Rect2(-bg_half, bg_half * 2.0), MatchConstants.BACKGROUND_COLOR)
	var half: Vector2 = court_size * 0.5
	draw_rect(Rect2(-half, court_size), MatchConstants.COURT_COLOR)
	var line: float = MatchConstants.LINE_WIDTH
	draw_rect(Rect2(Vector2(-half.x, -half.y - line), Vector2(court_size.x, line)), MatchConstants.LINE_COLOR)
	draw_rect(Rect2(Vector2(-half.x, half.y), Vector2(court_size.x, line)), MatchConstants.LINE_COLOR)
	var y: float = -half.y
	var net_half: float = MatchConstants.NET_WIDTH * 0.5
	while y < half.y:
		var dash: float = minf(MatchConstants.NET_DASH, half.y - y)
		draw_rect(Rect2(Vector2(-net_half, y), Vector2(MatchConstants.NET_WIDTH, dash)), MatchConstants.NET_COLOR)
		y += MatchConstants.NET_DASH + MatchConstants.NET_GAP
	_draw_trail()


func _draw_trail() -> void:
	var size: int = _trail.size()
	for i: int in _trail_count:
		var index: int = (_trail_head - 1 - i + size) % size
		var fade: float = 1.0 - float(i + 1) / float(_trail_count + 1)
		var dot_color: Color = trail_color
		dot_color.a = MatchConstants.TRAIL_OPACITY * fade
		var side: float = trail_side * lerpf(MatchConstants.TRAIL_MIN_SCALE, 1.0, fade)
		var h: float = side * 0.5
		draw_rect(Rect2(_trail[index] - Vector2(h, h), Vector2(side, side)), dot_color)
