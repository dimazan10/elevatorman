extends Node

var _active := false
var _debug_node_name := "__debug_collision__"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F4 and not event.echo:
		_active = not _active
		if _active:
			_enable()
		else:
			_disable()

func _enable() -> void:
	_walk(get_tree().root)

func _disable() -> void:
	var root = get_tree().root
	_remove_recursive(root)

func _walk(node: Node) -> void:
	for child in node.get_children():
		if child is CollisionShape2D and child.shape:
			_add_debug(child)
		elif child is CollisionPolygon2D and child.polygon.size() > 0:
			_add_debug(child)
		if child.get_child_count() > 0:
			_walk(child)

func _add_debug(collision: Node) -> void:
	var poly = Polygon2D.new()
	poly.name = _debug_node_name
	poly.z_index = 999
	poly.color = Color(0, 1, 0, 0.25)

	if collision is CollisionShape2D:
		if collision.shape is RectangleShape2D:
			var s = collision.shape.size
			poly.polygon = PackedVector2Array([
				Vector2(-s.x / 2, -s.y / 2),
				Vector2( s.x / 2, -s.y / 2),
				Vector2( s.x / 2,  s.y / 2),
				Vector2(-s.x / 2,  s.y / 2),
			])
		elif collision.shape is CircleShape2D:
			var r = collision.shape.radius
			var pts = PackedVector2Array()
			for i in 32:
				var a = TAU * i / 32.0
				pts.append(Vector2(cos(a), sin(a)) * r)
			poly.polygon = pts
		elif collision.shape is CapsuleShape2D:
			var r = collision.shape.radius
			var h = collision.shape.height
			var pts = PackedVector2Array()
			for i in 16:
				var a = -PI / 2.0 + PI * i / 15.0
				pts.append(Vector2(cos(a) * r, sin(a) * r + h / 2.0))
			for i in 16:
				var a = PI / 2.0 + PI * i / 15.0
				pts.append(Vector2(cos(a) * r, sin(a) * r - h / 2.0))
			poly.polygon = pts
	elif collision is CollisionPolygon2D:
		poly.polygon = collision.polygon

	collision.add_child(poly)

func _remove_recursive(node: Node) -> void:
	for child in node.get_children():
		if child.name == _debug_node_name:
			child.queue_free()
		elif child.get_child_count() > 0:
			_remove_recursive(child)
