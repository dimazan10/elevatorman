extends CharacterBody2D

signal health_changed(new_health)
signal dash_used(index: int)
signal dash_recharged(index: int)

@export var max_lives: int = 5
var current_lives: int = max_lives

var speed: float = 550.0
const MAX_DASH_CHARGES = 3
const DASH_COOLDOWN = 4.0
const DASH_SPEED = 1200.0
const DASH_DURATION = 0.15

const TUBE_SCENE = preload("res://Objects/TubeEffect.tscn")
const CLONE_SCENE = preload("res://Objects/CloneDecoy.tscn")

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

var _clone_node: Node2D = null
var _clone_active := false
var _blink_tween: Tween = null

const REWIND_INTERVAL := 0.1
const REWIND_BUFFER_SIZE := 40
var _rewind_buffer: Array[Dictionary] = []
var _rewind_timer := 0.0

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
	frames.add_animation("idle_left")
	frames.add_frame("idle_left", load("res://Assets/Sprites_Player/ggl.png"))
	frames.add_animation("idle_right")
	frames.add_frame("idle_right", load("res://Assets/Sprites_Player/ggr.png"))
	frames.add_animation("walk_left")
	frames.set_animation_speed("walk_left", 10)
	for i in range(1, 4):
		frames.add_frame("walk_left", load("res://Assets/Sprites_Player/gglgo" + str(i) + ".png"))
	frames.set_animation_loop("walk_left", true)
	frames.add_animation("walk_right")
	frames.set_animation_speed("walk_right", 10)
	for i in range(1, 4):
		frames.add_frame("walk_right", load("res://Assets/Sprites_Player/ggrgo" + str(i) + ".png"))
	frames.set_animation_loop("walk_right", true)
	frames.add_animation("walk_down")
	frames.set_animation_speed("walk_down", 5)
	for i in range(1, 5):
		frames.add_frame("walk_down", load("res://Assets/Sprites_Player/gg" + str(i) + ".png"))
	frames.set_animation_loop("walk_down", true)
	frames.add_animation("walk_up")
	frames.set_animation_speed("walk_up", 5)
	for i in range(1, 5):
		var tex = load("res://Assets/Sprites_Player/ggspina" + str(i) + ".png")
		frames.add_frame("walk_up", tex)
	frames.set_animation_loop("walk_up", true)

	frames.add_animation("death")
	frames.set_animation_speed("death", 8)
	frames.set_animation_loop("death", false)
	for i in range(1, 8):
		var tex = load("res://Assets/Sprites_Player/Death/gg_death" + str(i) + "-removebg-preview.png")
		if tex:
			frames.add_frame("death", tex)
	if frames.get_frame_count("death") == 0:
		frames.add_frame("death", load("res://Assets/Sprites_Player/gg.png"))

	animated_sprite.sprite_frames = frames
	animated_sprite.play("idle_right")
	animated_sprite.scale = Vector2(1.0, 1.0)

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

	if GameState.dark_mode:
		var light = get_node_or_null("PlayerLight")
		if light and light is PointLight2D:
			light.scale *= 2.0
			light.range_item_cull_mask = 2147483647
			light.range_z_min = -128
			light.range_z_max = 128
			light.modulate = Color(1.8, 1.8, 1.8, 1)
	
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

	if Input.is_action_just_pressed("dash"):
		perform_dash()

	if slow_timer > 0:
		slow_timer -= delta
		if slow_timer <= 0:
			slow_timer = 0.0
			slow_factor = 1.0

	if Input.is_action_just_pressed("use_item_1"):
		_use_item(0)

	if Input.is_action_just_pressed("use_item_2"):
		_use_item(1)

	_rewind_timer += delta
	if _rewind_timer >= REWIND_INTERVAL:
		_rewind_timer = 0.0
		_record_rewind_state()

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

	if _is_dying:
		velocity = Vector2.ZERO
		move_and_slide()
		return
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
		var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if dir.length() > 0.1:
			dir = dir.normalized()
			global_position += dir * speed * delta
		return

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var input_len := direction.length()
	var moving = input_len > 0.1

	if moving:
		direction /= input_len
		last_move_dir = direction

		velocity = direction * speed * slow_factor
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
		if direction.y < -0.3:
			animated_sprite.flip_h = direction.x < 0
			animated_sprite.play("walk_up")
		elif direction.x < -0.3:
			animated_sprite.flip_h = false
			animated_sprite.play("walk_left")
		elif direction.x > 0.3:
			animated_sprite.flip_h = false
			animated_sprite.play("walk_right")
		else:
			animated_sprite.flip_h = false
			if last_move_dir.x < -0.3:
				animated_sprite.play("walk_left")
			elif last_move_dir.x > 0.3:
				animated_sprite.play("walk_right")
			else:
				animated_sprite.play("walk_down")
	else:
		velocity = Vector2.ZERO
		footstep_timer = 0.0
		if last_move_dir.y < -0.3:
			animated_sprite.speed_scale = 0.0
			animated_sprite.flip_h = last_move_dir.x < 0
			animated_sprite.play("walk_up")
		elif last_move_dir.y > 0.3:
			animated_sprite.speed_scale = 0.0
			animated_sprite.play("walk_down")
		elif last_move_dir.x < -0.3:
			animated_sprite.play("idle_left")
		else:
			animated_sprite.play("idle_right")
	
	_push_enemies_out()

var _push_radius := 30.0
var _push_radius_sq := 900.0

func _push_enemies_out() -> void:
	var push_delta := get_physics_process_delta_time()
	var pos := global_position
	for e in get_tree().get_nodes_in_group("enemy"):
		var diff: Vector2 = e.global_position - pos
		var dist_sq := diff.length_squared()
		if dist_sq < _push_radius_sq and dist_sq > 0.000001:
			var dist := sqrt(dist_sq)
			var push_dir := diff / dist
			var push_force := (_push_radius - dist) * 8.0
			if e is RigidBody2D:
				e.apply_central_impulse(push_dir * push_force)
			elif e is CharacterBody2D:
				e.position += push_dir * push_force * push_delta

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
	if is_dashing or is_stunned:
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

	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir.length_squared() > 0.001:
		dir = dir.normalized()
		last_move_dir = dir
	else:
		dir = last_move_dir

	velocity = dir * DASH_SPEED

func take_damage(amount: int):
	if _noclip or _is_dying or _invulnerable:
		return
	
	if _try_bucket_hit():
		_invulnerable = true
		_start_blink(0.5)
		Engine.time_scale = 0.0
		await get_tree().create_timer(0.2, true, false, true).timeout
		Engine.time_scale = 1.0
		await get_tree().create_timer(0.3).timeout
		_stop_blink()
		_invulnerable = false
		return
	
	_invulnerable = true
	current_lives -= amount
	health_changed.emit(current_lives)
	if current_lives <= 0:
		_is_dying = true
	
	var my_camera = %PlayerCamera
		
	if my_camera and my_camera.has_method("apply_shake"):
		my_camera.apply_shake(20.0)
		
	hit_blow_audio.play()
	hit_fierce_audio.play()
	
	Engine.time_scale = 0.0
	await get_tree().create_timer(0.2, true, false, true).timeout
	Engine.time_scale = 1.0
	await get_tree().create_timer(0.3).timeout
	_invulnerable = false
	
	if _try_collar_hit():
		_invulnerable = true
		_start_blink(2.0)
		await get_tree().create_timer(2.0).timeout
		_stop_blink()
		_invulnerable = false
	
	if current_lives <= 0:
		die()

func die() -> void:
	if has_item("infinit"):
		_infinit_revive()
		return
	_is_dying = true
	var light = get_node_or_null("PlayerLight")
	if light:
		light.visible = false
	var attempts: int = GameState.add_death(GameState.current_floor)
	_play_death_frames()
	await get_tree().create_timer(1.2, true, false, true).timeout
	var death_screen := CanvasLayer.new()
	death_screen.name = "DeathScreen"
	death_screen.set_script(load("res://Scripts/DeathScreen.gd"))
	death_screen.set_meta("attempts", attempts)
	get_tree().root.add_child(death_screen)
	get_tree().paused = true

func _play_death_frames() -> void:
	var textures: Array[Texture2D] = []
	for i in range(1, 8):
		var tex = load("res://Assets/Sprites_Player/Death/gg_death" + str(i) + "-removebg-preview.png")
		if tex:
			textures.append(tex)
	if textures.is_empty():
		var fallback = load("res://Assets/Sprites_Player/gg.png")
		if fallback:
			textures.append(fallback)
	if textures.is_empty():
		return
	animated_sprite.visible = false
	var sprite := Sprite2D.new()
	sprite.name = "DeathSprite"
	sprite.position = animated_sprite.position
	sprite.scale = animated_sprite.scale
	add_child(sprite)
	for tex in textures:
		sprite.texture = tex
		await get_tree().create_timer(0.125, true, false, true).timeout

func _infinit_revive() -> void:
	for i in range(inventory.size()):
		if inventory[i].id == "infinit":
			clear_slot(i)
			break
	current_lives = max_lives
	health_changed.emit(current_lives)
	_is_dying = false
	_invulnerable = true
	can_move = true
	_start_blink(0.65)
	await get_tree().create_timer(0.65).timeout
	_stop_blink()
	_invulnerable = false

func _use_item(slot: int) -> void:
	if slot < 0 or slot >= inventory.size():
		return
	var item = inventory[slot]
	if item.id == "":
		return
	match item.id:
		"tube":
			_use_tube(slot)
		"clone":
			_use_clone(slot)
		"infinit":
			pass
		"rewind":
			_use_rewind(slot)

func _use_tube(slot: int) -> void:
	var tube = TUBE_SCENE.instantiate()
	tube.global_position = global_position
	get_tree().current_scene.add_child(tube)
	clear_slot(slot)

func _use_clone(slot: int) -> void:
	if _clone_active:
		return
	_clone_active = true
	var clone = CLONE_SCENE.instantiate()
	clone.global_position = global_position + Vector2(50, 0)
	get_tree().current_scene.add_child(clone)
	_clone_node = clone
	modulate = Color(1, 1, 1, 0.4)
	clone.decoy_destroyed.connect(_on_clone_destroyed)
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.has_method("set_target"):
			e.set_target(clone)
	clear_slot(slot)

func _on_clone_destroyed() -> void:
	_clone_active = false
	_clone_node = null
	modulate = Color.WHITE
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.has_method("set_target"):
			e.set_target(self)

func _start_blink(duration: float) -> void:
	_stop_blink()
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(self, "modulate:a", 0.2, 0.08)
	_blink_tween.tween_property(self, "modulate:a", 1.0, 0.08)

func _stop_blink() -> void:
	if _blink_tween:
		_blink_tween.kill()
		_blink_tween = null
	modulate.a = 1.0

func _record_rewind_state() -> void:
	var inv_copy: Array[Dictionary] = []
	for s in inventory:
		inv_copy.append({id = s.id, icon = s.icon, name = s.name})
	_rewind_buffer.append({
		position = global_position,
		hp = current_lives,
		inventory = inv_copy,
	})
	if _rewind_buffer.size() > REWIND_BUFFER_SIZE:
		_rewind_buffer.pop_front()

func _use_rewind(slot: int) -> void:
	if _rewind_buffer.is_empty():
		clear_slot(slot)
		return
	var state = _rewind_buffer[0]
	_rewind_buffer.clear()
	clear_slot(slot)
	global_position = state.position
	current_lives = state.hp
	for i in range(state.inventory.size()):
		if i < inventory.size() and state.inventory[i].id != "rewind":
			inventory[i] = state.inventory[i]
	health_changed.emit(current_lives)
	inventory_changed.emit()
	_invulnerable = true
	_start_blink(0.45)
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(0.4, 0.6, 1.0), 0.15)
	tw.tween_property(self, "modulate", Color.WHITE, 0.3)
	await tw.finished
	_stop_blink()
	_invulnerable = false

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

signal inventory_changed

var inventory: Array[Dictionary] = [
	{id = "", icon = null, name = ""},
	{id = "", icon = null, name = ""},
]

func get_inventory() -> Array[Dictionary]:
	return inventory

func set_slot(index: int, id: String, icon: Texture2D, name: String = "") -> void:
	if index < 0 or index >= inventory.size():
		return
	inventory[index] = {id = id, icon = icon, name = name}
	inventory_changed.emit()

func clear_slot(index: int) -> void:
	if index < 0 or index >= inventory.size():
		return
	inventory[index] = {id = "", icon = null, name = ""}
	inventory_changed.emit()

func has_item(id: String) -> bool:
	for s in inventory:
		if s.id == id:
			return true
	return false

const BUCKET_SCENE = preload("res://Objects/Bucket.tscn")
const COLLAR_SCENE = preload("res://Objects/Collar.tscn")
var _bucket: Node = null
var _collar: Node = null

func _setup_bucket() -> void:
	_bucket = BUCKET_SCENE.instantiate()
	_bucket.name = "Bucket"
	_bucket.position = Vector2(0, -33)
	_bucket.scale = Vector2(0.05, 0.05)
	_bucket.z_index = z_index
	add_child(_bucket)

func _setup_collar() -> void:
	_collar = COLLAR_SCENE.instantiate()
	_collar.name = "Collar"
	_collar.position = Vector2(0, -10)
	_collar.scale = Vector2(0.12, 0.12)
	_collar.z_index = z_index
	add_child(_collar)

func _try_bucket_hit() -> bool:
	if not _bucket or not _bucket.active or _bucket.charges <= 0:
		return false
	_bucket.hit()
	return true

func _try_collar_hit() -> bool:
	if not _collar or not _collar.active:
		return false
	_collar.hit()
	return true
