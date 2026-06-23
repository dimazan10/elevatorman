extends Node

func _ready() -> void:
	call_deferred("_apply")

func _apply() -> void:
	var f = ResourceLoader.load("res://Assets/Font/DefaultFont.tres", "FontFile")
	if f == null:
		f = ResourceLoader.load("res://Assets/Font/DefaultFont.tres")
	if f == null or not f is Font:
		return
	var t = Theme.new()
	t.set_font("font", "Label", f)
	t.set_font("font", "Button", f)
	t.set_font("font", "RichTextLabel", f)
	t.set_font("font", "Window", f)
	get_tree().root.theme = t
