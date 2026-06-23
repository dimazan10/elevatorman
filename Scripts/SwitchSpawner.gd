extends Node

var _spawned_switches: Array[Node] = []

enum Mode { CLASSIC, TIME_ATTACK }

var _level_configs := {
	1: { "total_classic": 3, "total_time_attack": 2 },
	2: { "total_classic": 3, "total_time_attack": 2 },
	3: { "total_classic": 3, "total_time_attack": 2 },
}

func spawn(level: int, parent: Node, mode: Mode = Mode.CLASSIC) -> Array[Node]:
	var config = _level_configs.get(level)
	if not config:
		return []

	clear_spawned()

	if mode == Mode.CLASSIC:
		return _spawn_classic(config, parent)
	else:
		return _spawn_time_attack(parent)

func _spawn_classic(config: Dictionary, parent: Node) -> Array[Node]:
	var points := get_tree().get_nodes_in_group("switch_point")
	if points.is_empty():
		return []

	var shuffled := points.duplicate()
	shuffled.shuffle()
	var count = mini(config.total_classic, shuffled.size())
	var selected = shuffled.slice(0, count)

	var scene = load("res://Objects/Summons/Switch.tscn")
	for pt in selected:
		var inst = scene.instantiate()
		parent.add_child(inst)
		inst.global_position = pt.global_position
		if not inst.is_in_group("switch"):
			inst.add_to_group("switch")
		_spawned_switches.append(inst)

	return _spawned_switches

func _spawn_time_attack(parent: Node) -> Array[Node]:
	var points_a := get_tree().get_nodes_in_group("switch_point")
	var points_b := get_tree().get_nodes_in_group("switch_point_none")
	var total = 2
	var all_points = points_a + points_b

	if all_points.is_empty():
		return []

	var scene = load("res://Objects/Summons/TwoSwitch.tscn")

	if points_a.size() > 0 and points_b.size() > 0:
		var idx_a = randi() % points_a.size()
		var pt_a = points_a[idx_a]
		var inst_a = scene.instantiate()
		parent.add_child(inst_a)
		inst_a.global_position = pt_a.global_position
		if not inst_a.is_in_group("switch"):
			inst_a.add_to_group("switch")
		_spawned_switches.append(inst_a)

		var idx_b = randi() % points_b.size()
		var pt_b = points_b[idx_b]
		var inst_b = scene.instantiate()
		parent.add_child(inst_b)
		inst_b.global_position = pt_b.global_position
		if not inst_b.is_in_group("switch"):
			inst_b.add_to_group("switch")
		_spawned_switches.append(inst_b)
	else:
		var shuffled := all_points.duplicate()
		shuffled.shuffle()
		var count = mini(total, shuffled.size())
		for i in count:
			var inst = scene.instantiate()
			parent.add_child(inst)
			inst.global_position = shuffled[i].global_position
			if not inst.is_in_group("switch"):
				inst.add_to_group("switch")
			_spawned_switches.append(inst)

	return _spawned_switches

func clear_spawned() -> void:
	for s in _spawned_switches:
		if is_instance_valid(s):
			s.queue_free()
	_spawned_switches.clear()
