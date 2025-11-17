# action_handler.gd (ИСПРАВЛЕНО - БЕЗ АВТОБИТВЫ)
extends Node

var building_system
var quest_system
var random_events
var districts_system
var hospital_system

var player_data: Dictionary
var current_location: String = ""

func initialize(p_player_data: Dictionary):
	player_data = p_player_data
	
	building_system = get_node("/root/BuildingSystem")
	quest_system = get_node_or_null("/root/QuestSystem")
	random_events = get_node_or_null("/root/RandomEvents")
	districts_system = get_node_or_null("/root/DistrictsSystem")
	hospital_system = get_node_or_null("/root/HospitalSystem")
	
	print("✅ Action Handler инициализирован (без автобитвы)")

func handle_location_action(location: String, action_index: int, main_node: Node):
	current_location = location
	print("🎯 Обработка действия в " + location + ", индекс: " + str(action_index))
	
	# ✅ Логируем действие в лог событий
	main_node.add_to_log("📍 Зашли: %s" % location)
	
	# ✅ НОВОЕ: Тратим время на действие (5-15 минут)
	var time_system = get_node_or_null("/root/TimeSystem")
	if time_system:
		var time_cost = randi_range(5, 15)
		time_system.add_minutes(time_cost)
		print("⏰ Время действия: +%d минут" % time_cost)
	
	# ✅ НОВОЕ: Обработка ФСБ
	if location == "ФСБ":
		handle_fsb_action(action_index, main_node)
		return
	
	# Специальная обработка больницы
	if location == "БОЛЬНИЦА":
		handle_hospital_action(action_index, main_node)
		return

	# ✅ ФИКС: Интеграция АВТОСАЛОНА
	if location == "АВТОСАЛОН":
		handle_car_dealership_action(action_index, main_node)
		return

	# ✅ ФИКС: Интеграция БАРА
	if location == "БАР":
		handle_bar_action(action_index, main_node)
		return
	
	# Обработка остальных локаций через building_system
	if building_system:
		building_system.handle_building_action(location, action_index, player_data, main_node)
	
	# Проверка прогресса квестов
	if quest_system:
		quest_system.check_quest_progress("collect", {"balance": player_data["balance"]})
		quest_system.check_quest_progress("item", {"inventory": player_data["inventory"]})
		quest_system.check_quest_progress("reputation", {"reputation": player_data["reputation"]})

func handle_hospital_action(action_index: int, main_node: Node):
	match action_index:
		0:  # Лечиться
			# ✅ Закрываем меню выбора действий ПЕРЕД открытием UI лечения
			main_node.close_location_menu()
			
			if hospital_system:
				hospital_system.show_hospital_menu(main_node, player_data)
			else:
				main_node.show_message("Система больниц недоступна")
		1:  # Купить аптечку
			if player_data["balance"] >= 100:
				player_data["balance"] -= 100
				player_data["inventory"].append("Аптечка")
				main_node.show_message("✅ Куплена аптечка (100 руб.)")
				main_node.update_ui()
			else:
				main_node.show_message("❌ Недостаточно денег! Нужно: 100 руб.")
		2:  # Уйти
			main_node.close_location_menu()

func trigger_location_events(location_name: String, main_node: Node):
	print("🎲 Триггер событий для локации: " + location_name)
	
	# ✅ ИСПРАВЛЕНО: НЕ запускаем НИКАКИЕ битвы автоматически
	# random_events НЕ ИСПОЛЬЗУЕМ ВООБЩЕ
	
	# Проверка прогресса квестов
	if quest_system:
		quest_system.check_quest_progress("visit", {"location": location_name})
	
	# Добавление влияния при посещении
	if districts_system:
		var district = districts_system.get_district_by_building(location_name)
		if district != "":
			districts_system.add_influence(district, "Игрок", 1)
			print("📊 +1% влияния в районе: " + district)

func get_current_location() -> String:
	return current_location

func handle_fsb_action(action_index: int, main_node: Node):
	var police_system = get_node_or_null("/root/PoliceSystem")
	
	match action_index:
		0:  # Дать взятку
			if police_system:
				police_system.show_fsb_bribe_menu(main_node)
			else:
				main_node.show_message("Система полиции недоступна")
		1:  # Уйти
			main_node.close_location_menu()

# ✅ АВТОСАЛОН - ИСПРАВЛЕНО
func handle_car_dealership_action(action_index: int, main_node: Node):
	var car_system = get_node_or_null("/root/CarSystem")

	if not car_system:
		main_node.show_message("❌ Автосалон закрыт")
		print("⚠️ CarSystem НЕ НАЙДЕН в autoload!")
		return

	print("✅ CarSystem найден, открываем автосалон")

	match action_index:
		0: # 🚗 Выбор машины
			main_node.close_location_menu()
			car_system.show_car_dealership_menu(main_node, main_node.player_data)
		1: # 🔧 Починить машину
			main_node.close_location_menu()
			car_system.show_car_dealership_menu(main_node, main_node.player_data)
		2: # 🚪 Уйти
			main_node.close_location_menu()

# ✅ БАР - ИСПРАВЛЕНО
func handle_bar_action(action_index: int, main_node: Node):
	var bar_system = get_node_or_null("/root/BarSystem")

	if not bar_system:
		main_node.show_message("❌ Бар закрыт")
		print("⚠️ BarSystem НЕ НАЙДЕН в autoload!")
		return

	print("✅ BarSystem найден, открываем бар")

	var gang_members = main_node.gang_members if "gang_members" in main_node else []

	match action_index:
		0: # 🍺 Отдохнуть
			main_node.close_location_menu()
			bar_system.show_bar_menu(main_node, main_node.player_data, gang_members)
		1: # 🍻 Бухать с бандой
			main_node.close_location_menu()
			bar_system.show_bar_menu(main_node, main_node.player_data, gang_members)
		2: # 🚪 Уйти
			main_node.close_location_menu()
