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
