# battle_manager.gd (v2.0 - ГРУППОВЫЕ БОИ)
extends Node

var quest_system
var districts_system

func initialize():
	quest_system = get_node_or_null("/root/QuestSystem")
	districts_system = get_node_or_null("/root/DistrictsSystem")
	print("⚔️ Battle Manager v2.0 (групповые бои)")

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
	
	var battle_script = load("res://scripts/battle/battle.gd")  # ✅ Новый путь
	if not battle_script:
		main_node.show_message("❌ Система боёв не найдена!")
		return
	
	var battle = battle_script.new()
	battle.name = "BattleScene"
	main_node.add_child(battle)
	battle.setup(main_node.player_data, enemy_type, is_first_battle)
	
	battle.battle_ended.connect(func(victory):
		if battle.player_data and battle.player_data.has("health"):
			main_node.player_data["health"] = battle.player_data["health"]
		
		if victory:
			main_node.show_message("✅ Победа в бою!")
			if quest_system:
				quest_system.check_quest_progress("combat", {"victory": true})
				quest_system.check_quest_progress("collect", {"balance": main_node.player_data["balance"]})
			
			if districts_system and main_node.current_location:
				var district = districts_system.get_district_by_building(main_node.current_location)
				var influence_gain = 5
				districts_system.add_influence(district, "Игрок", influence_gain)
				main_node.show_message("🏴 Влияние в районе увеличено на " + str(influence_gain) + "%")
		else:
			main_node.show_message("💀 Поражение...")
		
		main_node.update_ui()
	)
