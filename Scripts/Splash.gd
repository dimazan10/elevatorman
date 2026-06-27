extends Control

func _ready() -> void:
	var tex = load("res://Assets/art.jpg")
	var bg := TextureRect.new()
	bg.texture = tex
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(bg)

	await get_tree().create_timer(2.0).timeout

	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.modulate.a = 0.0
	add_child(fade)

	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, 0.5)
	await tw.finished

	get_tree().change_scene_to_file("res://Scenes/MainMenu/MainMenu.tscn")
