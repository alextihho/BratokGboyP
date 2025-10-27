# random_events.gd (ИСПРАВЛЕНО - СОБЫТИЯ РАБОТАЮТ!)
extends Node

signal event_triggered(event_type: String, event_data: Dictionary)

var player_stats
var items_db

func _ready():
	player_stats = get_node_or_null("/root/PlayerStats")
	items_db = get_node_or_null("/root/ItemsDB")
	print("🎲 Система случайных событий загружена")

# ✅ ИСПРАВЛЕНО: Увеличен шанс событий
func trigger_random_event(location: String, player_data: Dictionary, main_node: Node) -> bool:
	"""
	Триггерит случайное событие в локации
	Возвращает true если событие произошло
	"""
	var event_chance = randf()
	var chance_threshold = get_location_danger(location)
	
	print("🎲 Проверка события в %s: %.2f vs %.2f" % [location, event_chance, chance_threshold])
	
	if event_chance > chance_threshold:
		print("   ❌ Событие не произошло")
		return false
	
	var event_type = choose_event_type(location)
	print("   ✅ Событие: %s" % event_type)
	
	match event_type:
		"combat":
			start_combat_event(location, player_data, main_node)
			return true
		"find_item":
			find_item_event(player_data, main_node)
			return true
		"find_money":
			find_money_event(player_data, main_node)
			return true
		"meet_npc":
			meet_npc_event(location, player_data, main_node)
			return true
	
	return false

# ✅ ИСПРАВЛЕНО: Увеличены шансы событий (меньше = больше событий)
func get_location_danger(location: String) -> float:
	"""Возвращает порог вероятности события (чем ниже - тем больше событий)"""
	match location:
		"ОБЩЕЖИТИЕ":
			return 0.70  # Было 0.95 -> 30% событий вместо 5%
		"ЛАРЁК":
			return 0.60  # Было 0.90 -> 40% событий
		"ГАРАЖ":
			return 0.55  # Было 0.85 -> 45% событий
		"РЫНОК":
			return 0.50  # Было 0.80 -> 50% событий
		"ВОКЗАЛ":
			return 0.45  # Было 0.75 -> 55% событий
		"УЛИЦА":
			return 0.40  # Было 0.70 -> 60% событий
		"ПОРТ":
			return 0.30  # Было 0.60 -> 70% событий
		"БОЛЬНИЦА":
			return 0.65
		"ФСБ":
			return 0.80  # Почти нет событий
		"БАР":
			return 0.50
		"АВТОСАЛОН":
			return 0.60
		_:
			return 0.55

func choose_event_type(location: String) -> String:
	"""Выбирает тип события в зависимости от локации"""
	var roll = randf()
	
	match location:
		"УЛИЦА":
			if roll < 0.4:
				return "combat"
			elif roll < 0.6:
				return "meet_npc"
			elif roll < 0.8:
				return "find_money"
			else:
				return "find_item"
		
		"ПОРТ":
			if roll < 0.5:
				return "combat"
			elif roll < 0.7:
				return "find_item"
			else:
				return "meet_npc"
		
		"ВОКЗАЛ":
			if roll < 0.3:
				return "combat"
			elif roll < 0.6:
				return "meet_npc"
			else:
				return "find_money"
		
		"РЫНОК":
			if roll < 0.2:
				return "combat"
			elif roll < 0.5:
				return "meet_npc"
			elif roll < 0.8:
				return "find_item"
			else:
				return "find_money"
		
		"БАР":
			if roll < 0.4:
				return "meet_npc"
			elif roll < 0.6:
				return "combat"
			else:
				return "find_money"
		
		_:
			if roll < 0.3:
				return "find_money"
			elif roll < 0.6:
				return "meet_npc"
			else:
				return "find_item"

func start_combat_event(location: String, player_data: Dictionary, main_node: Node):
	"""Запускает боевое событие"""
	var enemy_type = choose_enemy_type(location)
	
	var enemy_names = {
		"gopnik": "Гопник",
		"drunkard": "Пьяный",
		"thug": "Хулиган",
		"bandit": "Бандит",
		"guard": "Охранник",
		"boss": "Главарь"
	}
	
	main_node.show_message("⚠️ " + enemy_names.get(enemy_type, "Противник") + " хочет подраться!")
	
	await main_node.get_tree().create_timer(1.5).timeout
	
	# Используем battle_manager
	if main_node.battle_manager:
		main_node.battle_manager.start_battle(main_node, enemy_type, false)
	else:
		print("❌ Battle manager не найден!")

func choose_enemy_type(location: String) -> String:
	"""Выбирает тип врага в зависимости от локации"""
	var roll = randf()
	
	match location:
		"УЛИЦА":
			if roll < 0.5:
				return "gopnik"
			elif roll < 0.8:
				return "thug"
			else:
				return "drunkard"
		
		"ПОРТ":
			if roll < 0.4:
				return "bandit"
			elif roll < 0.7:
				return "thug"
			else:
				return "guard"
		
		"ВОКЗАЛ":
			if roll < 0.6:
				return "gopnik"
			else:
				return "thug"
		
		"РЫНОК":
			if roll < 0.6:
				return "gopnik"
			elif roll < 0.9:
				return "thug"
			else:
				return "drunkard"
		
		"БАР":
			if roll < 0.5:
				return "drunkard"
			else:
				return "gopnik"
		
		_:
			if roll < 0.7:
				return "gopnik"
			else:
				return "thug"

func find_item_event(player_data: Dictionary, main_node: Node):
	"""Событие находки предмета"""
	var possible_items = [
		"Булка", "Сигареты", "Пиво", "Продукты", "Чипсы"
	]
	
	var luck = player_stats.get_stat("LCK") if player_stats else 1
	var rare_chance = 0.15 + luck * 0.03  # Увеличен шанс редких предметов
	
	var found_item = ""
	
	if randf() < rare_chance:
		var rare_items = ["Кожанка", "Бита", "Отмычка", "Аптечка", "Кепка"]
		found_item = rare_items[randi() % rare_items.size()]
		main_node.show_message("✨ Редкая находка: " + found_item + "!")
	else:
		found_item = possible_items[randi() % possible_items.size()]
		main_node.show_message("🔍 Нашли: " + found_item)
	
	player_data["inventory"].append(found_item)
	
	if player_stats:
		player_stats.add_stat_xp("LCK", 5)
	
	emit_signal("event_triggered", "find_item", {"item": found_item})

func find_money_event(player_data: Dictionary, main_node: Node):
	"""Событие находки денег"""
	var luck = player_stats.get_stat("LCK") if player_stats else 1
	var base_amount = randi_range(20, 80)  # Увеличено с 10-50
	var amount = base_amount + luck * 10  # Увеличен бонус от удачи
	
	player_data["balance"] += amount
	main_node.show_message("💰 Нашли " + str(amount) + " руб.!")
	main_node.update_ui()
	
	if player_stats:
		player_stats.add_stat_xp("LCK", 3)
	
	emit_signal("event_triggered", "find_money", {"amount": amount})

func meet_npc_event(location: String, player_data: Dictionary, main_node: Node):
	"""Событие встречи с NPC"""
	var dialogues = get_location_dialogues(location)
	var dialogue = dialogues[randi() % dialogues.size()]
	
	main_node.show_message("💬 " + dialogue)
	
	emit_signal("event_triggered", "meet_npc", {"dialogue": dialogue})

func get_location_dialogues(location: String) -> Array:
	"""Возвращает массив возможных диалогов для локации"""
	match location:
		"УЛИЦА":
			return [
				"Прохожий: 'Эй, не найдётся пары рублей?'",
				"Старик: 'Молодёжь пошла не та...'",
				"Кент: 'Слышал, на порту движуха...'",
				"Девушка: 'Извините, где вокзал?'",
				"Подросток: 'У тебя сигареты есть?'",
				"Бомж: 'Ваще всё плохо стало...'",
				"Братан: 'Земляк, ты откуда?'"
			]
		
		"ВОКЗАЛ":
			return [
				"Контакт: 'Ищешь работу? Есть дельце...'",
				"Мент: 'Документы есть?'",
				"Барыга: 'Качественный товар!'",
				"Цыганка: 'Погадать, красавчик?'",
				"Проводник: 'Поезд через 5 минут!'",
				"Пассажир: 'Какой хаос на вокзале...'"
			]
		
		"РЫНОК":
			return [
				"Торговец: 'Гляди, какой товар!'",
				"Бабка: 'Купи огурчиков!'",
				"Братан: 'Помоги с грузом...'",
				"Продавец: 'Свежее мясо!'",
				"Покупатель: 'Цены кусаются...'",
				"Охранник: 'Не воруй, щас поймаю!'"
			]
		
		"ПОРТ":
			return [
				"Грузчик: 'Порт - не место для прогулок'",
				"Шёпот: 'Интересуешься оружием?'",
				"Охранник: 'Чего тут шляешься?'",
				"Моряк: 'Море зовёт...'",
				"Контрабандист: 'Есть интересное дельце...'",
				"Рабочий: 'Грузы не сами себя таскают!'"
			]
		
		"БАР":
			return [
				"Бармен: 'Что будешь?'",
				"Пьяница: 'Налей ещё!'",
				"Братан: 'За встречу!'",
				"Девушка: 'Угостишь?'",
				"Охранник: 'Спокойно, пацаны!'",
				"Кент: 'Слышал новости?'"
			]
		
		"ГАРАЖ":
			return [
				"Механик: 'Машина хреновая совсем...'",
				"Парень: 'Помоги открутить?'",
				"Автолюбитель: 'Движок не тянет...'",
				"Мастер: 'Золотые руки нужны!'",
				"Водитель: 'Запчасти дорогие стали...'"
			]
		
		"АВТОСАЛОН":
			return [
				"Продавец: 'Смотри какая красота!'",
				"Клиент: 'Дорого всё...'",
				"Менеджер: 'Могу скидку сделать!'",
				"Механик: 'Машина огонь!'",
				"Покупатель: 'Тачка мечты!'"
			]
		
		_:
			return [
				"Незнакомец кивает",
				"Кто-то проходит мимо",
				"Тихо вокруг...",
				"Ничего интересного"
			]
