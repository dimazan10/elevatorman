extends CanvasLayer

var _phase := 0
var _exiting := false
var _label: Label
var _sub_label: Label

const STORY_TEXT := "Our main hero, despite all the hardships,\nmanaged to reach the top of the skyscraper\nand, with the power of his lamp, illuminate\nthe entire frightened city shrouded in darkness.\n\nThe light that enveloped the city became a new hope\nfor a brighter future for all humankind."
const THANKS_TEXT := "Thank you for playing\n♥"
const CREDITS_TEXT := "Game developers:\nDimazan\nFFost\n\nSpecial thanks:\nCHUMNOi"

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_label = $VBox/Label as Label
	_sub_label = $VBox/SubLabel as Label
	_label.text = ""
	_sub_label.text = ""
	_phase = 0
	_start_story()

func _start_story() -> void:
	_label.text = ""
	_sub_label.text = ""
	await _type_text(_label, STORY_TEXT, 0.05)
	await get_tree().create_timer(3.0).timeout
	await _fade_label(_label)
	_phase = 1
	_label.text = ""
	_sub_label.text = ""
	await _type_text(_label, THANKS_TEXT, 0.07)
	await get_tree().create_timer(3.0).timeout
	await _fade_label(_label)
	_phase = 2
	_label.text = ""
	_sub_label.text = ""
	await _type_text(_label, CREDITS_TEXT, 0.05)
	await get_tree().create_timer(5.0).timeout
	_go_to_menu()

func _type_text(lbl: Label, text: String, speed: float) -> void:
	lbl.text = ""
	for i in range(text.length()):
		lbl.text += text[i]
		await get_tree().create_timer(speed).timeout

func _fade_label(lbl: Label) -> Signal:
	var tw := create_tween()
	tw.tween_property(lbl, "modulate:a", 0.0, 1.0)
	await tw.finished
	lbl.modulate.a = 1.0
	return tw.finished

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and not _exiting:
		_go_to_menu()

func _go_to_menu() -> void:
	if _exiting:
		return
	_exiting = true
	get_tree().change_scene_to_file("res://Scenes/MainMenu/MainMenu.tscn")
