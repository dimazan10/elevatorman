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
	var total = 2

	if points.is_empty():
		return []

	var scene = load("res://Objects/Summons/TwoSwitch.tscn")
	var shuffled := points.duplicate()
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
