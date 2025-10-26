extends Node

signal building_action_completed(location: String, action_index: int)

var items_db
var current_building_menu = null

func _ready():
	items_db = get_node("/root/ItemsDB")

# Обработка действия в здании
func handle_building_action(location: String, action_index: int, player_data: Dictionary, main_node: Node):
	print("🏢 Действие в " + location + ", индекс: " + str(action_index))
	
	# ✅ ДОБАВЛЕНО: Получаем системы времени и полиции
	var time_system = get_node_or_null("/root/TimeSystem")
	var police_system = get_node_or_null("/root/PoliceSystem")
	
	match location:
		"ЛАРЁК":
			handle_kiosk_action(action_index, player_data, main_node, time_system, police_system)
		"ГАРАЖ":
			handle_garage_action(action_index, player_data, main_node, time_system, police_system)
		"РЫНОК":
			handle_market_action(action_index, player_data, main_node, time_system, police_system)
		"ПОРТ":
			handle_port_action(action_index, player_data, main_node, time_system, police_system)
		"ОБЩЕЖИТИЕ":
			handle_dorm_action(action_index, player_data, main_node, time_system, police_system)
		"УЛИЦА":
			handle_street_action(action_index, player_data, main_node, time_system, police_system)
		"ВОКЗАЛ":
			handle_station_action(action_index, player_data, main_node, time_system, police_system)
	
	building_action_completed.emit(location, action_index)

# ЛАРЁК
func handle_kiosk_action(action_index: int, player_data: Dictionary, main_node: Node, time_system, police_system):
	match action_index:
		0: # Купить пиво (30р)
			buy_item("Пиво", player_data, main_node)
			if time_system:
				time_system.add_minutes(5)  # ✅ Быстрая покупка
		1: # Купить сигареты (15р)
			buy_item("Сигареты", player_data, main_node)
			if time_system:
				time_system.add_minutes(3)
		2: # Купить кепку (50р)
			buy_item("Кепка", player_data, main_node)
			if time_system:
				time_system.add_minutes(10)

# ГАРАЖ
func handle_garage_action(action_index: int, player_data: Dictionary, main_node: Node, time_system, police_system):
	match action_index:
		0: # Купить биту (100р)
			buy_item("Бита", player_data, main_node)
			if time_system:
				time_system.add_minutes(10)
		1: # Помочь механику
			if "Пиво" in player_data["inventory"]:
				player_data["inventory"].erase("Пиво")
				player_data["balance"] += 100
				player_data["reputation"] += 5
				main_node.show_message("Помогли механику! +100 руб., +5 репутации")
				main_node.update_ui()
				
				# Прокачка силы и вождения за ремонт
				var stats_system = get_node("/root/PlayerStats")
				if stats_system:
					stats_system.add_stat_xp("STR", 10)
					stats_system.add_stat_xp("DRV", 5)
				
				# ✅ Работа в гараже занимает время
				if time_system:
					time_system.add_minutes(45)
			else:
				main_node.show_message("Механик: 'Принеси пивка!'")
		2: # Взять инструменты
			player_data["inventory"].append("Инструменты")
			main_node.show_message("Взяли инструменты из гаража")
			
			# Попытка взлома замка на ящике
			var stats_system = get_node("/root/PlayerStats")
			if stats_system and "Отмычка" in player_data["inventory"]:
				var lockpick_chance = stats_system.calculate_lockpick_chance(0.2)
				if randf() < lockpick_chance:
					player_data["balance"] += 50
					stats_system.on_lockpick_attempt(true)
					main_node.show_message("🔓 Взломали ящик! Нашли 50 руб.")
				else:
					stats_system.on_lockpick_attempt(false)
					main_node.show_message("🔒 Не удалось взломать замок")
			
			# ✅ Взлом занимает время
			if time_system:
				time_system.add_minutes(15)

# РЫНОК
func handle_market_action(action_index: int, player_data: Dictionary, main_node: Node, time_system, police_system):
	match action_index:
		0: # Купить кожанку (200р)
			buy_item("Кожанка", player_data, main_node)
			if time_system:
				time_system.add_minutes(15)
		1: # Продать вещь
			if player_data["inventory"].size() > 0:
				show_sell_menu(player_data, main_node)
				if time_system:
					time_system.add_minutes(20)
			else:
				main_node.show_message("Рюкзак пуст, нечего продавать")
		2: # Узнать новости
			var news = [
				"Говорят, на порту можно достать ствол...",
				"Слышал, механику в гараже нужна помощь",
				"На вокзале кто-то ищет курьера",
				"В городе появились новые люди"
			]
			main_node.show_message(news[randi() % news.size()])
			
			# Шанс украсть что-то незаметно при посещении рынка
			var player_stats = get_node("/root/PlayerStats")
			if player_stats and randf() < 0.3:  # 30% шанс
				var stealth_check = randf()
				var detection_chance = 0.5 - player_stats.get_stat("STEALTH") * 0.05
				
				if stealth_check > detection_chance:
					var stolen_items = ["Продукты", "Сигареты", "Булка"]
					var stolen = stolen_items[randi() % stolen_items.size()]
					player_data["inventory"].append(stolen)
					player_stats.on_theft_attempt(false, 25)
					main_node.show_message("🥷 Незаметно украли: " + stolen)
				else:
					player_stats.on_theft_attempt(true, 0)
					# ✅ ДОБАВЛЕНО: Повышаем УА если заметили
					if police_system:
						police_system.on_theft(25)
					main_node.show_message("⚠️ Чуть не заметили при попытке воровства!")
			
			# ✅ Время на новости
			if time_system:
				time_system.add_minutes(10)

# ПОРТ
func handle_port_action(action_index: int, player_data: Dictionary, main_node: Node, time_system, police_system):
	match action_index:
		0: # Купить ПМ (500р)
			buy_item("ПМ", player_data, main_node)
			if time_system:
				time_system.add_minutes(20)
		1: # Купить отмычку (100р)
			buy_item("Отмычка", player_data, main_node)
			if time_system:
				time_system.add_minutes(15)
		2: # Уйти
			main_node.close_location_menu()
			
			# Шанс встретить контрабандистов (прокачка красноречия)
			var stats_system = get_node("/root/PlayerStats")
			if stats_system and randf() < 0.2:  # 20% шанс
				var cha = stats_system.get_stat("CHA")
				var persuasion_chance = 0.3 + cha * 0.05
				
				if randf() < persuasion_chance:
					player_data["balance"] += 50
					stats_system.on_persuasion_attempt(true)
					main_node.show_message("💬 Убедили контрабандистов поделиться (+50 руб)")
				else:
					stats_system.on_persuasion_attempt(false)
					main_node.show_message("💬 Не удалось договориться с контрабандистами")
			
			if time_system:
				time_system.add_minutes(5)

# ОБЩЕЖИТИЕ
func handle_dorm_action(action_index: int, player_data: Dictionary, main_node: Node, time_system, police_system):
	match action_index:
		0: # Отдохнуть
			var heal_amount = 30
			player_data["health"] = min(100, player_data["health"] + heal_amount)
			main_node.show_message("Хорошо отдохнули (+30 HP)")
			main_node.update_ui()
			if time_system:
				time_system.add_minutes(120)  # 2 часа отдыха
		1: # Поговорить с другом
			var dialogues = [
				"Друг: 'Как дела, братан?'",
				"Друг: 'Слышал, на рынке выгодно продают'",
				"Друг: 'Береги себя на улицах'",
				"Друг: 'Может, пива принесёшь?'"
			]
			main_node.show_message(dialogues[randi() % dialogues.size()])
			if time_system:
				time_system.add_minutes(30)
		2: # Взять вещи
			player_data["inventory"].append("Продукты")
			main_node.show_message("Взяли продукты из общаги")
			if time_system:
				time_system.add_minutes(5)

# УЛИЦА
func handle_street_action(action_index: int, player_data: Dictionary, main_node: Node, time_system, police_system):
	match action_index:
		0: # Прогуляться
			var events = [
				"Приятная прогулка по Твери",
				"Встретили бродячую собаку",
				"Нашли 10 рублей на земле!",
				"Погода отличная"
			]
			var event = randi() % events.size()
			if event == 2:
				player_data["balance"] += 10
				main_node.update_ui()
			main_node.show_message(events[event])
			if time_system:
				time_system.add_minutes(20)
		1: # Встретить знакомого
			main_node.show_message("Кент: 'Привет! Как жизнь?'")
			if time_system:
				time_system.add_minutes(15)
		2: # Посмотреть вокруг
			main_node.show_message("Вокруг много людей, шумный город")
			if time_system:
				time_system.add_minutes(5)

# ВОКЗАЛ
func handle_station_action(action_index: int, player_data: Dictionary, main_node: Node, time_system, police_system):
	match action_index:
		0: # Купить билет
			if player_data["balance"] >= 50:
				player_data["balance"] -= 50
				main_node.show_message("Купили билет на поезд (50 руб.)")
				main_node.update_ui()
			else:
				main_node.show_message("Не хватает денег! Нужно 50 руб.")
			if time_system:
				time_system.add_minutes(10)
		1: # Встретить контакт
			var contacts = [
				"Контакт не появился...",
				"Незнакомец: 'Ищешь работу?'",
				"Контакт передал записку"
			]
			main_node.show_message(contacts[randi() % contacts.size()])
			if time_system:
				time_system.add_minutes(30)
		2: # Осмотреться
			main_node.show_message("Много людей спешат на поезда")
			if time_system:
				time_system.add_minutes(5)

# Покупка предмета
func buy_item(item_name: String, player_data: Dictionary, main_node: Node):
	var item_data = items_db.get_item(item_name)
	if not item_data:
		main_node.show_message("❌ Предмет не найден!")
		return
	
	var price = item_data["price"]
	
	if player_data["balance"] >= price:
		player_data["balance"] -= price
		player_data["inventory"].append(item_name)
		main_node.show_message("✅ Куплено: " + item_name + " за " + str(price) + " руб.")
		main_node.update_ui()
	else:
		main_node.show_message("❌ Не хватает денег! Нужно: " + str(price) + " руб.")

# Меню продажи
func show_sell_menu(player_data: Dictionary, main_node: Node):
	var sell_menu = CanvasLayer.new()
	sell_menu.layer = 25  # ✅ Выше сетки (1)
	sell_menu.name = "SellMenu"
	main_node.add_child(sell_menu)
	
	var bg = ColorRect.new()
	bg.size = Vector2(500, 700)
	bg.position = Vector2(110, 290)
	bg.color = Color(0.05, 0.05, 0.05, 0.95)
	sell_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "ЧТО ПРОДАТЬ?"
	title.position = Vector2(280, 310)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	sell_menu.add_child(title)
	
	var y_pos = 360
	for i in range(player_data["inventory"].size()):
		var item = player_data["inventory"][i]
		var item_data = items_db.get_item(item)
		var sell_price = item_data["price"] / 2 if item_data else 5
		
		var item_btn = Button.new()
		item_btn.custom_minimum_size = Vector2(460, 45)
		item_btn.position = Vector2(130, y_pos)
		item_btn.text = item + " — продать за " + str(sell_price) + " руб."
		
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.2, 0.25, 0.2, 1.0)
		item_btn.add_theme_stylebox_override("normal", style_normal)
		
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.3, 0.35, 0.3, 1.0)
		item_btn.add_theme_stylebox_override("hover", style_hover)
		
		item_btn.add_theme_font_size_override("font_size", 16)
		item_btn.add_theme_color_override("font_color", Color.WHITE)
		
		var item_to_sell = item
		item_btn.pressed.connect(func(): 
			sell_item(item_to_sell, player_data, main_node)
			sell_menu.queue_free()
		)
		
		sell_menu.add_child(item_btn)
		y_pos += 55
	
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(460, 50)
	close_btn.position = Vector2(130, 920)
	close_btn.text = "ОТМЕНА"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	
	close_btn.pressed.connect(func(): sell_menu.queue_free())
	
	sell_menu.add_child(close_btn)

# Продажа предмета
func sell_item(item_name: String, player_data: Dictionary, main_node: Node):
	if item_name not in player_data["inventory"]:
		return
	
	var item_data = items_db.get_item(item_name)
	var sell_price = item_data["price"] / 2 if item_data else 5
	
	player_data["inventory"].erase(item_name)
	player_data["balance"] += sell_price
	
	main_node.show_message("💰 Продано: " + item_name + " за " + str(sell_price) + " руб.")
	main_node.update_ui()
