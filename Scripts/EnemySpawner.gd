extends Node

var _spawned_enemies: Array[Node] = []

var _pool := ["angry_ball", "DrunkKiller", "Spider", "Turret"]

func _ready() -> void:
	pass

func spawn(level: int, parent: Node, group_name: String = "spawn_point", zone_name: String = "", arena: Node = null, bonus: int = 0) -> Array[Node]:
	var all_points := get_tree().get_nodes_in_group(group_name)
	var points := []
	for pt in all_points:
		if arena == null or arena.is_ancestor_of(pt):
			points.append(pt)
	if points.is_empty():
		return []

	var gate_triggers := get_tree().get_nodes_in_group("gate_trigger")
	var safe_points := []
	for pt in points:
		var too_close := false
		for gt in gate_triggers:
			if pt.global_position.distance_to(gt.global_position) < 250.0:
				too_close = true
				break
		if not too_close:
			safe_points.append(pt)

	var use_points := safe_points if not safe_points.is_empty() else points

	var total = 3 + level + randi() % 3 + bonus
	var types: Array[String] = ["angry_ball", "DrunkKiller", "Spider", "Turret"]

	var remaining = total - types.size()
	for _i in remaining:
		types.append(_pool[randi() % _pool.size()])

	types.shuffle()

	for t in types:
		if use_points.is_empty():
			break
		var idx = randi() % use_points.size()
		var pt = use_points[idx]
		use_points.remove_at(idx)
		var scene = load("res://Objects/Summons/" + t + ".tscn")
		if scene == null:
			continue
			
		var inst = scene.instantiate()
		inst.global_position = pt.global_position
		inst.set_meta("spawn_position", pt.global_position)
		inst.set_meta("zone_name", zone_name)
		parent.add_child(inst)
		if not inst.is_in_group("enemy"):
			inst.add_to_group("enemy")
		_spawned_enemies.append(inst)

	return _spawned_enemies

func clear_spawned() -> void:
	for e in _spawned_enemies:
		if is_instance_valid(e):
			e.queue_free()
	_spawned_enemies.clear()
