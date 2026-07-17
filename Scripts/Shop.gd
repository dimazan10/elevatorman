extends Control

const MAX_HP := 5
const COIN_COLOR := Color(1.0, 0.85, 0.2)

const INFINIT_ICON = preload("res://Assets/Items/Infinit.png")
const TUBE_ICON = preload("res://Assets/Items/Tube.png")
const CLONE_ICON = preload("res://Assets/Items/Clone.png")
const REWIND_ICON = preload("res://Assets/Items/Rewind.png")
const COLLAR_ICON = preload("res://Assets/Items/Collar.png")

const PRICE_INFINIT := 9
const PRICE_TUBE := 2
const PRICE_CLONE := 6
const PRICE_REWIND := 4
const PRICE_COLLAR := 4

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
@onready var rewind_btn: Button = $VBoxMain/HBoxMain/InfoSide/RewindBtn
@onready var rewind_status: Label = $VBoxMain/HBoxMain/InfoSide/RewindStatus
@onready var collar_btn: Button = $VBoxMain/HBoxMain/InfoSide/CollarBtn
@onready var collar_status: Label = $VBoxMain/HBoxMain/InfoSide/CollarStatus
@onready var bottle_body: Panel = $VBoxMain/HBoxMain/BottleSide/BottleBody
@onready var bottle_clip: Control = $VBoxMain/HBoxMain/BottleSide/BottleBody/BottleClip
@onready var liquid: ColorRect = $VBoxMain/HBoxMain/BottleSide/BottleBody/BottleClip/Liquid
@onready var hp_count_label: Label = $VBoxMain/HBoxMain/BottleSide/HPCountLabel
@onready var collect_btn: Button = $VBoxMain/HBoxMain/BottleSide/CollectBtn
@onready var coin_icon: Label = $VBoxMain/HBoxMain/InfoSide/CoinDisplay/CoinIcon
@onready var coin_layer: Control = $CoinLayer
@onready var neck: Panel = $VBoxMain/HBoxMain/BottleSide/BottleNeck
@onready var neck_liquid: ColorRect = $VBoxMain/HBoxMain/BottleSide/BottleNeck/NeckClip/NeckLiquid
@onready var shop_label: Label = $VBoxMain/HBoxMain/InfoSide/ShopLabel

var _collected := false
var _shop_items: Array[Dictionary] = []

func _ready() -> void:
	CursorManager.setup_buttons(self)
	_setup_bottle_style()
	_pick_random_items()
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

func _pick_random_items() -> void:
	var all_items: Array[Dictionary] = [
		{"id": "bucket", "btn": bucket_btn, "status": bucket_status, "price": 3},
		{"id": "collar", "btn": collar_btn, "status": collar_status, "price": PRICE_COLLAR},
		{"id": "infinit", "btn": infinit_btn, "status": infinit_status, "price": PRICE_INFINIT},
		{"id": "tube", "btn": tube_btn, "status": tube_status, "price": PRICE_TUBE},
		{"id": "clone", "btn": clone_btn, "status": clone_status, "price": PRICE_CLONE},
		{"id": "rewind", "btn": rewind_btn, "status": rewind_status, "price": PRICE_REWIND},
	]
	if GameState.current_floor < 2:
		all_items = all_items.filter(func(item): return item["price"] <= 5)
	all_items.shuffle()
	_shop_items = all_items.slice(0, mini(3, all_items.size()))

	var all_btns := [bucket_btn, collar_btn, infinit_btn, tube_btn, clone_btn, rewind_btn]
	var all_statuses := [bucket_status, collar_status, infinit_status, tube_status, clone_status, rewind_status]
	var selected_btns: Array[Button] = []
	var selected_statuses: Array[Label] = []
	for item in _shop_items:
		selected_btns.append(item["btn"])
		selected_statuses.append(item["status"])

	var info_side = $VBoxMain/HBoxMain/InfoSide
	for i in range(all_btns.size()):
		var btn: Button = all_btns[i]
		var status: Label = all_statuses[i]
		if btn not in selected_btns:
			btn.visible = false
			status.visible = false

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
	for item in _shop_items:
		_update_item_button(item["id"], item["btn"], item["status"], item["price"])

func _update_item_button(id: String, btn: Button, status: Label, price: int) -> void:
	if id == "bucket":
		_update_bucket_ui()
		return
	if id == "collar":
		_update_collar_ui()
		return
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

func _update_bucket_ui() -> void:
	if GameState.has_bucket:
		bucket_btn.disabled = true
		bucket_btn.text = "Куплено"
		bucket_status.text = "Ведро (%d зар." % GameState.bucket_charges + ")"
	else:
		bucket_btn.disabled = GameState.currency < 3 or not _collected or GameState.has_collar
		bucket_btn.text = "Купить ведро (3 монеты)"
		bucket_status.text = ""

func _update_collar_ui() -> void:
	if GameState.has_collar:
		collar_btn.disabled = true
		collar_btn.text = "Куплено"
		collar_status.text = "Ошейник"
	else:
		collar_btn.disabled = GameState.currency < PRICE_COLLAR or not _collected or GameState.has_bucket
		collar_btn.text = "Купить ошейник (%d монет)" % PRICE_COLLAR
		collar_status.text = ""

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
		GameState.bucket_charges = 2
	currency_label.text = str(GameState.currency)
	_update_bucket_ui()
	_update_item_ui()

func _on_collar_buy() -> void:
	if GameState.currency >= PRICE_COLLAR and not GameState.has_collar:
		GameState.currency -= PRICE_COLLAR
		GameState.has_collar = true
	currency_label.text = str(GameState.currency)
	_update_bucket_ui()
	_update_item_ui()

func _on_infinit_buy() -> void:
	_buy_item("infinit", INFINIT_ICON, PRICE_INFINIT)

func _on_tube_buy() -> void:
	_buy_item("tube", TUBE_ICON, PRICE_TUBE)

func _on_clone_buy() -> void:
	_buy_item("clone", CLONE_ICON, PRICE_CLONE)

func _on_rewind_buy() -> void:
	_buy_item("rewind", REWIND_ICON, PRICE_REWIND)

func _on_continue() -> void:
	if not _collected:
		GameState.currency += GameState.last_floor_hp
		_collected = true
	if GameState.current_floor >= 3:
		GameState.current_floor = 1
		GameState.has_bucket = false
		GameState.has_collar = false
		GameState.currency = 0
		StyleManager.reset_score()
		get_tree().change_scene_to_file("res://Scenes/MainMenu/MainMenu.tscn")
	else:
		GameState.current_floor += 1
		get_tree().change_scene_to_file("res://Scenes/Game/game.tscn")
