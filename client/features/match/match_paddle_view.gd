class_name MatchPaddleView
extends Node2D
## One paddle drawn as a rounded bar centered on the node. The match scene sets its size, color and position. A paddle
## hit marks where the ball met the paddle with a short bright bar across it that fades, so the return angle reads.

@export var contact_mark: Polygon2D

var bar_size: Vector2 = Vector2.ZERO
var color: Color = Color.WHITE
var _mark_options: TweenOptions = null


func set_look(size_pixels: Vector2, bar_color: Color) -> void:
	bar_size = size_pixels
	color = bar_color
	var half: Vector2 = Vector2(size_pixels.x * 0.5 + MatchConstants.CONTACT_MARK_OVERHANG,
		MatchConstants.CONTACT_MARK_HEIGHT * 0.5)
	contact_mark.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	contact_mark.color = MatchConstants.CONTACT_MARK_COLOR
	contact_mark.modulate.a = 0.0
	queue_redraw()


## Marks the place `offset_y` pixels below the paddle center where the ball met the paddle. The mark fades on game
## time, so it holds while the match is stopped.
func mark_contact(offset_y: float, scope: Scope) -> void:
	if _mark_options == null:
		_mark_options = TweenOptions.new()
		_mark_options.time_basis = TweenCore.TimeBasis.GAME_TIME
	contact_mark.position = Vector2(0.0, offset_y)
	TweenCore.play_preset(ResourceKey.TWEEN__MATCH__CONTACT_MARK, scope, contact_mark, _mark_options)


func _draw() -> void:
	var half: Vector2 = bar_size * 0.5
	draw_rect(Rect2(-half, bar_size), color)
