extends Area2D

@export var slow_factor: float = 0.3
@export var slow_duration: float = 2.0
@export var fade_duration: float = 7.0

var _time: float = 0.0

func _ready() -> void:
	modulate = Color(0.6, 0.7, 0.6)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	$DestroyTimer.wait_time = fade_duration
	$DestroyTimer.start()

func _process(delta: float) -> void:
	_time += delta
	var t := _time / fade_duration
	if t > 0.8:
		modulate.a = maxf(1.0 - (t - 0.8) / 0.2, 0.0)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("apply_slow"):
		body.apply_slow(slow_factor, slow_duration)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("apply_slow"):
		body.apply_slow(1.0, 0.1)

func _on_destroy_timeout() -> void:
	queue_free()
