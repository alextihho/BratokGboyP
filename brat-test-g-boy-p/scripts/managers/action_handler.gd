# action_handler.gd - Обработчик действий локаций
extends Node

var player_data: Dictionary
var items_db
var building_system
var quest_system
var simple_jobs
var hospital_system
var police_system
var bar_system
var car_system
var time_system

func initialize(p_player_data: Dictionary):
	player_data = p_player_data
	
	# Загружаем системы
	items_db = get_node_or_null("/root/ItemsDB")
	building_system = get_node_or_null("/root/BuildingSystem")
	quest_system = get_node_or_null("/root/QuestSystem")
	simple_jobs = get_node_or_null("/root/SimpleJobs")
	hospital_system = get_node_or_null("/root/HospitalSystem")
	police_system = get_node_or_null("/root/PoliceSystem")
	bar_system = get_node_or_null("/root/BarSystem")
	car_system = get_node_or_null("/root/CarSystem")
	time_system = get_node_or_null("/root/TimeSystem")
	
	print("🎯 ActionHandler инициализирован")

func handle_location_action(location_name: String, action_index: int, main_node: Node):
	print("🎯 Обработка действия [%d] в локации: %s" % [action_index, location_name])
	
	match location_name:
		"ОБЩЕЖИТИЕ":
			handle_dorm_action(action_index, main_node)
		"ЛАРЁК":
			handle_kiosk_action(action_index, main_node)
		"ВОКЗАЛ":
			handle_station_action(action_index, main_node)
		"ГАРАЖ":
			handle_garage_action(action_index, main_node)
		"РЫНОК":
			handle_market_action(action_index, main_node)
		"ПОРТ":
			handle_port_action(action_index, main_node)
		"УЛИЦА":
			handle_street_action(action_index, main_node)
		"БОЛЬНИЦА":
			handle_hospital_action(action_index, main_node)
		"ФСБ":
			handle_fsb_action(action_index, main_node)
		"БАР":  # ✅ НОВОЕ
			handle_bar_action(action_index, main_node)
		"АВТОСАЛОН":  # ✅ НОВОЕ
			handle_car_dealership_action(action_index, main_node)
		_:
			main_node.show_message("❌ Действие для локации %s не определено!" % location_name)

# ===== ОБЩЕЖИТИЕ =====
func handle_dorm_action(action_index: int, main_node: Node):
	match action_index:
		0:  # Отдохнуть
			if time_system:
				time_system.add_hours(8)
			player_data["health"] = min(100, player_data["health"] + 50)
			main_node.show_message("😴 Вы хорошо отдохнули.\n❤️ Здоровье: +50")
			main_node.update_ui()
			main_node.close_location_menu()
		1:  # Поговорить с другом
			main_node.show_message("👋 Друг рассказал новости района")
			main_node.close_location_menu()
		2:  # Взять вещи
			main_node.show_message("📦 Взяли пару вещей из комнаты")
			main_node.close_location_menu()

# ===== ЛАРЁК =====
func handle_kiosk_action(action_index: int, main_node: Node):
	match action_index:
		0:  # Купить пиво (30р)
			if player_data["balance"] >= 30:
				player_data["balance"] -= 30
				player_data["inventory"].append("Пиво")
				main_node.show_message("🍺 Куплено пиво за 30 руб.")
				main_node.update_ui()
			else:
				main_node.show_message("❌ Недостаточно денег!")
			main_node.close_location_menu()
		1:  # Купить сигареты (15р)
			if player_data["balance"] >= 15:
				player_data["balance"] -= 15
				player_data["inventory"].append("Сигареты")
				main_node.show_message("🚬 Куплены сигареты за 15 руб.")
				main_node.update_ui()
			else:
				main_node.show_message("❌ Недостаточно денег!")
			main_node.close_location_menu()
		2:  # Купить кепку (50р)
			if player_data["balance"] >= 50:
				player_data["balance"] -= 50
				player_data["inventory"].append("Кепка")
				main_node.show_message("🧢 Куплена кепка за 50 руб.")
				main_node.update_ui()
			else:
				main_node.show_message("❌ Недостаточно денег!")
			main_node.close_location_menu()

# ===== ВОКЗАЛ =====
func handle_station_action(action_index: int, main_node: Node):
	match action_index:
		0:  # Купить билет
			main_node.show_message("🚂 Билеты пока недоступны")
			main_node.close_location_menu()
		1:  # Встретить контакт
			if quest_system:
				main_node.show_message("👤 Контакт сообщил важную информацию")
			main_node.close_location_menu()
		2:  # Осмотреться
			main_node.show_message("👀 Вокзал полон людей...")
			main_node.close_location_menu()

# ===== ГАРАЖ =====
func handle_garage_action(action_index: int, main_node: Node):
	match action_index:
		0:  # Купить биту (100р)
			if player_data["balance"] >= 100:
				player_data["balance"] -= 100
				player_data["inventory"].append("Бита")
				main_node.show_message("⚾ Куплена бита за 100 руб.")
				
				if quest_system:
					quest_system.update_quest("buy_weapon", 1)
				
				main_node.update_ui()
			else:
				main_node.show_message("❌ Недостаточно денег!")
			main_node.close_location_menu()
		1:  # Помочь механику
			if simple_jobs:
				main_node.close_location_menu()
				simple_jobs.show_job_menu(main_node)
			else:
				main_node.show_message("💼 Механик занят...")
				main_node.close_location_menu()
		2:  # Взять инструменты
			main_node.show_message("🔧 Взяли несколько инструментов")
			main_node.close_location_menu()

# ===== РЫНОК =====
func handle_market_action(action_index: int, main_node: Node):
	match action_index:
		0:  # Купить кожанку (200р)
			if player_data["balance"] >= 200:
				player_data["balance"] -= 200
				player_data["inventory"].append("Кожанка")
				main_node.show_message("🧥 Куплена кожанка за 200 руб.")
				main_node.update_ui()
			else:
				main_node.show_message("❌ Недостаточно денег!")
			main_node.close_location_menu()
		1:  # Продать вещь
			main_node.show_message("💰 Продажа пока недоступна")
			main_node.close_location_menu()
		2:  # Узнать новости
			main_node.show_message("📰 На рынке говорят о новых разборках...")
			main_node.close_location_menu()

# ===== ПОРТ =====
func handle_port_action(action_index: int, main_node: Node):
	match action_index:
		0:  # Купить ПМ (500р)
			if player_data["balance"] >= 500:
				player_data["balance"] -= 500
				player_data["inventory"].append("ПМ")
				main_node.show_message("🔫 Куплен ПМ за 500 руб.")
				
				if quest_system:
					quest_system.update_quest("buy_weapon", 1)
				
				main_node.update_ui()
			else:
				main_node.show_message("❌ Недостаточно денег!")
			main_node.close_location_menu()
		1:  # Купить отмычку (100р)
			if player_data["balance"] >= 100:
				player_data["balance"] -= 100
				player_data["inventory"].append("Отмычка")
				main_node.show_message("🔓 Куплена отмычка за 100 руб.")
				main_node.update_ui()
			else:
				main_node.show_message("❌ Недостаточно денег!")
			main_node.close_location_menu()
		2:  # Уйти
			main_node.close_location_menu()

# ===== УЛИЦА =====
func handle_street_action(action_index: int, main_node: Node):
	match action_index:
		0:  # Прогуляться
			if time_system:
				time_system.add_minutes(30)
			main_node.show_message("🚶 Прогулялись по улице")
			main_node.close_location_menu()
		1:  # Встретить знакомого
			main_node.show_message("👋 Встретили старого знакомого")
			main_node.close_location_menu()
		2:  # Посмотреть вокруг
			main_node.show_message("👀 Улицы полны жизни 90-х...")
			main_node.close_location_menu()

# ===== БОЛЬНИЦА =====
func handle_hospital_action(action_index: int, main_node: Node):
	match action_index:
		0:  # Лечиться
			if hospital_system:
				main_node.close_location_menu()
				# ✅ ИСПРАВЛЕНО: Передаем gang_members
				hospital_system.show_hospital_menu(
					main_node, 
					main_node.player_data,
					main_node.gang_members
				)
			else:
				main_node.show_message("❌ Система больницы недоступна!")
				main_node.close_location_menu()
		1:  # Купить аптечку (100р)
			if player_data["balance"] >= 100:
				player_data["balance"] -= 100
				player_data["inventory"].append("Аптечка")
				main_node.show_message("💊 Куплена аптечка за 100 руб.")
				main_node.update_ui()
			else:
				main_node.show_message("❌ Недостаточно денег!")
			main_node.close_location_menu()
		2:  # Уйти
			main_node.close_location_menu()

# ===== ФСБ =====
func handle_fsb_action(action_index: int, main_node: Node):
	match action_index:
		0:  # Дать взятку
			if police_system:
				main_node.close_location_menu()
				police_system.show_bribe_menu(main_node)
			else:
				main_node.show_message("❌ Система полиции недоступна!")
				main_node.close_location_menu()
		1:  # Уйти
			main_node.close_location_menu()

# ===== БАР ✨ НОВОЕ =====
func handle_bar_action(action_index: int, main_node: Node):
	match action_index:
		0:  # Отдохнуть
			if bar_system:
				main_node.close_location_menu()
				bar_system.show_bar_menu(main_node, main_node.player_data, main_node.gang_members)
			else:
				main_node.show_message("❌ Система бара недоступна!\nДобавь BarSystem в autoloads")
				main_node.close_location_menu()
		1:  # Бухать с бандой
			if bar_system:
				main_node.close_location_menu()
				bar_system.show_bar_menu(main_node, main_node.player_data, main_node.gang_members)
			else:
				main_node.show_message("❌ Система бара недоступна!\nДобавь BarSystem в autoloads")
				main_node.close_location_menu()
		2:  # Уйти
			main_node.close_location_menu()

# ===== АВТОСАЛОН ✨ НОВОЕ =====
func handle_car_dealership_action(action_index: int, main_node: Node):
	match action_index:
		0:  # Выбор машины
			if car_system:
				main_node.close_location_menu()
				car_system.show_car_dealership_menu(main_node, main_node.player_data)
			else:
				main_node.show_message("❌ Система машин недоступна!\nДобавь CarSystem в autoloads")
				main_node.close_location_menu()
		1:  # Починить машину
			if car_system:
				main_node.close_location_menu()
				car_system.show_car_dealership_menu(main_node, main_node.player_data)
			else:
				main_node.show_message("❌ Система машин недоступна!\nДобавь CarSystem в autoloads")
				main_node.close_location_menu()
		2:  # Уйти
			main_node.close_location_menu()
