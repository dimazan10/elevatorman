extends StaticBody2D

const LOOT_SCENE = preload("res://Objects/CrateLoot.tscn")

var loot_id: String = ""

func _ready() -> void:
	add_to_group("crate")

func take_damage(_amount: int) -> void:
	if loot_id != "":
		var loot = LOOT_SCENE.instantiate()
		loot.loot_id = loot_id
		loot.global_position = global_position
		get_tree().current_scene.add_child(loot)
	queue_free()
