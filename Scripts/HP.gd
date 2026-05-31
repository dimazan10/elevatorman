extends Control

@onready var hearts_container = $HeartsContainer

# ЭТОГО БЛОКА НЕ ХВАТАЛО:
func _ready() -> void:
	# Ждем загрузки сцены
	await get_tree().process_frame
	
	# Ищем игрока по группе
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		# Связываем сигнал игрока с твоей функцией update_hearts
		player.health_changed.connect(update_hearts)
		print("Твой прошлый код успешно подключен!")

# Твоя функция (остается без изменений)
func update_hearts(current_health: int):
	var hearts = hearts_container.get_children()
	var hearts_to_remove = hearts.size() - current_health
	
	for i in range(hearts_to_remove):
		var last_heart = hearts[hearts.size() - 1 - i]
		last_heart.queue_free()
