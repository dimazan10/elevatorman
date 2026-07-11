extends Node

var _spawned_enemies: Array[Node] = []

func _ready() -> void:
	pass

func spawn(level: int, parent: Node, group_name: String = "spawn_point", zone_name: String = "", arena: Node = null, base_count: int = 5) -> Array[Node]:
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

	var floor_bonus := maxi(0, level - 1)
	var total := base_count + floor_bonus

	var pool: Array[String] = ["angry_ball", "DrunkKiller", "Spider", "Turret"]
	if level >= 2:
		pool.append("Clown")
		pool.append("GrenadeMan")

	var types: Array[String] = []
	var available := pool.duplicate()
	available.shuffle()
	var min_types := mini(3, available.size())
	for _i in min_types:
		types.append(available.pop_back())
	for _i in maxi(0, total - types.size()):
		types.append(pool[randi() % pool.size()])

	if level >= 2:
		var clown_count := 0
		for t in types:
			if t == "Clown":
				clown_count += 1
		while clown_count > 1:
			for i in types.size():
				if types[i] == "Clown":
					var replacement := pool[randi() % pool.size()]
					while replacement == "Clown":
						replacement = pool[randi() % pool.size()]
					types[i] = replacement
					clown_count -= 1
					break

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
		inst.set_meta("spawn_position", pt.global_position)
		inst.set_meta("zone_name", zone_name)
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
