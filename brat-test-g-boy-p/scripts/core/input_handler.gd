# scripts/core/input_handler.gd
extends Node

# ===== ОБРАБОТКА ВВОДА =====
func handle_input(event, game_controller) -> bool:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var click_pos = game_controller.get_viewport().get_mouse_position()
			
			print("🎯 CLICK: " + str(click_pos))
			
			# Блокируем если идёт бой
			if game_controller.get_node_or_null("BattleScene"):
				print("⚠️ Бой идёт")
				return true
			
			# Проверяем открытые меню
			if has_any_menu_open(game_controller):
				print("⚠️ Меню открыто")
				return true
			
			# Проверка клика на UI
			if is_click_on_ui(click_pos):
				print("⚠️ Клик на UI")
				return true
			
			print("✅ Клик на сетку разрешён")
			
			# Проверка клика по сетке
			if game_controller.grid_movement_manager:
				game_controller.grid_movement_manager.handle_grid_click(click_pos)
			
			return true
	
	return false

# ===== ПРОВЕРКА КЛИКА НА UI =====
func is_click_on_ui(click_pos: Vector2) -> bool:
	# Верхняя панель
	if click_pos.y < 120:
		print("   → Верхняя панель")
		return true
	
	# Нижняя панель
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

# ===== ПРОВЕРКА ОТКРЫТЫХ МЕНЮ =====
func has_any_menu_open(game_controller) -> bool:
	var menus = [
		"BuildingMenu", "GangMenu", "InventoryMenu", "QuestMenu",
		"DistrictsMenu", "MainMenuLayer", "MovementMenu",
		"HospitalMenu", "JobsMenu", "SellMenu"
	]
	
	for menu_name in menus:
		if game_controller.get_node_or_null(menu_name):
			return true
	
	return false
