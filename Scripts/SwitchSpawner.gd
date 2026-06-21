extends Node

var _spawned_switches: Array[Node] = []

var _level_configs := {
	1: { "total": 3 },
	2: { "total": 3 },
	3: { "total": 3 },
}

func spawn(level: int, parent: Node) -> Array[Node]:
	var config = _level_configs.get(level)
	if not config:
		return []

	var points := get_tree().get_nodes_in_group("switch_point")
	if points.is_empty():
		return []

	clear_spawned()

	var shuffled := points.duplicate()
	shuffled.shuffle()
	var count = mini(config.total, shuffled.size())
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

func clear_spawned() -> void:
	for s in _spawned_switches:
		if is_instance_valid(s):
			s.queue_free()
	_spawned_switches.clear()
