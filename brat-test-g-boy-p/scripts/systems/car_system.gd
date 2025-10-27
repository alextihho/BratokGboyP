# car_system.gd - ОБНОВЛЕНО (система мест и экипировки)
extends Node

signal car_purchased(car_name: String)
signal car_repaired()
signal driver_changed(member_index: int)

var player_stats
var time_system
var log_system  # ✅ НОВОЕ

# ✅ ОБНОВЛЕНО: База данных машин с количеством мест
var cars_db = {
	"vaz_2106": {
		"name": "ВАЗ-2106",
		"price": 5000,
		"speed": 120,
		"durability": 60,
		"fuel_consumption": 8,
		"seats": 2,  # ✅ НОВОЕ: Водитель + 1 пассажир
		"description": "Классическая 'шестёрка' - надёжная рабочая лошадка (2 места)",
		"image": "res://assets/cars/vaz_2106.png"
	},
	"volga_3110": {
		"name": "Волга ГАЗ-3110",
		"price": 12000,
		"speed": 140,
		"durability": 80,
		"fuel_consumption": 12,
		"seats": 4,  # ✅ НОВОЕ: Водитель + 3 пассажира
		"description": "Просторная и комфортная - идеальна для банды (4 места)",
		"image": "res://assets/cars/volga.png"
	},
	"bmw_e34": {
		"name": "BMW E34",
		"price": 25000,
		"speed": 180,
		"durability": 90,
		"fuel_consumption": 10,
		"seats": 6,  # ✅ НОВОЕ: Водитель + 5 пассажиров
		"description": "Легенда 90-х - статус и мощь (6 мест)",
		"image": "res://assets/cars/bmw_e34.png"
	}
}

func _ready():
	player_stats = get_node_or_null("/root/PlayerStats")
	time_system = get_node_or_null("/root/TimeSystem")
	log_system = get_node_or_null("/root/LogSystem")  # ✅ НОВОЕ
	print("🚗 Система машин загружена (с местами)")

# Показать меню автосалона
func show_car_dealership_menu(main_node: Node, player_data: Dictionary):
	var dealership_menu = CanvasLayer.new()
	dealership_menu.layer = 100
	dealership_menu.name = "DealershipMenu"
	main_node.add_child(dealership_menu)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	dealership_menu.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(700, 1100)
	bg.position = Vector2(10, 90)
	bg.color = Color(0.05, 0.05, 0.15, 0.95)
	dealership_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "🚗 АВТОСАЛОН"
	title.position = Vector2(260, 110)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0, 1.0))
	dealership_menu.add_child(title)
	
	# Информация о текущей машине
	var current_car_text = "Текущая машина: "
	if player_data.get("car"):
		var car = cars_db.get(player_data["car"])
		if car:
			current_car_text += car["name"] + " (%d мест)" % car["seats"]
			current_car_text += " (состояние: %.0f%%)" % player_data.get("car_condition", 100)
		else:
			current_car_text += "Нет"
	else:
		current_car_text += "Нет"
	
	var current_car_label = Label.new()
	current_car_label.text = current_car_text
	current_car_label.position = Vector2(160, 160)
	current_car_label.add_theme_font_size_override("font_size", 16)
	current_car_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 1.0))
	dealership_menu.add_child(current_car_label)
	
	var y_pos = 220
	
	# Кнопка "ВЫБОР МАШИНЫ"
	var choose_car_btn = Button.new()
	choose_car_btn.custom_minimum_size = Vector2(660, 80)
	choose_car_btn.position = Vector2(30, y_pos)
	choose_car_btn.text = "🚗 ВЫБОР МАШИНЫ"
	
	var style_choose = StyleBoxFlat.new()
	style_choose.bg_color = Color(0.2, 0.5, 0.8, 1.0)
	choose_car_btn.add_theme_stylebox_override("normal", style_choose)
	
	choose_car_btn.add_theme_font_size_override("font_size", 24)
	choose_car_btn.pressed.connect(func():
		dealership_menu.queue_free()
		show_car_selection_menu(main_node, player_data)
	)
	dealership_menu.add_child(choose_car_btn)
	
	y_pos += 100
	
	# Кнопка "ПОЧИНИТЬ МАШИНУ"
	var repair_btn = Button.new()
	repair_btn.custom_minimum_size = Vector2(660, 80)
	repair_btn.position = Vector2(30, y_pos)
	repair_btn.text = "🔧 ПОЧИНИТЬ МАШИНУ"
	repair_btn.disabled = not player_data.get("car") or player_data.get("car_condition", 100) >= 100
	
	var style_repair = StyleBoxFlat.new()
	if repair_btn.disabled:
		style_repair.bg_color = Color(0.3, 0.3, 0.3, 1.0)
	else:
		style_repair.bg_color = Color(0.6, 0.4, 0.2, 1.0)
	repair_btn.add_theme_stylebox_override("normal", style_repair)
	
	repair_btn.add_theme_font_size_override("font_size", 24)
	repair_btn.pressed.connect(func():
		show_repair_menu(main_node, player_data, dealership_menu)
	)
	dealership_menu.add_child(repair_btn)
	
	y_pos += 100
	
	# Информационный блок
	var info_bg = ColorRect.new()
	info_bg.size = Vector2(660, 600)
	info_bg.position = Vector2(30, y_pos)
	info_bg.color = Color(0.1, 0.1, 0.2, 0.8)
	dealership_menu.add_child(info_bg)
	
	var info_text = "ℹ️ АВТОСАЛОН\n\n"
	info_text += "Здесь вы можете:\n"
	info_text += "• Купить машину для быстрых передвижений\n"
	info_text += "• Починить свою машину\n\n"
	info_text += "⚠️ ВАЖНО:\n"
	info_text += "• После покупки назначьте водителя в меню\n"
	info_text += "• Количество мест ограничивает банду в поездках\n"
	info_text += "• Машина изнашивается при использовании\n\n"
	info_text += "💡 Совет: лучшая машина = больше мест и престиж!"
	
	var info_label = Label.new()
	info_label.text = info_text
	info_label.position = Vector2(50, y_pos + 20)
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9, 1.0))
	dealership_menu.add_child(info_label)
	
	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(680, 50)
	close_btn.position = Vector2(20, 1100)
	close_btn.text = "УЙТИ"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func():
		dealership_menu.queue_free()
	)
	dealership_menu.add_child(close_btn)

# Меню выбора машины
func show_car_selection_menu(main_node: Node, player_data: Dictionary):
	var selection_menu = CanvasLayer.new()
	selection_menu.layer = 110
	selection_menu.name = "CarSelectionMenu"
	main_node.add_child(selection_menu)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	selection_menu.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(700, 1100)
	bg.position = Vector2(10, 90)
	bg.color = Color(0.05, 0.05, 0.15, 0.98)
	selection_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "🚗 ВЫБОР МАШИНЫ"
	title.position = Vector2(230, 110)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0, 1.0))
	selection_menu.add_child(title)
	
	var balance_label = Label.new()
	balance_label.text = "💰 Баланс: %d руб." % player_data["balance"]
	balance_label.position = Vector2(260, 160)
	balance_label.add_theme_font_size_override("font_size", 18)
	balance_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	selection_menu.add_child(balance_label)
	
	var y_pos = 220
	
	# Список машин
	for car_id in cars_db:
		var car = cars_db[car_id]
		
		var card_bg = ColorRect.new()
		card_bg.size = Vector2(680, 220)
		card_bg.position = Vector2(20, y_pos)
		card_bg.color = Color(0.15, 0.15, 0.25, 1.0)
		selection_menu.add_child(card_bg)
		
		# Placeholder для изображения машины
		var car_image_bg = ColorRect.new()
		car_image_bg.size = Vector2(200, 150)
		car_image_bg.position = Vector2(40, y_pos + 20)
		car_image_bg.color = Color(0.2, 0.2, 0.3, 1.0)
		selection_menu.add_child(car_image_bg)
		
		var car_icon = Label.new()
		car_icon.text = "🚗"
		car_icon.position = Vector2(110, y_pos + 65)
		car_icon.add_theme_font_size_override("font_size", 64)
		selection_menu.add_child(car_icon)
		
		# Информация о машине
		var car_name = Label.new()
		car_name.text = car["name"] + " (%d мест)" % car["seats"]  # ✅ Показываем места
		car_name.position = Vector2(260, y_pos + 20)
		car_name.add_theme_font_size_override("font_size", 20)
		car_name.add_theme_color_override("font_color", Color(1.0, 1.0, 0.5, 1.0))
		selection_menu.add_child(car_name)
		
		var car_desc = Label.new()
		car_desc.text = car["description"]
		car_desc.position = Vector2(260, y_pos + 50)
		car_desc.add_theme_font_size_override("font_size", 13)
		car_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
		selection_menu.add_child(car_desc)
		
		var car_stats = Label.new()
		car_stats.text = "⚡ %d км/ч | 🛡️ %d | ⛽ %d л/100км | 👥 %d мест" % [
			car["speed"],
			car["durability"],
			car["fuel_consumption"],
			car["seats"]  # ✅ Показываем места в статах
		]
		car_stats.position = Vector2(260, y_pos + 80)
		car_stats.add_theme_font_size_override("font_size", 13)
		car_stats.add_theme_color_override("font_color", Color(0.5, 1.0, 0.8, 1.0))
		selection_menu.add_child(car_stats)
		
		var car_price = Label.new()
		car_price.text = "💰 Цена: %d руб." % car["price"]
		car_price.position = Vector2(260, y_pos + 110)
		car_price.add_theme_font_size_override("font_size", 18)
		car_price.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1.0))
		selection_menu.add_child(car_price)
		
		# Кнопка выбора
		var select_btn = Button.new()
		select_btn.custom_minimum_size = Vector2(180, 50)
		select_btn.position = Vector2(500, y_pos + 150)
		
		# Проверяем есть ли уже эта машина
		if player_data.get("car") == car_id:
			select_btn.text = "✓ КУПЛЕНА"
			select_btn.disabled = true
		else:
			select_btn.text = "КУПИТЬ"
			select_btn.disabled = player_data["balance"] < car["price"]
		
		var style_select = StyleBoxFlat.new()
		if select_btn.disabled:
			style_select.bg_color = Color(0.3, 0.3, 0.3, 1.0)
		else:
			style_select.bg_color = Color(0.3, 0.7, 0.3, 1.0)
		select_btn.add_theme_stylebox_override("normal", style_select)
		
		select_btn.add_theme_font_size_override("font_size", 16)
		
		var c_id = car_id
		var c_car = car.duplicate()
		select_btn.pressed.connect(func():
			buy_car(main_node, player_data, c_id, c_car, selection_menu)
		)
		selection_menu.add_child(select_btn)
		
		y_pos += 240
	
	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(680, 50)
	close_btn.position = Vector2(20, 1100)
	close_btn.text = "НАЗАД"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func():
		selection_menu.queue_free()
		show_car_dealership_menu(main_node, player_data)
	)
	selection_menu.add_child(close_btn)

# Купить машину
func buy_car(main_node: Node, player_data: Dictionary, car_id: String, car: Dictionary, selection_menu: CanvasLayer):
	if player_data["balance"] < car["price"]:
		main_node.show_message("❌ Недостаточно денег!")
		return
	
	# Списываем деньги
	player_data["balance"] -= car["price"]
	
	# Устанавливаем машину
	player_data["car"] = car_id
	player_data["car_condition"] = 100.0
	player_data["car_equipped"] = false  # ✅ Нужно надеть в меню
	player_data["current_driver"] = null  # ✅ Нужно назначить водителя
	
	main_node.show_message("🚗 Поздравляем с покупкой: %s!\n⚠️ Назначьте водителя в меню!" % car["name"])
	
	# ✅ НОВОЕ: Логируем покупку
	if log_system:
		log_system.add_money_log("🚗 Куплена машина: %s (-% dр)" % [car["name"], car["price"]])
	
	main_node.update_ui()
	
	car_purchased.emit(car["name"])
	
	selection_menu.queue_free()
	await main_node.get_tree().create_timer(1.0).timeout
	show_car_dealership_menu(main_node, player_data)

# Меню ремонта (без изменений)
func show_repair_menu(main_node: Node, player_data: Dictionary, dealership_menu: CanvasLayer):
	if not player_data.get("car"):
		main_node.show_message("❌ У вас нет машины!")
		return
	
	var condition = player_data.get("car_condition", 100)
	if condition >= 100:
		main_node.show_message("✅ Машина в отличном состоянии!")
		return
	
	var car = cars_db.get(player_data["car"])
	if not car:
		return
	
	var wear = 100 - condition
	var base_cost = int(car["price"] * 0.01 * wear)
	
	var charisma_discount = 0
	if player_stats:
		var charisma = player_stats.get_stat("Харизма")
		charisma_discount = charisma * 2
	
	var repair_cost = int(base_cost * (100 - charisma_discount) / 100.0)
	repair_cost = max(50, repair_cost)
	
	# Создаём диалог подтверждения
	var confirm_layer = CanvasLayer.new()
	confirm_layer.layer = 120
	confirm_layer.name = "RepairConfirm"
	main_node.add_child(confirm_layer)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.9)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm_layer.add_child(overlay)
	
	var dialog_bg = ColorRect.new()
	dialog_bg.size = Vector2(600, 400)
	dialog_bg.position = Vector2(60, 440)
	dialog_bg.color = Color(0.1, 0.1, 0.15, 0.98)
	confirm_layer.add_child(dialog_bg)
	
	var title = Label.new()
	title.text = "🔧 РЕМОНТ МАШИНЫ"
	title.position = Vector2(210, 470)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3, 1.0))
	confirm_layer.add_child(title)
	
	var info_text = "Машина: %s\n\nТекущее состояние: %.0f%%\nИзнос: %.0f%%\n\n" % [
		car["name"],
		condition,
		wear
	]
	info_text += "Стоимость ремонта: %d руб." % repair_cost
	
	if charisma_discount > 0:
		info_text += "\n(скидка %d%% от харизмы)" % charisma_discount
	
	var info_label = Label.new()
	info_label.text = info_text
	info_label.position = Vector2(140, 530)
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	confirm_layer.add_child(info_label)
	
	var repair_btn = Button.new()
	repair_btn.custom_minimum_size = Vector2(250, 60)
	repair_btn.position = Vector2(100, 730)
	repair_btn.text = "ПОЧИНИТЬ"
	repair_btn.disabled = player_data["balance"] < repair_cost
	
	var style_repair = StyleBoxFlat.new()
	if repair_btn.disabled:
		style_repair.bg_color = Color(0.3, 0.3, 0.3, 1.0)
	else:
		style_repair.bg_color = Color(0.3, 0.7, 0.3, 1.0)
	repair_btn.add_theme_stylebox_override("normal", style_repair)
	
	repair_btn.add_theme_font_size_override("font_size", 20)
	repair_btn.pressed.connect(func():
		repair_car(main_node, player_data, repair_cost, confirm_layer, dealership_menu)
	)
	confirm_layer.add_child(repair_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.custom_minimum_size = Vector2(250, 60)
	cancel_btn.position = Vector2(370, 730)
	cancel_btn.text = "ОТМЕНА"
	
	var style_cancel = StyleBoxFlat.new()
	style_cancel.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	cancel_btn.add_theme_stylebox_override("normal", style_cancel)
	
	cancel_btn.add_theme_font_size_override("font_size", 20)
	cancel_btn.pressed.connect(func():
		confirm_layer.queue_free()
	)
	confirm_layer.add_child(cancel_btn)

# Починить машину
func repair_car(main_node: Node, player_data: Dictionary, cost: int, confirm_layer: CanvasLayer, dealership_menu: CanvasLayer):
	if player_data["balance"] < cost:
		main_node.show_message("❌ Недостаточно денег!")
		return
	
	player_data["balance"] -= cost
	player_data["car_condition"] = 100.0
	
	if time_system:
		time_system.add_hours(randi_range(1, 3))
	
	main_node.show_message("🔧 Машина отремонтирована!\n💰 Потрачено: %d руб." % cost)
	
	# ✅ НОВОЕ: Логируем ремонт
	if log_system:
		log_system.add_money_log("🔧 Ремонт машины (-%dр)" % cost)
	
	main_node.update_ui()
	
	car_repaired.emit()
	
	confirm_layer.queue_free()
	dealership_menu.queue_free()
	await main_node.get_tree().create_timer(0.5).timeout
	show_car_dealership_menu(main_node, player_data)

# Изнашивание машины при использовании
func use_car(player_data: Dictionary, distance: float = 10.0):
	if not player_data.get("car"):
		return
	
	var car = cars_db.get(player_data["car"])
	if not car:
		return
	
	var wear_rate = 100.0 / car["durability"]
	var wear = wear_rate * (distance / 10.0)
	
	player_data["car_condition"] = max(0, player_data.get("car_condition", 100) - wear)

# ✅ НОВОЕ: Получить количество мест в машине
func get_car_seats(car_id: String) -> int:
	var car = cars_db.get(car_id)
	if car and car.has("seats"):
		return car["seats"]
	return 1
