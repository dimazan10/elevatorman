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
	var coins = randi_range(1, 3)
	GameState.currency += coins
	_spawn_coin_labels(coins)
	_spawn碎片()
	queue_free()

func _spawn_coin_labels(count: int) -> void:
	var scene = get_tree().current_scene
	if not scene:
		return
	var label_layer = scene.get_node_or_null("TimerUI")
	if not label_layer:
		return
	for i in count:
		var lbl = Label.new()
		lbl.text = "+1$"
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.add_theme_color_override("font_color", Color(1, 0.85, 0))
		lbl.add_theme_constant_override("outline_size", 1)
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl.position = global_position + Vector2(randf_range(-15, 15), randf_range(-20, 0))
		scene.add_child(lbl)
		var tw = create_tween()
		tw.tween_property(lbl, "position:y", lbl.position.y - 40, 0.5)
		tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5)
		tw.tween_callback(lbl.queue_free)

func _spawn碎片() -> void:
	for i in 4:
		var piece = Sprite2D.new()
		piece.texture = $Sprite2D.texture
		piece.region_enabled = true
		var cx = randf_range(0.1, 0.4) * 256
		var cy = randf_range(0.1, 0.4) * 256
		piece.region_rect = Rect2(cx, cy, 32, 32)
		piece.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		piece.z_index = 5
		get_tree().current_scene.add_child(piece)
		var dir = Vector2(randf_range(-1, 1), randf_range(-1, 0.5)).normalized()
		var tw = create_tween()
		tw.tween_property(piece, "position", piece.position + dir * randf_range(40, 80), 0.3).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(piece, "rotation", randf_range(-3, 3), 0.3)
		tw.parallel().tween_property(piece, "modulate:a", 0.0, 0.3).set_delay(0.1)
		tw.tween_callback(piece.queue_free)
