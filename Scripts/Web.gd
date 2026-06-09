extends Area2D

@export var slow_factor: float = 0.3
@export var fade_duration: float = 0.5

var _player_ref: Node2D = null
var _fading := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	$DestroyTimer.timeout.connect(_on_destroy_timeout)

func _fade_and_free() -> void:
	if _fading:
		return
	_fading = true
	$DestroyTimer.stop()
	_remove_boosts()
	body_entered.disconnect(_on_body_entered)
	body_exited.disconnect(_on_body_exited)
	var tween := create_tween()
	tween.tween_property($Sprite2D, "modulate:a", 0.0, fade_duration)
	await tween.finished
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if _fading:
		return
	if body.is_in_group("player"):
		_player_ref = body
		body.slow_factor = slow_factor
		body.slow_timer = 99999.0
	elif body.is_in_group("enemy") and body.has_method("set_web_boost"):
		body.set_web_boost(true)

func _on_body_exited(body: Node2D) -> void:
	if _fading:
		return
	if body.is_in_group("player"):
		_player_ref = null
		body.slow_factor = 1.0
		body.slow_timer = 0.0
		_fade_and_free()
	elif body.is_in_group("enemy") and body.has_method("set_web_boost"):
		body.set_web_boost(false)

func _remove_boosts() -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("enemy") and body.has_method("set_web_boost"):
			body.set_web_boost(false)

func _on_destroy_timeout() -> void:
	if _player_ref:
		_player_ref.slow_factor = 1.0
		_player_ref.slow_timer = 0.0
		_player_ref = null
	_remove_boosts()
	_fade_and_free()
