# grid_movement_manager.gd (ИСПРАВЛЕН - СТРОГАЯ ПРОВЕРКА ГРАНИЦ)
extends Node

signal movement_started(from: String, to: String)
signal movement_completed(square: String)

var main_node
var grid_system
var movement_system
var time_system

var movement_menu = null
var pending_target_square: String = ""
var is_menu_open: bool = false
var is_moving: bool = false

func initialize(p_main_node, p_grid_system, p_movement_system):
	main_node = p_main_node
	grid_system = p_grid_system
	movement_system = p_movement_system
	time_system = get_node_or_null("/root/TimeSystem")
	print("🚶 Grid Movement Manager инициализирован")

func handle_grid_click(click_pos: Vector2):
	# ✅ СТРОГАЯ ПРОВЕРКА ГРАНИЦ!
	print("🎯 Grid click check: " + str(click_pos))
	
	# ✅ БЛОКИРУЕМ верхнюю панель (y < 120)
	if click_pos.y < 120:
		print("   ❌ ВЕРХНЯЯ ПАНЕЛЬ (y=%d)" % click_pos.y)
		return
	
	# ✅ БЛОКИРУЕМ нижнюю панель (y >= 1180)
	if click_pos.y >= 1180:
		print("   ❌ НИЖНЯЯ ПАНЕЛЬ (y=%d)" % click_pos.y)
		return
	
	# ✅ БЛОКИРУЕМ если идёт перемещение
	if is_moving:
		print("   ⚠️ Идёт перемещение")
		return
	
	# ✅ БЛОКИРУЕМ если меню открыто
	if is_menu_open:
		print("   ⚠️ Меню передвижения открыто")
		return
	
	# ✅ БЛОКИРУЕМ если идёт бой
	if main_node.get_node_or_null("BattleScene"):
		print("   ⚠️ Бой идёт")
		return
	
	# ✅ БЛОКИРУЕМ если ЛЮБОЕ меню открыто
	var open_menus = [
		"BuildingMenu", "GangMenu", "InventoryMenu", "QuestMenu",
		"DistrictsMenu", "MainMenuLayer", "HospitalMenu", "JobsMenu"
	]
	
	for menu_name in open_menus:
		if main_node.get_node_or_null(menu_name):
			print("   ⚠️ Открыто меню: " + menu_name)
			return
	
	# ✅ Получаем квадрат
	var clicked_square = grid_system.get_square_at_position(click_pos)
	
	if clicked_square == "":
		print("   ⚠️ Клик вне сетки")
		return
	
	var current_square = grid_system.get_player_square()
	
	# ✅ Если кликнули на свой квадрат
	if clicked_square == current_square:
		var building = grid_system.get_building(clicked_square)
		if building and building != "":
			print("   🏢 Открываем меню здания: " + building)
			main_node.show_location_menu(building)
		else:
			print("   ⚠️ Уже на этом квадрате")
		return
	
	# ✅ Проверяем есть ли здание в ЦЕЛЕВОЙ клетке
	var building = grid_system.get_building(clicked_square)
	
	if building and building != "":
		print("   🎯 Клик на здание: " + building)
		show_movement_menu(clicked_square, click_pos, building)
	else:
		print("   🎯 Клик на пустой квадрат: " + clicked_square)
		show_movement_menu(clicked_square, click_pos, "")

func show_movement_menu(target_square: String, click_pos: Vector2, building_name: String = ""):
	close_movement_menu()
	
	pending_target_square = target_square
	is_menu_open = true
	
	var current_square = grid_system.get_player_square()
	var distance = grid_system.get_distance(current_square, target_square)
	var time_walk = distance * 30
	
	movement_menu = CanvasLayer.new()
	movement_menu.name = "MovementMenu"
	movement_menu.layer = 150
	main_node.add_child(movement_menu)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.position = Vector2(0, 0)
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	movement_menu.add_child(overlay)
	
	var menu_bg = ColorRect.new()
	menu_bg.size = Vector2(400, 320)
	menu_bg.position = Vector2(160, 480)
	menu_bg.color = Color(0.1, 0.1, 0.1, 0.95)
	menu_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	movement_menu.add_child(menu_bg)
	
	var title = Label.new()
	if building_name != "":
		title.text = "🏢 ПЕРЕЙТИ: " + building_name
	else:
		title.text = "🚶 ПЕРЕДВИЖЕНИЕ"
	title.position = Vector2(200, 500)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	movement_menu.add_child(title)
	
	var info = Label.new()
	info.text = "Расстояние: %d квадратов\nВремя: ~%d мин" % [distance, time_walk]
	info.position = Vector2(240, 550)
	info.add_theme_font_size_override("font_size", 16)
	info.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	movement_menu.add_child(info)
	
	var walk_btn = Button.new()
	walk_btn.custom_minimum_size = Vector2(360, 60)
	walk_btn.position = Vector2(180, 630)
	walk_btn.text = "🚶 ИДТИ (~%d мин)" % time_walk
	walk_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var style_walk = StyleBoxFlat.new()
	style_walk.bg_color = Color(0.2, 0.5, 0.2, 1.0)
	walk_btn.add_theme_stylebox_override("normal", style_walk)
	
	var style_walk_hover = StyleBoxFlat.new()
	style_walk_hover.bg_color = Color(0.3, 0.6, 0.3, 1.0)
	walk_btn.add_theme_stylebox_override("hover", style_walk_hover)
	
	walk_btn.add_theme_font_size_override("font_size", 20)
	walk_btn.pressed.connect(func():
		print("✅ Начало перехода к: " + pending_target_square)
		start_movement(pending_target_square, time_walk, building_name)
		close_movement_menu()
	)
	movement_menu.add_child(walk_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.custom_minimum_size = Vector2(360, 60)
	cancel_btn.position = Vector2(180, 710)
	cancel_btn.text = "❌ ОТМЕНА"
	cancel_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var style_cancel = StyleBoxFlat.new()
	style_cancel.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	cancel_btn.add_theme_stylebox_override("normal", style_cancel)
	
	var style_cancel_hover = StyleBoxFlat.new()
	style_cancel_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	cancel_btn.add_theme_stylebox_override("hover", style_cancel_hover)
	
	cancel_btn.add_theme_font_size_override("font_size", 20)
	cancel_btn.pressed.connect(func():
		print("❌ Отмена")
		close_movement_menu()
	)
	movement_menu.add_child(cancel_btn)

func close_movement_menu():
	if movement_menu:
		movement_menu.queue_free()
		movement_menu = null
		is_menu_open = false
		pending_target_square = ""

func start_movement(target_square: String, time_minutes: int, building_name: String = ""):
	var current_square = grid_system.get_player_square()
	
	is_moving = true
	
	print("🚶 Начало движения: %s → %s" % [current_square, target_square])
	
	show_movement_animation(time_minutes, building_name)
	
	if time_system:
		time_system.add_minutes(time_minutes)
	
	await main_node.get_tree().create_timer(1.5).timeout
	
	grid_system.set_player_square(target_square)
	
	if main_node.player_data:
		main_node.player_data["current_square"] = target_square
	
	main_node.update_ui()
	
	is_moving = false
	
	movement_completed.emit(target_square)
	
	if building_name != "":
		await main_node.get_tree().create_timer(0.3).timeout
		print("🏢 Прибыли к зданию: " + building_name)
		main_node.show_location_menu(building_name)

func show_movement_animation(time_minutes: int, building_name: String):
	var anim_layer = CanvasLayer.new()
	anim_layer.name = "MovementAnimation"
	anim_layer.layer = 200
	main_node.add_child(anim_layer)
	
	var bg = ColorRect.new()
	bg.size = Vector2(720, 1280)
	bg.color = Color(0, 0, 0, 0.7)
	anim_layer.add_child(bg)
	
	var icon = Label.new()
	icon.text = "🚶"
	icon.position = Vector2(320, 540)
	icon.add_theme_font_size_override("font_size", 64)
	anim_layer.add_child(icon)
	
	var text = Label.new()
	if building_name != "":
		text.text = "Идём к зданию:\n" + building_name
	else:
		text.text = "Перемещение..."
	text.position = Vector2(240, 640)
	text.add_theme_font_size_override("font_size", 22)
	text.add_theme_color_override("font_color", Color.WHITE)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anim_layer.add_child(text)
	
	var time_label = Label.new()
	time_label.text = "⏱ ~" + str(time_minutes) + " минут"
	time_label.position = Vector2(280, 710)
	time_label.add_theme_font_size_override("font_size", 18)
	time_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	anim_layer.add_child(time_label)
	
	var timer = Timer.new()
	timer.wait_time = 1.5
	timer.one_shot = true
	main_node.add_child(timer)
	
	timer.timeout.connect(func():
		if anim_layer and is_instance_valid(anim_layer):
			anim_layer.queue_free()
		timer.queue_free()
	)
	timer.start()

func check_arrival_events(square_id: String):
	var random_events = get_node_or_null("/root/RandomEvents")
	if random_events and randf() < 0.2:
		random_events.trigger_random_event("УЛИЦА", main_node.player_data, main_node)
