extends Node2D

const PATRON_SCENE := preload("res://Objects/Boss/Robot/Patron.tscn")
const EARTHQUAKE_SOUND := preload("res://Assets/Enemies/Boss/Sprite_Robot/earthquake_sound.mp3")
@onready var _anim := $Sprite2D/AnimationPlayer

func _ready():
	var audio := AudioStreamPlayer2D.new()
	audio.name = "EarthquakeAudio"
	audio.stream = EARTHQUAKE_SOUND
	audio.bus = &"Effects"
	audio.global_position = global_position
	get_parent().add_child(audio)
	audio.play()
	audio.finished.connect(audio.queue_free)

	_anim.animation_finished.connect(_on_anim_finished)
	_anim.play("DownFallBox")

func _on_anim_finished(anim: String):
	if anim == "DownFallBox":
		var patron = PATRON_SCENE.instantiate()
		patron.global_position = global_position
		get_parent().add_child(patron)
		queue_free()
