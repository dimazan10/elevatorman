extends CharacterBody2D

@export var speed: float = 200.0
@export var health: int = 60
@export var segment_count: int = 14
@export var segment_radius: float = 10.0
@export var segment_spacing: float = 13.0
@export var coil_radius: float = 70.0
@export var uncoil_speed: float = 2.5
@export var separation_force: float = 60.0
@export var aggro_range: float = 400.0
@export var bite_damage: int = 1
@export var bite_cooldown: float = 1.0

enum State { COILED, CHASING, STUNNED }
var current_state: State = State.COILED

var _player_ref: Node2D = null
var _segments: Array[Vector2] = []
var _segment_targets: Array[Vector2] = []
var _uncoil_progress: float = 0.0
var _bite_timer: float = 0.0
var _stun_timer: float = 0.0
var _spawn_pos: Vector2 = Vector2.ZERO
var _zone_name: String = ""
var _enraged: bool = false
var _time: float = 0.0

const BODY_INNER := Color(0.12, 0.48, 0.12)
const BODY_OUTER := Color(0.22, 0.62, 0.22)
const BODY_BRIGHT := Color(0.3, 0.7, 0.3)
const HEAD_COL := Color(0.18, 0.55, 0.15)
const HEAD_DARK := Color(0.1, 0.38, 0.1)
const TAIL_TIP := Color(0.3, 0.72, 0.28)
const EYE_WHITE := Color(1.0, 1.0, 0.85)
const EYE_PUPIL := Color(0.05, 0.05, 0.05)
const TONGUE_COL := Color(0.85, 0.12, 0.12)
const ENRAGE_TINT := Color(1.6, 0.5, 0.5)
const BELLY_COLOR := Color(0.35, 0.65, 0.2)

func _ready() -> void:
	add_to_group("enemy")
	_spawn_pos = global_position
	_zone_name = get_meta("zone_name", "")
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player_ref = players[0]
	_init_coil()
	queue_redraw()

func _init_coil() -> void:
	_segments.clear()
	_segment_targets.clear()
	for i in segment_count:
		var t := float(i) / segment_count
		var spiral_angle := t * TAU * 2.5
		var r := coil_radius * (1.0 - t * 0.7)
		var pos := Vector2(cos(spiral_angle), sin(spiral_angle)) * r
		_segments.append(pos)
		_segment_targets.append(pos)

func _physics_process(delta: float) -> void:
	_time += delta
	_bite_timer = maxf(_bite_timer - delta, 0.0)

	match current_state:
		State.COILED:
			_process_coiled(delta)
		State.CHASING:
			_process_chasing(delta)
		State.STUNNED:
			_stun_timer -= delta
			if _stun_timer <= 0:
				current_state = State.CHASING

	_handle_separation(delta)
	queue_redraw()

func _process_coiled(_delta: float) -> void:
	if not is_instance_valid(_player_ref):
		return
	var dist := global_position.distance_to(_player_ref.global_position)
	if dist < aggro_range:
		current_state = State.CHASING
		_uncoil_progress = 0.0

func _process_chasing(delta: float) -> void:
	if not is_instance_valid(_player_ref):
		return

	if _uncoil_progress < 1.0:
		_uncoil_progress = minf(_uncoil_progress + uncoil_speed * delta, 1.0)

	var dir := global_position.direction_to(_player_ref.global_position)
	var move_speed := speed * (_enraged ? 1.4 : 1.0)
	velocity = dir * move_speed
	move_and_slide()

	_update_chain(delta)
	_check_bite()

func _update_chain(delta: float) -> void:
	if _segments.is_empty():
		return

	if _uncoil_progress < 1.0:
		for i in _segments.size():
			var t := float(i) / segment_count
			var spiral_angle := t * TAU * 2.5 + _uncoil_progress * TAU * 3.0
			var r := coil_radius * (1.0 - t * 0.7) * (1.0 - _uncoil_progress)
			_segment_targets[i] = Vector2(cos(spiral_angle), sin(spiral_angle)) * r
			_segments[i] = _segments[i].lerp(_segment_targets[i], delta * 8.0)
	else:
		_segments[0] = Vector2.ZERO
		for i in range(1, _segments.size()):
			var prev := _segments[i - 1]
			var cur := _segments[i]
			var diff := cur - prev
			var dist := diff.length()
			if dist > segment_spacing:
				cur = prev + diff.normalized() * segment_spacing
			elif dist < segment_spacing * 0.5 and dist > 0.01:
				cur = prev + diff.normalized() * segment_spacing * 0.5
			_segments[i] = cur

func _check_bite() -> void:
	if not is_instance_valid(_player_ref) or _bite_timer > 0:
		return
	if _segments.is_empty():
		return
	var head_global := global_position + _segments[0]
	if head_global.distance_to(_player_ref.global_position) < segment_radius * 2.0 + 18.0:
		if _player_ref.has_method("take_damage"):
			_player_ref.take_damage(bite_damage)
		_bite_timer = bite_cooldown

func _handle_separation(delta: float) -> void:
	var sep := Vector2.ZERO
	for body in get_tree().get_nodes_in_group("enemy"):
		if body == self or not body is Node2D:
			continue
		var diff := global_position - body.global_position
		if diff.length() > 0.001 and diff.is_finite():
			sep += diff.normalized() / diff.length()
	if sep.length() > 0:
		global_position += sep.normalized() * separation_force * delta

func _draw() -> void:
	for i in range(_segments.size() - 1, -1, -1):
		var pos := _segments[i]
		var t := float(i) / maxf(_segments.size() - 1, 1)
		var size_scale := 1.0 - t * 0.5
		var r := segment_radius * size_scale
		var wobble := sin(_time * 4.0 + i * 0.8) * 1.5

		var col := BODY_OUTER.lerp(TAIL_TIP, t * t)
		if _enraged:
			col = col.blend(ENRAGE_TINT)

		draw_circle(pos, r + 1.5, col.darkened(0.2))
		draw_circle(pos, r, col)
		draw_circle(pos + Vector2(wobble, -wobble * 0.5), r * 0.55, BELLY_COLOR.lerp(col, t))

		if i % 3 == 0 and t < 0.8:
			var band_pos := pos + Vector2(cos(_segment_angle(i)), sin(_segment_angle(i))) * r * 0.3
			draw_circle(band_pos, r * 0.35, col.darkened(0.25))

	if not _segments.is_empty():
		_draw_head(_segments[0])

func _segment_angle(i: int) -> float:
	if i == 0:
		return velocity.angle()
	if i < _segments.size():
		var diff := _segments[i] - _segments[i - 1]
		if diff.length() > 0.01:
			return diff.angle()
	return 0.0

func _draw_head(pos: Vector2) -> void:
	var head_angle := velocity.angle() if velocity.length() > 10 else _segment_angle(0)
	var head_r := segment_radius * 2.0
	var col := HEAD_COL
	if _enraged:
		col = col.blend(ENRAGE_TINT)

	var forward := Vector2(cos(head_angle), sin(head_angle))
	var right := Vector2(-sin(head_angle), cos(head_angle))

	var p1 := pos + forward * head_r * 0.9
	var p2 := pos - forward * head_r * 0.4 + right * head_r * 0.7
	var p3 := pos - forward * head_r * 0.4 - right * head_r * 0.7
	var p4 := pos - forward * head_r * 0.2

	draw_colored_polygon([p1, p2, p4, p3], col)
	draw_circle(pos, head_r * 0.7, col.darkened(0.15))

	var eye_dist := head_r * 0.45
	var eye_size := head_r * 0.28
	var eye1 := pos + forward * head_r * 0.3 + right * eye_dist
	var eye2 := pos + forward * head_r * 0.3 - right * eye_dist
	draw_circle(eye1, eye_size, EYE_WHITE)
	draw_circle(eye2, eye_size, EYE_WHITE)

	var pupil_size := eye_size * 0.55
	var look_dir := forward * eye_size * 0.25
	draw_circle(eye1 + look_dir, pupil_size, EYE_PUPIL)
	draw_circle(eye2 + look_dir, pupil_size, EYE_PUPIL)

	var tongue_start := pos + forward * head_r * 0.85
	var tongue_len := head_r * 1.8
	var flicker := sin(_time * 12.0) * 0.3 + 0.7
	var tongue_main := tongue_start + forward * tongue_len * flicker
	var fork_len := tongue_len * 0.35
	var fork1 := tongue_main + forward * fork_len + right * fork_len * 0.6
	var fork2 := tongue_main + forward * fork_len - right * fork_len * 0.6
	draw_line(tongue_start, tongue_main, TONGUE_COL, 2.0)
	draw_line(tongue_main, fork1, TONGUE_COL, 1.5)
	draw_line(tongue_main, fork2, TONGUE_COL, 1.5)

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()

func apply_knockback(impulse: Vector2) -> void:
	velocity = impulse * 0.5
	current_state = State.STUNNED
	_stun_timer = 0.3

func set_target(new_target: Node2D) -> void:
	pass

func set_enraged(enraged: bool) -> void:
	_enraged = enraged
	queue_redraw()
