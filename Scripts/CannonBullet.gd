extends Area2D

var target: Vector2
var speed: float = 1200.0
var _start: Vector2

func _ready() -> void:
	_start = global_position
	add_to_group("bullet")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	scale = Vector2(0.3, 0.3)

func _physics_process(delta: float) -> void:
	if global_position.distance_to(target) < 20:
		_explode()
		return
	var dir = (target - global_position).normalized()
	position += dir * speed * delta
	rotation = dir.angle()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		return
	if body is StaticBody2D or body.is_in_group("enemy"):
		_explode()

func _on_area_entered(_area: Area2D) -> void:
	pass

func _explode() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(2, 2), 0.15)
	tw.parallel().tween_property(self, "modulate", Color.TRANSPARENT, 0.15)
	tw.tween_callback(queue_free)
