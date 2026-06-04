extends Control

@onready var bg := $TextureRect
var extra := 60.0
var max_move := 25.0

func _ready() -> void:
	bg.offset_left -= extra
	bg.offset_top -= extra
	bg.offset_right += extra
	bg.offset_bottom += extra

func _process(_delta: float) -> void:
	var center := get_viewport_rect().size * 0.5
	var mouse := get_global_mouse_position()
	var rel := (mouse - center) / center
	var dx := -rel.x * max_move
	var dy := -rel.y * max_move

	bg.offset_left = -extra + dx
	bg.offset_top = -extra + dy
	bg.offset_right = extra + dx
	bg.offset_bottom = extra + dy

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Game/start.tscn")

func _on_settings_pressed() -> void:
	print("Настройки — в разработке")
