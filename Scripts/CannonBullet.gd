extends Area2D

var target: Vector2
var speed: float = 2400.0
var _hit := false
var _used := false

func _ready() -> void:
	add_to_group("bullet")
	var vis := ColorRect.new()
	vis.name = "Visual"
	vis.size = Vector2(80, 80)
	vis.color = Color(1, 0.8, 0.2)
	vis.position = Vector2(-40, -40)
	add_child(vis)

func _physics_process(delta: float) -> void:
	if _hit:
		return

	var from: Vector2 = global_position
	var distance: float = from.distance_to(target)
	if distance < 20:
		on_hit()
		return

	var dir: Vector2 = (target - from).normalized()
	var travel: float = minf(speed * delta, distance)
	var next_position: Vector2 = from + dir * travel
	if _try_hit_between(from, next_position):
		return

	global_position = next_position
	rotation = dir.angle()

	if travel >= distance:
		on_hit()

func _try_hit_between(from: Vector2, to: Vector2) -> bool:
	var segment := SegmentShape2D.new()
	segment.a = from
	segment.b = to

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = segment
	query.transform = Transform2D.IDENTITY
	query.collision_mask = collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.exclude = [get_rid()]

	var results: Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(query)
	if results.is_empty():
		return false

	for result: Dictionary in results:
		var collider: Object = result.get("collider")
		var hit_position: Vector2 = _closest_point_on_segment(collider, from, to)
		if _notify_bullet_hit(collider, hit_position):
			return true
		if collider is Node:
			var collider_node: Node = collider as Node
			if _notify_bullet_hit(collider_node.get_parent(), hit_position):
				return true
	return false

func _closest_point_on_segment(collider: Object, from: Vector2, to: Vector2) -> Vector2:
	var point: Vector2 = to
	if collider is Node2D:
		var collider_2d: Node2D = collider as Node2D
		point = collider_2d.global_position

	var segment: Vector2 = to - from
	var length_squared: float = segment.length_squared()
	if length_squared <= 0.0:
		return from

	var t: float = clampf((point - from).dot(segment) / length_squared, 0.0, 1.0)
	return from + segment * t

func _notify_bullet_hit(node: Object, hit_position: Vector2) -> bool:
	if not node:
		return false
	if node is Node and node.has_method("try_hit_with_bullet"):
		var handled: bool = bool(node.call("try_hit_with_bullet", self, hit_position))
		return handled
	return false

func is_used() -> bool:
	return _used

func mark_used() -> void:
	_used = true

func on_hit() -> void:
	if _hit:
		return
	_hit = true
	_explode()

func _explode() -> void:
	var tw := create_tween()
	var vis = get_node_or_null("Visual")
	if vis:
		tw.tween_property(vis, "scale", Vector2(4, 4), 0.15)
		tw.parallel().tween_property(vis, "modulate", Color.TRANSPARENT, 0.15)
	tw.tween_callback(queue_free)
