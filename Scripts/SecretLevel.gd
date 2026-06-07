extends Node2D

const FadeTransition = preload("res://Scripts/FadeTransition.gd")

const FLOOR_SCENES = [
	"res://Scenes/Floors/Floor_Arena_01.tscn",
	"res://Scenes/Floors/Floor_Corridor.tscn",
	"res://Scenes/Floors/Floor_Base.tscn",
]

const FLOOR_HEIGHT = 1065.0

@onready var anim = $Hole/FloorElevator/AnimationPlayer
@onready var player_node = get_tree().get_first_node_in_group("player") as Node2D

var transport_enabled: bool = false
var floors: Array = []
var current_floor_index: int = 0
var combat_timer: Timer
var in_combat: bool = false

func _ready() -> void:
	print("SecretLevel: Starting level generation")
	_generate_floors()
	print("SecretLevel: Generated %d floors" % floors.size())
	
	_hide_player()
	FadeTransition.fade_in()
	$Hole/FloorElevator/TransportArea.body_entered.connect(_on_transport_entered)
	$Hole/FloorElevator/ExitArea.body_exited.connect(_on_exit_exited)
	$Hole/FloorElevator/TransportArea/CollisionShape.set_deferred("disabled", true)
	
	anim.play("RESET")
	anim.seek(0, true)
	anim.stop()
	anim.play("DownUp")
	await anim.animation_finished
	anim.play("Open")
	await anim.animation_finished
	$Hole/FloorElevator/TransportArea/CollisionShape.set_deferred("disabled", false)
	_show_player()
	player_node.can_move = true
	await get_tree().create_timer(1.5).timeout
	transport_enabled = true

func _generate_floors() -> void:
	var container = get_node_or_null("FloorsContainer")
	if not container:
		container = Node2D.new()
		container.name = "FloorsContainer"
		add_child(container)
		move_child(container, 0)  # Move to front so floors are behind other elements
	
	# Generate 3-5 random floors
	var floor_count = 3
	var current_y: float = 0.0
	
	for i in range(floor_count):
		var scene_path = FLOOR_SCENES[randi() % FLOOR_SCENES.size()]
		var floor_scene = load(scene_path)
		if floor_scene:
			var floor = floor_scene.instantiate()
			floor.position.y = current_y
			floor.floor_index = i
			container.add_child(floor)
			floors.append(floor)
			current_y += FLOOR_HEIGHT

func _on_exit_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if in_combat or not transport_enabled:
		return
	
	print("SecretLevel: Player exited elevator - starting combat")
	in_combat = true
	transport_enabled = false
	_start_combat()

func _start_combat() -> void:
	player_node.can_move = true
	
	# Start timer
	combat_timer = Timer.new()
	combat_timer.name = "CombatTimer"
	combat_timer.one_shot = true
	combat_timer.wait_time = 15.0
	combat_timer.timeout.connect(_on_combat_timeout)
	add_child(combat_timer)
	combat_timer.start()
	
	print("SecretLevel: Combat timer started - 15 seconds")

func _on_combat_timeout() -> void:
	print("SecretLevel: Combat timer ended")
	in_combat = false
	player_node.can_move = false
	
	anim.play("DownUp")
	await anim.animation_finished
	anim.play("Open")
	await anim.animation_finished
	
	transport_enabled = true

func _on_transport_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or not transport_enabled:
		return
	
	print("SecretLevel: Player entered elevator")
	transport_enabled = false
	player_node.can_move = false
	
	if combat_timer:
		combat_timer.stop()
		combat_timer.queue_free()
	
	anim.stop()
	anim.play("Close")
	await anim.animation_finished
	
	# Check if there are more floors
	if current_floor_index + 1 < floors.size():
		print("SecretLevel: Moving to next floor")
		current_floor_index += 1
		_move_to_floor(current_floor_index)
	else:
		print("SecretLevel: All floors completed - returning to menu")
		anim.play("Up")
		await anim.animation_finished
		await FadeTransition.fade_out()
		get_tree().change_scene_to_file("res://Scenes/MainMenu/MainMenu.tscn")

func _move_to_floor(floor_index: int) -> void:
	var target_y: float = -floor_index * FLOOR_HEIGHT
	
	# Tween elevator to target floor
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property($Hole/FloorElevator, "position:y", target_y, 1.5)
	await tween.finished
	
	anim.play("DownUp")
	await anim.animation_finished
	anim.play("Open")
	await anim.animation_finished
	
	transport_enabled = true

func _hide_player() -> void:
	player_node.process_mode = Node.PROCESS_MODE_DISABLED
	for child in player_node.get_children():
		if child is Camera2D:
			continue
		if child is AnimatedSprite2D:
			child.hide()
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
		if child is AudioStreamPlayer2D:
			child.stop()

func _show_player() -> void:
	player_node.process_mode = Node.PROCESS_MODE_INHERIT
	for child in player_node.get_children():
		if child is Camera2D:
			continue
		if child is AnimatedSprite2D:
			child.show()
		if child is CollisionShape2D:
			child.set_deferred("disabled", false)
