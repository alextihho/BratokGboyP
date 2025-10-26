# battle_manager.gd (v2.1 - ИСПРАВЛЕНО)
extends Node

var quest_system
var districts_system

func initialize():
	quest_system = get_node_or_null("/root/QuestSystem")
	districts_system = get_node_or_null("/root/DistrictsSystem")
	print("⚔️ Battle Manager v2.1 (групповые бои + сохранение HP)")

func show_enemy_selection_menu(main_node):
	var enemy_menu = CanvasLayer.new()
	enemy_menu.name = "EnemySelectionMenu"
	enemy_menu.layer = 150
	main_node.add_child(enemy_menu)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	enemy_menu.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(500, 700)
	bg.position = Vector2(110, 290)
	bg.color = Color(0.05, 0.02, 0.02, 0.98)
	enemy_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "ВЫБЕРИ ПРОТИВНИКА"
	title.position = Vector2(230, 310)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	enemy_menu.add_child(title)
	
	var enemies = [
		{"name": "Пьяный (легко)", "type": "drunkard", "desc": "1-3 врага"},
		{"name": "Гопник (нормально)", "type": "gopnik", "desc": "2-5 врагов"},
		{"name": "Хулиган (средне)", "type": "thug", "desc": "3-6 врагов"},
		{"name": "Бандит (сложно)", "type": "bandit", "desc": "4-8 врагов"},
		{"name": "Охранник (очень сложно)", "type": "guard", "desc": "5-10 врагов"},
		{"name": "Главарь (БОСС)", "type": "boss", "desc": "6-12 врагов"}
	]
	
	var y_pos = 360
	
	for enemy in enemies:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(460, 60)
		btn.position = Vector2(130, y_pos)
		btn.text = enemy["name"] + "\n" + enemy["desc"]
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.2, 0.2, 1.0)
		btn.add_theme_stylebox_override("normal", style)
		
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.4, 0.3, 0.3, 1.0)
		btn.add_theme_stylebox_override("hover", style_hover)
		
		btn.add_theme_font_size_override("font_size", 16)
		
		var enemy_type = enemy["type"]
		btn.pressed.connect(func():
			enemy_menu.queue_free()
			start_battle(main_node, enemy_type)
		)
		
		enemy_menu.add_child(btn)
		y_pos += 70
	
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(460, 50)
	close_btn.position = Vector2(130, 930)
	close_btn.text = "ОТМЕНА"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(func(): enemy_menu.queue_free())
	
	enemy_menu.add_child(close_btn)

func start_battle(main_node: Node, enemy_type: String = "gopnik", is_first_battle: bool = false):
	print("⚔️ Запуск боя: " + enemy_type)
	
	var battle_script = load("res://scripts/battle/battle.gd")
	if not battle_script:
		main_node.show_message("❌ Система боёв не найдена!")
		return
	
	var battle = battle_script.new()
	battle.name = "BattleScene"
	main_node.add_child(battle)
	
	# ✅ ИСПРАВЛЕНО: Передаём gang_members
	var gang_members = []
	if "gang_members" in main_node:
		gang_members = main_node.gang_members
	
	battle.setup(main_node.player_data, enemy_type, is_first_battle, gang_members)
	
	battle.battle_ended.connect(func(victory):
		print("🔔 СИГНАЛ battle_ended получен! Victory:", victory)
		
		# ✅ ИСПРАВЛЕНО: Сохраняем HP главного игрока после боя
		if battle.battle_logic and battle.battle_logic.player_team.size() > 0:
			var main_player = battle.battle_logic.player_team[0]  # Главный игрок всегда первый
			if main_player and main_player.has("hp"):
				main_node.player_data["health"] = max(1, main_player["hp"])  # Минимум 1 HP
				print("💚 HP после боя: %d" % main_node.player_data["health"])
			
			# ✅ ИСПРАВЛЕНО: Сохраняем HP членов банды
			for i in range(1, battle.battle_logic.player_team.size()):
				var gang_member = battle.battle_logic.player_team[i]
				if gang_member.has("gang_member_index"):
					var idx = gang_member["gang_member_index"]
					if idx < main_node.gang_members.size():
						main_node.gang_members[idx]["hp"] = max(1, gang_member["hp"])
						print("💚 HP члена банды %s: %d" % [gang_member["name"], gang_member["hp"]])
		
		if victory:
			main_node.show_message("✅ Победа в бою!")
			if quest_system:
				quest_system.check_quest_progress("combat", {"victory": true})
				quest_system.check_quest_progress("collect", {"balance": main_node.player_data["balance"]})
			
			if districts_system and main_node.has("current_location"):
				var district = districts_system.get_district_by_building(main_node.current_location)
				var influence_gain = 5
				districts_system.add_influence(district, "Игрок", influence_gain)
				main_node.show_message("🏴 Влияние в районе увеличено на " + str(influence_gain) + "%")
		else:
			main_node.show_message("💀 Поражение...")
		
		main_node.update_ui()
		
		print("⏰ Создаём таймер для закрытия боя...")
		
		# ✅ ИСПРАВЛЕНО v2: Захватываем battle в замыкание
		var battle_to_close = battle
		var close_timer = Timer.new()
		close_timer.wait_time = 2.0
		close_timer.one_shot = true
		main_node.add_child(close_timer)
		
		print("⏰ Таймер создан, подключаем timeout...")
		
		close_timer.timeout.connect(func():
			print("⏰ TIMEOUT! Закрываем окно боя...")
			if battle_to_close and is_instance_valid(battle_to_close):
				battle_to_close.queue_free()
				print("⚔️ Окно боя закрыто через queue_free()")
			else:
				print("❌ battle_to_close не валиден!")
			close_timer.queue_free()
		)
		
		print("⏰ Запускаем таймер...")
		close_timer.start()
		print("⏰ Таймер запущен!")
	)
func apply_gang_experience(main_node, battle_logic, victory: bool):
	"""
	Даёт опыт всем участникам боя
	Вызывать в battle.battle_ended после сохранения HP
	"""
	if not battle_logic or not battle_logic.player_team:
		return
	
	# Базовый опыт за бой
	var base_exp = 10 if victory else 5
	
	# Бонус за сложность (количество врагов)
	var enemy_count = battle_logic.enemy_team.size()
	var difficulty_bonus = enemy_count * 2
	
	var total_exp = base_exp + difficulty_bonus
	
	print("📊 Опыт за бой: %d (базовый %d + сложность %d)" % [total_exp, base_exp, difficulty_bonus])
	
	# Прокачиваем главного игрока
	var player_stats = get_node_or_null("/root/PlayerStats")
	if player_stats:
		# Даём опыт в случайные статы
		var stats_to_train = ["STR", "AGI", "VIT"]
		for stat in stats_to_train:
			var exp_amount = randi_range(total_exp / 3, total_exp / 2)
			player_stats.add_experience(stat, exp_amount)
		
		main_node.show_message("📈 Вы получили опыт в бою!")
	
	# Прокачиваем членов банды
	for i in range(1, battle_logic.player_team.size()):
		var gang_fighter = battle_logic.player_team[i]
		
		if not gang_fighter.get("is_gang_member", false):
			continue
		
		if not gang_fighter.has("gang_member_index"):
			continue
		
		var member_index = gang_fighter["gang_member_index"]
		if member_index >= main_node.gang_members.size():
			continue
		
		var member = main_node.gang_members[member_index]
		
		# Инициализируем систему опыта если нет
		if not member.has("experience"):
			member["experience"] = 0
		if not member.has("level"):
			member["level"] = 1
		
		# Добавляем опыт
		member["experience"] += total_exp
		
		# Проверка уровня
		var exp_needed = member["level"] * 100  # 100 опыта на уровень
		
		if member["experience"] >= exp_needed:
			member["experience"] -= exp_needed
			member["level"] += 1
			
			# Повышаем статы при уровне
			level_up_gang_member(member, main_node)
			
			main_node.show_message("⭐ %s повысил уровень до %d!" % [member["name"], member["level"]])
			print("⬆️ %s: Уровень %d" % [member["name"], member["level"]])

func level_up_gang_member(member: Dictionary, main_node):
	"""
	Повышает статы члена банды при повышении уровня
	"""
	# Повышаем HP
	var hp_increase = randi_range(5, 10)
	if member.has("max_hp"):
		member["max_hp"] += hp_increase
	else:
		member["max_hp"] = member.get("hp", 80) + hp_increase
	
	member["hp"] = member.get("max_hp", 80)  # Восстанавливаем HP
	
	# Повышаем урон
	var damage_increase = randi_range(2, 5)
	if member.has("damage"):
		member["damage"] += damage_increase
	else:
		member["damage"] = member.get("strength", 10) + damage_increase
	
	# Повышаем защиту
	var defense_increase = randi_range(1, 3)
	if member.has("defense"):
		member["defense"] += defense_increase
	else:
		member["defense"] = defense_increase
	
	# Повышаем меткость
	var accuracy_increase = 0.02  # +2%
	if member.has("accuracy"):
		member["accuracy"] = min(0.95, member["accuracy"] + accuracy_increase)
	else:
		member["accuracy"] = 0.65 + accuracy_increase
	
	# Повышаем мораль
	if member.has("morale"):
		member["morale"] = min(100, member["morale"] + 5)
	else:
		member["morale"] = 85
	
	print("  📊 Новые статы: HP %d, Урон %d, Защита %d, Меткость %.2f" % [
		member.get("max_hp", 80),
		member.get("damage", 10),
		member.get("defense", 0),
		member.get("accuracy", 0.65)
	])

# ===== КАК ИСПОЛЬЗОВАТЬ =====
# В battle_manager.gd в функции start_battle() после сохранения HP добавьте:

# ПРИМЕР ИСПОЛЬЗОВАНИЯ в battle_manager.gd:
"""
battle.battle_ended.connect(func(victory):
	# Сохраняем HP (уже есть)
	if battle.battle_logic and battle.battle_logic.player_team.size() > 0:
		var main_player = battle.battle_logic.player_team[0]
		if main_player and main_player.has("hp"):
			main_node.player_data["health"] = max(1, main_player["hp"])
		
		for i in range(1, battle.battle_logic.player_team.size()):
			var gang_member = battle.battle_logic.player_team[i]
			if gang_member.has("gang_member_index"):
				var idx = gang_member["gang_member_index"]
				if idx < main_node.gang_members.size():
					main_node.gang_members[idx]["hp"] = max(1, gang_member["hp"])
	
	# ✅ ДОБАВИТЬ ЭТО:
	apply_gang_experience(main_node, battle.battle_logic, victory)
	
	# Остальной код победы/поражения...
	if victory:
		main_node.show_message("✅ Победа в бою!")
		# ...
)
"""

# ===== ОТОБРАЖЕНИЕ УРОВНЯ В gang_menu.gd =====
# Добавьте в gang_menu.gd при отображении члена банды:

"""
var level_label = Label.new()
level_label.text = "⭐ Уровень: %d" % member.get("level", 1)
level_label.position = Vector2(30, member_y + 135)
level_label.add_theme_font_size_override("font_size", 14)
level_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
add_child(level_label)

var exp_label = Label.new()
var exp = member.get("experience", 0)
var exp_needed = member.get("level", 1) * 100
exp_label.text = "📈 Опыт: %d/%d" % [exp, exp_needed]
exp_label.position = Vector2(200, member_y + 135)
exp_label.add_theme_font_size_override("font_size", 14)
exp_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 1.0))
add_child(exp_label)
"""
