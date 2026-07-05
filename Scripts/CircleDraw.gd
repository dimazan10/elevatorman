extends Node2D

var radius := 50.0
var color := Color(1, 0, 0, 0.3)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
