extends Control

@onready var hearts_container = $HeartsContainer

# Функция, которая будет вызываться при получении урона
func update_hearts(current_health: int):
	# Получаем актуальный массив оставшихся сердечек в контейнере
	var hearts = hearts_container.get_children()
	
	# Считаем, сколько сердец сейчас на экране лишние
	# Например: было 3 сердца, а текущее здоровье стало 2. Значит лишнее = 1 сердце.
	var hearts_to_remove = hearts.size() - current_health
	
	# Если есть лишние сердца, удаляем их с конца списка
	for i in range(hearts_to_remove):
		# Берём самое последнее сердечко (крайнее правое)
		var last_heart = hearts[hearts.size() - 1 - i]
		
		# Удаляем его из игры
		last_heart.queue_free()
