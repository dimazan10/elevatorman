extends Area2D

@onready var anim := $"../AnimationPlayer"

func _ready() -> void:
	anim.play("RESET")
	anim.advance(0)
	anim.stop()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		anim.play("Open")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		anim.play("Close")

func force_open() -> void:
	anim.stop()
	anim.play("Open")

func force_close() -> void:
	anim.stop()
	anim.play("Close")
