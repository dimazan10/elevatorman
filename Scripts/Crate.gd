extends StaticBody2D

@export var max_health: int = 3
var health: int = max_health

func _ready() -> void:
	health = max_health
	add_to_group("crate")

func take_damage(amount: int) -> void:
	health -= amount
	_flash_white()
	if health <= 0:
		_destroy()

func _flash_white() -> void:
	var sprite = $Sprite2D
	if sprite:
		sprite.modulate = Color(10, 10, 10)
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.15)

func _destroy() -> void:
	queue_free()
