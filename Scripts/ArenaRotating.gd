extends Node2D

var rotation_speed: float = 0.5

func _ready() -> void:
	randomize()
	$Pivot.rotation = randf_range(0, TAU)

func _physics_process(delta: float) -> void:
	var pivot = $Pivot
	if not pivot:
		return
	var rot: float = pivot.rotation + delta * rotation_speed
	if rot >= TAU:
		pivot.rotation = 0.0
		set_process(false)
	else:
		pivot.rotation = rot
