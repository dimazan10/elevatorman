extends Node2D

const FLOOR_EMPTY = preload("res://Scenes/Floors/Floor_Empty.tscn")
const FLOOR_ELEVATOR = preload("res://Scenes/Floors/Floor_Elevator.tscn")
const FLOOR_RECTANGLE = preload("res://Scenes/Floors/Floor_Rectangle.tscn")

const DOOR_POINTS = [
	Vector2(461.25, 266.25),
	Vector2(0, 532.5),
	Vector2(-461.25, 266.25),
	Vector2(-461.25, -266.25),
	Vector2(0, -532.5),
	Vector2(461.25, -266.25),
]

const HEX_DIRS = [
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0),
	Vector2i(0, -1),
	Vector2i(1, -1),
]

const OPPOSITE_DOOR = [3, 4, 5, 0, 1, 2]

const RECT_DOORPOINT_0 = Vector2(300, 0)
const RECT_DOORPOINT_1 = Vector2(1800, 0)

const STEP_Q = DOOR_POINTS[0] - DOOR_POINTS[3]
const STEP_R = DOOR_POINTS[1] - DOOR_POINTS[4]

@export var room_count: int = 5
@export var stretch: float = 1.0

var rng = RandomNumberGenerator.new()
var floor_container: Node2D
var generated_rooms = {}  # "q,r" -> RoomData

class RoomData:
	var axial: Vector2i
	var world_pos: Vector2
	var scene: Node2D
	var doors_open: Array = [false, false, false, false, false, false]
	var connections: Array = []  # [{dir, other_axial, other_door}]

func _ready() -> void:
	print("LevelGen: starting generation")
	rng.randomize()
	floor_container = Node2D.new()
	floor_container.name = "Floors"
	add_child(floor_container)
	move_child(floor_container, 0)  # floors render BEHIND player/UI
	generate()

func generate() -> void:
	var start = Vector2i(0, 0)
	_add_room(start, true)

	_bfs_expand()

	_place_rectangles()

	_open_close_doors()

	_add_wall_visuals()

	_move_player_to_start()

	print("LevelGen: generated %d rooms" % generated_rooms.size())

func axial_to_world(q: int, r: int) -> Vector2:
	return STEP_Q * q + STEP_R * r

func _add_room(axial: Vector2i, is_start: bool) -> RoomData:
	var key = "%d,%d" % [axial.x, axial.y]
	if generated_rooms.has(key):
		return generated_rooms[key]

	var world_pos = axial_to_world(axial.x, axial.y)

	var scene = FLOOR_ELEVATOR.instantiate() if is_start else FLOOR_EMPTY.instantiate()
	scene.position = world_pos
	floor_container.add_child(scene)

	var data = RoomData.new()
	data.axial = axial
	data.world_pos = world_pos
	data.scene = scene
	generated_rooms[key] = data
	return data

func _bfs_expand() -> void:
	var keys = generated_rooms.keys()
	var queue = [generated_rooms[keys[0]]]

	while generated_rooms.size() < room_count and queue.size() > 0:
		var room = queue.pop_front()

		var dirs = _pick_random_dirs()
		for d in dirs:
			var neighbor_axial = room.axial + HEX_DIRS[d]
			var nkey = "%d,%d" % [neighbor_axial.x, neighbor_axial.y]
			if generated_rooms.has(nkey):
				continue
			if generated_rooms.size() >= room_count:
				break

			var is_start = false
			var neighbor = _add_room(neighbor_axial, is_start)
			room.doors_open[d] = true
			neighbor.doors_open[OPPOSITE_DOOR[d]] = true
			room.connections.append({"dir": d, "other_axial": neighbor_axial, "other_door": OPPOSITE_DOOR[d]})
			neighbor.connections.append({"dir": OPPOSITE_DOOR[d], "other_axial": room.axial, "other_door": d})
			queue.append(neighbor)

func _pick_random_dirs() -> Array:
	var count = rng.randi_range(2, 4)
	var dirs = [0, 1, 2, 3, 4, 5]
	dirs.shuffle()
	return dirs.slice(0, count)

func _place_rectangles() -> void:
	for key in generated_rooms:
		var room = generated_rooms[key]
		for conn in room.connections:
			var door_idx = conn["dir"]
			if not room.doors_open[door_idx]:
				continue
			var other_key = "%d,%d" % [conn["other_axial"].x, conn["other_axial"].y]
			if not generated_rooms.has(other_key):
				continue
			if key > other_key:
				continue  # process each connection once only

			var other = generated_rooms[other_key]

			var my_door_world = room.world_pos + DOOR_POINTS[door_idx]
			var other_door_world = other.world_pos + DOOR_POINTS[conn["other_door"]]
			var mid = (my_door_world + other_door_world) / 2.0
			var gap = other_door_world - my_door_world
			var gap_len = gap.length()

			var rect = FLOOR_RECTANGLE.instantiate()
			rect.position = mid
			rect.rotation = atan2(gap.y, gap.x) - atan2(RECT_DOORPOINT_1.y - RECT_DOORPOINT_0.y, RECT_DOORPOINT_1.x - RECT_DOORPOINT_0.x)

			var base_len = RECT_DOORPOINT_1.distance_to(RECT_DOORPOINT_0)
			if base_len > 0:
				rect.scale.x = gap_len / base_len
			floor_container.add_child(rect)

func _move_player_to_start() -> void:
	var key = "0,0"
	if not generated_rooms.has(key):
		return
	var start_room = generated_rooms[key]
	var spawn = _find_child_recursive(start_room.scene, "SpawnPoint")
	if spawn:
		var player = get_node_or_null("Player")
		if player:
			player.position = spawn.global_position

func _add_wall_visuals() -> void:
	var wall_color = Color(0.4, 0.4, 0.5, 1)
	var wall_polygon = PackedVector2Array([-307.5, -10, 307.5, -10, 307.5, 10, -307.5, 10])

	for key in generated_rooms:
		var room = generated_rooms[key]
		var all_nodes = [room.scene]
		while all_nodes.size() > 0:
			var node = all_nodes.pop_back()
			for child in node.get_children():
				if child is StaticBody2D and child.name.begins_with("W"):
					var existing = child.get_node_or_null("Visual")
					if not existing:
						var vis = Polygon2D.new()
						vis.name = "Visual"
						vis.color = wall_color
						vis.polygon = wall_polygon
						child.add_child(vis)
				all_nodes.append(child)

func _find_door_shape(room: RoomData, door_idx: int) -> Node:
	var doors = _find_child_recursive(room.scene, "Doors")
	if not doors:
		return null
	var w = doors.get_node_or_null("W%d" % door_idx)
	if not w:
		return null
	return w.get_node_or_null("CollisionShape")

func _open_close_doors() -> void:
	for key in generated_rooms:
		var room = generated_rooms[key]
		for i in range(6):
			var doors = _find_child_recursive(room.scene, "Doors")
			if not doors:
				continue
			var w = doors.get_node_or_null("W%d" % i)
			if not w:
				continue
			var cs = w.get_node_or_null("CollisionShape")
			if cs:
				cs.set_deferred("disabled", room.doors_open[i])
			var vis = w.get_node_or_null("Visual")
			if vis:
				vis.visible = not room.doors_open[i]

func _find_child_recursive(node: Node, name: String) -> Node:
	if node.name == name:
		return node
	for child in node.get_children():
		var result = _find_child_recursive(child, name)
		if result:
			return result
	return null
