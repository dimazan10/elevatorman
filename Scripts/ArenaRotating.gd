extends Node2D

var rotation_speed: float = 0.5

func _physics_process(delta: float) -> void:
	var pivot = $Pivot
	if pivot:
		pivot.rotation += delta * rotation_speed
