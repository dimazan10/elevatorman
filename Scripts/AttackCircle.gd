extends Area2D

var circle_radius := 500.0
var circle_color := Color(1, 0, 0, 0.25)
var is_blue := false

func _ready() -> void:
	$CollisionShape2D.shape.radius = circle_radius
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, circle_radius, circle_color)
