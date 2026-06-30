extends Area2D

var attached := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if attached:
		return
	if not body.is_in_group("player"):
		return
	attached = true
	_pickup.call_deferred(body)

func _pickup(body: Node2D) -> void:
	if body.get_node_or_null("Patron"):
		attached = false
		return
	monitoring = false
	collision_layer = 0
	collision_mask = 0
	reparent(body)
	position = Vector2(0, -50)

func is_attached() -> bool:
	return attached
