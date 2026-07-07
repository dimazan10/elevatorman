extends Node2D

@onready var _marker: Sprite2D = $Marker
@onready var _rocket_sprite: Sprite2D = $Rocket
@onready var _anim_player: AnimationPlayer = $Rocket/AnimationPlayer
@onready var _explosion: AnimatedSprite2D = $AnimatedSprite2D
@onready var _hitbox: Area2D = $Hitbox

func _ready() -> void:
	_explosion.visible = false
	_explosion.stop()
	_explosion.animation_finished.connect(_on_explosion_finished)
	_hitbox.monitoring = false

	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_callback(_start_fall)

func _process(delta: float) -> void:
	_marker.rotation += delta * 2.0

func _start_fall() -> void:
	_anim_player.animation_finished.connect(_on_land)
	_anim_player.play("BoomAnimation")

func _on_land(_anim_name: String) -> void:
	_rocket_sprite.visible = false
	_hitbox.monitoring = true
	_explosion.visible = true
	_explosion.play("Boom")

	for body in _hitbox.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.call("take_damage", 1)

func _on_explosion_finished() -> void:
	queue_free()
