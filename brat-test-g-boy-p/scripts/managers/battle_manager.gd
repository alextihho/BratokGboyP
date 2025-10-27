# battle_manager.gd (v2.3 - ИСПРАВЛЕНО: удалён дублирующий таймер закрытия UI)
extends Node

var quest_system
var districts_system

# Шаблоны для наград (из enemy_templates)
var enemy_reward_templates = {
	"drunkard": {"money": 20, "reputation": 5},
	"gopnik": {"money": 50, "reputation": 10},
	"thug": {"money": 80, "reputation": 15},
	"bandit": {"money": 120, "reputation": 20},
	"guard": {"money": 150, "reputation": 25},
	"boss": {"money": 300, "reputation": 50}
}

func initialize():
	quest_system = get_node_or_null("/root/QuestSystem")
	districts_system = get_node_or_null("/root/DistrictsSystem")
	print("⚔️ Battle Manager v2.3 (групповые бои + правильное закрытие UI)")

# ✅ ФИКС: Расчёт награды
func calculate_reward(enemy_type: String, enemy_count: int) -> Dictionary:
	if not enemy_reward_templates.has(enemy_type):
		enemy_type = "gopnik"
	var base = enemy_reward_templates[enemy_type]
	var money = base["money"] * enemy_count
	var rep = base["reputation"] * enemy_count
	if enemy_count > 1:
		money += int(money * 0.2)
		rep += int(rep * 0.1)
	return {"money": max(10, money), "reputation": max(5, rep)}

# ✅ ФИКС: Опыт банды (реализована из примера)
func apply_gang_experience(main_node, battle_logic, victory):
	if not victory:
		return
	var total_exp = 50 * battle_logic.enemy_team.size()
	for member in main_node.gang_members:
		if not member.has("experience"):
			member["experience"] = 0
		if not member.has("level"):
			member["level"] = 1
		member["experience"] += total_exp
		var exp_needed = member["level"] * 100
		if member["experience"] >= exp_needed:
			member["experience"] -= exp_needed
			member["level"] += 1
			level_up_gang_member(member, main_node)
			main_node.show_message("⭐ %s повысил уровень до %d!" % [member["name"], member["level"]])

func show_enemy_selection_menu(main_node):
	# Твой оригинальный код без изменений
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
	
	# Передаём gang_members (если есть)
	var gang_members = []
	if "gang_members" in main_node:
		gang_members = main_node.gang_members
	
	battle.setup(main_node.player_data, enemy_type, is_first_battle, gang_members)
	
	# ✅ ИСПРАВЛЕНО: Убран таймер - закрытие UI теперь ТОЛЬКО в battle.gd
	battle.battle_ended.connect(func(victory):
		print("🔔 СИГНАЛ battle_ended получен! Victory: %s" % victory)
		
		# Сохранение HP
		if battle.battle_logic and battle.battle_logic.player_team.size() > 0:
			var main_player = battle.battle_logic.player_team[0]
			if main_player and main_player.has("hp"):
				main_node.player_data["health"] = max(1, main_player["hp"])
				print("💾 HP игрока: %d" % main_node.player_data["health"])
			
			for i in range(1, battle.battle_logic.player_team.size()):
				var gang_member = battle.battle_logic.player_team[i]
				if gang_member.has("gang_member_index"):
					var idx = gang_member["gang_member_index"]
					if idx < main_node.gang_members.size():
						main_node.gang_members[idx]["hp"] = max(1, gang_member["hp"])
						print("💾 HP %s: %d" % [main_node.gang_members[idx]["name"], main_node.gang_members[idx]["hp"]])
		
		# Опыт банды
		apply_gang_experience(main_node, battle.battle_logic, victory)
		
		# Обработка результата
		if victory:
			var enemy_count = battle.battle_logic.enemy_team.size() if battle.battle_logic else 1
			var reward = calculate_reward(enemy_type, enemy_count)
			main_node.player_data["balance"] += reward["money"]
			main_node.player_data["reputation"] += reward["reputation"]
			
			# Квесты/районы
			if main_node.quest_system:
				main_node.quest_system.progress_quest("win_fights", 1)
			if main_node.current_location and main_node.districts_system:
				main_node.districts_system.capture_district(main_node.current_location, "player_gang")
			
			main_node.show_message("✅ Победа!\n💰 +%d руб.\n⭐ +%d репы" % [reward["money"], reward["reputation"]])
			print("🏆 Победа! Награда: %s" % reward)
		else:
			main_node.player_data["balance"] = max(0, main_node.player_data["balance"] - 50)
			main_node.show_message("❌ Поражение!\n💸 -50 руб.")
			print("💀 Поражение!")
		
		# ✅ ВАЖНО: Не создаём таймер здесь! 
		# Закрытие UI происходит автоматически в battle.gd (win_battle/lose_battle)
		
		main_node.update_ui()  # Обновление UI
	)

# Твоя функция level_up_gang_member (без изменений)
func level_up_gang_member(member: Dictionary, main_node):
	var hp_increase = randi_range(5, 10)
	if member.has("max_hp"):
		member["max_hp"] += hp_increase
	else:
		member["max_hp"] = member.get("hp", 80) + hp_increase
	
	member["hp"] = member.get("max_hp", 80)
	
	var damage_increase = randi_range(2, 5)
	if member.has("damage"):
		member["damage"] += damage_increase
	else:
		member["damage"] = member.get("strength", 10) + damage_increase
	
	var defense_increase = randi_range(1, 3)
	if member.has("defense"):
		member["defense"] += defense_increase
	else:
		member["defense"] = defense_increase
	
	var accuracy_increase = 0.02
	if member.has("accuracy"):
		member["accuracy"] = min(0.95, member["accuracy"] + accuracy_increase)
	else:
		member["accuracy"] = 0.65 + accuracy_increase
	
	if member.has("morale"):
		member["morale"] = min(100, member["morale"] + 5)
	else:
		member["morale"] = 85
	
	print("📊 %s: HP %d, Урон %d, Защита %d, Меткость %.2f" % [
		member.get("name", "Боец"),
		member.get("max_hp", 80),
		member.get("damage", 10),
		member.get("defense", 0),
		member.get("accuracy", 0.65)
	])
