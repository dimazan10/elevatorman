extends CharacterBody2D

signal activated

var _activated := false

func _ready() -> void:
	add_to_group("switch")
	var area := Area2D.new()
	area.name = "PlayerDetector"
	var shape := CollisionShape2D.new()
	shape.shape = $CollisionShape2D.shape.duplicate()
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _activated:
		return
	if not body.is_in_group("player"):
		return
	_activated = true
	$AnimatedSprite2D.play("default")
	activated.emit()
