extends CharacterBody2D

const SPEED = 400.0
const MAX_HEALTH := 3

signal health_changed(current_health: int)

var health := MAX_HEALTH
var animated_sprite: AnimatedSprite2D
var audio_player: AudioStreamPlayer2D
var footstep_sounds: Array[AudioStream] = []
var footstep_timer: float = 0.0

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	for child in get_children():
		if child.name == "Visual":
			remove_child(child)
			child.queue_free()

	animated_sprite = AnimatedSprite2D.new()
	animated_sprite.name = "AnimatedSprite"
	add_child(animated_sprite)

	var dirs = ["Walk_Right", "Walk_Left", "Walk_Up", "Walk_Back"]
	var anim_names = ["walk_right", "walk_left", "walk_up", "walk_back"]
	var frames = SpriteFrames.new()

	for j in dirs.size():
		var anim = anim_names[j]
		frames.add_animation(anim)
		frames.set_animation_speed(anim, 5)
		for i in range(1, 6):
			var tex = load("res://Assets/Sprites_Animation/" + dirs[j] + "/" + dirs[j] + "_" + str(i) + ".png")
			frames.add_frame(anim, tex)

	animated_sprite.sprite_frames = frames
	animated_sprite.play("walk_back")
	animated_sprite.scale = Vector2(0.5, 0.5)

	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	animated_sprite.material = mat

	audio_player = AudioStreamPlayer2D.new()
	audio_player.name = "FootstepAudio"
	add_child(audio_player)

	for i in range(1, 5):
		var stream = load("res://Assets/Sounds/FootStepsSound/FootStep_" + str(i) + ".wav")
		if stream:
			footstep_sounds.append(stream)

func _physics_process(_delta: float) -> void:
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

		velocity = direction * SPEED
		move_and_slide()

		footstep_timer -= _delta
		if footstep_timer <= 0 and footstep_sounds.size() > 0:
			footstep_timer = 0.3
			var idx = randi() % footstep_sounds.size()
			audio_player.stream = footstep_sounds[idx]
			audio_player.play()

		if direction.x > 0:
			animated_sprite.play("walk_right")
		elif direction.x < 0:
			animated_sprite.play("walk_left")
		elif direction.y < 0:
			animated_sprite.play("walk_up")
		else:
			animated_sprite.play("walk_back")
		animated_sprite.speed_scale = 1.0
	else:
		velocity = Vector2.ZERO
		animated_sprite.speed_scale = 0.0
		footstep_timer = 0.0

func take_damage(amount: int) -> void:
	health -= amount
	if health < 0:
		health = 0
	health_changed.emit(health)

	for child in get_children():
		if child is Camera2D and child.has_method("apply_shake"):
			child.apply_shake(5.0)

	if health <= 0:
		get_tree().change_scene_to_file("res://Scenes/MainMenu/MainMenu.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://Scenes/MainMenu/MainMenu.tscn")
