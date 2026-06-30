extends StaticBody2D

signal loaded_changed(loaded: bool)

var loaded := false

func _ready() -> void:
	$InteractZone.body_entered.connect(_on_zone_entered)
	_setup_loading_animation()

func _setup_loading_animation() -> void:
	var anim := Animation.new()
	anim.length = 1.5
	var track_idx := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "ShellPath/ShellFollow:progress")
	anim.track_insert_key(track_idx, 0.0, 0.0)
	anim.track_insert_key(track_idx, 1.5, 1.0)
	$AnimationPlayer.add_animation("load", anim)

func _on_zone_entered(body: Node2D) -> void:
	if loaded:
		return
	if not body.is_in_group("player"):
		return
	var patron = body.get_node_or_null("Patron")
	if not patron or not patron.has_method("is_attached") or not patron.is_attached():
		return
	_start_loading(body, patron)

func _start_loading(player: Node2D, patron: Node2D) -> void:
	player.can_move = false
	patron.queue_free()
	$ShellPath/ShellFollow/ShellVisual.visible = true
	$AnimationPlayer.play("load")
	await $AnimationPlayer.animation_finished
	$ShellPath/ShellFollow/ShellVisual.visible = false
	loaded = true
	loaded_changed.emit(true)
	player.can_move = true

func get_barrel_pivot() -> Node2D:
	return $BarrelPivot

func get_muzzle() -> Marker2D:
	return $BarrelPivot/Muzzle

func is_loaded() -> bool:
	return loaded

func reset() -> void:
	loaded = false
	loaded_changed.emit(false)

func get_max_angle() -> float:
	return deg_to_rad(60.0)
