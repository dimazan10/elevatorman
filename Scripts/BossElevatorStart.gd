extends Area2D

const FadeTransition := preload("res://Scripts/FadeTransition.gd")

@onready var anim := $"../AnimationPlayer"
@onready var player_node := get_tree().get_first_node_in_group("player") as Node2D
var transporting := false

func _ready() -> void:
	get_tree().create_timer(0.5).timeout.connect(_start_transport)

func _start_transport() -> void:
	if transporting:
		return
	transporting = true
	_hide_player()
	anim.stop()
	anim.play("Close")
	await get_tree().create_timer(1.0).timeout
	anim.play("Up")
	await get_tree().create_timer(2.0).timeout
	await FadeTransition.fade_out()
	var boss := get_tree().current_scene
	var pivot := boss.get_node("ArenaSwitch/Pivot") as Node2D
	player_node.global_position = pivot.global_position
	_show_player()
	_block_player()
	await get_tree().create_timer(5.0).timeout
	await FadeTransition.fade_in()
	_unblock_player()
	boss.activate_boss()

func _hide_player() -> void:
	for child in player_node.get_children():
		if child is Camera2D:
			continue
		if child is AnimatedSprite2D:
			child.hide()
		if child is Sprite2D:
			child.hide()
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
		if child is AudioStreamPlayer2D:
			child.stop()
	player_node.set_process(false)
	player_node.set_physics_process(false)

func _show_player() -> void:
	for child in player_node.get_children():
		if child is Camera2D:
			continue
		if child is AnimatedSprite2D:
			child.show()
		if child is Sprite2D:
			child.show()
		if child is CollisionShape2D:
			child.set_deferred("disabled", false)
	player_node.set_process(true)
	player_node.set_physics_process(true)

var _original_process_mode := Node.PROCESS_MODE_INHERIT

func _block_player() -> void:
	_original_process_mode = player_node.process_mode
	player_node.process_mode = Node.PROCESS_MODE_DISABLED

func _unblock_player() -> void:
	player_node.process_mode = _original_process_mode
