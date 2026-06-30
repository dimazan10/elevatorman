extends Area2D

var target: Vector2
var speed: float = 2400.0

func _ready() -> void:
	add_to_group("bullet")
	body_entered.connect(_on_body_entered)
	var vis := ColorRect.new()
	vis.name = "Visual"
	vis.size = Vector2(80, 80)
	vis.color = Color(1, 0.8, 0.2)
	vis.position = Vector2(-40, -40)
	add_child(vis)

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

func _explode() -> void:
	var tw := create_tween()
	var vis = get_node_or_null("Visual")
	if vis:
		tw.tween_property(vis, "scale", Vector2(4, 4), 0.15)
		tw.parallel().tween_property(vis, "modulate", Color.TRANSPARENT, 0.15)
	tw.tween_callback(queue_free)
