extends StaticBody2D

func _ready() -> void:
	add_to_group("crate")

func take_damage(_amount: int) -> void:
	queue_free()
