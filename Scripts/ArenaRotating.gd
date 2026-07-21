extends AnimatableBody2D

const FadeTransition := preload("res://Scripts/FadeTransition.gd")

var rotation_speed: float = 0.5
var _cutscene_active := false

func start_boss_cutscene() -> void:
	if _cutscene_active:
		return
	_cutscene_active = true
	rotation_speed = 0.0

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		_lock_player(player)

	var boss_scene := get_tree().current_scene

	var hole_start := boss_scene.get_node_or_null("HoleStart/FloorElevator") as Node2D
	if hole_start:
		var anim := hole_start.get_node_or_null("AnimationPlayer") as AnimationPlayer
		if anim and anim.has_animation("DownClose"):
			anim.stop()
			anim.play("DownClose")

	await get_tree().create_timer(1.5).timeout
	await FadeTransition.fade_out()

	await get_tree().create_timer(5.0).timeout
	await FadeTransition.fade_in()

	var robot := boss_scene.get_node_or_null("Robot")
	if robot:
		if robot.has_method("set_can_attack"):
			robot.set_can_attack(true)
		if robot.has_signal("hp_changed"):
			robot.emit_signal("hp_changed", robot.current_hp if "current_hp" in robot else 0, robot.max_hp if "max_hp" in robot else 1)

	if player:
		_unlock_player(player)

func _lock_player(p: Node2D) -> void:
	p.set_meta("orig_process", p.process_mode)
	p.process_mode = Node.PROCESS_MODE_DISABLED

func _unlock_player(p: Node2D) -> void:
	if p.has_meta("orig_process"):
		p.process_mode = p.get_meta("orig_process")
		p.remove_meta("orig_process")

func _physics_process(delta: float) -> void:
	if _cutscene_active:
		_update_gate()
		return
	var pivot: Node2D = $Pivot
	if not pivot:
		return
	pivot.rotation = fmod(pivot.rotation + delta * rotation_speed, TAU)
	_update_gate()

func _update_gate() -> void:
	var gate: StaticBody2D = $Pivot/Walls/W4/Gate
	if not gate:
		return
	var gate_pos: Vector2 = gate.global_position
	var is_near: bool = false
	for t in get_tree().get_nodes_in_group("gate_trigger"):
		if gate_pos.distance_to(t.global_position) < 80.0:
			is_near = true
			break
	gate.collision_layer = 2 if is_near else 3
	var v: Node2D = gate.get_node("Visual")
	if v:
		v.modulate = Color(1, 1, 1, 0.3 if is_near else 1.0)
