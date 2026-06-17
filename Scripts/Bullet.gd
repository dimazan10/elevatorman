extends Area2D

@export var speed: float = 500.0
var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Подключаем сигнал столкновения
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		queue_free()
	elif body is StaticBody2D:
		queue_free()
