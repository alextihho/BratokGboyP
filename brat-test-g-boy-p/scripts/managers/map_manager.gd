# map_manager.gd
# Управление картой, локациями и игроком
extends Node

signal location_clicked(location_name: String)

var player: ColorRect
var locations = {}

func initialize(parent_node: Node2D, location_data: Dictionary):
	locations = location_data
	create_tver_map(parent_node)
	create_player(parent_node)

func create_tver_map(parent: Node2D):
	# Фон карты
	var background = ColorRect.new()
	background.size = Vector2(720, 1280)
	background.position = Vector2(0, 0)
	background.color = Color(0.25, 0.35, 0.25, 1.0)
	background.z_index = -10
	background.name = "MapBackground"
	parent.add_child(background)
	
	# Река
	var river = ColorRect.new()
	river.size = Vector2(720, 200)
	river.color = Color(0.2, 0.4, 0.7, 1.0)
	river.position = Vector2(0, 400)
	river.z_index = -5
	river.name = "River"
	parent.add_child(river)
	
	# Создаём локации
	for location_name in locations:
		var pos = locations[location_name]["position"]
		add_location(parent, location_name, pos)

func add_location(parent: Node2D, name: String, position: Vector2):
	# ✅ НЕ создаем визуальные элементы!
	# Здания отображаются через grid_system как желтые квадраты
	# Здесь только логика для обратной совместимости
	pass

func create_player(parent: Node2D):
	player = ColorRect.new()
	player.size = Vector2(20, 20)
	player.position = Vector2(350, 500)
	player.color = Color.RED
	player.z_index = 5
	player.name = "Player"
	parent.add_child(player)

func move_player(click_pos: Vector2):
	if player:
		player.position = click_pos - player.size / 2

func check_location_click(click_pos: Vector2) -> String:
	for location_name in locations:
		var loc_pos = locations[location_name]["position"]
		var location_rect = Rect2(loc_pos, Vector2(80, 40))
		
		if location_rect.has_point(click_pos):
			location_clicked.emit(location_name)
			return location_name
	
	return ""

func get_location_actions(location_name: String) -> Array:
	if locations.has(location_name):
		return locations[location_name]["actions"]
	return []

func get_player_position() -> Vector2:
	if player:
		return player.position
	return Vector2.ZERO
