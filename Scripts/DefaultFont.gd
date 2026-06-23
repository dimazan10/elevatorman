extends Node

func _ready() -> void:
	var f = load("res://Assets/Font/ISAACFONTDESCRIPTIONENGRUS-FILL_0.TTF")
	if f == null:
		return
	var t = Theme.new()
	t.set_font("font", "Label", f)
	get_tree().root.theme = t
