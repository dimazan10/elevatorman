extends CanvasLayer

signal fire_requested

var _crosshair := Sprite2D.new()
var _crosshair_pos := Vector2(640, 360)
var _aim_vel := Vector2.ZERO

@export var crosshair_speed: float = 300.0
@export var crosshair_texture: Texture2D

func _init() -> void:
	layer = 131
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_crosshair.texture = crosshair_texture
	_crosshair.scale = Vector2(0.5, 0.5)
	add_child(_crosshair)

	set_process(true)
	set_process_input(true)

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func set_crosshair_pos(pos: Vector2) -> void:
	_crosshair_pos = pos

func _process(delta: float) -> void:
	if not _crosshair:
		return
	_crosshair.global_position = _crosshair_pos

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		fire_requested.emit()

func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
