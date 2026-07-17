extends Node2D

const FadeTransition := preload("res://Scripts/FadeTransition.gd")

func _ready() -> void:
	add_to_group("pausable")
	if GameState.dark_mode:
		var cm := CanvasModulate.new()
		cm.name = "DarkOverlay"
		cm.color = Color(0.0, 0.0, 0.0)
		cm.z_index = -10
		add_child(cm)
	await FadeTransition.fade_in()
