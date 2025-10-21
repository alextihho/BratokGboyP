# scripts/core/game_initializer.gd
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
	
	print("✅ Автолоад системы загружены")

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
	# Map Manager
	game_controller.map_manager = preload("res://scripts/managers/map_manager.gd").new()
	game_controller.map_manager.name = "MapManager"
	game_controller.add_child(game_controller.map_manager)
	game_controller.map_manager.initialize(game_controller, game_controller.locations)
	game_controller.map_manager.location_clicked.connect(game_controller.on_location_clicked)
	
	# UI Controller
	game_controller.ui_controller = preload("res://scripts/managers/ui_controller.gd").new()
	game_controller.ui_controller.name = "UIController"
	game_controller.add_child(game_controller.ui_controller)
	game_controller.ui_controller.initialize(game_controller, game_controller.player_data)
	var ui_layer = game_controller.ui_controller.get_ui_layer()
	if ui_layer:
		ui_layer.layer = 50
	
	# Action Handler
	game_controller.action_handler = preload("res://scripts/managers/action_handler.gd").new()
	game_controller.action_handler.name = "ActionHandler"
	game_controller.add_child(game_controller.action_handler)
	game_controller.action_handler.initialize(game_controller.player_data)
	
	# Menu Manager
	game_controller.menu_manager = preload("res://scripts/managers/menu_manager.gd").new()
	game_controller.menu_manager.name = "MenuManager"
	game_controller.add_child(game_controller.menu_manager)
	game_controller.menu_manager.initialize(game_controller.player_data, game_controller.gang_members)
	
	# Clicker System
	game_controller.clicker_system = preload("res://scripts/managers/clicker_system.gd").new()
	game_controller.clicker_system.name = "ClickerSystem"
	game_controller.add_child(game_controller.clicker_system)
	game_controller.clicker_system.initialize(game_controller.ui_controller.get_ui_layer(), game_controller.player_data)
	
	# Districts Menu Manager
	game_controller.districts_menu_manager = preload("res://scripts/managers/districts_menu_manager.gd").new()
	game_controller.districts_menu_manager.name = "DistrictsMenuManager"
	game_controller.add_child(game_controller.districts_menu_manager)
	game_controller.districts_menu_manager.initialize()
	
	# Battle Manager
	game_controller.battle_manager = preload("res://scripts/managers/battle_manager.gd").new()
	game_controller.battle_manager.name = "BattleManager"
	game_controller.add_child(game_controller.battle_manager)
	game_controller.battle_manager.initialize()
	
	# Grid Movement Manager
	var grid_movement_script = load("res://scripts/managers/grid_movement_manager.gd")
	if grid_movement_script:
		game_controller.grid_movement_manager = grid_movement_script.new()
		game_controller.grid_movement_manager.name = "GridMovementManager"
		game_controller.add_child(game_controller.grid_movement_manager)
		game_controller.grid_movement_manager.initialize(game_controller, game_controller.grid_system, game_controller.movement_system)
	
	print("✅ Менеджеры инициализированы")

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
