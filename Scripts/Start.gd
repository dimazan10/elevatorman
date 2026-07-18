extends Node2D

const FadeTransition := preload("res://Scripts/FadeTransition.gd")

func _ready() -> void:
	if GameState.dark_mode:
		_setup_dark_mode()
	add_to_group("pausable")
	await FadeTransition.fade_in()

func _setup_dark_mode() -> void:
	var cm := CanvasModulate.new()
	cm.color = Color(0, 0, 0, 1)
	add_child(cm)
	move_child(cm, 0)
	var player = get_node_or_null("Player")
	if not player:
		return
	var light := player.get_node_or_null("PlayerLight") as PointLight2D
	if light:
		light.light_mask = 7
		light.texture_scale = 8.0
		light.energy = 1.5
		light.range_z_min = -100
		light.range_z_max = 100
		light.shadow_enabled = true
	player.light_mask = 7
	player.visibility_layer = 7
	_set_all_layers(self)

func _set_all_layers(node: Node) -> void:
	for child in node.get_children():
		if child is CanvasItem:
			child.light_mask = 7
			child.visibility_layer = 7
		_set_all_layers(child)
