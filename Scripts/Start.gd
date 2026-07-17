extends Node2D

const FadeTransition := preload("res://Scripts/FadeTransition.gd")

func _ready() -> void:
	add_to_group("pausable")
	await FadeTransition.fade_in()
