extends Node

func _ready() -> void:
	call_deferred("_apply")

func _apply() -> void:
	var f = ResourceLoader.load("res://Assets/Font/ISAACFONTDESCRIPTIONENGRUS-FILL_0.TTF") as FontFile
	if not f:
		return
	var t = Theme.new()
	t.set_font("font", "Label", f)
	t.set_font("font", "Button", f)
	t.set_font("font", "RichTextLabel", f)
	t.set_font("font", "Window", f)
	get_tree().root.theme = t
