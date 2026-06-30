extends Node2D

const AIM_OVERLAY := preload("res://Scripts/CannonAimOverlay.gd")
const CANNON_BULLET: PackedScene = preload("res://Objects/Boss/Robot/CannonBullet.tscn")

var _aiming := false
var _gun: Node2D = null
var _aim_overlay: CanvasLayer = null
var _player_camera: Camera2D = null
var _camera_zoom_orig: Vector2
var _crosshair_pos := Vector2.ZERO
var _player: Node2D = null

@export var camera_zoom_target: Vector2 = Vector2(0.25, 0.25)
@export var camera_zoom_duration: float = 1.0

func _ready() -> void:
	$InteractZone.body_entered.connect(_on_zone_entered)

func _find_gun() -> Node2D:
	for child in get_parent().get_children():
		if child is StaticBody2D and child.has_method("is_loaded"):
			return child
	return null

func _on_zone_entered(body: Node2D) -> void:
	if _aiming:
		return
	if not body.is_in_group("player"):
		return
	_gun = _find_gun()
	if not _gun or not _gun.is_loaded():
		return
	_player = body
	_start_aiming()

func _start_aiming() -> void:
	_aiming = true
	_player.can_move = false

	_player_camera = _player.get_node_or_null("PlayerCamera") as Camera2D
	if _player_camera:
		_camera_zoom_orig = _player_camera.zoom
		var tw := create_tween()
		tw.tween_property(_player_camera, "zoom", camera_zoom_target, camera_zoom_duration).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(_player_camera, "global_position", Vector2(640, 360), camera_zoom_duration)

	_aim_overlay = AIM_OVERLAY.new()
	_aim_overlay.fire_requested.connect(_on_fire)
	add_child(_aim_overlay)

func _process(_delta: float) -> void:
	if not _aiming:
		return
	_update_crosshair()

func _update_crosshair() -> void:
	if not _aim_overlay:
		return
	var input_dir := Vector2.ZERO
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		_crosshair_pos = get_global_mouse_position()
	else:
		input_dir = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
		if input_dir.length() > 0.2:
			_crosshair_pos += input_dir * 400.0 * get_process_delta_time()
	_crosshair_pos.x = clamp(_crosshair_pos.x, 0, 1280)
	_crosshair_pos.y = clamp(_crosshair_pos.y, 0, 720)
	_aim_overlay.set_crosshair_pos(_crosshair_pos)
	_rotate_barrel()

func _rotate_barrel() -> void:
	if not _gun:
		return
	var pivot := _gun.get_barrel_pivot()
	if not pivot:
		return
	var target_angle = (_crosshair_pos - pivot.global_position).angle()
	var max_angle = _gun.get_max_angle()
	var local_angle = target_angle - pivot.global_rotation
	local_angle = clamp(local_angle, -max_angle, max_angle)
	pivot.rotation = lerp_angle(pivot.rotation, local_angle, get_process_delta_time() * 2.0)

func _on_fire() -> void:
	if not _aiming or not _gun or not _gun.is_loaded():
		return
	_aiming = false
	if _aim_overlay:
		_aim_overlay.queue_free()
		_aim_overlay = null

	var muzzle := _gun.get_muzzle()
	if muzzle and CANNON_BULLET:
		var bullet := CANNON_BULLET.instantiate()
		bullet.global_position = muzzle.global_position
		bullet.target = _crosshair_pos
		get_tree().current_scene.add_child(bullet)

	_gun.reset()

	if _player_camera:
		var tw := create_tween()
		tw.tween_property(_player_camera, "zoom", _camera_zoom_orig, 0.8).set_ease(Tween.EASE_IN_OUT)
		tw.tween_callback(_end_aiming)

func _end_aiming() -> void:
	_player_camera = null
	_gun = null
	_player = null
	_aiming = false
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = true
