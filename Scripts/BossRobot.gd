extends Node2D

const HealthUI := preload("res://Objects/UI_HP.tscn")
const DashUI := preload("res://Objects/DashUI.tscn")
const InventoryUI := preload("res://Objects/InventoryUI.tscn")
const BossHPBar := preload("res://Scripts/BossHPBar.gd")

func _ready() -> void:
	add_to_group("pausable")
	add_child(HealthUI.instantiate())
	add_child(DashUI.instantiate())
	add_child(InventoryUI.instantiate())

	var bar := BossHPBar.new()
	add_child(bar)
	var robot := get_node_or_null("Robot")
	if robot:
		bar.setup(robot)
