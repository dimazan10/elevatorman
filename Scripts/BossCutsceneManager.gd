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

	if boss and boss.has_method("is_boss_active") and boss.is_boss_active():
		return

	body.process_mode = Node.PROCESS_MODE_DISABLED

	await FadeTransition.fade_out()

	await get_tree().create_timer(5.0).timeout

	await FadeTransition.fade_in()

	if boss and boss.has_method("activate_boss"):
		boss.activate_boss()

	body.process_mode = Node.PROCESS_MODE_INHERIT
