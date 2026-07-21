extends Area2D

const FadeTransition := preload("res://Scripts/FadeTransition.gd")

var anim: AnimationPlayer
var transporting := false

func _ready() -> void:
	var boss := get_tree().current_scene
	if boss:
		anim = boss.get_node("HoleEnd/FloorElevator/AnimationPlayer") as AnimationPlayer
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or transporting:
		return
	var boss := get_tree().current_scene
	var robot := boss.get_node_or_null("Robot") if boss else null
	if robot and robot.current_hp > 0:
		return
	transporting = true
	_hide_player()
	anim.stop()
	anim.play("Close")
	await anim.animation_finished
	anim.play("Up")
	_darken_camera()
	await anim.animation_finished
	await FadeTransition.fade_out()
	get_tree().change_scene_to_file("res://Scenes/Game/credits.tscn")

func _darken_camera() -> void:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if not p:
		return
	var camera := p.get_node_or_null("PlayerCamera") as Camera2D
	if not camera:
		return
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camera.add_child(overlay)
	var tw := create_tween()
	tw.tween_property(overlay, "color:a", 1.0, 2.0)

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
