extends Node

var _spawned_enemies: Array[Node] = []

var _level_configs := {
	1: {
		"total": 5,
		"min_angry_ball": 1,
		"min_drunk_killer": 1,
	}
}

func spawn(level: int, parent: Node) -> Array[Node]:
	var config = _level_configs.get(level)
	if not config:
		return []

	var points := get_tree().get_nodes_in_group("spawn_point")
	if points.is_empty():
		return []

	var types: Array[String] = []
	for _i in config.min_angry_ball:
		types.append("angry_ball")
	for _i in config.min_drunk_killer:
		types.append("DrunkKiller")

	var remaining = config.total - types.size()
	var pool = ["angry_ball", "DrunkKiller"]
	for _i in remaining:
		types.append(pool[randi() % pool.size()])

	types.shuffle()

	clear_spawned()
	for t in types:
		var pt = points[randi() % points.size()]
		var scene = load("res://Objects/" + t + ".tscn")
		var inst = scene.instantiate()
		parent.add_child(inst)
		inst.global_position = pt.global_position
		if not inst.is_in_group("enemy"):
			inst.add_to_group("enemy")
		_spawned_enemies.append(inst)

	return _spawned_enemies

func clear_spawned() -> void:
	for e in _spawned_enemies:
		if is_instance_valid(e):
			e.queue_free()
	_spawned_enemies.clear()
