extends StaticBody2D

signal loaded_changed(loaded: bool)

var loaded := false
var _loading := false

func _ready() -> void:
	$InteractZone.body_entered.connect(_on_zone_entered)

func _on_zone_entered(body: Node2D) -> void:
	if loaded or _loading:
		return
	if not body.is_in_group("player"):
		return
	var patron = body.get_node_or_null("Patron")
	if not patron or not patron.has_method("is_attached") or not patron.is_attached():
		return
	_start_loading(body, patron)

func _start_loading(player: Node2D, patron: Node2D) -> void:
	_loading = true
	player.can_move = false
	patron.queue_free()
	$Sprite.visible = true
	$AnimationPlayer.play("Line")
	await $AnimationPlayer.animation_finished
	$Sprite.visible = false
	loaded = true
	_loading = false
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
