extends Node2D

@onready var _marker: Sprite2D = $Marker
@onready var _rocket_sprite: Sprite2D = $Rocket
@onready var _anim_player: AnimationPlayer = $Rocket/AnimationPlayer
@onready var _explosion: AnimatedSprite2D = $AnimatedSprite2D
var _audio: AudioStreamPlayer2D

func _ready() -> void:
	_explosion.visible = false
	_explosion.stop()
	_explosion.animation_finished.connect(_on_explosion_finished)

	_audio = AudioStreamPlayer2D.new()
	_audio.stream = load("res://Assets/Enemies/Boss/Boom/BoomSound.mp3")
	_audio.bus = &"Effects"
	_audio.finished.connect(_audio.queue_free)
	get_tree().root.add_child(_audio)

	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_callback(_start_fall)

	var fade_tw := create_tween()
	fade_tw.tween_interval(3.0)
	fade_tw.tween_property(_marker, "modulate:a", 0.0, 0.8)

func _process(delta: float) -> void:
	_marker.rotation += delta * 2.0

func _start_fall() -> void:
	_anim_player.animation_finished.connect(_on_land)
	_anim_player.play("BoomAnimation")
	if _audio:
		_audio.play()

func _on_land(_anim_name: String) -> void:
	_rocket_sprite.visible = false
	_explosion.visible = true
	_explosion.play("Boom")

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and player.has_method("take_damage"):
		var dist := global_position.distance_to(player.global_position)
		if dist < 100.0:
			player.call("take_damage", 1)

func _on_explosion_finished() -> void:
	queue_free()
