extends Node2D

const HealthUI := preload("res://Objects/UI_HP.tscn")
const DashUI := preload("res://Objects/DashUI.tscn")
const InventoryUI := preload("res://Objects/InventoryUI.tscn")
const BossHPBar := preload("res://Scripts/BossHPBar.gd")

func _ready() -> void:
	add_to_group("pausable")
	add_child(HealthUI.instantiate())
	add_child(DashUI.instantiate())
	add_child(InventoryUI.instantiate())

	var bar := BossHPBar.new()
	add_child(bar)
	var robot := get_node_or_null("Robot")
	if robot:
		bar.setup(robot)

	var music := AudioStreamPlayer.new()
	music.name = "BossMusic"
	music.stream = load("res://Assets/Enemies/Boss/Sprite_Robot/Music.mp3")
	music.bus = &"Music"
	add_child(music)
	music.play()

	if robot:
		robot.died.connect(_on_boss_died)

func _on_boss_died() -> void:
	var music := get_node_or_null("BossMusic") as AudioStreamPlayer
	if not music:
		return
	var tw := create_tween()
	tw.tween_property(music, "volume_db", -80.0, 2.0)
