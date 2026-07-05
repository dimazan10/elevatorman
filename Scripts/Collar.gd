extends Sprite2D

var active := true
var charges := 3

func hit() -> bool:
	if not active or charges <= 0:
		return false
	charges -= 1
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.CYAN, 0.05)
	tw.tween_property(self, "modulate", Color.WHITE, 0.1)
	if charges <= 0:
		_destroy()
	return true

func _destroy() -> void:
	active = false
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)
