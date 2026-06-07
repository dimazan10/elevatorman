extends Node2D

const FadeTransition := preload("res://Scripts/FadeTransition.gd")

@onready var anim := $Hole/FloorElevator/AnimationPlayer
@onready var player_node := get_tree().get_first_node_in_group("player") as Node2D

var transport_enabled := false

func _ready() -> void:
	_hide_player()
	FadeTransition.fade_in()
	$Hole/FloorElevator/TransportArea.body_entered.connect(_on_transport_entered)
	$Hole/FloorElevator/TransportArea/CollisionShape.set_deferred("disabled", true)
	anim.play("RESET")
	anim.seek(0, true)
	anim.stop()
	anim.play("DownUp")
	await anim.animation_finished
	anim.play("Open")
	await anim.animation_finished
	$Hole/FloorElevator/TransportArea/CollisionShape.set_deferred("disabled", false)
	_show_player()
	player_node.can_move = true
	await get_tree().create_timer(1.5).timeout
	transport_enabled = true

func _on_transport_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or not transport_enabled:
		return
	transport_enabled = false
	player_node.can_move = false
	_hide_player()
	anim.stop()
	anim.play("Close")
	await anim.animation_finished
	anim.play("Up")
	await anim.animation_finished
	await FadeTransition.fade_out()
	get_tree().change_scene_to_file("res://Scenes/Game/game.tscn")

func _hide_player() -> void:
	player_node.process_mode = Node.PROCESS_MODE_DISABLED
	for child in player_node.get_children():
		if child is Camera2D:
			continue
		if child is AnimatedSprite2D:
			child.hide()
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
		if child is AudioStreamPlayer2D:
			child.stop()

func _show_player() -> void:
	player_node.process_mode = Node.PROCESS_MODE_INHERIT
	for child in player_node.get_children():
		if child is Camera2D:
			continue
		if child is AnimatedSprite2D:
			child.show()
		if child is CollisionShape2D:
			child.set_deferred("disabled", false)
