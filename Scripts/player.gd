extends CharacterBody2D

# --- НАШИ НОВЫЕ ПЕРЕМЕННЫЕ ДЛЯ UI И ЖИЗНЕЙ ---
signal health_changed(new_health)

@export var max_lives: int = 3
var current_lives: int = max_lives
# ---------------------------------------------

const SPEED = 400.0

var animated_sprite: AnimatedSprite2D
var audio_player: AudioStreamPlayer2D
var footstep_sounds: Array[AudioStream] = []
var footstep_timer: float = 0.0

func _ready() -> void:
	# Твой существующий код инициализации жизней
	current_lives = max_lives
	
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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://Scenes/MainMenu/MainMenu.tscn")

# --- НАША НОВАЯ ФУНКЦИЯ УРОНА ---
func take_damage(amount: int):
	current_lives -= amount
	health_changed.emit(current_lives)
	
	# 1. ЗАПУСК ТРЯСКИ ЭКРАНА
	# Обращаемся напрямую к переименованной камере через %
	var my_camera = %PlayerCamera
		
	if my_camera and my_camera.has_method("apply_shake"):
		my_camera.apply_shake(20.0) # 20.0 — сила тряски
	else:
		print("ВНИМАНИЕ: Скрипт не нашел %PlayerCamera или у неё нет функции apply_shake!")
		
	# 2. ХИТСТОП (ЗАМОРОЗКА ИГРЫ)
	Engine.time_scale = 0.0
	await get_tree().create_timer(0.2, true, false, true).timeout
	Engine.time_scale = 1.0
	
	# 3. ПРОВЕРКА НА СМЕРТЬ
	if current_lives <= 0:
		die()

func die() -> void:
	print("Игрок погиб!")
	# Здесь можно перезагрузить сцену:
	get_tree().reload_current_scene()
