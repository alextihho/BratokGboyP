# main.gd (ОБНОВЛЕНО - логи, кнопка денег, автозапуск квестов, прокачка от движения)
extends Node2D

# ===== КОМПОНЕНТЫ =====
var game_initializer
var input_handler

# ===== МЕНЕДЖЕРЫ =====
var map_manager
var ui_controller
var action_handler
var menu_manager
var clicker_system
var districts_menu_manager
var battle_manager
var grid_movement_manager

# ===== СИСТЕМЫ (AUTOLOAD) =====
var items_db
var building_system
var player_stats
var quest_system
var random_events
var inventory_manager
var gang_manager
var save_manager
var districts_system
var simple_jobs
var hospital_system
var time_system
var log_system  # ✅ НОВОЕ: Система логов

# ===== ИГРОВЫЕ СИСТЕМЫ =====
var grid_system
var movement_system

# ===== СОСТОЯНИЕ ИГРЫ =====
var current_location = null
var menu_open = false
var first_battle_started = false

# ===== ДАННЫЕ ЛОКАЦИЙ =====
var locations = {
	"ОБЩЕЖИТИЕ": {"position": Vector2(500, 200), "actions": ["Отдохнуть", "Поговорить с другом", "Взять вещи"], "grid_square": "6_2"},
	"ЛАРЁК": {"position": Vector2(200, 350), "actions": ["Купить пиво (30р)", "Купить сигареты (15р)", "Купить кепку (50р)"], "grid_square": "2_4"},
	"ВОКЗАЛ": {"position": Vector2(100, 150), "actions": ["Купить билет", "Встретить контакт", "Осмотреться"], "grid_square": "1_1"},
	"ГАРАЖ": {"position": Vector2(550, 650), "actions": ["Купить биту (100р)", "Помочь механику", "Взять инструменты"], "grid_square": "9_8"},
	"РЫНОК": {"position": Vector2(300, 850), "actions": ["Купить кожанку (200р)", "Продать вещь", "Узнать новости"], "grid_square": "5_10"},
	"ПОРТ": {"position": Vector2(600, 450), "actions": ["Купить ПМ (500р)", "Купить отмычку (100р)", "Уйти"], "grid_square": "10_5"},
	"УЛИЦА": {"position": Vector2(150, 1050), "actions": ["Прогуляться", "Встретить знакомого", "Посмотреть вокруг"], "grid_square": "2_13"},
	"БОЛЬНИЦА": {"position": Vector2(400, 500), "actions": ["Лечиться", "Купить аптечку (100р)", "Уйти"], "grid_square": "6_6"},
	"ФСБ": {"position": Vector2(350, 300), "actions": ["💰 Дать взятку", "🚪 Уйти"], "grid_square": "5_3"},
	"БАР": {"position": Vector2(420, 540), "actions": ["Отдохнуть", "Бухать с бандой", "Уйти"], "grid_square": "7_7"},
	"АВТОСАЛОН": {"position": Vector2(180, 540), "actions": ["Выбор машины", "Починить машину", "Уйти"], "grid_square": "3_7"}
}

# ===== ДАННЫЕ ИГРОКА =====
var player_data = {
	"balance": 150,
	"health": 100,
	"reputation": 0,
	"completed_quests": [],
	"equipment": {"helmet": null, "armor": null, "melee": null, "ranged": null, "gadget": null, "car": null},  # ✅ Добавлен слот car
	"inventory": ["Пачка сигарет", "Булка", "Нож"],
	"pockets": [null, null, null],
	"current_square": "6_2",
	"first_battle_completed": false,
	"car": null,
	"car_condition": 100.0,
	"car_equipped": false,  # ✅ НОВОЕ: Надета ли машина
	"current_driver": null  # ✅ НОВОЕ: Индекс водителя в gang_members
}

# ===== ДАННЫЕ БАНДЫ =====
var gang_members = [
	{
		"name": "Главный (ты)",
		"health": 100,
		"strength": 10,
		"equipment": {"helmet": null, "armor": null, "melee": null, "ranged": null, "gadget": null, "car": null},  # ✅ Добавлен слот car
		"inventory": [],
		"pockets": [null, null, null],
		"is_active": true
	}
]

func _ready():
	# Загружаем компоненты
	game_initializer = preload("res://scripts/core/game_initializer.gd").new()
	input_handler = preload("res://scripts/core/input_handler.gd").new()
	
	# Инициализация
	game_initializer.load_autoload_systems(self)
	
	# ✅ НОВОЕ: Инициализация системы логов
	log_system = get_node_or_null("/root/LogSystem")
	if log_system:
		setup_log_window()
		log_system.add_log("🎮 Игра началась!", "event")
	
	game_initializer.setup_grid_and_movement(self)
	game_initializer.initialize_managers(self)
	game_initializer.setup_game_systems(self)
	game_initializer.connect_signals(self)
	
	# ✅ НОВОЕ: Подключаем сигнал повышения уровня к логам
	if player_stats and log_system:
		player_stats.stat_leveled_up.connect(_on_stat_leveled_up)
	
	show_intro_text()
	
	# ✅ НОВОЕ: Запускаем начальные квесты
	start_initial_quests()
	
	print("✅ Игра готова! (С ЛОГАМИ)")

# ✅ ИСПРАВЛЕНО: Настройка окна логов (теперь работает!)
func setup_log_window():
	"""Создает окно логов внизу экрана"""
	print("🔧 setup_log_window вызвана")
	
	# Удаляем старое окно если есть
	var old_container = get_node_or_null("LogContainer")
	if old_container:
		print("   Удаляем старый LogContainer")
		old_container.queue_free()
		await get_tree().process_frame
	
	var log_container = CanvasLayer.new()
	log_container.name = "LogContainer"
	log_container.layer = 5
	add_child(log_container)
	print("   LogContainer создан")
	
	# Фон для логов
	var log_bg = ColorRect.new()
	log_bg.size = Vector2(420, 230)
	log_bg.position = Vector2(290, 900)
	log_bg.color = Color(0.08, 0.08, 0.08, 0.95)
	log_bg.name = "LogBG"
	log_container.add_child(log_bg)
	
	# Заголовок
	var log_title = Label.new()
	log_title.text = "📜 ЛОГИ СОБЫТИЙ"
	log_title.position = Vector2(345, 905)
	log_title.add_theme_font_size_override("font_size", 16)
	log_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	log_title.name = "LogTitle"
	log_container.add_child(log_title)
	
	# Контейнер для скролла
	var log_scroll = ScrollContainer.new()
	log_scroll.custom_minimum_size = Vector2(410, 180)
	log_scroll.position = Vector2(295, 935)
	log_scroll.name = "LogScroll"
	log_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	log_container.add_child(log_scroll)
	
	# VBox для логов
	var log_vbox = VBoxContainer.new()
	log_vbox.name = "LogVBox"
	log_vbox.custom_minimum_size = Vector2(390, 0)
	log_scroll.add_child(log_vbox)
	print("   UI создан")
	
	# ✅ КРИТИЧНО: Устанавливаем в систему логов
	if log_system:
		print("   Подключаем к LogSystem")
		log_system.set_display_node(log_scroll)
		
		# Даем время на инициализацию
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Тестовое сообщение
		log_system.add_log("✅ Окно логов работает!", "event")
		print("✅ Окно логов создано и подключено")
	else:
		print("⚠️ LogSystem не найдена!")

# ✅ НОВОЕ: Автозапуск начальных квестов
func start_initial_quests():
	"""Запускает начальные квесты при старте игры"""
	if not quest_system:
		print("⚠️ QuestSystem не найдена!")
		return
	
	print("📜 Запускаем начальные квесты")
	
	# Запускаем квесты
	quest_system.start_quest("first_money")
	quest_system.start_quest("first_fight")
	quest_system.start_quest("visit_locations")
	
	if log_system:
		log_system.add_quest_log("📋 Получены начальные квесты")
	
	print("📜 Начальные квесты запущены")

# ✅ НОВОЕ: Обработчик повышения уровня для логов
func _on_stat_leveled_up(stat_name: String, new_level: int):
	if log_system:
		log_system.add_level_up_log("⭐ %s → Ур.%d" % [stat_name, new_level])
	show_level_up_message(stat_name, new_level)

# ===== ОБРАБОТКА ВВОДА =====
func _unhandled_input(event):
	if input_handler.handle_input(event, self):
		get_viewport().set_input_as_handled()

# ===== МЕНЮ ЛОКАЦИЙ =====
func show_location_menu(location_name: String):
	current_location = location_name
	menu_open = true
	print("🏢 Открываем меню: " + location_name)
	
	# Логируем посещение
	if log_system:
		log_system.add_event_log("🏢 Посещение: " + location_name)
	
	# ✅ ИСПРАВЛЕНО: Триггерим случайное событие
	if random_events:
		print("🎲 Проверяем случайное событие")
		var event_happened = random_events.trigger_random_event(location_name, player_data, self)
		if event_happened:
			print("   ✅ Событие произошло!")
			if log_system:
				log_system.add_event_log("🎲 Случилось событие!")
	
	var old_menu = get_node_or_null("BuildingMenu")
	if old_menu:
		old_menu.queue_free()
		await get_tree().process_frame
	
	var building_menu_script = load("res://scripts/ui/building_menu.gd")
	var building_menu = building_menu_script.new()
	building_menu.name = "BuildingMenu"
	add_child(building_menu)
	
	var actions = locations[location_name]["actions"]
	building_menu.setup(location_name, actions)
	
	building_menu.action_selected.connect(func(action_index):
		handle_location_action(action_index)
	)
	
	building_menu.menu_closed.connect(func():
		close_location_menu()
	)

func handle_location_action(action_index: int):
	if current_location == null:
		return
	
	print("🎯 Действие %d в %s" % [action_index, current_location])
	
	action_handler.handle_location_action(current_location, action_index, self)
	
	# ✅ ИСПРАВЛЕНО: Добавляем время при действии
	if time_system:
		var time_cost = randi_range(5, 15)
		print("⏰ Добавляем %d минут" % time_cost)
		time_system.add_minutes(time_cost)
		
		# ✅ КРИТИЧНО: Обновляем UI времени
		call_deferred("update_time_ui")
		
		if log_system:
			log_system.add_movement_log("⏰ Прошло %d мин" % time_cost)
	
	# Логируем действие
	if log_system and current_location:
		var actions = locations[current_location]["actions"]
		if action_index < actions.size():
			log_system.add_event_log("🎯 " + actions[action_index])

func close_location_menu():
	var layer = get_node_or_null("BuildingMenu")
	if layer:
		layer.queue_free()
	menu_open = false
	current_location = null
	print("✅ Меню локации закрыто")

func on_location_clicked(location_name: String):
	show_location_menu(location_name)
	action_handler.trigger_location_events(location_name, self)

# ===== КНОПКИ НИЖНЕЙ ПАНЕЛИ =====
func on_bottom_button_pressed(button_name: String):
	match button_name:
		"Банда":
			if gang_manager:
				gang_manager.show_gang_menu(self, gang_members)
			elif menu_manager:
				menu_manager.show_gang_menu(self)
			else:
				show_message("❌ Система банды недоступна!")
				print("❌ GangManager и MenuManager не найдены!")
		"Районы":
			districts_menu_manager.show_districts_menu(self)
		"Квесты":
			menu_manager.show_quests_menu(self)
		"Меню":
			show_main_menu_with_money_button()  # ✅ НОВОЕ: С кнопкой денег

# ✅ НОВОЕ: Меню с кнопкой денег
func show_main_menu_with_money_button():
	var menu_layer = CanvasLayer.new()
	menu_layer.name = "MainMenu"
	menu_layer.layer = 150
	add_child(menu_layer)
	
	# Overlay
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_layer.add_child(overlay)
	
	# Фон
	var bg = ColorRect.new()
	bg.size = Vector2(700, 900)
	bg.position = Vector2(10, 190)
	bg.color = Color(0.05, 0.05, 0.05, 0.95)
	menu_layer.add_child(bg)
	
	# Заголовок
	var title = Label.new()
	title.text = "⚙️ МЕНЮ"
	title.position = Vector2(300, 210)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	menu_layer.add_child(title)
	
	var y_pos = 280
	
	# ✅ НОВОЕ: Кнопка денег (для тестирования)
	var money_btn = Button.new()
	money_btn.text = "💰 Деньги (+10000) [ТЕСТ]"
	money_btn.custom_minimum_size = Vector2(680, 60)
	money_btn.position = Vector2(20, y_pos)
	money_btn.add_theme_font_size_override("font_size", 20)
	
	var style_money = StyleBoxFlat.new()
	style_money.bg_color = Color(0.2, 0.6, 0.2)
	money_btn.add_theme_stylebox_override("normal", style_money)
	
	money_btn.pressed.connect(func():
		player_data["balance"] += 10000
		update_ui()
		if log_system:
			log_system.add_money_log("💰 +10000 руб. (тестовый режим)")
		show_message("💰 Получено 10000 рублей!")
	)
	menu_layer.add_child(money_btn)
	y_pos += 80
	
	# ✅ КНОПКА ТЕСТА БОЯ
	var test_battle_btn = Button.new()
	test_battle_btn.text = "⚔️ Тест боя"
	test_battle_btn.custom_minimum_size = Vector2(680, 60)
	test_battle_btn.position = Vector2(20, y_pos)
	test_battle_btn.add_theme_font_size_override("font_size", 20)
	
	var style_battle = StyleBoxFlat.new()
	style_battle.bg_color = Color(0.7, 0.2, 0.2)
	test_battle_btn.add_theme_stylebox_override("normal", style_battle)
	
	test_battle_btn.pressed.connect(func():
		menu_layer.queue_free()
		_start_test_battle()
	)
	menu_layer.add_child(test_battle_btn)
	y_pos += 80
	
	# Остальные кнопки...
	var stats_btn = Button.new()
	stats_btn.text = "📊 Статистика"
	stats_btn.custom_minimum_size = Vector2(680, 60)
	stats_btn.position = Vector2(20, y_pos)
	stats_btn.add_theme_font_size_override("font_size", 20)
	stats_btn.pressed.connect(func():
		if menu_manager:
			menu_layer.queue_free()
			menu_manager.show_stats_menu(self)
	)
	menu_layer.add_child(stats_btn)
	y_pos += 80
	
	# Кнопка сохранения
	var save_btn = Button.new()
	save_btn.text = "💾 Сохранить игру"
	save_btn.custom_minimum_size = Vector2(680, 60)
	save_btn.position = Vector2(20, y_pos)
	save_btn.add_theme_font_size_override("font_size", 20)
	save_btn.pressed.connect(func():
		if save_manager:
			save_manager.save_game(self)
			show_message("💾 Игра сохранена!")
			if log_system:
				log_system.add_event_log("💾 Игра сохранена")
	)
	menu_layer.add_child(save_btn)
	y_pos += 80
	
	# Кнопка загрузки
	var load_btn = Button.new()
	load_btn.text = "📂 Загрузить игру"
	load_btn.custom_minimum_size = Vector2(680, 60)
	load_btn.position = Vector2(20, y_pos)
	load_btn.add_theme_font_size_override("font_size", 20)
	load_btn.pressed.connect(func():
		if save_manager:
			save_manager.load_game(self)
			if log_system:
				log_system.add_event_log("📂 Игра загружена")
	)
	menu_layer.add_child(load_btn)
	y_pos += 80
	
	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.text = "ЗАКРЫТЬ"
	close_btn.custom_minimum_size = Vector2(680, 60)
	close_btn.position = Vector2(20, y_pos + 40)
	close_btn.add_theme_font_size_override("font_size", 20)
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	close_btn.pressed.connect(func():
		menu_layer.queue_free()
	)
	menu_layer.add_child(close_btn)

# ===== ОБНОВЛЕНИЕ UI =====
func update_ui():
	ui_controller.update_ui()
	clicker_system.player_data = player_data
	update_time_ui()

func update_time_ui():
	if not ui_controller or not time_system:
		return
	var ui_layer = ui_controller.get_ui_layer()
	var date_label = ui_layer.get_node_or_null("DateLabel")
	if date_label:
		date_label.text = time_system.get_date_time_string()

func show_message(text: String):
	ui_controller.show_message(text, self)

# ===== СОБЫТИЯ ВРЕМЕНИ =====
func _on_time_changed(_hour: int, _minute: int):
	update_time_ui()

func _on_day_changed(_day: int, _month: int, _year: int):
	print("📅 Новый день: %d.%d.%d" % [_day, _month, _year])
	show_message("📅 Новый день!")
	if log_system:
		log_system.add_event_log("📅 Наступил новый день")
	if districts_system:
		districts_system.process_daily_income()
	update_time_ui()

func _on_time_of_day_changed(period: String):
	var messages = {
		"утро": "🌅 Наступило утро",
		"день": "☀️ День",
		"вечер": "🌆 Наступил вечер",
		"ночь": "🌙 Ночь"
	}
	if period in messages:
		show_message(messages[period])

# ===== ВСТУПЛЕНИЕ =====
func show_intro_text():
	var intro_layer = CanvasLayer.new()
	intro_layer.name = "IntroLayer"
	add_child(intro_layer)
	
	var label = Label.new()
	label.text = "Тверь. Начало пути.\n02.03.1992, 10:00"
	label.position = Vector2(150, 500)
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro_layer.add_child(label)
	
	await get_tree().create_timer(3.0).timeout
	intro_layer.queue_free()
	
	if not first_battle_started and not player_data.get("first_battle_completed", false):
		first_battle_started = true
		player_data["first_battle_completed"] = true
		
		await get_tree().create_timer(1.0).timeout
		show_message("⚠️ ОБУЧЕНИЕ: Встретился гопник!")
		await get_tree().create_timer(1.5).timeout
		
		if battle_manager:
			battle_manager.start_battle(self, "gopnik", false)

# ===== УРОВЕНЬ ХАРАКТЕРИСТИК =====
func show_level_up_message(stat_name: String, new_level: int):
	var level_up_layer = CanvasLayer.new()
	level_up_layer.name = "LevelUpLayer"
	add_child(level_up_layer)
	
	var bg = ColorRect.new()
	bg.size = Vector2(500, 200)
	bg.position = Vector2(110, 540)
	bg.color = Color(0.1, 0.3, 0.1, 0.95)
	level_up_layer.add_child(bg)
	
	var title = Label.new()
	title.text = "⭐ ПОВЫШЕНИЕ УРОВНЯ! ⭐"
	title.position = Vector2(200, 560)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	level_up_layer.add_child(title)
	
	var stat_label = Label.new()
	stat_label.text = stat_name + " → " + str(new_level)
	stat_label.position = Vector2(280, 620)
	stat_label.add_theme_font_size_override("font_size", 32)
	stat_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	level_up_layer.add_child(stat_label)
	
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(func():
		if level_up_layer and is_instance_valid(level_up_layer):
			level_up_layer.queue_free()
		timer.queue_free()
	)
	timer.start()

# ===== КВЕСТЫ =====
func on_quest_completed(quest_id: String):
	if not quest_system:
		return
	var reward = null
	if quest_system.available_quests.has(quest_id):
		reward = quest_system.available_quests[quest_id]["reward"]
	if reward:
		if reward.has("money"):
			player_data["balance"] += reward["money"]
		if reward.has("reputation"):
			player_data["reputation"] += reward["reputation"]
		var reward_text = "✅ Квест выполнен!\n"
		if reward.has("money"):
			reward_text += "💰 +" + str(reward["money"]) + " руб.\n"
		if reward.has("reputation"):
			reward_text += "⭐ +" + str(reward["reputation"]) + " репутации"
		show_message(reward_text)
		
		# ✅ НОВОЕ: Логируем награду за квест
		if log_system:
			var quest_info = quest_system.available_quests[quest_id]
			var log_msg = "✅ Квест: " + quest_info.get("title", "")
			if reward.has("money"):
				log_msg += " | 💰 +" + str(reward["money"]) + "р"
			if reward.has("reputation"):
				log_msg += " | ⭐ +" + str(reward["reputation"])
			log_system.add_quest_log(log_msg)
		
		update_ui()

# ===== РАЙОНЫ =====
func on_district_captured(district_name: String, by_gang: String):
	districts_menu_manager.show_district_captured_notification(self, district_name, by_gang)

# ===== БОЙ =====
func show_enemy_selection_menu():
	battle_manager.show_enemy_selection_menu(self)

func start_battle(enemy_type: String = "gopnik"):
	battle_manager.start_battle(self, enemy_type)

func show_districts_menu():
	districts_menu_manager.show_districts_menu(self)

# ===== ЗАГРУЗКА ИГРЫ =====
func load_game_from_data(save_data: Dictionary):
	if save_data.is_empty():
		show_message("❌ Нет данных для загрузки!")
		return
	
	if save_data.has("player"):
		var player = save_data["player"]
		player_data["balance"] = player.get("balance", 0)
		player_data["health"] = player.get("health", 100)
		player_data["reputation"] = player.get("reputation", 0)
		player_data["completed_quests"] = player.get("completed_quests", [])
		player_data["equipment"] = player.get("equipment", {}).duplicate(true)
		player_data["inventory"] = player.get("inventory", []).duplicate(true)
		player_data["pockets"] = player.get("pockets", [null, null, null]).duplicate(true)
		player_data["first_battle_completed"] = player.get("first_battle_completed", true)
		player_data["car"] = player.get("car", null)
		player_data["car_condition"] = player.get("car_condition", 100.0)
		
		if player.has("current_square"):
			player_data["current_square"] = player["current_square"]
	
	if save_data.has("gang"):
		gang_members = save_data["gang"].duplicate(true)
		print("📂 Загружаем банду: %d членов" % gang_members.size())
		
		for i in range(gang_members.size()):
			var member = gang_members[i]
			if not member.has("is_active"):
				member["is_active"] = (i == 0)
			if not member.has("hp"):
				member["hp"] = member.get("health", 100)
			if not member.has("max_hp"):
				member["max_hp"] = member.get("hp", 100)
			if not member.has("damage"):
				member["damage"] = member.get("strength", 10)
			if not member.has("defense"):
				member["defense"] = 0
			if not member.has("morale"):
				member["morale"] = 80
			if not member.has("accuracy"):
				member["accuracy"] = 0.65
			if not member.has("weapon"):
				member["weapon"] = "Кулаки"
			if not member.has("inventory"):
				member["inventory"] = []
			if not member.has("equipment"):
				member["equipment"] = {"helmet": null, "armor": null, "melee": null, "ranged": null, "gadget": null}
			if not member.has("pockets"):
				member["pockets"] = [null, null, null]
			
			print("  [%d] %s (active: %s, hp: %d)" % [
				i, 
				member.get("name", "???"), 
				member.get("is_active", false),
				member.get("hp", 100)
			])
	
	if save_manager:
		if save_data.has("quests"):
			save_manager.restore_quest_data(save_data["quests"])
		if save_data.has("districts"):
			save_manager.restore_districts_data(save_data["districts"])
	
	update_ui()
	show_message("✅ Игра загружена!")
	print("📂 Загружено - первый бой: %s" % player_data["first_battle_completed"])

# ===== ДОПОЛНИТЕЛЬНЫЕ ФУНКЦИИ =====

func get_current_transport_type() -> int:
	"""Определяет тип транспорта на основе экипированной машины"""
	if not player_data.get("car_equipped"):
		return movement_system.TransportType.WALK
	
	if not player_data.get("car"):
		return movement_system.TransportType.WALK
	
	if player_data.get("current_driver") == null:
		return movement_system.TransportType.WALK
	
	# Определяем по ID машины
	var car_id = player_data["car"]
	match car_id:
		"vaz_2106":
			return movement_system.TransportType.CAR_LEVEL1
		"volga_3110", "bmw_e34":
			return movement_system.TransportType.CAR_LEVEL2
		_:
			return movement_system.TransportType.WALK

func _start_test_battle():
	"""Запускает тестовый бой"""
	print("⚔️ Запуск тестового боя")
	
	if not battle_manager:
		show_message("❌ Система боя не загружена!")
		print("❌ battle_manager не найден!")
		return
	
	# Создаем тестового врага
	var test_enemy = {
		"name": "Тестовый гопник",
		"hp": 50,
		"max_hp": 50,
		"damage": 15,
		"defense": 5,
		"accuracy": 0.7,
		"weapon": "Бита",
		"morale": 80
	}
	
	if log_system:
		log_system.add_combat_log("⚔️ Начался тестовый бой!")
	
	show_message("⚔️ Начинаем тестовый бой!")
	
	# ✅ ИСПРАВЛЕНО: Правильный вызов start_battle
	# battle_manager.start_battle(main, members, enemies, location)
	print("   Вызываем battle_manager.start_battle")
	battle_manager.start_battle(self, gang_members, [test_enemy], "ТЕСТОВАЯ АРЕНА")

# ===== ЭКИПИРОВКА МАШИНЫ (будет перенесена в gang_manager) =====
func show_car_equipment_menu():
	"""Меню для назначения водителя"""
	var equip_menu = CanvasLayer.new()
	equip_menu.name = "CarEquipMenu"
	equip_menu.layer = 160
	add_child(equip_menu)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	equip_menu.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(700, 900)
	bg.position = Vector2(10, 190)
	bg.color = Color(0.05, 0.05, 0.15, 0.95)
	equip_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "🚗 ЭКИПИРОВКА МАШИНЫ"
	title.position = Vector2(200, 210)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	equip_menu.add_child(title)
	
	var y_pos = 280
	
	# Информация о машине
	var owned_car_text = "Ваша машина: "
	if player_data.get("car"):
		var car_system = get_node_or_null("/root/CarSystem")
		if car_system and car_system.cars_db.has(player_data["car"]):
			owned_car_text += car_system.cars_db[player_data["car"]]["name"]
		else:
			owned_car_text += player_data["car"]
	else:
		owned_car_text += "Нет (купите в АВТОСАЛОНЕ)"
	
	var owned_label = Label.new()
	owned_label.text = owned_car_text
	owned_label.position = Vector2(190, y_pos)
	owned_label.add_theme_font_size_override("font_size", 18)
	owned_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
	equip_menu.add_child(owned_label)
	y_pos += 60
	
	# Список членов банды
	if player_data.get("car"):
		var info_label = Label.new()
		info_label.text = "Выберите водителя из банды:"
		info_label.position = Vector2(210, y_pos)
		info_label.add_theme_font_size_override("font_size", 16)
		info_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
		equip_menu.add_child(info_label)
		y_pos += 50
		
		for i in range(gang_members.size()):
			var member = gang_members[i]
			var is_driver = (player_data.get("current_driver") == i)
			
			var member_btn = Button.new()
			member_btn.custom_minimum_size = Vector2(680, 60)
			member_btn.position = Vector2(20, y_pos)
			
			var member_text = member["name"]
			if is_driver:
				member_text += " ✅ (водитель)"
			
			member_btn.text = member_text
			member_btn.add_theme_font_size_override("font_size", 18)
			
			var style = StyleBoxFlat.new()
			if is_driver:
				style.bg_color = Color(0.2, 0.6, 0.2)
			else:
				style.bg_color = Color(0.3, 0.3, 0.4)
			member_btn.add_theme_stylebox_override("normal", style)
			
			var member_index = i
			member_btn.pressed.connect(func():
				set_driver(member_index, equip_menu)
			)
			equip_menu.add_child(member_btn)
			y_pos += 70
	else:
		var no_car_label = Label.new()
		no_car_label.text = "У вас нет машины!\nКупите машину в АВТОСАЛОНЕ"
		no_car_label.position = Vector2(220, y_pos + 100)
		no_car_label.add_theme_font_size_override("font_size", 20)
		no_car_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		equip_menu.add_child(no_car_label)
	
	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(680, 60)
	close_btn.position = Vector2(20, 1000)
	close_btn.text = "ЗАКРЫТЬ"
	close_btn.add_theme_font_size_override("font_size", 20)
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	close_btn.pressed.connect(func():
		equip_menu.queue_free()
	)
	equip_menu.add_child(close_btn)

func set_driver(member_index: int, equip_menu: CanvasLayer):
	"""Устанавливает члена банды водителем"""
	if not player_data.get("car"):
		show_message("❌ У вас нет машины!")
		return
	
	player_data["current_driver"] = member_index
	player_data["car_equipped"] = true
	gang_members[member_index]["equipment"]["car"] = player_data["car"]
	
	if log_system:
		log_system.add_event_log("🚗 %s назначен водителем" % gang_members[member_index]["name"])
	
	show_message("✅ %s назначен водителем!" % gang_members[member_index]["name"])
	
	# Обновляем меню
	equip_menu.queue_free()
	await get_tree().process_frame
	show_car_equipment_menu()

func get_save_data() -> Dictionary:
	return {
		"player_data": player_data,
		"gang_members": gang_members
	}
