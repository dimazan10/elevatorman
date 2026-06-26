extends Control

const MAX_HP := 5
const COIN_COLOR := Color(1.0, 0.85, 0.2)

const INFINIT_ICON = preload("res://Assets/Inventory/Infinit.png")
const TUBE_ICON = preload("res://Assets/Inventory/Tube.png")
const CLONE_ICON = preload("res://Assets/Inventory/Clone.png")

const PRICE_INFINIT := 9
const PRICE_TUBE := 4
const PRICE_CLONE := 6

@onready var vbox: VBoxContainer = $VBoxMain
@onready var time_label: Label = $VBoxMain/HBoxMain/InfoSide/TimeLabel
@onready var currency_label: Label = $VBoxMain/HBoxMain/InfoSide/CoinDisplay/CurrencyLabel
@onready var bucket_btn: Button = $VBoxMain/HBoxMain/InfoSide/BucketBuy
@onready var continue_btn: Button = $VBoxMain/HBoxMain/InfoSide/ContinueBtn
@onready var bucket_status: Label = $VBoxMain/HBoxMain/InfoSide/BucketStatus
@onready var infinit_btn: Button = $VBoxMain/HBoxMain/InfoSide/InfinitBtn
@onready var infinit_status: Label = $VBoxMain/HBoxMain/InfoSide/InfinitStatus
@onready var tube_btn: Button = $VBoxMain/HBoxMain/InfoSide/TubeBtn
@onready var tube_status: Label = $VBoxMain/HBoxMain/InfoSide/TubeStatus
@onready var clone_btn: Button = $VBoxMain/HBoxMain/InfoSide/CloneBtn
@onready var clone_status: Label = $VBoxMain/HBoxMain/InfoSide/CloneStatus
@onready var bottle_body: Panel = $VBoxMain/HBoxMain/BottleSide/BottleBody
@onready var bottle_clip: Control = $VBoxMain/HBoxMain/BottleSide/BottleBody/BottleClip
@onready var liquid: ColorRect = $VBoxMain/HBoxMain/BottleSide/BottleBody/BottleClip/Liquid
@onready var hp_count_label: Label = $VBoxMain/HBoxMain/BottleSide/HPCountLabel
@onready var collect_btn: Button = $VBoxMain/HBoxMain/BottleSide/CollectBtn
@onready var coin_icon: Label = $VBoxMain/HBoxMain/InfoSide/CoinDisplay/CoinIcon
@onready var coin_layer: Control = $CoinLayer
@onready var neck: Panel = $VBoxMain/HBoxMain/BottleSide/BottleNeck
@onready var neck_liquid: ColorRect = $VBoxMain/HBoxMain/BottleSide/BottleNeck/NeckClip/NeckLiquid

var _collected := false

func _ready() -> void:
	CursorManager.setup_buttons(self)
	_setup_bottle_style()
	var t = GameState.last_floor_time
	var m = int(t) / 60
	var s = int(t) % 60
	time_label.text = "Время: %02d:%02d" % [m, s]
	hp_count_label.text = str(GameState.last_floor_hp)
	_set_liquid_fill(clampf(GameState.last_floor_hp / float(MAX_HP), 0.0, 1.0))
	currency_label.text = str(GameState.currency)
	_update_bucket_ui()
	_update_item_ui()
	collect_btn.grab_focus.call_deferred()

func _setup_bottle_style() -> void:
	var sbf := StyleBoxFlat.new()
	sbf.bg_color = Color(0.08, 0.08, 0.12)
	sbf.border_color = Color(0.3, 0.3, 0.4)
	sbf.border_width_left = 2
	sbf.border_width_right = 2
	sbf.border_width_bottom = 2
	sbf.corner_radius_bottom_left = 20
	sbf.corner_radius_bottom_right = 20
	bottle_body.add_theme_stylebox_override("panel", sbf)

	var sn := StyleBoxFlat.new()
	sn.bg_color = Color(0.08, 0.08, 0.12)
	sn.border_color = Color(0.3, 0.3, 0.4)
	sn.border_width_left = 2
	sn.border_width_right = 2
	sn.border_width_top = 2
	sn.corner_radius_top_left = 8
	sn.corner_radius_top_right = 8
	neck.add_theme_stylebox_override("panel", sn)

	liquid.color = Color(0.2, 0.7, 0.3)
	neck_liquid.color = Color(0.2, 0.7, 0.3)
	liquid.size.x = bottle_clip.size.x
	neck_liquid.size.x = neck.size.x - 2

func _set_liquid_fill(ratio: float) -> void:
	var ch: float = bottle_clip.size.y
	liquid.position.y = ch * (1.0 - ratio)
	liquid.size.y = ch * ratio
	neck_liquid.visible = ratio >= 0.99

func _item_slot_free() -> int:
	for i in range(GameState.inventory.size()):
		if GameState.inventory[i].id == "":
			return i
	return -1

func _update_item_ui() -> void:
	_update_item_button("infinit", infinit_btn, infinit_status, PRICE_INFINIT)
	_update_item_button("tube", tube_btn, tube_status, PRICE_TUBE)
	_update_item_button("clone", clone_btn, clone_status, PRICE_CLONE)

func _update_item_button(id: String, btn: Button, status: Label, price: int) -> void:
	var owned := false
	var slot = -1
	for i in range(GameState.inventory.size()):
		if GameState.inventory[i].id == id:
			owned = true
			slot = i
			break
	if owned:
		btn.disabled = true
		btn.text = "Куплено"
		status.text = "Слот " + str(slot + 1)
	else:
		btn.disabled = GameState.currency < price or _item_slot_free() == -1
		btn.text = "Купить " + id.capitalize() + " (" + str(price) + " монет)"
		status.text = ""

func _buy_item(id: String, icon: Texture2D, price: int) -> void:
	if GameState.currency < price:
		return
	var slot = _item_slot_free()
	if slot == -1:
		return
	GameState.currency -= price
	GameState.inventory[slot] = {id = id, icon = icon, name = id.capitalize()}
	currency_label.text = str(GameState.currency)
	_update_item_ui()

func _update_bucket_ui() -> void:
	if GameState.has_bucket:
		bucket_btn.disabled = true
		bucket_btn.text = "Куплено"
		bucket_status.text = "Ведро (%d зар." % GameState.bucket_charges + ")"
	else:
		bucket_btn.disabled = GameState.currency < 3 or not _collected
		bucket_btn.text = "Купить ведро (3 монеты)"
		bucket_status.text = ""

func _on_collect() -> void:
	if _collected:
		return
	_collected = true
	collect_btn.disabled = true

	var tween: Tween = create_tween().set_parallel(false)
	var hp := GameState.last_floor_hp
	var ratio := clampf(hp / float(MAX_HP), 0.0, 1.0)

	tween.tween_method(_animate_liquid, ratio, 0.0, 0.6).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(neck_liquid, "visible", false, 0.3)

	GameState.currency += hp
	_spawn_coins(hp)
	await tween.finished

	var bounce: Tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	bounce.tween_property(coin_icon, "scale", Vector2(1.5, 1.5), 0.2)
	bounce.tween_property(coin_icon, "scale", Vector2(1.0, 1.0), 0.3)
	currency_label.text = str(GameState.currency)
	_update_bucket_ui()
	_update_item_ui()

func _animate_liquid(v: float) -> void:
	_set_liquid_fill(v)

func _spawn_coins(count: int) -> void:
	var start: Vector2 = bottle_body.global_position + bottle_body.size * Vector2(0.5, 0.0)
	var target: Vector2 = coin_icon.global_position + Vector2(8, 8) - coin_layer.global_position

	for i in range(min(count, 10)):
		var coin := Label.new()
		coin.text = "+1"
		coin.add_theme_color_override("font_color", COIN_COLOR)
		coin.add_theme_font_size_override("font_size", 18)
		coin.add_theme_constant_override("outline_size", 1)
		coin.add_theme_color_override("font_outline_color", Color.BLACK)
		coin_layer.add_child(coin)

		coin.position = start + Vector2(randf_range(-20, 20), randf_range(-30, 0)) - coin_layer.global_position
		var ct: Tween = create_tween()
		ct.tween_property(coin, "position", target + Vector2(randf_range(-10, 10), randf_range(-10, 10)), 0.5).set_delay(i * 0.08).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		ct.tween_callback(coin.queue_free).set_delay(i * 0.08 + 0.6)

func _on_bucket_buy() -> void:
	if GameState.currency >= 3 and not GameState.has_bucket:
		GameState.currency -= 3
		GameState.has_bucket = true
		GameState.bucket_charges = 3
	currency_label.text = str(GameState.currency)
	_update_bucket_ui()
	_update_item_ui()

func _on_infinit_buy() -> void:
	_buy_item("infinit", INFINIT_ICON, PRICE_INFINIT)

func _on_tube_buy() -> void:
	_buy_item("tube", TUBE_ICON, PRICE_TUBE)

func _on_clone_buy() -> void:
	_buy_item("clone", CLONE_ICON, PRICE_CLONE)

func _on_continue() -> void:
	if GameState.current_floor >= 3:
		GameState.current_floor = 1
		GameState.has_bucket = false
		GameState.currency = 0
		StyleManager.reset_score()
		get_tree().change_scene_to_file("res://Scenes/MainMenu/MainMenu.tscn")
	else:
		GameState.current_floor += 1
		get_tree().change_scene_to_file("res://Scenes/Game/game.tscn")
