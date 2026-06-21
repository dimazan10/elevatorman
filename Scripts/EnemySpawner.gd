extends Node

var _spawned_enemies: Array[Node] = []

var _pool := ["angry_ball", "DrunkKiller", "Spider"]

func spawn(level: int, parent: Node, group_name: String = "spawn_point", zone_name: String = "") -> Array[Node]:
	var points := get_tree().get_nodes_in_group(group_name)
	if points.is_empty():
		return []

	var total = 3 + level + randi() % 3
	var types: Array[String] = ["angry_ball", "DrunkKiller", "Spider"]

	var remaining = total - types.size()
	for _i in remaining:
		types.append(_pool[randi() % _pool.size()])

	types.shuffle()

	for t in types:
		if points.is_empty():
			break
		var idx = randi() % points.size()
		var pt = points[idx]
		points.remove_at(idx)
		var scene = load("res://Objects/Summons/" + t + ".tscn")
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
