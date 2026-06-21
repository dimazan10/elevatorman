extends Area2D

const FadeTransition := preload("res://Scripts/FadeTransition.gd")

@onready var anim := $"../AnimationPlayer"
@onready var player_node := get_tree().get_first_node_in_group("player") as Node2D
var transporting := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not transporting:
		transporting = true
		_hide_player_visual()
		anim.stop()
		anim.play("Close")
		await get_tree().create_timer(1.0).timeout
		anim.play("Up")
		await get_tree().create_timer(2.5).timeout
		await FadeTransition.fade_out()
		get_tree().change_scene_to_file("res://Scenes/Game/game.tscn")

func _hide_player_visual() -> void:
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
