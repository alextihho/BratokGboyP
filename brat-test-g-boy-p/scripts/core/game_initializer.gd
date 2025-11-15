# scripts/core/game_initializer.gd (ОБНОВЛЕНО - добавлены новые системы)
extends Node

# ===== ЗАГРУЗКА АВТОЛОАД СИСТЕМ =====
func load_autoload_systems(game_controller):
	game_controller.items_db = get_node("/root/ItemsDB")
	game_controller.building_system = get_node("/root/BuildingSystem")
	game_controller.player_stats = get_node("/root/PlayerStats")
	game_controller.quest_system = get_node_or_null("/root/QuestSystem")
	game_controller.random_events = get_node_or_null("/root/RandomEvents")
	game_controller.inventory_manager = get_node("/root/InventoryManager")
	game_controller.gang_manager = get_node("/root/GangManager")
	game_controller.save_manager = get_node("/root/SaveManager")
	game_controller.districts_system = get_node_or_null("/root/DistrictsSystem")
	game_controller.simple_jobs = get_node_or_null("/root/SimpleJobs")
	game_controller.hospital_system = get_node_or_null("/root/HospitalSystem")
	game_controller.time_system = get_node_or_null("/root/TimeSystem")
	
	# ✅ НОВОЕ: Загружаем новые системы
	game_controller.log_system = get_node_or_null("/root/LogSystem")
	game_controller.bar_system = get_node_or_null("/root/BarSystem")
	game_controller.car_system = get_node_or_null("/root/CarSystem")
	
	print("✅ Автолоад системы загружены")
	
	if game_controller.log_system:
		print("✅ LogSystem доступен")
	else:
		print("⚠️ LogSystem не найден!")
	
	if game_controller.bar_system:
		print("✅ BarSystem доступен")
	else:
		print("⚠️ BarSystem не найден!")
	
	if game_controller.car_system:
		print("✅ CarSystem доступен")
	else:
		print("⚠️ CarSystem не найден!")

# ===== НАСТРОЙКА СЕТКИ И ДВИЖЕНИЯ =====
func setup_grid_and_movement(game_controller):
	var grid_script = load("res://scripts/systems/grid_system.gd")
	if grid_script:
		game_controller.grid_system = grid_script.new()
		game_controller.grid_system.name = "GridSystem"
		game_controller.add_child(game_controller.grid_system)
		game_controller.move_child(game_controller.grid_system, game_controller.get_child_count() - 1)
		print("🗺️ Сетка создана")
	
	var movement_script = load("res://scripts/systems/movement_system.gd")
	if movement_script:
		game_controller.movement_system = movement_script.new()
		game_controller.movement_system.name = "MovementSystem"
		game_controller.add_child(game_controller.movement_system)
		if game_controller.grid_system:
			game_controller.movement_system.initialize(game_controller.grid_system)
	
	if game_controller.grid_system:
		for location_name in game_controller.locations:
			var location = game_controller.locations[location_name]
			if location.has("grid_square"):
				game_controller.grid_system.set_building(location["grid_square"], location_name)
		game_controller.grid_system.set_player_square(game_controller.player_data["current_square"])
		print("✅ Здания размещены: " + str(game_controller.locations.size()))

# ===== ИНИЦИАЛИЗАЦИЯ МЕНЕДЖЕРОВ =====
func initialize_managers(game_controller):
	"""Инициализирует менеджеры"""
	print("🔧 initialize_managers старт")
	
	# Map Manager
	var map_manager_script = preload("res://scripts/managers/map_manager.gd")
	if map_manager_script:
		var map_manager = map_manager_script.new()
		if map_manager:
			map_manager.name = "MapManager"
			game_controller.add_child(map_manager)
			map_manager.initialize(game_controller, game_controller.locations)
			map_manager.location_clicked.connect(game_controller.on_location_clicked)
			print("✅ MapManager создан")
		else:
			print("❌ MapManager.new() returned Nil!")
	else:
		print("❌ preload map_manager.gd failed!")
	
	# UI Controller
	var ui_script = load("res://scripts/managers/ui_controller.gd")
	if ui_script:
		game_controller.ui_controller = ui_script.new()
		if game_controller.ui_controller:
			game_controller.ui_controller.name = "UIController"
			game_controller.add_child(game_controller.ui_controller)
			game_controller.ui_controller.initialize(game_controller, game_controller.player_data)
			print("✅ UIController создан")
		else:
			print("❌ ui_controller.new() returned Nil!")
	else:
		print("❌ load ui_controller.gd failed!")
	
	var ui_layer = game_controller.ui_controller.get_ui_layer() if game_controller.ui_controller else null
	if ui_layer:
		ui_layer.layer = 50
		print("✅ UI Layer layer=50")
	else:
		print("⚠️ get_ui_layer() returned null")
	
	# Action Handler
	var action_handler_script = preload("res://scripts/managers/action_handler.gd")
	if action_handler_script:
		game_controller.action_handler = action_handler_script.new()
		if game_controller.action_handler:
			game_controller.action_handler.name = "ActionHandler"
			game_controller.add_child(game_controller.action_handler)
			# ✅ ИСПРАВЛЕНО: Передаём только player_data
			game_controller.action_handler.initialize(game_controller.player_data)
			print("✅ ActionHandler создан")
		else:
			print("❌ ActionHandler.new() returned Nil!")
	else:
		print("❌ preload action_handler.gd failed!")
	
	# Menu Manager
	var menu_manager_script = load("res://scripts/managers/menu_manager.gd")
	if menu_manager_script:
		game_controller.menu_manager = menu_manager_script.new()
		if game_controller.menu_manager:
			game_controller.menu_manager.name = "MenuManager"
			game_controller.add_child(game_controller.menu_manager)
			print("✅ MenuManager создан")
	
	# Clicker System
	var clicker_script = load("res://scripts/managers/clicker_system.gd")
	if clicker_script:
		game_controller.clicker_system = clicker_script.new()
		if game_controller.clicker_system:
			game_controller.clicker_system.name = "ClickerSystem"
			game_controller.add_child(game_controller.clicker_system)
			# ✅ ИСПРАВЛЕНО: Передаём ui_layer и player_data
			var clicker_ui_layer = game_controller.ui_controller.get_ui_layer() if game_controller.ui_controller else null
			if clicker_ui_layer:
				game_controller.clicker_system.initialize(clicker_ui_layer, game_controller.player_data)
				print("✅ ClickerSystem создан")
			else:
				print("⚠️ ClickerSystem не инициализирован - нет ui_layer")
	
	# Districts Menu Manager
	var districts_menu_script = load("res://scripts/managers/districts_menu_manager.gd")
	if districts_menu_script:
		game_controller.districts_menu_manager = districts_menu_script.new()
		if game_controller.districts_menu_manager:
			game_controller.districts_menu_manager.name = "DistrictsMenuManager"
			game_controller.add_child(game_controller.districts_menu_manager)
			game_controller.districts_menu_manager.initialize() # ✅ ФИКС: Инициализируем менеджер
			print("✅ DistrictsMenuManager создан")
	
	# Battle Manager
	var battle_manager_script = load("res://scripts/managers/battle_manager.gd")
	if battle_manager_script:
		game_controller.battle_manager = battle_manager_script.new()
		if game_controller.battle_manager:
			game_controller.battle_manager.name = "BattleManager"
			game_controller.add_child(game_controller.battle_manager)
			game_controller.battle_manager.initialize(game_controller)
			print("✅ BattleManager создан")
	
	# Grid Movement Manager
	var grid_movement_script = load("res://scripts/managers/grid_movement_manager.gd")
	if grid_movement_script:
		game_controller.grid_movement_manager = grid_movement_script.new()
		if game_controller.grid_movement_manager:
			game_controller.grid_movement_manager.name = "GridMovementManager"
			game_controller.add_child(game_controller.grid_movement_manager)
			game_controller.grid_movement_manager.initialize(
				game_controller,
				game_controller.grid_system,
				game_controller.movement_system
			)
			print("✅ GridMovementManager создан")
	
	print("🔧 initialize_managers конец")

# ===== НАСТРОЙКА ИГРОВЫХ СИСТЕМ =====
func setup_game_systems(game_controller):
	if game_controller.player_stats:
		game_controller.player_stats.recalculate_equipment_bonuses(game_controller.player_data["equipment"], game_controller.items_db)
		game_controller.player_stats.stat_leveled_up.connect(game_controller.show_level_up_message)
	
	if game_controller.quest_system:
		game_controller.quest_system.start_quest("first_money")
		game_controller.quest_system.start_quest("buy_weapon")
		game_controller.quest_system.start_quest("win_fights")
		game_controller.quest_system.quest_completed.connect(game_controller.on_quest_completed)
	
	if game_controller.districts_system:
		game_controller.districts_system.district_captured.connect(game_controller.on_district_captured)
	
	print("✅ Игровые системы настроены")

# ===== ПОДКЛЮЧЕНИЕ СИГНАЛОВ =====
func connect_signals(game_controller):
	if game_controller.time_system:
		game_controller.time_system.time_changed.connect(game_controller._on_time_changed)
		game_controller.time_system.day_changed.connect(game_controller._on_day_changed)
		game_controller.time_system.time_of_day_changed.connect(game_controller._on_time_of_day_changed)
	
	print("✅ Сигналы подключены")
