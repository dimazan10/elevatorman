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
	var points := get_tree().get_nodes_in_group("switch_point_double")

	if points.is_empty():
		return []

	var arena_groups: Dictionary = {}
	for pt in points:
		var arena = pt.get_parent()
		while arena and not (arena is AnimatableBody2D):
			arena = arena.get_parent()
		if not arena:
			continue
		if not arena_groups.has(arena):
			arena_groups[arena] = []
		arena_groups[arena].append(pt)

	var scene = load("res://Objects/Summons/TwoSwitch.tscn")
	for arena_pts in arena_groups.values():
		var pt = arena_pts[randi() % arena_pts.size()]
		var inst = scene.instantiate()
		parent.add_child(inst)
		inst.global_position = pt.global_position
		if not inst.is_in_group("switch"):
			inst.add_to_group("switch")
		_spawned_switches.append(inst)

	return _spawned_switches

func clear_spawned() -> void:
	for s in _spawned_switches:
		if is_instance_valid(s):
			s.queue_free()
	_spawned_switches.clear()
