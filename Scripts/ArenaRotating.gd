extends Node2D

var rotation_speed: float = 0.5

func _physics_process(delta: float) -> void:
	var pivot: Node2D = $Pivot
	if not pivot:
		return
	pivot.rotation = fmod(pivot.rotation + delta * rotation_speed, TAU)
