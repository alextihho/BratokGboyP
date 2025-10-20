# main.gd (ИСПРАВЛЕНО - ПРАВИЛЬНЫЕ КООРДИНАТЫ)
extends Node2D

# ========== МЕНЕДЖЕРЫ ==========
var map_manager
var ui_controller
var action_handler
var menu_manager
var clicker_system
var districts_menu_manager
var battle_manager
var grid_movement_manager

# ========== СИСТЕМЫ (AUTOLOAD) ==========
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

# ========== ИГРОВЫЕ СИСТЕМЫ ==========
var grid_system
var movement_system

# ========== СОСТОЯНИЕ ИГРЫ ==========
var current_location = null
var menu_open = false
var first_battle_started = false

# ========== ДАННЫЕ ЛОКАЦИЙ ==========
var locations = {
	"ОБЩЕЖИТИЕ": {"position": Vector2(500, 200), "actions": ["Отдохнуть", "Поговорить с другом", "Взять вещи"], "grid_square": "6_2"},
	"ЛАРЁК": {"position": Vector2(200, 350), "actions": ["Купить пиво (30р)", "Купить сигареты (15р)", "Купить кепку (50р)"], "grid_square": "2_4"},
	"ВОКЗАЛ": {"position": Vector2(100, 150), "actions": ["Купить билет", "Встретить контакт", "Осмотреться"], "grid_square": "1_1"},
	"ГАРАЖ": {"position": Vector2(550, 650), "actions": ["Купить биту (100р)", "Помочь механику", "Взять инструменты"], "grid_square": "9_8"},
	"РЫНОК": {"position": Vector2(300, 850), "actions": ["Купить кожанку (200р)", "Продать вещь", "Узнать новости"], "grid_square": "5_10"},
	"ПОРТ": {"position": Vector2(600, 450), "actions": ["Купить ПМ (500р)", "Купить отмычку (100р)", "Уйти"], "grid_square": "10_5"},
	"УЛИЦА": {"position": Vector2(150, 1050), "actions": ["Прогуляться", "Встретить знакомого", "Посмотреть вокруг"], "grid_square": "2_13"},
	"БОЛЬНИЦА": {"position": Vector2(400, 500), "actions": ["Лечиться", "Купить аптечку (100р)", "Уйти"], "grid_square": "6_6"},
	"ФСБ": {"position": Vector2(350, 800), "actions": ["Дать взятку", "Уйти"], "grid_square": "5_9"}
}

# ========== ДАННЫЕ ИГРОКА ==========
var player_data = {
	"balance": 150,
	"health": 100,
	"reputation": 0,
	"completed_quests": [],
	"equipment": {"helmet": null, "armor": null, "melee": null, "ranged": null, "gadget": null},
	"inventory": ["Пачка сигарет", "Булка", "Нож"],
	"pockets": [null, null, null],
	"current_square": "6_2"
}

# ========== ДАННЫЕ БАНДЫ ==========
var gang_members = [
	{
		"name": "Главный (ты)",
		"health": 100,
		"strength": 10,
		"equipment": {"helmet": null, "armor": null, "melee": null, "ranged": null, "gadget": null},
		"inventory": [],
		"pockets": [null, null, null]
	}
]

func _ready():
	load_autoload_systems()
	setup_grid_and_movement()
	initialize_managers()
	setup_game_systems()
	connect_signals()
	show_intro_text()
	print("✅ Игра готова! (ИСПРАВЛЕНЫ КООРДИНАТЫ КЛИКОВ)")

func load_autoload_systems():
	items_db = get_node("/root/ItemsDB")
	building_system = get_node("/root/BuildingSystem")
	player_stats = get_node("/root/PlayerStats")
	quest_system = get_node_or_null("/root/QuestSystem")
	random_events = get_node_or_null("/root/RandomEvents")
	inventory_manager = get_node("/root/InventoryManager")
	gang_manager = get_node("/root/GangManager")
	save_manager = get_node("/root/SaveManager")
	districts_system = get_node_or_null("/root/DistrictsSystem")
	simple_jobs = get_node_or_null("/root/SimpleJobs")
	hospital_system = get_node_or_null("/root/HospitalSystem")
	time_system = get_node_or_null("/root/TimeSystem")

func setup_grid_and_movement():
	var grid_script = load("res://scripts/systems/grid_system.gd")
	if grid_script:
		grid_system = grid_script.new()
		grid_system.name = "GridSystem"
		add_child(grid_system)
		move_child(grid_system, get_child_count() - 1)
		print("🗺️ Сетка создана")
	
	var movement_script = load("res://scripts/systems/movement_system.gd")
	if movement_script:
		movement_system = movement_script.new()
		movement_system.name = "MovementSystem"
		add_child(movement_system)
		if grid_system:
			movement_system.initialize(grid_system)
	
	if grid_system:
		for location_name in locations:
			var location = locations[location_name]
			if location.has("grid_square"):
				grid_system.set_building(location["grid_square"], location_name)
		grid_system.set_player_square(player_data["current_square"])
		print("✅ Здания размещены: " + str(locations.size()))

func initialize_managers():
	map_manager = preload("res://scripts/managers/map_manager.gd").new()
	map_manager.name = "MapManager"
	add_child(map_manager)
	map_manager.initialize(self, locations)
	map_manager.location_clicked.connect(on_location_clicked)
	
	ui_controller = preload("res://scripts/managers/ui_controller.gd").new()
	ui_controller.name = "UIController"
	add_child(ui_controller)
	ui_controller.initialize(self, player_data)
	var ui_layer = ui_controller.get_ui_layer()
	if ui_layer:
		ui_layer.layer = 50
	
	action_handler = preload("res://scripts/managers/action_handler.gd").new()
	action_handler.name = "ActionHandler"
	add_child(action_handler)
	action_handler.initialize(player_data)
	
	menu_manager = preload("res://scripts/managers/menu_manager.gd").new()
	menu_manager.name = "MenuManager"
	add_child(menu_manager)
	menu_manager.initialize(player_data, gang_members)
	
	clicker_system = preload("res://scripts/managers/clicker_system.gd").new()
	clicker_system.name = "ClickerSystem"
	add_child(clicker_system)
	clicker_system.initialize(ui_controller.get_ui_layer(), player_data)
	
	districts_menu_manager = preload("res://scripts/managers/districts_menu_manager.gd").new()
	districts_menu_manager.name = "DistrictsMenuManager"
	add_child(districts_menu_manager)
	districts_menu_manager.initialize()
	
	battle_manager = preload("res://scripts/managers/battle_manager.gd").new()
	battle_manager.name = "BattleManager"
	add_child(battle_manager)
	battle_manager.initialize()
	
	var grid_movement_script = load("res://scripts/managers/grid_movement_manager.gd")
	if grid_movement_script:
		grid_movement_manager = grid_movement_script.new()
		grid_movement_manager.name = "GridMovementManager"
		add_child(grid_movement_manager)
		grid_movement_manager.initialize(self, grid_system, movement_system)

func setup_game_systems():
	if player_stats:
		player_stats.recalculate_equipment_bonuses(player_data["equipment"], items_db)
		player_stats.stat_leveled_up.connect(show_level_up_message)
	
	if quest_system:
		quest_system.start_quest("first_money")
		quest_system.start_quest("buy_weapon")
		quest_system.start_quest("win_fights")
		quest_system.quest_completed.connect(on_quest_completed)
	
	if districts_system:
		districts_system.district_captured.connect(on_district_captured)

func connect_signals():
	if time_system:
		time_system.time_changed.connect(_on_time_changed)
		time_system.day_changed.connect(_on_day_changed)
		time_system.time_of_day_changed.connect(_on_time_of_day_changed)

# ========================================
# ОБРАБОТКА ВВОДА (ИСПРАВЛЕНО - VIEWPORT КООРДИНАТЫ!)
# ========================================

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# ✅ КРИТИЧНО: Используем позицию ВНУТРИ viewport, а не глобальную!
			var click_pos = get_viewport().get_mouse_position()
			
			print("🎯 CLICK: " + str(click_pos))
			
			# Блокируем если идёт бой
			if get_node_or_null("BattleScene"):
				print("⚠️ Бой идёт")
				return
			
			# Проверяем открытые меню
			if has_any_menu_open():
				print("⚠️ Меню открыто")
				return
			
			# Дополнительная проверка UI зон
			if is_click_on_ui(click_pos):
				print("⚠️ Клик на UI")
				return
			
			print("✅ Клик на сетку разрешён")
			
			# Проверка клика по сетке
			if grid_movement_manager:
				grid_movement_manager.handle_grid_click(click_pos)
			
			# Отмечаем что обработали
			get_viewport().set_input_as_handled()

# ✅ Проверка клика на UI
func is_click_on_ui(click_pos: Vector2) -> bool:
	# Верхняя панель: y < 120
	if click_pos.y < 120:
		print("   → Верхняя панель")
		return true
	
	# Нижняя панель: y >= 1180
	if click_pos.y >= 1180:
		print("   → Нижняя панель y=%d" % click_pos.y)
		return true
	
	# Кнопка заработка
	if click_pos.x >= 590 and click_pos.x <= 710 and click_pos.y >= 55 and click_pos.y <= 105:
		print("   → Кнопка заработка")
		return true
	
	# Кнопка сетки
	if click_pos.x >= 540 and click_pos.x <= 590 and click_pos.y >= 55 and click_pos.y <= 85:
		print("   → Кнопка сетки")
		return true
	
	return false

# ✅ Проверка открытых меню
func has_any_menu_open() -> bool:
	var menus = [
		"BuildingMenu", "GangMenu", "InventoryMenu", "QuestMenu",
		"DistrictsMenu", "MainMenuLayer", "MovementMenu",
		"HospitalMenu", "JobsMenu", "SellMenu"
	]
	
	for menu_name in menus:
		if get_node_or_null(menu_name):
			return true
	
	return false

# ========================================
# МЕНЮ ЛОКАЦИЙ
# ========================================

func show_location_menu(location_name: String):
	current_location = location_name
	menu_open = true
	print("🏢 Открываем меню: " + location_name)
	
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
		close_location_menu()
	)
	
	building_menu.menu_closed.connect(func():
		close_location_menu()
	)

func handle_location_action(action_index: int):
	if current_location == null:
		return
	action_handler.handle_location_action(current_location, action_index, self)
	if time_system:
		var time_cost = randi_range(5, 15)
		time_system.add_minutes(time_cost)

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

# ========================================
# КНОПКИ НИЖНЕЙ ПАНЕЛИ
# ========================================

func on_bottom_button_pressed(button_name: String):
	match button_name:
		"Банда":
			menu_manager.show_gang_menu(self)
		"Районы":
			districts_menu_manager.show_districts_menu(self)
		"Квесты":
			menu_manager.show_quests_menu(self)
		"Меню":
			menu_manager.show_main_menu(self)

# ========================================
# ОБНОВЛЕНИЕ UI
# ========================================

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

# ========================================
# СОБЫТИЯ ВРЕМЕНИ
# ========================================

func _on_time_changed(_hour: int, _minute: int):
	update_time_ui()

func _on_day_changed(_day: int, _month: int, _year: int):
	show_message("📅 Новый день!")
	if districts_system:
		var daily_income = districts_system.get_total_player_income()
		if daily_income > 0:
			player_data["balance"] += daily_income
			show_message("💰 Пассивный доход: +" + str(daily_income) + " руб.")
			update_ui()

func _on_time_of_day_changed(period: String):
	var messages = {
		"утро": "🌅 Наступило утро",
		"день": "☀️ День",
		"вечер": "🌆 Наступил вечер",
		"ночь": "🌙 Ночь"
	}
	if period in messages:
		show_message(messages[period])

# ========================================
# ОСТАЛЬНЫЕ ФУНКЦИИ (БЕЗ ИЗМЕНЕНИЙ)
# ========================================

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
	
	if not first_battle_started:
		first_battle_started = true
		await get_tree().create_timer(1.0).timeout
		show_message("⚠️ ОБУЧЕНИЕ: Встретился гопник!")
		await get_tree().create_timer(1.5).timeout
		
		if battle_manager:
			battle_manager.start_battle(self, "gopnik", false)

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
		update_ui()

func on_district_captured(district_name: String, by_gang: String):
	districts_menu_manager.show_district_captured_notification(self, district_name, by_gang)

func show_enemy_selection_menu():
	battle_manager.show_enemy_selection_menu(self)

func start_battle(enemy_type: String = "gopnik"):
	battle_manager.start_battle(self, enemy_type)

func show_districts_menu():
	districts_menu_manager.show_districts_menu(self)
