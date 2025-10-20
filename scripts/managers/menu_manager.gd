# menu_manager.gd (ИСПРАВЛЕН - LAYER 200 ДЛЯ ВСЕХ МЕНЮ)
extends Node

var gang_manager
var quest_system
var districts_system
var simple_jobs
var player_stats
var save_manager

var player_data: Dictionary
var gang_members: Array

func initialize(p_player_data, p_gang_members):
	player_data = p_player_data
	gang_members = p_gang_members
	
	gang_manager = get_node("/root/GangManager")
	quest_system = get_node_or_null("/root/QuestSystem")
	districts_system = get_node_or_null("/root/DistrictsSystem")
	simple_jobs = get_node_or_null("/root/SimpleJobs")
	player_stats = get_node_or_null("/root/PlayerStats")
	save_manager = get_node("/root/SaveManager")

func show_gang_menu(main_node: Node):
	gang_manager.show_gang_menu(main_node, gang_members)

func show_districts_menu(main_node: Node):
	if not districts_system:
		main_node.show_message("Система районов недоступна")
		return
	main_node.show_districts_menu()

func show_quests_menu(main_node: Node):
	if quest_system:
		quest_system.show_quests_menu(main_node)
	else:
		main_node.show_message("Квесты - в разработке")

func show_main_menu(main_node: Node):
	var menu_layer = CanvasLayer.new()
	menu_layer.name = "MainMenuLayer"
	menu_layer.layer = 200  # ✅ КРИТИЧНО! ВЫШЕ сетки (5) и UI (50)
	main_node.add_child(menu_layer)
	
	# ✅ Полупрозрачный overlay (блокирует клики)
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.position = Vector2(0, 0)
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_layer.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(500, 850)
	bg.position = Vector2(110, 215)
	bg.color = Color(0.05, 0.05, 0.05, 0.95)
	menu_layer.add_child(bg)
	
	var title = Label.new()
	title.text = "МЕНЮ"
	title.position = Vector2(310, 245)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	menu_layer.add_child(title)
	
	var options = ["Продолжить", "Сохранить игру", "Загрузить игру", "Квесты", "Инвентарь", "Статистика", "Тест бой", "Выход"]
	var y_pos = 320
	
	for option in options:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(460, 50)
		btn.position = Vector2(130, y_pos)
		btn.text = option
		btn.name = "MenuOption_" + option
		
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.25, 0.25, 0.3, 1.0)
		btn.add_theme_stylebox_override("normal", style_normal)
		
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.35, 0.35, 0.4, 1.0)
		btn.add_theme_stylebox_override("hover", style_hover)
		
		btn.add_theme_font_size_override("font_size", 20)
		btn.add_theme_color_override("font_color", Color.WHITE)
		
		var current_option = option
		btn.pressed.connect(func(): handle_menu_option(current_option, main_node))
		
		menu_layer.add_child(btn)
		y_pos += 70
	
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(460, 50)
	close_btn.position = Vector2(130, 1000)
	close_btn.text = "ЗАКРЫТЬ"
	close_btn.name = "CloseMainMenu"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): 
		var menu = main_node.get_node_or_null("MainMenuLayer")
		if menu:
			menu.queue_free()
	)
	menu_layer.add_child(close_btn)

func handle_menu_option(option: String, main_node: Node):
	var menu_layer = main_node.get_node_or_null("MainMenuLayer")
	
	match option:
		"Продолжить":
			if menu_layer:
				menu_layer.queue_free()
		
		"Сохранить игру":
			save_game(main_node)
		
		"Загрузить игру":
			load_game(main_node)
		
		"Квесты":
			if menu_layer:
				menu_layer.queue_free()
			show_quests_menu(main_node)
		
		"Инвентарь":
			if menu_layer:
				menu_layer.queue_free()
			var inventory_manager = get_node("/root/InventoryManager")
			inventory_manager.show_inventory_for_member(main_node, 0, gang_members, player_data)
		
		"Статистика":
			if menu_layer:
				menu_layer.queue_free()
			show_stats_window(main_node)
		
		"Тест бой":
			if menu_layer:
				menu_layer.queue_free()
			main_node.show_enemy_selection_menu()
		
		"Выход":
			main_node.get_tree().quit()

func save_game(main_node: Node):
	var quest_data = {}
	if quest_system:
		quest_data = {
			"active_quests": quest_system.active_quests.duplicate(true),
			"completed_quests": quest_system.completed_quests.duplicate(true)
		}
	
	var success = save_manager.save_game(player_data, gang_members, quest_data)
	if success:
		main_node.show_message("💾 Игра сохранена!")
	else:
		main_node.show_message("❌ Ошибка сохранения!")

func load_game(main_node: Node):
	if not save_manager.has_save():
		main_node.show_message("⚠️ Нет сохранённой игры!")
		return
	
	var save_data = save_manager.load_game()
	if save_data.is_empty():
		main_node.show_message("❌ Ошибка загрузки!")
		return
	
	player_data = save_data.get("player_data", player_data)
	gang_members = save_data.get("gang_members", gang_members)
	
	if quest_system and save_data.has("quest_system"):
		var quest_data = save_data["quest_system"]
		quest_system.active_quests = quest_data.get("active_quests", [])
		quest_system.completed_quests = quest_data.get("completed_quests", [])
	
	if player_stats:
		var items_db = get_node("/root/ItemsDB")
		player_stats.recalculate_equipment_bonuses(player_data["equipment"], items_db)
	
	main_node.update_ui()
	main_node.show_message("✅ Игра загружена!")
	
	var menu_layer = main_node.get_node_or_null("MainMenuLayer")
	if menu_layer:
		menu_layer.queue_free()

func show_stats_window(main_node: Node):
	if not player_stats:
		main_node.show_message("Статистика недоступна")
		return
	
	var stats_popup = CanvasLayer.new()
	stats_popup.name = "StatsPopup"
	stats_popup.layer = 200  # ✅ ВЫШЕ сетки
	main_node.add_child(stats_popup)
	
	# ✅ Overlay
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.position = Vector2(0, 0)
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	stats_popup.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(680, 950)
	bg.position = Vector2(20, 165)
	bg.color = Color(0.05, 0.05, 0.05, 0.98)
	stats_popup.add_child(bg)
	
	var title = Label.new()
	title.text = "📊 СТАТИСТИКА"
	title.position = Vector2(250, 185)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	stats_popup.add_child(title)
	
	var stats_text = player_stats.get_stats_text()
	var label = Label.new()
	label.text = stats_text
	label.position = Vector2(40, 235)
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color.WHITE)
	stats_popup.add_child(label)
	
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(640, 50)
	close_btn.position = Vector2(40, 1050)
	close_btn.text = "ЗАКРЫТЬ"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): stats_popup.queue_free())
	
	stats_popup.add_child(close_btn)
