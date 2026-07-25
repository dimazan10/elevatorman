extends AnimatableBody2D

const FadeTransition := preload("res://Scripts/FadeTransition.gd")

var rotation_speed: float = 0.5
var _cutscene_active := false
var _combat_locked := false
@onready var _pivot := $Pivot as Node2D
@onready var _gate := $Pivot/Walls/W4/Gate as StaticBody2D
var _gate_triggers: Array[Node2D] = []

func _ready() -> void:
	refresh_gate_triggers()

func refresh_gate_triggers() -> void:
	_gate_triggers.clear()
	for trigger in get_tree().get_nodes_in_group("gate_trigger"):
		if trigger is Node2D:
			_gate_triggers.append(trigger)

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

func set_combat_locked(locked: bool) -> void:
	_combat_locked = locked
	if _combat_locked:
		rotation_speed = 0.0
	_update_gate()

func _lock_player(p: Node2D) -> void:
	p.set_meta("orig_process", p.process_mode)
	p.process_mode = Node.PROCESS_MODE_DISABLED

func _unlock_player(p: Node2D) -> void:
	if p.has_meta("orig_process"):
		p.process_mode = p.get_meta("orig_process")
		p.remove_meta("orig_process")

func _physics_process(delta: float) -> void:
	if _cutscene_active or _combat_locked:
		_update_gate()
		return
	if not _pivot:
		return
	_pivot.rotation = fmod(_pivot.rotation + delta * rotation_speed, TAU)
	_update_gate()

func _update_gate() -> void:
	if not _gate:
		return
	if _combat_locked:
		_gate.collision_layer = 3
		var combat_visual := _gate.get_node_or_null("Visual") as Node2D
		if combat_visual:
			combat_visual.modulate = Color(1, 0.15, 0.15)
		return
	var gate_pos: Vector2 = _gate.global_position
	var is_near: bool = false
	for t in _gate_triggers:
		if gate_pos.distance_to(t.global_position) < 80.0:
			is_near = true
			break
	_gate.collision_layer = 2 if is_near else 3
	var v: Node2D = _gate.get_node("Visual")
	if v:
		v.modulate = Color(0.15, 1, 0.15, 0.3) if is_near else Color(1, 0.15, 0.15)
	if is_near and not _cutscene_active:
		rotation_speed = min(rotation_speed, 0.05)
	elif not _cutscene_active:
		rotation_speed = 0.5
