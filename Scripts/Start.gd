extends Node2D

const FadeTransition := preload("res://Scripts/FadeTransition.gd")

func _ready() -> void:
	await FadeTransition.fade_in()
