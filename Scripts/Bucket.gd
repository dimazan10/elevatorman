extends Sprite2D

var charges := 3
var active := true

func hit() -> bool:
	if not active or charges <= 0:
		return false
	charges -= 1

	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.RED, 0.05)
	tw.tween_property(self, "modulate", Color.WHITE, 0.1)

	var orig = position
	for _i in range(3):
		position = orig + Vector2(randf_range(-4, 4), randf_range(-4, 4))
		await get_tree().create_timer(0.02).timeout
	position = orig

	if charges <= 0:
		_destroy()

	return true

func _destroy() -> void:
	active = false
	var gp = global_position
	top_level = true
	position = gp
	var dir = Vector2(randf_range(-100, 100), -200).rotated(randf_range(-0.3, 0.3))
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "rotation", rotation + TAU * 3, 1.0)
	tw.tween_property(self, "position", position + dir, 1.0)
	tw.tween_property(self, "scale", Vector2.ZERO, 1.0)
	tw.tween_callback(queue_free).set_delay(1.0)
