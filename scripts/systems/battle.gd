# battle.gd (РЕФАКТОРИНГ - основной файл)
extends CanvasLayer

signal battle_ended(victory: bool)

var player_team: Array = []
var enemy_team: Array = []
var current_turn: String = "player"
var current_attacker_index: int = 0
var current_target_index: int = 0
var buttons_locked: bool = false
var is_first_battle: bool = false
var awaiting_target_selection: bool = false
var awaiting_zone_selection: bool = false
var selected_zone: int = 0

var player_stats
var player_data
var battle_log_lines: Array = []
var max_log_lines: int = 15

# Подключаем отдельные модули
var combat_calculator
var ui_builder

func _ready():
	layer = 200
	player_stats = get_node("/root/PlayerStats")
	
	# Загружаем модули
	combat_calculator = preload("res://scripts/systems/battle_combat.gd").new()
	combat_calculator.name = "CombatCalculator"
	add_child(combat_calculator)
	
	ui_builder = preload("res://scripts/systems/battle_ui.gd").new()
	ui_builder.name = "UIBuilder"
	add_child(ui_builder)
	
	ui_builder.create_ui(self)

func setup(p_data: Dictionary, enemy_type: String = "gopnik", first_battle: bool = false, p_gang_members: Array = []):
	player_data = p_data
	is_first_battle = first_battle
	
	# Инициализация команды игрока
	player_team = []
	player_team.append({
		"name": "Главный (ты)",
		"health": player_data.get("health", 100),
		"max_health": 100,
		"strength": player_stats.get_stat("STR") if player_stats else 10,
		"agility": player_stats.get_stat("AGI") if player_stats else 5,
		"accuracy": player_stats.get_stat("ACC") if player_stats else 5,
		"equipment": player_data.get("equipment", {})
	})
	
	# Добавляем банду (до 3 членов)
	for i in range(min(3, p_gang_members.size())):
		var member = p_gang_members[i]
		if member["name"] != "Главный (ты)":
			player_team.append({
				"name": member["name"],
				"health": member.get("health", 80),
				"max_health": member.get("max_health", 80),
				"strength": member.get("strength", 5),
				"agility": member.get("agility", 5),
				"accuracy": member.get("accuracy", 5),
				"equipment": member.get("equipment", {})
			})
	
	# Инициализация врагов
	enemy_team = combat_calculator.create_enemy_team(enemy_type, is_first_battle)
	
	update_ui()
	add_to_log("⚔️ БОЙ НАЧАЛСЯ!")
	add_to_log("👥 Ваша команда: " + str(player_team.size()) + " бойцов")
	add_to_log("👹 Врагов: " + str(enemy_team.size()))
	
	if is_first_battle:
		add_to_log("⚠️ ПЕРВЫЙ БОЙ - убежать нельзя!")
	
	start_player_turn()

func update_ui():
	ui_builder.update_fighters(self, player_team, enemy_team, current_attacker_index, current_target_index, current_turn)
	
	var turn_info = get_node_or_null("TurnInfo")
	if turn_info:
		if awaiting_zone_selection:
			turn_info.text = "Выберите зону удара"
		elif awaiting_target_selection:
			turn_info.text = "Выберите цель (клик по врагу)"
		elif current_turn == "player":
			var fighter = player_team[current_attacker_index]
			turn_info.text = "Ваш ход: " + fighter["name"]
		else:
			turn_info.text = "Ход противника..."
	
	lock_buttons(current_turn != "player" or buttons_locked or awaiting_target_selection or awaiting_zone_selection)

func lock_buttons(locked: bool):
	var attack_btn = get_node_or_null("AttackBtn")
	var defend_btn = get_node_or_null("DefendBtn")
	var run_btn = get_node_or_null("RunBtn")
	
	if attack_btn:
		attack_btn.disabled = locked
	if defend_btn:
		defend_btn.disabled = locked
	if run_btn:
		run_btn.disabled = locked or is_first_battle

func add_to_log(text: String):
	battle_log_lines.insert(0, text)
	if battle_log_lines.size() > max_log_lines:
		battle_log_lines.resize(max_log_lines)
	ui_builder.update_log(self, battle_log_lines, max_log_lines)

# ========== КНОПКИ ДЕЙСТВИЙ ==========

func on_attack():
	if current_turn != "player" or buttons_locked or awaiting_target_selection or awaiting_zone_selection:
		return
	
	if enemy_team.size() == 0:
		add_to_log("❌ Нет врагов для атаки!")
		return
	
	print("🎯 Кнопка АТАКА нажата")
	
	# ШАГ 1: Выбор зоны удара
	awaiting_zone_selection = true
	buttons_locked = true
	update_ui()
	show_zone_selection_menu()

func show_zone_selection_menu():
	print("🎯 Показываем меню выбора зоны")
	
	var zone_menu = ColorRect.new()
	zone_menu.size = Vector2(600, 450)
	zone_menu.position = Vector2(60, 410)
	zone_menu.color = Color(0.1, 0.05, 0.05, 0.95)
	zone_menu.name = "ZoneSelectionMenu"
	add_child(zone_menu)
	
	var menu_title = Label.new()
	menu_title.text = "🎯 ВЫБЕРИ ЗОНУ УДАРА"
	menu_title.position = Vector2(180, 430)
	menu_title.add_theme_font_size_override("font_size", 24)
	menu_title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	menu_title.set_meta("zone_menu_element", true)
	add_child(menu_title)
	
	var zones = combat_calculator.get_hit_zones()
	var y_pos = 490
	
	for zone in zones:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(560, 70)
		btn.position = Vector2(80, y_pos)
		btn.text = zone["icon"] + " " + zone["name"]
		btn.set_meta("zone_menu_element", true)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.2, 0.2, 1.0)
		btn.add_theme_stylebox_override("normal", style)
		
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.4, 0.3, 0.3, 1.0)
		btn.add_theme_stylebox_override("hover", style_hover)
		
		btn.add_theme_font_size_override("font_size", 20)
		
		var hint = Label.new()
		hint.text = "Урон x%.1f | Шанс: %d%%" % [zone["damage_mult"], zone["hit_chance"]]
		hint.position = Vector2(200, y_pos + 45)
		hint.add_theme_font_size_override("font_size", 14)
		hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
		hint.set_meta("zone_menu_element", true)
		add_child(hint)
		
		var zone_id = zone["id"]
		btn.pressed.connect(func():
			on_zone_selected(zone_id)
		)
		
		add_child(btn)
		y_pos += 85
	
	var cancel_btn = Button.new()
	cancel_btn.custom_minimum_size = Vector2(560, 60)
	cancel_btn.position = Vector2(80, y_pos + 10)
	cancel_btn.text = "❌ ОТМЕНА"
	cancel_btn.set_meta("zone_menu_element", true)
	
	var style_cancel = StyleBoxFlat.new()
	style_cancel.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	cancel_btn.add_theme_stylebox_override("normal", style_cancel)
	cancel_btn.add_theme_font_size_override("font_size", 20)
	
	cancel_btn.pressed.connect(func():
		close_zone_selection_menu()
		awaiting_zone_selection = false
		buttons_locked = false
		update_ui()
	)
	
	add_child(cancel_btn)

func close_zone_selection_menu():
	var menu = get_node_or_null("ZoneSelectionMenu")
	if menu:
		menu.queue_free()
	
	# Удаляем связанные элементы (кнопки и подсказки)
	for child in get_children():
		if child is Control or child is Label:
			if child.has_meta("zone_menu_element"):
				child.queue_free()

func on_zone_selected(zone_id: int):
	print("✅ Выбрана зона: " + str(zone_id))
	selected_zone = zone_id
	close_zone_selection_menu()
	
	var zone_name = combat_calculator.get_zone_name(zone_id)
	add_to_log("🎯 Зона атаки: " + zone_name)
	
	# ШАГ 2: Выбор цели
	awaiting_zone_selection = false
	awaiting_target_selection = true
	update_ui()

func select_target(target_index: int):
	if not awaiting_target_selection:
		return
	
	print("✅ Выбрана цель: " + enemy_team[target_index]["name"])
	current_target_index = target_index
	awaiting_target_selection = false
	
	add_to_log("🎯 Цель: " + enemy_team[target_index]["name"])
	
	# ШАГ 3: Выполнить атаку
	execute_attack()

func execute_attack():
	var attacker = player_team[current_attacker_index]
	var target = enemy_team[current_target_index]
	
	if attacker["health"] <= 0:
		add_to_log("💀 " + attacker["name"] + " мёртв!")
		next_player_fighter()
		return
	
	if target["health"] <= 0:
		add_to_log("🎯 Цель уже мертва!")
		buttons_locked = false
		update_ui()
		return
	
	var result = combat_calculator.calculate_attack(attacker, target, selected_zone)
	
	if not result["hit"]:
		add_to_log("❌ " + attacker["name"] + " промахнулся!")
	else:
		target["health"] -= result["damage"]
		add_to_log("⚔️ " + attacker["name"] + " → " + result["zone_name"] + " → " + target["name"] + " (-" + str(result["damage"]) + " HP)")
		
		if result.has("effect"):
			add_to_log(result["effect"])
		
		if target["health"] <= 0:
			add_to_log("💀 " + target["name"] + " повержен!")
			target["health"] = 0
	
	if player_stats:
		player_stats.on_melee_attack()
	
	update_ui()
	
	await get_tree().create_timer(1.5).timeout
	
	if check_victory():
		return
	
	next_player_fighter()

func on_defend():
	if current_turn != "player" or buttons_locked:
		return
	
	buttons_locked = true
	var attacker = player_team[current_attacker_index]
	
	add_to_log("🛡️ " + attacker["name"] + " защищается")
	attacker["defending"] = true
	
	await get_tree().create_timer(1.0).timeout
	next_player_fighter()

func on_run():
	if is_first_battle:
		add_to_log("⚠️ В первом бою убежать нельзя!")
		return
	
	if current_turn != "player" or buttons_locked:
		return
	
	buttons_locked = true
	
	var run_chance = combat_calculator.calculate_run_chance(player_team)
	
	if randf() < run_chance:
		add_to_log("🏃 Успешно сбежали!")
		await get_tree().create_timer(1.5).timeout
		save_team_health()
		battle_ended.emit(false)
		queue_free()
	else:
		add_to_log("🏃 Не удалось сбежать!")
		await get_tree().create_timer(1.0).timeout
		next_player_fighter()

# ========== УПРАВЛЕНИЕ ХОДАМИ ==========

func start_player_turn():
	current_turn = "player"
	current_attacker_index = 0
	awaiting_target_selection = false
	awaiting_zone_selection = false
	buttons_locked = false
	
	while current_attacker_index < player_team.size() and player_team[current_attacker_index]["health"] <= 0:
		current_attacker_index += 1
	
	if current_attacker_index >= player_team.size():
		start_enemy_turn()
		return
	
	add_to_log("🎯 Ваш ход: " + player_team[current_attacker_index]["name"])
	update_ui()

func next_player_fighter():
	current_attacker_index += 1
	
	while current_attacker_index < player_team.size() and player_team[current_attacker_index]["health"] <= 0:
		current_attacker_index += 1
	
	if current_attacker_index >= player_team.size():
		start_enemy_turn()
	else:
		buttons_locked = false
		awaiting_target_selection = false
		awaiting_zone_selection = false
		update_ui()
		add_to_log("🎯 Ход: " + player_team[current_attacker_index]["name"])

func start_enemy_turn():
	current_turn = "enemy"
	current_attacker_index = 0
	buttons_locked = true
	
	add_to_log("👹 Ход противника!")
	update_ui()
	
	await get_tree().create_timer(1.0).timeout
	enemy_attack_sequence()

func enemy_attack_sequence():
	while current_attacker_index < enemy_team.size() and enemy_team[current_attacker_index]["health"] <= 0:
		current_attacker_index += 1
	
	if current_attacker_index >= enemy_team.size():
		start_player_turn()
		return
	
	var attacker = enemy_team[current_attacker_index]
	var alive_targets = []
	
	for i in range(player_team.size()):
		if player_team[i]["health"] > 0:
			alive_targets.append(i)
	
	if alive_targets.size() == 0:
		lose_battle()
		return
	
	var target_index = alive_targets[randi() % alive_targets.size()]
	var target = player_team[target_index]
	var zone = randi() % 4
	
	var result = combat_calculator.calculate_attack(attacker, target, zone)
	
	if not result["hit"]:
		add_to_log("❌ " + attacker["name"] + " промахнулся!")
	else:
		if target.get("defending", false):
			result["damage"] = int(result["damage"] * 0.5)
			add_to_log("🛡️ " + target["name"] + " блокирует урон!")
			target["defending"] = false
		
		target["health"] -= result["damage"]
		add_to_log("💢 " + attacker["name"] + " → " + result["zone_name"] + " → " + target["name"] + " (-" + str(result["damage"]) + " HP)")
		
		if target["health"] <= 0:
			add_to_log("💀 " + target["name"] + " повержен!")
			target["health"] = 0
	
	update_ui()
	await get_tree().create_timer(1.5).timeout
	
	if check_defeat():
		return
	
	current_attacker_index += 1
	enemy_attack_sequence()

# ========== ПРОВЕРКИ ПОБЕДЫ/ПОРАЖЕНИЯ ==========

func check_victory() -> bool:
	for enemy in enemy_team:
		if enemy["health"] > 0:
			return false
	win_battle()
	return true

func check_defeat() -> bool:
	for fighter in player_team:
		if fighter["health"] > 0:
			return false
	lose_battle()
	return true

func win_battle():
	add_to_log("🎉 ПОБЕДА!")
	
	var reward = 0
	for enemy in enemy_team:
		reward += enemy["strength"] * 15
	
	if player_data:
		player_data["balance"] += reward
		player_data["reputation"] += 15
	
	add_to_log("💰 +" + str(reward) + " руб., +15 репутации")
	
	await get_tree().create_timer(2.5).timeout
	save_team_health()
	battle_ended.emit(true)
	queue_free()

func lose_battle():
	add_to_log("💀 ПОРАЖЕНИЕ...")
	
	if player_data:
		player_data["balance"] = max(0, player_data["balance"] - 100)
	
	add_to_log("💸 -100 руб.")
	
	await get_tree().create_timer(2.5).timeout
	
	for fighter in player_team:
		fighter["health"] = max(1, int(fighter["max_health"] * 0.2))
	
	save_team_health()
	battle_ended.emit(false)
	queue_free()

func save_team_health():
	if player_data and player_team.size() > 0:
		player_data["health"] = player_team[0]["health"]
