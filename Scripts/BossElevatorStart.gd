extends Area2D

const FadeTransition := preload("res://Scripts/FadeTransition.gd")

@onready var anim := $"../AnimationPlayer"
var transporting := false

func _ready() -> void:
	anim.play("RESET")
	anim.advance(0)
	anim.stop()
	anim.play("Open")
	await get_tree().create_timer(1.3).timeout
	_start_transport()

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
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		player.global_position = pivot.global_position
		_show_player(player)
		_block_player(player)
	await get_tree().create_timer(5.0).timeout
	await FadeTransition.fade_in()
	if player:
		_unblock_player(player)
	boss.activate_boss()

func _hide_player() -> void:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if not p:
		return
	for child in p.get_children():
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
	p.set_process(false)
	p.set_physics_process(false)

func _show_player(p: Node2D) -> void:
	for child in p.get_children():
		if child is Camera2D:
			continue
		if child is AnimatedSprite2D:
			child.show()
		if child is Sprite2D:
			child.show()
		if child is CollisionShape2D:
			child.set_deferred("disabled", false)
	p.set_process(true)
	p.set_physics_process(true)

func _block_player(p: Node2D) -> void:
	p.set_meta("orig_process", p.process_mode)
	p.process_mode = Node.PROCESS_MODE_DISABLED

func _unblock_player(p: Node2D) -> void:
	if p.has_meta("orig_process"):
		p.process_mode = p.get_meta("orig_process")
		p.remove_meta("orig_process")
