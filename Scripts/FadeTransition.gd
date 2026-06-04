extends Node

static func fade_out(fade_duration: float = 0.8):
	var tree := Engine.get_main_loop() as SceneTree
	if not tree: return
	var current := tree.current_scene
	if not current: return
	var layer := CanvasLayer.new()
	layer.layer = 128
	layer.name = "FadeLayer"
	var rect := ColorRect.new()
	rect.color = Color.BLACK
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.modulate = Color(1, 1, 1, 0)
	layer.add_child(rect)
	current.add_child(layer)
	var tween := current.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(rect, "modulate", Color(1, 1, 1, 1.0), fade_duration)
	await tween.finished

static func fade_in(fade_duration: float = 0.8):
	var tree := Engine.get_main_loop() as SceneTree
	if not tree: return
	var current := tree.current_scene
	if not current: return
	var layer := CanvasLayer.new()
	layer.layer = 128
	layer.name = "FadeLayer"
	var rect := ColorRect.new()
	rect.color = Color.BLACK
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.modulate = Color(1, 1, 1, 1)
	layer.add_child(rect)
	current.add_child(layer)
	var tween := current.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(rect, "modulate", Color(1, 1, 1, 0), fade_duration)
	await tween.finished
	layer.queue_free()
