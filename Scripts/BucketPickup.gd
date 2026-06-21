extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = true
	var gp = global_position
	top_level = true
	global_position = gp

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_node("Bucket"):
		queue_free()
		return
	var bucket = preload("res://Objects/Bucket.tscn").instantiate()
	bucket.name = "Bucket"
	bucket.position = Vector2(0, -33)
	bucket.scale = Vector2(0.05, 0.05)
	bucket.z_index = body.z_index
	body.add_child(bucket)
	body._bucket = bucket
	queue_free()
