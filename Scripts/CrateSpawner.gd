extends Marker2D

const CRATE_SCENE = preload("res://Objects/Crate.tscn")

const LOOT_POOL := ["tube", "clone", "infinit", "bucket", "collar"]
const EQUIPMENT := ["bucket", "collar"]

static var _used_equipment: Array[String] = []
static var _loot_assigned: bool = false

static func reset_equipment() -> void:
	_used_equipment.clear()
	_loot_assigned = false

@export var min_crates: int = 4
@export var max_crates: int = 9
@export var spacing: float = 30.0

func _ready() -> void:
	call_deferred("_spawn_cluster")

func _spawn_cluster() -> void:
	var count = randi_range(min_crates, max_crates)
	var grid_size = ceili(sqrt(float(count)))
	var crates_to_spawn = count
	var offset_x = -(grid_size - 1) * spacing * 0.5
	var offset_y = -(grid_size - 1) * spacing * 0.5
	var pivot = get_parent()
	var spawned_crates: Array[StaticBody2D] = []

	for gy in grid_size:
		for gx in grid_size:
			if crates_to_spawn <= 0:
				break
			var pos = Vector2(
				offset_x + gx * spacing + randf_range(-3, 3),
				offset_y + gy * spacing + randf_range(-3, 3)
			)
			if pos.length() > 250:
				continue
			var crate = CRATE_SCENE.instantiate()
			crate.position = position + pos
			pivot.add_child(crate)
			spawned_crates.append(crate)
			crates_to_spawn -= 1

	for _remaining in crates_to_spawn:
		var angle = randf() * TAU
		var dist = randf_range(0, 60)
		var crate = CRATE_SCENE.instantiate()
		crate.position = position + Vector2(cos(angle), sin(angle)) * dist
		pivot.add_child(crate)
		spawned_crates.append(crate)

	if spawned_crates.is_empty():
		return

	if not _loot_assigned:
		_loot_assigned = true
		var lucky = spawned_crates[randi() % spawned_crates.size()]
		lucky.loot_id = LOOT_POOL[randi() % LOOT_POOL.size()]
