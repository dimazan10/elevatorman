extends Node2D

const PATRON_SCENE := preload("res://Objects/Boss/Robot/Patron.tscn")
@onready var _anim := $Sprite2D/AnimationPlayer

func _ready():
	_anim.animation_finished.connect(_on_anim_finished)
	_anim.play("DownFallBox")

func _on_anim_finished(anim: String):
	if anim == "DownFallBox":
		var patron = PATRON_SCENE.instantiate()
		patron.global_position = global_position
		get_parent().add_child(patron)
		queue_free()
