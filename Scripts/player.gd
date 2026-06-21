extends CharacterBody2D

signal health_changed(new_health)
signal dash_used(index: int)
signal dash_recharged(index: int)

@export var max_lives: int = 5
var current_lives: int = max_lives

const SPEED = 550.0
const MAX_DASH_CHARGES = 3
const DASH_COOLDOWN = 4.0
const DASH_SPEED = 1200.0
const DASH_DURATION = 0.15

var dash_cooldowns: Array[float] = [0.0, 0.0, 0.0]
var is_dashing := false
var dash_timer := 0.0
var last_move_dir := Vector2.DOWN

var animated_sprite: AnimatedSprite2D
var audio_player: AudioStreamPlayer2D
var dash_audio: AudioStreamPlayer2D
var hit_blow_audio: AudioStreamPlayer2D
var hit_fierce_audio: AudioStreamPlayer2D
var footstep_sounds: Array[AudioStream] = []
var footstep_timer: float = 0.0

var is_stunned: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var can_move: bool = true

var slow_factor: float = 1.0
var slow_timer: float = 0.0

var pull_target: Node2D = null
var pull_offset: Vector2 = Vector2.ZERO
var _is_dying := false
var _invulnerable := false

func _ready() -> void:
	current_lives = max_lives
	
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	for child in get_children():
		if child.name == "Visual":
			remove_child(child)
			child.queue_free()

	animated_sprite = AnimatedSprite2D.new()
	animated_sprite.name = "AnimatedSprite"
	add_child(animated_sprite)

	var frames = SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 5)
	for i in range(1, 5):
		var tex = load("res://Assets/Sprites_Player/gg" + (str(i) if i > 0 else "") + ".png")
		frames.add_frame("idle", tex)
	frames.set_animation_loop("idle", true)

	animated_sprite.sprite_frames = frames
	animated_sprite.play("idle")
	animated_sprite.scale = Vector2(0.15, 0.15)

	audio_player = AudioStreamPlayer2D.new()
	audio_player.name = "FootstepAudio"
	audio_player.bus = &"Effects"
	add_child(audio_player)

	dash_audio = AudioStreamPlayer2D.new()
	dash_audio.name = "DashAudio"
	dash_audio.stream = load("res://Assets/Sounds/Effects/dash.mp3")
	dash_audio.bus = &"Effects"
	add_child(dash_audio)

	hit_blow_audio = AudioStreamPlayer2D.new()
	hit_blow_audio.name = "HitBlowAudio"
	hit_blow_audio.stream = load("res://Assets/Sounds/Effects/the-blow-is-muffled-decisive.mp3")
	hit_blow_audio.bus = &"Effects"
	add_child(hit_blow_audio)

	hit_fierce_audio = AudioStreamPlayer2D.new()
	hit_fierce_audio.name = "HitFierceAudio"
	hit_fierce_audio.stream = load("res://Assets/Sounds/Effects/Звук лютого удару в тіло.mp3")
	hit_fierce_audio.bus = &"Effects"
	add_child(hit_fierce_audio)

	for i in range(1, 5):
		var stream = load("res://Assets/Sounds/FootStepsSound/FootStep_" + str(i) + ".wav")
		if stream:
			footstep_sounds.append(stream)
	
var _shift_held := false
var _ghost_timer := 0.0
var _noclip := false
var _f1_held := false

func _process(delta: float) -> void:
	for i in range(MAX_DASH_CHARGES):
		if dash_cooldowns[i] > 0:
			dash_cooldowns[i] -= delta
			if dash_cooldowns[i] <= 0:
				dash_cooldowns[i] = 0.0
				dash_recharged.emit(i)

	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
		_ghost_timer += delta
		if _ghost_timer >= 0.05:
			_ghost_timer = 0.0
			_spawn_ghost()

	var shift_down := Input.is_key_pressed(KEY_SHIFT)
	if shift_down and not _shift_held:
		perform_dash()
	_shift_held = shift_down

	if slow_timer > 0:
		slow_timer -= delta
		if slow_timer <= 0:
			slow_timer = 0.0
			slow_factor = 1.0

func _toggle_noclip() -> void:
	_noclip = not _noclip
	$CollisionShape.disabled = _noclip
	if _noclip:
		modulate = Color(1, 1, 1, 0.5)
	else:
		modulate = Color(1, 1, 1, 1)

func _physics_process(delta: float) -> void:
	var f1_down := Input.is_key_pressed(KEY_F1)
	if f1_down and not _f1_held:
		_toggle_noclip()
	_f1_held = f1_down

	if not can_move:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if is_stunned:
		if pull_target:
			var target_pos = pull_target.global_position + pull_offset
			var pull_vec = target_pos - global_position
			var dir = pull_vec.normalized() if pull_vec.length_squared() > 0.001 else Vector2.ZERO
			velocity = dir * 300.0
			if not velocity.is_finite():
				velocity = Vector2.ZERO
		else:
			knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 1000 * delta)
			velocity = knockback_velocity
			if not velocity.is_finite():
				velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if is_dashing:
		if not velocity.is_finite():
			velocity = Vector2.ZERO
		move_and_slide()
		return

	if _noclip:
		var dir := Vector2.ZERO
		if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
			dir.x += 1
		if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
			dir.x -= 1
		if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
			dir.y += 1
		if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
			dir.y -= 1
		if dir.length() > 0:
			dir = dir.normalized()
			global_position += dir * SPEED * delta
		return

	var direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		direction.x += 1
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		direction.y += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		direction.y -= 1

	var moving = direction.length() > 0

	if moving:
		direction = direction.normalized()
		last_move_dir = direction

		velocity = direction * SPEED * slow_factor
		if not velocity.is_finite():
			velocity = Vector2.ZERO
		move_and_slide()

		# ЗАМЕНИЛИ _delta НА ОБЫЧНУЮ delta, чтобы время шагов считалось правильно
		footstep_timer -= delta
		if footstep_timer <= 0 and footstep_sounds.size() > 0:
			footstep_timer = 0.3
			var idx = randi() % footstep_sounds.size()
			audio_player.stream = footstep_sounds[idx]
			audio_player.play()

		animated_sprite.speed_scale = 1.0
		if direction.x > 0:
			animated_sprite.flip_h = false
		elif direction.x < 0:
			animated_sprite.flip_h = true
	else:
		velocity = Vector2.ZERO
		animated_sprite.speed_scale = 0.0
		footstep_timer = 0.0

func _spawn_ghost() -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	var ghost := AnimatedSprite2D.new()
	ghost.sprite_frames = animated_sprite.sprite_frames
	ghost.animation = animated_sprite.animation
	ghost.frame = animated_sprite.frame
	ghost.global_position = global_position
	ghost.scale = animated_sprite.scale
	ghost.modulate = Color(1, 1, 1, 0.4)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ghost.material = mat
	ghost.stop()
	get_parent().add_child(ghost)
	var tw := create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tw.tween_callback(ghost.queue_free)

func perform_dash() -> void:
	if is_dashing:
		return

	var charge_idx := -1
	for i in range(MAX_DASH_CHARGES):
		if dash_cooldowns[i] <= 0:
			charge_idx = i
			break

	if charge_idx == -1:
		return

	dash_cooldowns[charge_idx] = DASH_COOLDOWN
	is_dashing = true
	dash_timer = DASH_DURATION
	dash_used.emit(charge_idx)
	if dash_audio:
		dash_audio.play()

	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir.x += 1
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		dir.x -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		dir.y += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		dir.y -= 1

	if dir == Vector2.ZERO:
		dir = last_move_dir
	else:
		dir = dir.normalized()
		last_move_dir = dir

	velocity = dir * DASH_SPEED

func take_damage(amount: int):
	if _noclip or _is_dying or _invulnerable:
		return
	
	if _try_bucket_hit():
		return
	
	_invulnerable = true
	current_lives -= amount
	health_changed.emit(current_lives)
	if current_lives <= 0:
		_is_dying = true
	
	var my_camera = %PlayerCamera
		
	if my_camera and my_camera.has_method("apply_shake"):
		my_camera.apply_shake(20.0)
		
	can_move = false
	velocity = Vector2.ZERO
	hit_blow_audio.play()
	hit_fierce_audio.play()
	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.15).timeout
	modulate = Color.WHITE
	can_move = true
	_invulnerable = false
	
	if current_lives <= 0:
		die()

func die() -> void:
	print("Игрок погиб!")
	var tree := get_tree()
	if tree:
		tree.reload_current_scene()

func apply_stun_and_knockback(knockback_impulse: Vector2, duration: float) -> void:
	if is_stunned: 
		return
		
	is_stunned = true
	knockback_velocity = knockback_impulse
	
	await get_tree().create_timer(duration).timeout
	is_stunned = false

func apply_slow(factor: float, duration: float) -> void:
	slow_factor = factor
	slow_timer = duration

func apply_pull_toward(target: Node2D, duration: float, offset: Vector2 = Vector2.ZERO) -> void:
	if is_stunned:
		return
	is_stunned = true
	pull_target = target
	pull_offset = offset
	knockback_velocity = Vector2.ZERO
	if is_instance_valid(target):
		add_collision_exception_with(target)
	await get_tree().create_timer(duration).timeout
	is_stunned = false
	pull_target = null
	pull_offset = Vector2.ZERO
	if is_instance_valid(target):
		remove_collision_exception_with(target)

const BUCKET_SCENE = preload("res://Objects/Bucket.tscn")
var _bucket: Node = null

func _setup_bucket() -> void:
	_bucket = BUCKET_SCENE.instantiate()
	_bucket.name = "Bucket"
	_bucket.position = Vector2(0, -33)
	_bucket.scale = Vector2(0.05, 0.05)
	_bucket.z_index = z_index
	add_child(_bucket)

func _try_bucket_hit() -> bool:
	if not _bucket or not _bucket.active or _bucket.charges <= 0:
		return false
	_bucket.hit()
	return true
