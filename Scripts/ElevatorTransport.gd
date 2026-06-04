extends Area2D

@onready var anim := $"../AnimationPlayer"
var restarting := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or restarting:
		return
	var game = get_tree().current_scene
	if game and game.has_method("start_restart"):
		game.start_restart()
