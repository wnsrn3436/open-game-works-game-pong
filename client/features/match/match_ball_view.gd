class_name MatchBallView
extends Node2D
## The ball: a square with a soft glow, drawn centered on the node. Its color goes warm as the ball speeds up. While
## it waits for the serve it is dimmed and shows the serve direction with dots and an arrow head.

var side: float = 0.0
var color: Color = Color.WHITE
## Unit direction of the next serve while the ball waits; zero while it is in play.
var aim: Vector2 = Vector2.ZERO


func set_look(side_pixels: float, ball_color: Color) -> void:
	if side == side_pixels and color == ball_color:
		return
	side = side_pixels
	color = ball_color
	queue_redraw()


func set_aim(direction: Vector2) -> void:
	if aim == direction:
		return
	aim = direction
	queue_redraw()


func _draw() -> void:
	var glow: Color = color
	glow.a = MatchConstants.BALL_GLOW_OPACITY
	draw_circle(Vector2.ZERO, side * 0.5 * MatchConstants.BALL_GLOW_SCALE, glow)
	var half: float = side * 0.5
	draw_rect(Rect2(Vector2(-half, -half), Vector2(side, side)), color)
	if aim != Vector2.ZERO:
		_draw_aim()


func _draw_aim() -> void:
	var mark: Color = color
	mark.a = MatchConstants.SERVE_AIM_OPACITY
	for distance: float in MatchConstants.SERVE_AIM_DOTS:
		draw_circle(aim * distance, MatchConstants.SERVE_AIM_DOT_RADIUS, mark)
	var across: Vector2 = Vector2(-aim.y, aim.x) * MatchConstants.SERVE_AIM_HEAD_HALF_WIDTH
	var tip: Vector2 = aim * MatchConstants.SERVE_AIM_TIP
	var base: Vector2 = aim * (MatchConstants.SERVE_AIM_TIP - MatchConstants.SERVE_AIM_HEAD_LENGTH)
	draw_colored_polygon(PackedVector2Array([tip, base + across, base - across]), mark)
