extends Node

func _ready() -> void:
	var f = load("res://Assets/Font/ISAACFONTDESCRIPTIONENGRUS-FILL_0.TTF")
	if f == null or not (f is Font):
		return
	get_tree().root.theme = Theme.new()
	get_tree().root.theme.default_font = f
