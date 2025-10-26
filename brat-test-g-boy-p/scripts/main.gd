# main.gd (ИСПРАВЛЕНО - первый бой только раз)
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
	"ФСБ": {"position": Vector2(350, 300), "actions": ["💰 Дать взятку", "🚪 Уйти"], "grid_square": "5_3"}  # ✅ ДОБАВЛЕНО
	
}

# ===== ДАННЫЕ ИГРОКА =====
var player_data = {
	"balance": 150,
	"health": 100,
	"reputation": 0,
	"completed_quests": [],
	"equipment": {"helmet": null, "armor": null, "melee": null, "ranged": null, "gadget": null},
	"inventory": ["Пачка сигарет", "Булка", "Нож"],
	"pockets": [null, null, null],
	"current_square": "6_2",
	"first_battle_completed": false  # ✅ Добавлено!
}

# ===== ДАННЫЕ БАНДЫ =====
var gang_members = [
	{
		"name": "Главный (ты)",
		"health": 100,
		"strength": 10,
		"equipment": {"helmet": null, "armor": null, "melee": null, "ranged": null, "gadget": null},
		"inventory": [],
		"pockets": [null, null, null],
		"is_active": true  # ✅ Главный всегда активен
	}
]

func _ready():
	# Загружаем компоненты
	game_initializer = preload("res://scripts/core/game_initializer.gd").new()
	input_handler = preload("res://scripts/core/input_handler.gd").new()
	
	# Инициализация
	game_initializer.load_autoload_systems(self)
	game_initializer.setup_grid_and_movement(self)
	game_initializer.initialize_managers(self)
	game_initializer.setup_game_systems(self)
	game_initializer.connect_signals(self)
	
	show_intro_text()
	print("✅ Игра готова! (РЕФАКТОРИНГ)")

# ===== ОБРАБОТКА ВВОДА =====
func _unhandled_input(event):
	if input_handler.handle_input(event, self):
		get_viewport().set_input_as_handled()

# ===== МЕНЮ ЛОКАЦИЙ =====
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
	)
	
	building_menu.menu_closed.connect(func():
		close_location_menu()  # ✅ Только по кнопке "Закрыть"
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

# ===== КНОПКИ НИЖНЕЙ ПАНЕЛИ =====
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
	
	# ✅ ИСПРАВЛЕНО: Проверяем не только флаг, но и player_data
	if not first_battle_started and not player_data.get("first_battle_completed", false):
		first_battle_started = true
		player_data["first_battle_completed"] = true  # ✅ Сохраняем в данные
		
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

# ✅ ЗАГРУЗКА ИГРЫ (ИСПРАВЛЕНО)
func load_game_from_data(save_data: Dictionary):
	if save_data.is_empty():
		show_message("❌ Нет данных для загрузки!")
		return
	
	# Восстанавливаем игрока
	if save_data.has("player"):
		var player = save_data["player"]
		player_data["balance"] = player.get("balance", 0)
		player_data["health"] = player.get("health", 100)
		player_data["reputation"] = player.get("reputation", 0)
		player_data["completed_quests"] = player.get("completed_quests", [])
		player_data["equipment"] = player.get("equipment", {}).duplicate(true)
		player_data["inventory"] = player.get("inventory", []).duplicate(true)
		player_data["pockets"] = player.get("pockets", [null, null, null]).duplicate(true)
		
		# ✅ ВАЖНО: Восстанавливаем флаг первого боя
		player_data["first_battle_completed"] = player.get("first_battle_completed", true)
		
		if player.has("current_square"):
			player_data["current_square"] = player["current_square"]
	
	# Восстанавливаем банду
	if save_data.has("gang"):
		gang_members = save_data["gang"].duplicate(true)
		
		# Инициализируем is_active
		for i in range(gang_members.size()):
			if not gang_members[i].has("is_active"):
				gang_members[i]["is_active"] = (i == 0)
	
	# ✅ ИСПРАВЛЕНО: Восстанавливаем квесты и районы
	if save_manager:
		if save_data.has("quests"):
			save_manager.restore_quest_data(save_data["quests"])
		
		if save_data.has("districts"):
			save_manager.restore_districts_data(save_data["districts"])
	
	update_ui()
	show_message("✅ Игра загружена!")
	print("📂 Загружено - первый бой: %s" % player_data["first_battle_completed"])

func get_save_data() -> Dictionary:
	return {
		"player_data": player_data,
		"gang_members": gang_members
	}
