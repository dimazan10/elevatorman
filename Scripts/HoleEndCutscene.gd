extends Area2D

const FadeTransition := preload("res://Scripts/FadeTransition.gd")

var _triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	monitoring = false

	var boss := get_tree().current_scene
	var robot := boss.get_node_or_null("Robot") as Node2D
	var player := body as Node2D

	player.process_mode = Node.PROCESS_MODE_DISABLED

	var hole_end := boss.get_node_or_null("HoleEnd/FloorElevator") as Sprite2D
	if hole_end:
		hole_end.get_node("RoofElevator2").z_index = 3
		hole_end.get_node("Door1").visible = true
		hole_end.get_node("Door2").visible = true
		hole_end.self_modulate = Color(1, 1, 1, 1)

		var anim := hole_end.get_node_or_null("AnimationPlayer") as AnimationPlayer
		if anim:
			if anim.has_animation("Close"):
				anim.play("Close")
				await anim.animation_finished
			if anim.has_animation("DownClose"):
				anim.play("DownClose")
				await anim.animation_finished

		hole_end.get_node("RoofElevator2").z_index = 0
		hole_end.get_node("Door1").visible = false
		hole_end.get_node("Door2").visible = false
		hole_end.self_modulate = Color(1, 1, 1, 0)

		var hole_end_parent := hole_end.get_parent()
		if hole_end_parent:
			for child in hole_end_parent.get_children():
				if child is StaticBody2D or child is Area2D:
					child.set_process(false)
					child.set_physics_process(false)
					for shape in child.get_children():
						if shape is CollisionShape2D:
							shape.set_deferred("disabled", true)

	await FadeTransition.fade_out()

	if robot:
		robot.visible = true

	await FadeTransition.fade_in()

	_show_boss_hp_bar(boss, 3.0)

	player.process_mode = Node.PROCESS_MODE_INHERIT
	player.can_move = true

	if boss and boss.has_method("activate_boss"):
		boss.activate_boss()

func _show_boss_hp_bar(boss: Node, duration: float) -> void:
	for child in boss.get_children():
		if child is CanvasLayer and child.has_method("_modulate_a"):
			child._modulate_a(1.0)
			await get_tree().create_timer(duration).timeout
			child._modulate_a(0.0)
			return
