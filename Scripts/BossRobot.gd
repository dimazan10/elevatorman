extends Node2D

const HealthUI := preload("res://Objects/UI_HP.tscn")
const DashUI := preload("res://Objects/DashUI.tscn")
const InventoryUI := preload("res://Objects/InventoryUI.tscn")

func _ready() -> void:
	add_to_group("pausable")
	add_child(HealthUI.instantiate())
	add_child(DashUI.instantiate())
	add_child(InventoryUI.instantiate())
