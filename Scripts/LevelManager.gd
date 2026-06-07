extends Node2D
# Level manager - selects random floors and stacks them

const FLOOR_SCENES = [
	"res://Scenes/Floors/Floor_Arena_01.tscn",
	"res://Scenes/Floors/Floor_Corridor.tscn",
	"res://Scenes/Floors/Floor_Base.tscn",
]

@export var floor_count: int = 3
@export var floor_height: float = 1065.0

var floors: Array = []
var current_floor_index: int = 0

func _ready() -> void:
	print("LevelManager: Starting level generation")
	generate_floors()
	print("LevelManager: Level generation complete. Floors: %d" % floors.size())

func generate_floors() -> void:
	var container = Node2D.new()
	container.name = "FloorsContainer"
	add_child(container)

	# Select random floors
	var selected_scenes: Array = []
	for i in range(floor_count):
		var scene_path = FLOOR_SCENES[randi() % FLOOR_SCENES.size()]
		selected_scenes.append(scene_path)

	# Instantiate and stack them
	var current_y: float = 0.0
	for i in range(selected_scenes.size()):
		var scene_path = selected_scenes[i]
		var floor_scene = load(scene_path)
		if floor_scene:
			var floor = floor_scene.instantiate()
			floor.position.y = current_y
			floor.floor_index = i
			container.add_child(floor)
			floors.append(floor)
			current_y += floor_height

	print("LevelManager: Generated %d floors" % floors.size())

func get_current_floor() -> Node2D:
	if current_floor_index >= 0 and current_floor_index < floors.size():
		return floors[current_floor_index]
	return null

func get_floor_spawn_point(index: int) -> Vector2:
	if index >= 0 and index < floors.size():
		return floors[index].get_spawn_point()
	return Vector2.ZERO

func advance_floor() -> bool:
	current_floor_index += 1
	if current_floor_index >= floors.size():
		return false  # No more floors - game complete
	return true

func get_total_floors() -> int:
	return floors.size()
