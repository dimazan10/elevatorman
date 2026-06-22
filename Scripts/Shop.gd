extends Control

@onready var time_label := $VBox/TimeLabel
@onready var hp_label := $VBox/HPLabel
@onready var currency_label := $VBox/CurrencyLabel
@onready var bucket_btn := $VBox/BucketBuy
@onready var continue_btn := $VBox/ContinueBtn
@onready var bucket_status := $VBox/BucketStatus

func _ready() -> void:
	var t = GameState.last_floor_time
	var m = int(t) / 60
	var s = int(t) % 60
	time_label.text = "Время: %02d:%02d" % [m, s]
	hp_label.text = "Сохранено HP: %d (+%d монет)" % [GameState.last_floor_hp, GameState.last_floor_hp]
	currency_label.text = "Монет: %d" % GameState.currency
	_update_bucket_ui()

func _update_bucket_ui() -> void:
	if GameState.has_bucket:
		bucket_btn.disabled = true
		bucket_btn.text = "Куплено"
		bucket_status.text = "Ведро (%d зар." % GameState.bucket_charges + ")"
	else:
		bucket_btn.disabled = GameState.currency < 3
		bucket_btn.text = "Купить ведро (3 монеты)"
		bucket_status.text = ""

func _on_bucket_buy() -> void:
	if GameState.currency >= 3 and not GameState.has_bucket:
		GameState.currency -= 3
		GameState.has_bucket = true
		GameState.bucket_charges = 3
		currency_label.text = "Монет: %d" % GameState.currency
		_update_bucket_ui()

func _on_continue() -> void:
	if GameState.current_floor >= 3:
		GameState.current_floor = 1
		GameState.has_bucket = false
		GameState.currency = 0
		StyleManager.reset_score()
		get_tree().change_scene_to_file("res://Scenes/MainMenu/MainMenu.tscn")
	else:
		GameState.current_floor += 1
		get_tree().reload_current_scene()
