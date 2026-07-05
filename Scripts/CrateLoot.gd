extends Area2D

const ICONS = {
	"tube": preload("res://Assets/Items/Tube.png"),
	"clone": preload("res://Assets/Items/Clone.png"),
	"infinit": preload("res://Assets/Items/Infinit.png"),
	"bucket": preload("res://Assets/Items/Bucket.png"),
	"collar": preload("res://Assets/Items/Collar.png"),
}

var loot_id: String = ""
var _sprite: Sprite2D
var _glow: Sprite2D
var _bob_tween: Tween

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = ICONS.get(loot_id)
	_sprite.scale = Vector2(0.15, 0.15)
	_sprite.z_index = 5
	add_child(_sprite)

	var glow = Sprite2D.new()
	glow.texture = preload("res://Assets/Items/Wind.png")
	glow.scale = Vector2(0.12, 0.12)
	glow.modulate = Color(1.0, 0.95, 0.4, 0.35)
	glow.z_index = 4
	add_child(glow)
	_glow = glow

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 14.0
	col.shape = shape
	add_child(col)

	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, true)

	body_entered.connect(_on_body_entered)
	monitoring = true

	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(_sprite, "position:y", -4.0, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_bob_tween.parallel().tween_property(_glow, "position:y", -4.0, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_bob_tween.tween_property(_sprite, "position:y", 0.0, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_bob_tween.parallel().tween_property(_glow, "position:y", 0.0, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	var pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(_glow, "modulate:a", 0.15, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(_glow, "modulate:a", 0.45, 0.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if not body.has_method("set_slot"):
		return

	match loot_id:
		"bucket":
			if body.has_node("Bucket"):
				return
			if GameState.has_collar:
				return
			var bucket = preload("res://Objects/Bucket.tscn").instantiate()
			bucket.name = "Bucket"
			bucket.position = Vector2(0, -33)
			bucket.scale = Vector2(0.05, 0.05)
			bucket.z_index = body.z_index
			body.add_child(bucket)
			body._bucket = bucket
			GameState.has_bucket = true
			GameState.bucket_charges = 2
		"collar":
			if body.has_node("Collar"):
				return
			if GameState.has_bucket:
				return
			var collar = preload("res://Objects/Collar.tscn").instantiate()
			collar.name = "Collar"
			collar.position = Vector2(0, -10)
			collar.scale = Vector2(0.12, 0.12)
			collar.z_index = body.z_index
			body.add_child(collar)
			body._collar = collar
			GameState.has_collar = true
			GameState.collar_charges = 3
		_:
			for i in range(body.inventory.size()):
				if body.inventory[i].id == "":
					body.set_slot(i, loot_id, ICONS[loot_id], loot_id.capitalize())
					break

	queue_free()
