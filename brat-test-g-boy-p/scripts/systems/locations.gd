extends Node

var locations = {
	"ОБЩЕЖИТИЕ": {"position": Vector2(100, 200), "actions": ["Отдохнуть", "Поговорить с другом", "Взять вещи"]},
	"ЛАРЁК": {"position": Vector2(500, 300), "actions": ["Купить пиво", "Купить сигареты", "Поговорить"]},
	"ГАРАЖ": {"position": Vector2(200, 700), "actions": ["Осмотреть машину", "Помочь механику", "Украсть запчасть"]},
	"РЫНОК": {"position": Vector2(400, 900), "actions": ["Купить продукты", "Продать вещи", "Узнать новости"]},
	"УЛИЦА": {"position": Vector2(100, 1100), "actions": ["Прогуляться", "Встретить знакомого", "Посмотреть вокруг"]}
}

var current_location: String = ""
var menu_open: bool = false
var menu_canvas: CanvasLayer = null

signal location_entered(location_name: String)

func add_location(parent: Node2D, name: String, position: Vector2):
	var location = ColorRect.new()
	location.size = Vector2(80, 40)
	location.color = Color.GRAY
	location.position = position
	location.name = name
	parent.add_child(location)
	
	var label = Label.new()
	label.text = name
	label.position = position + Vector2(0, -20)
	label.add_theme_font_size_override("font_size", 16)
	parent.add_child(label)

func check_location_click(click_pos: Vector2, player_pos: Vector2) -> bool:
	for location_name in locations:
		var loc_pos = locations[location_name]["position"]
		var location_rect = Rect2(loc_pos, Vector2(80, 40))
		if location_rect.has_point(click_pos) and location_rect.has_point(player_pos):
			show_location_menu(location_name)
			return true
	return false

func show_location_menu(location_name: String):
	current_location = location_name
	menu_open = true
	location_entered.emit(location_name)
	
	menu_canvas = CanvasLayer.new()
	menu_canvas.name = "CanvasLayer"
	get_parent().add_child(menu_canvas)
	
	var actions = locations[location_name]["actions"]
	
	# Фон меню (центр для portrait)
	var menu_bg = ColorRect.new()
	menu_bg.size = Vector2(400, 350 + actions.size() * 45)
	menu_bg.position = Vector2(160, 465)  # Центр экрана
	menu_bg.color = Color.DARK_GRAY
	menu_bg.name = "LocationMenu"
	menu_canvas.add_child(menu_bg)
	
	var title = Label.new()
	title.text = location_name
	title.position = Vector2(180, 475)
	title.add_theme_font_size_override("font_size", 24)
	menu_canvas.add_child(title)
	
	for i in range(actions.size()):
		var button = ColorRect.new()
		button.size = Vector2(360, 35)
		button.position = Vector2(180, 530 + i * 45)
		button.color = Color.GRAY
		button.name = "ActionButton_" + str(i)
		menu_canvas.add_child(button)
		
		var button_label = Label.new()
		button_label.text = str(i+1) + ". " + actions[i]
		button_label.position = Vector2(190, 540 + i * 45)
		button_label.add_theme_font_size_override("font_size", 18)
		menu_canvas.add_child(button_label)
	
	var close_button = ColorRect.new()
	close_button.size = Vector2(360, 35)
	close_button.position = Vector2(180, 530 + actions.size() * 45)
	close_button.color = Color.DARK_RED
	close_button.name = "CloseButton"
	menu_canvas.add_child(close_button)
	
	var close_label = Label.new()
	close_label.text = "0. Закрыть"
	close_label.position = Vector2(190, 540 + actions.size() * 45)
	close_label.add_theme_font_size_override("font_size", 18)
	menu_canvas.add_child(close_label)

func handle_menu_click(click_pos: Vector2):
	if not menu_open or current_location == "":
		return
	
	var menu_pos = Vector2(160, 465)
	var menu_size = Vector2(400, 350 + locations[current_location]["actions"].size() * 45)
	var menu_rect = Rect2(menu_pos, menu_size)
	
	print("Клик: " + str(click_pos) + " | Меню rect: " + str(menu_rect))  # Дебаг
	
	if not menu_rect.has_point(click_pos):
		print("Клик вне меню")
		return
	
	var local_pos = click_pos - menu_pos
	var actions = locations[current_location]["actions"]
	
	print("Local pos: " + str(local_pos))  # Дебаг
	
	for i in range(actions.size()):
		var button_pos = Vector2(20, 65 + i * 45)
		var button_size = Vector2(360, 35)
		var button_rect = Rect2(button_pos, button_size)
		
		if button_rect.has_point(local_pos):
			print("Клик по действию " + str(i) + " (" + actions[i] + ")")  # Дебаг
			get_parent().handle_location_action(current_location, i)
			return
	
	var close_pos = Vector2(20, 65 + actions.size() * 45)
	var close_size = Vector2(360, 35)
	var close_rect = Rect2(close_pos, close_size)
	
	if close_rect.has_point(local_pos):
		print("Клик по закрытию")  # Дебаг
		close_location_menu()

func close_location_menu():
	if menu_canvas != null:
		menu_canvas.queue_free()
	menu_open = false
	current_location = ""

func trigger_random_event(location: String):
	var parent_node = get_parent()
	if parent_node == null:
		return
	
	match location:
		"УЛИЦА":
			if randf() < 0.2:
				var event_type = randi() % 2
				if event_type == 0:
					parent_node.show_message("Встретил братка: 'Эй, помоги с делом?'")
				else:
					parent_node.show_message("Стычка! Запуск боя...")
					start_battle()
		"ГАРАЖ":
			if randf() < 0.1:
				parent_node.show_message("Нашёл забытые ключи от тачки!")
				var player_data = get_node("/root/PlayerData")
				if player_data != null:
					player_data.add_item("Ключи от машины")

func start_battle():
	var battle_scene = preload("res://scenes/BattleUI.tscn")
	if battle_scene:
		var battle = battle_scene.instantiate()
		get_parent().add_child(battle)
	else:
		print("⚠️ BattleUI.tscn не найден!")
		get_parent().show_message("Бой не доступен")
