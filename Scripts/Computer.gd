extends Node2D

signal aiming_changed(is_aiming: bool)

const AIM_OVERLAY := preload("res://Scripts/CannonAimOverlay.gd")
var CANNON_BULLET: PackedScene
const PATRON_OUT := preload("res://Assets/Enemies/Boss/Sprite_Gun/PatronOut.png")

var _aiming := false
var _gun = null
var _aim_overlay: CanvasLayer = null
var _player_camera: Camera2D = null
var _camera_zoom_orig: Vector2
var _camera_pos_orig: Vector2
var _crosshair_pos := Vector2.ZERO
var _player: Node2D = null
var _shoot_audio: AudioStreamPlayer2D = null

@export var camera_zoom_target: Vector2 = Vector2(0.55, 0.55)
@export var camera_zoom_duration: float = 1.0

func _ready() -> void:
	CANNON_BULLET = load("res://Objects/Boss/Robot/CannonBullet.tscn")
	_shoot_audio = AudioStreamPlayer2D.new()
	_shoot_audio.stream = load("res://Assets/Enemies/Boss/Sprite_Gun/Shoot.mp3")
	add_child(_shoot_audio)
	_prebuffer_audio.call_deferred()
	$InteractZone.body_entered.connect(_on_zone_entered)
	$InteractZone.body_exited.connect(_on_zone_exited)

func _prebuffer_audio() -> void:
	_shoot_audio.play()
	await get_tree().process_frame
	_shoot_audio.stop()
	_shoot_audio.stop()

func _find_gun() -> Node2D:
	var gun = get_node_or_null("../Gun")
	if gun and gun.has_method("is_loaded"):
		return gun
	if get_parent():
		for child in get_parent().get_children():
			if child.has_method("is_loaded"):
				return child
	return null

func _on_zone_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player = body
	_gun = _find_gun()
	if _gun and _gun.is_loaded() and not _aiming:
		_start_aiming()

func _on_zone_exited(body: Node2D) -> void:
	if body == _player:
		_player = null

func _start_aiming() -> void:
	if _aiming:
		return
	_aiming = true
	aiming_changed.emit(true)
	
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		
	if is_instance_valid(_player):
		_player.can_move = false
		_player_camera = _player.get_node_or_null("PlayerCamera") as Camera2D

	if _player_camera:
		_camera_zoom_orig = _player_camera.zoom
		_camera_pos_orig = _player_camera.global_position
		_crosshair_pos = get_global_mouse_position()
		var tw := create_tween()
		tw.tween_property(_player_camera, "zoom", camera_zoom_target, camera_zoom_duration).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(_player_camera, "global_position", Vector2(640, 838), camera_zoom_duration)

	_aim_overlay = AIM_OVERLAY.new()
	_aim_overlay.fire_requested.connect(_on_fire)
	add_child(_aim_overlay)

func _process(_delta: float) -> void:
	if _aiming:
		_update_crosshair()
		return

	if not is_instance_valid(_player):
		var p = get_tree().get_first_node_in_group("player") as Node2D
		if p and global_position.distance_to(p.global_position) < 180.0:
			_player = p

	if is_instance_valid(_player) and global_position.distance_to(_player.global_position) < 180.0:
		_gun = _find_gun()
		if _gun and _gun.is_loaded():
			_start_aiming()

func _update_crosshair() -> void:
	if not _aim_overlay:
		return
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		var mouse_pos = get_global_mouse_position()
		_crosshair_pos = _crosshair_pos.lerp(mouse_pos, get_process_delta_time() * 16.0)
	else:
		var input_dir := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
		if input_dir.length() > 0.2:
			_crosshair_pos += input_dir * 500.0 * get_process_delta_time()

	var camera := get_viewport().get_camera_2d()
	if camera:
		var viewport := get_viewport()
		var vp_size := Vector2(viewport.get_visible_rect().size)
		var top_left: Vector2 = camera.global_position - vp_size / (2.0 * camera.zoom)
		var bottom_right: Vector2 = camera.global_position + vp_size / (2.0 * camera.zoom)
		_crosshair_pos.x = clamp(_crosshair_pos.x, top_left.x, bottom_right.x)
		_crosshair_pos.y = clamp(_crosshair_pos.y, top_left.y, bottom_right.y)
		var screen_pos: Vector2 = (_crosshair_pos - camera.global_position) * camera.zoom + vp_size / 2.0
		_aim_overlay.set_crosshair_pos(screen_pos)
	else:
		_aim_overlay.set_crosshair_pos(_crosshair_pos)
	_rotate_barrel()
	if _aim_overlay and _gun:
		var pivot := _gun.get_barrel_pivot() as Node2D
		if pivot:
			_aim_overlay.set_crosshair_angle(pivot.rotation)

func _rotate_barrel() -> void:
	if not _gun:
		return
	var pivot := _gun.get_barrel_pivot() as Node2D
	if not pivot:
		return
	var target_angle: float = (_crosshair_pos - pivot.global_position).angle() + PI / 2
	var max_angle: float = _gun.get_max_angle()
	var parent_node: Node = pivot.get_parent()
	var parent_rot: float = (parent_node as Node2D).global_rotation if parent_node is Node2D else 0.0
	var desired_local: float = target_angle - parent_rot
	desired_local = clamp(desired_local, -max_angle, max_angle)
	pivot.rotation = lerp_angle(pivot.rotation, desired_local, get_process_delta_time() * 10.0)

func _spawn_patron_out(pos: Vector2) -> void:
	var pivot := _gun.get_barrel_pivot() as Node2D
	if not pivot:
		return
	var dir := Vector2.RIGHT.rotated(pivot.global_rotation)
	if randf() > 0.5:
		dir = -dir
	var spr := Sprite2D.new()
	spr.texture = PATRON_OUT
	spr.global_position = pos
	spr.scale = Vector2(0.05, 0.05)
	spr.rotation = dir.angle()
	get_tree().current_scene.add_child(spr)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(spr, "global_position", pos + dir * randf_range(30, 60) + Vector2(0, 40), 0.4)
	tw.tween_property(spr, "modulate", Color.TRANSPARENT, 0.3).set_delay(0.2)
	tw.tween_property(spr, "rotation", spr.rotation + randf_range(-4, 4), 0.4)
	tw.finished.connect(spr.queue_free)

func _on_fire() -> void:
	if not _aiming or not _gun or not _gun.is_loaded():
		return
	_aiming = false
	if _aim_overlay:
		_aim_overlay.queue_free()
		_aim_overlay = null

	var muzzle := _gun.get_muzzle() as Marker2D
	if muzzle and CANNON_BULLET:
		var bullet := CANNON_BULLET.instantiate()
		bullet.global_position = muzzle.global_position
		bullet.target = _crosshair_pos
		get_tree().current_scene.add_child(bullet)

	_shoot_audio.play()
	var eject := _gun.get_eject_point() as Marker2D
	if eject:
		_spawn_patron_out(eject.global_position)
	_gun.reset()

	if _player_camera:
		var tw := create_tween()
		tw.tween_property(_player_camera, "zoom", _camera_zoom_orig, 0.8).set_ease(Tween.EASE_IN_OUT)
		tw.parallel().tween_property(_player_camera, "global_position", _camera_pos_orig, 0.8).set_ease(Tween.EASE_IN_OUT)
		tw.tween_callback(_end_aiming)

func _end_aiming() -> void:
	_player_camera = null
	_gun = null
	_aiming = false
	aiming_changed.emit(false)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.can_move = true