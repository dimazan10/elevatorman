extends CanvasLayer

@onready var wind_tex: Texture2D = preload("res://Assets/Inventory/Wind.png")
@onready var slots: Array[Control] = [
	$Panel/BgWind/Slot0,
	$Panel/BgWind/Slot1,
]

func _ready() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p and p.has_signal("inventory_changed"):
		p.inventory_changed.connect(_refresh)
	for i in range(slots.size()):
		slots[i].gui_input.connect(_on_slot_gui_input.bind(i))
	_refresh()

func _refresh() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if not p or not p.has_method("get_inventory"):
		return
	var inv = p.get_inventory()
	for i in range(slots.size()):
		var icon = slots[i].get_node("Icon") as TextureRect
		if not icon:
			continue
		if i < inv.size() and inv[i].icon:
			icon.texture = inv[i].icon
		else:
			icon.texture = null
		slots[i].visible = true

func _on_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_use_item_on_slot(slot_index)
	elif event is InputEventScreenTouch and event.pressed:
		_use_item_on_slot(slot_index)

func _use_item_on_slot(slot_index: int) -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p and p.has_method("_use_item"):
		p._use_item(slot_index)
