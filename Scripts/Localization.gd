extends Node
class_name Localization

const TEXT := {
	"play": {"en": "Play", "ru": "Играть"},
	"settings": {"en": "Settings", "ru": "Настройки"},
	"exit": {"en": "Exit", "ru": "Выйти"},
	"dark_mode": {"en": "Dark Mode", "ru": "Тёмный режим"},
	"achievements": {"en": "Achievements", "ru": "Достижения"},
	"achievement_completed_name": {"en": "Thanks for Playing", "ru": "Спасибо за игру"},
	"achievement_completed_desc": {"en": "Complete the game", "ru": "Пройдите игру"},
	"achievement_perfect_name": {"en": "Perfect Run", "ru": "Идеальное прохождение"},
	"achievement_perfect_desc": {"en": "Complete the game without taking damage", "ru": "Пройдите игру, не получив урона"},
	"achievement_dark_name": {"en": "Hope for a Bright Future", "ru": "Надежда на светлое будущее"},
	"achievement_dark_desc": {"en": "Complete the game in dark mode", "ru": "Пройдите игру в тёмном режиме"},
	"achievement_dark_perfect_name": {"en": "That Was Easy", "ru": "Это было легко"},
	"achievement_dark_perfect_desc": {"en": "Complete the game in dark mode without taking damage", "ru": "Пройдите игру в тёмном режиме без урона"},
	"close": {"en": "Close", "ru": "Закрыть"},
	"back": {"en": "Back", "ru": "Назад"},
	"continue": {"en": "Continue", "ru": "Продолжить"},
	"restart": {"en": "Restart", "ru": "Заново"},
	"main_menu": {"en": "Main Menu", "ru": "Главное меню"},
	"pause": {"en": "PAUSE", "ru": "ПАУЗА"},
	"master_volume": {"en": "Master Volume", "ru": "Общая громкость"},
	"music_volume": {"en": "Music Volume", "ru": "Громкость музыки"},
	"effects_volume": {"en": "Effects Volume", "ru": "Громкость эффектов"},
	"show_fps": {"en": "Show FPS", "ru": "Показывать FPS"},
	"mobile_controls": {"en": "Mobile Controls", "ru": "Мобильное управление"},
	"fullscreen": {"en": "Fullscreen", "ru": "Полный экран"},
	"language": {"en": "Language", "ru": "Язык"},
	"between_floors": {"en": "BETWEEN FLOORS", "ru": "МЕЖДУ ЭТАЖАМИ"},
	"collect_coins": {"en": "COLLECT COINS", "ru": "СОБРАТЬ МОНЕТЫ"},
	"shop": {"en": "SHOP", "ru": "МАГАЗИН"},
	"purchased": {"en": "Purchased", "ru": "Куплено"},
	"slot": {"en": "Slot %d", "ru": "Ячейка %d"},
	"buy_item": {"en": "Buy %s (%d coins)", "ru": "Купить: %s (%d мон.)"},
	"charges": {"en": "%s (%d charges)", "ru": "%s (%d заряд.)"},
	"time": {"en": "Time: %02d:%02d", "ru": "Время: %02d:%02d"},
	"floor": {"en": "Floor %d", "ru": "Этаж %d"},
	"activate_three": {"en": "Activate 3 levers", "ru": "Активируйте 3 рычага"},
	"activate_two": {"en": "Activate 2 levers", "ru": "Активируйте 2 рычага"},
	"find_second": {"en": "Find the second lever", "ru": "Найдите второй рычаг"},
	"go_elevator": {"en": "Go to the elevator", "ru": "Идите к лифту"},
	"reach_elevator": {"en": "Reach the other elevator", "ru": "Доберитесь до другого лифта"},
	"light_fades": {"en": "The light fades...", "ru": "Свет угасает..."},
	"attempt": {"en": "Attempt #%d on floor %d", "ru": "Попытка №%d на этаже %d"},
	"item_acquired": {"en": "Item acquired", "ru": "Предмет получен"},
	"item_bucket": {"en": "Bucket", "ru": "Ведро"},
	"item_collar": {"en": "Collar", "ru": "Ошейник"},
	"item_tube": {"en": "Tube", "ru": "Труба"},
	"item_clone": {"en": "Clone", "ru": "Клон"},
	"item_infinit": {"en": "Infinit", "ru": "Бесконечность"},
	"item_rewind": {"en": "Rewind", "ru": "Перемотка"},
	"item_bucket_desc": {"en": "Blocks the next 2 hits. Cannot be used together with the Collar.", "ru": "Блокирует следующие 2 удара. Нельзя использовать вместе с ошейником."},
	"item_collar_desc": {"en": "After taking damage, grants brief invulnerability. Activates 3 times, then breaks. Cannot be used together with the Bucket.", "ru": "После получения урона ненадолго даёт неуязвимость. Срабатывает 3 раза, затем разрушается. Нельзя использовать вместе с ведром."},
	"item_tube_desc": {"en": "Creates a gust that pushes nearby enemies away and destroys projectiles.", "ru": "Создаёт поток воздуха, отталкивающий ближайших врагов и разрушающий снаряды."},
	"item_clone_desc": {"en": "Creates a decoy that distracts enemies and makes you invisible.", "ru": "Создаёт приманку, отвлекающую врагов, и делает игрока невидимым."},
	"item_infinit_desc": {"en": "Revives you once after death, but permanently reduces maximum health.", "ru": "Один раз воскрешает после смерти, но навсегда уменьшает максимум здоровья."},
	"item_rewind_desc": {"en": "Returns you to your recent position and restores your saved health.", "ru": "Возвращает на недавнюю позицию и восстанавливает сохранённое здоровье."},
	"credits_story": {"en": "Our main hero, despite all the hardships,\nmanaged to reach the top of the skyscraper\nand, with the power of his lamp, illuminate\nthe entire frightened city shrouded in darkness.\n\nThe light that enveloped the city became a new hope\nfor a brighter future for all humankind.", "ru": "Наш главный герой, несмотря на все сложности,\nсмог добраться до вершины небоскрёба\nи силой своей лампы осветить весь этот\nнапуганный, погружённый во тьму город.\n\nСвет, окутавший город, стал новой надеждой\nна светлое будущее для всего человечества."},
	"credits_thanks": {"en": "Thank you for playing\n♥", "ru": "Спасибо за игру\n♥"},
	"credits_names": {"en": "Game developers:\nDimazan\nFFost\n\nSpecial thanks:\nCHUMNOi", "ru": "Разработчики игры:\nDimazan\nFFost\n\nОсобая благодарность:\nCHUMNOi"},
}

var _last_scene_id := 0

static func t(key: String, args: Array = []) -> String:
	var entry: Dictionary = TEXT.get(key, {})
	var value: String = entry.get(GameState.language, entry.get("en", key))
	return value % args if not args.is_empty() else value

static func item_name(item_id: String) -> String:
	return t("item_" + item_id)

static func item_description(item_id: String) -> String:
	return t("item_" + item_id + "_desc")

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene and scene.get_instance_id() != _last_scene_id:
		_last_scene_id = scene.get_instance_id()
		call_deferred("_apply_scene", scene)

func _apply_scene(scene: Node) -> void:
	apply_to_tree(scene)

static func apply_to_tree(node: Node) -> void:
	if node is Label:
		var label := node as Label
		if not label.text.is_empty():
			label.text = _translate_existing(label.text)
	elif node is CheckBox:
		var checkbox := node as CheckBox
		if not checkbox.text.is_empty():
			checkbox.text = _translate_existing(checkbox.text)
	elif node is Button:
		var button := node as Button
		if not button.text.is_empty():
			button.text = _translate_existing(button.text)
	for child in node.get_children():
		apply_to_tree(child)

static func _translate_existing(value: String) -> String:
	if value == "DarkMode":
		return t("dark_mode")
	for key in TEXT:
		var entry: Dictionary = TEXT[key]
		if value == entry.get("en", "") or value == entry.get("ru", ""):
			return t(key)
	return value
