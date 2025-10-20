# grid_system.gd (ИСПРАВЛЕННАЯ - полное покрытие карты)
extends CanvasLayer

signal square_clicked(square_id: String)

var square_size: int = 60
var grid_width: int = 12
var grid_height: int = 18  # Увеличил высоту для полного покрытия

var grid_squares = {}

var districts = {
	"Центр": {"color": Color(0.7, 0.7, 0.7, 0.2), "squares": []},
	"Заречье": {"color": Color(0.3, 0.5, 0.7, 0.2), "squares": []},
	"Окраина": {"color": Color(0.5, 0.3, 0.3, 0.2), "squares": []},
	"Промзона": {"color": Color(0.4, 0.4, 0.2, 0.2), "squares": []},
	"Спальный": {"color": Color(0.3, 0.6, 0.3, 0.2), "squares": []}
}

var selected_square: String = ""
var player_square: String = ""

var draw_control: Control
var toggle_button: Button
var grid_visible: bool = true

func _ready():
	layer = 1  # ✅ ТОЛЬКО над картой (0), ПОД всем UI (2+)
	
	draw_control = Control.new()
	draw_control.position = Vector2(0, 0)
	draw_control.size = Vector2(720, 1280)
	draw_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(draw_control)
	
	set_process_input(false)
	initialize_grid()
	
	draw_control.draw.connect(_draw_grid)
	draw_control.queue_redraw()
	
	print("==================================================")
	print("🗺️ СЕТКА: Layer %d (над картой=0, под UI=2+)" % layer)
	print("   Grid: %dx%d (полное покрытие карты)" % [grid_width, grid_height])
	print("==================================================")

func initialize_grid():
	for y in range(grid_height):
		for x in range(grid_width):
			var square_id = "%d_%d" % [x, y]
			var pos = Vector2(x * square_size, y * square_size + 120)
			
			grid_squares[square_id] = {
				"position": pos,
				"grid_x": x,
				"grid_y": y,
				"district": assign_district(x, y),
				"building": null,
				"owner": "Нейтральный"
			}
	
	for square_id in grid_squares:
		var square = grid_squares[square_id]
		var district_name = square["district"]
		districts[district_name]["squares"].append(square_id)
	
	print("✅ Инициализировано: " + str(grid_squares.size()) + " квадратов")

func assign_district(x: int, y: int) -> String:
	if x >= 4 and x <= 7 and y >= 2 and y <= 5:
		return "Центр"
	if x >= 8 and y >= 6 and y <= 10:
		return "Заречье"
	if y >= 14:  # Увеличил окраину
		return "Окраина"
	if x <= 3 and y >= 8:
		return "Промзона"
	return "Спальный"

func _draw_grid():
	if not grid_visible:
		return
	
	var start_y = 120
	var end_y = start_y + (grid_height * square_size)  # Динамическая высота
	
	# Закрашенные квадраты
	for square_id in grid_squares:
		var square = grid_squares[square_id]
		var district_name = square["district"]
		var color = districts[district_name]["color"]
		draw_control.draw_rect(Rect2(square["position"], Vector2(square_size, square_size)), color, true)
	
	# Линии сетки
	var line_color = Color.WHITE
	var line_width = 2
	
	for x in range(grid_width + 1):
		var start = Vector2(x * square_size, start_y)
		var end = Vector2(x * square_size, end_y)
		draw_control.draw_line(start, end, line_color, line_width)
	
	for y in range(grid_height + 1):
		var y_pos = start_y + y * square_size
		if y_pos > 1280:  # Максимальная высота экрана
			break
		var start = Vector2(0, y_pos)
		var end = Vector2(grid_width * square_size, y_pos)
		draw_control.draw_line(start, end, line_color, line_width)
	
	# Выделение
	if selected_square != "" and grid_squares.has(selected_square):
		var square = grid_squares[selected_square]
		draw_control.draw_rect(Rect2(square["position"], Vector2(square_size, square_size)), Color(1.0, 1.0, 0.0, 0.4), true)
		draw_control.draw_rect(Rect2(square["position"], Vector2(square_size, square_size)), Color.YELLOW, false, 4.0)
	
	# Игрок
	if player_square != "" and grid_squares.has(player_square):
		var square = grid_squares[player_square]
		var center = square["position"] + Vector2(square_size / 2, square_size / 2)
		draw_control.draw_circle(center, 18, Color.RED)
		draw_control.draw_circle(center, 18, Color.WHITE, false, 4.0)
	
	# Здания
	for square_id in grid_squares:
		var square = grid_squares[square_id]
		if square["building"] != null:
			var building_pos = square["position"] + Vector2(square_size / 2 - 12, square_size / 2 - 12)
			draw_control.draw_rect(Rect2(building_pos, Vector2(24, 24)), Color.YELLOW, true)
			draw_control.draw_rect(Rect2(building_pos, Vector2(24, 24)), Color.ORANGE, false, 3.0)

func get_square_at_position(pos: Vector2) -> String:
	# Проверяем что клик в пределах карты (исключаем UI зоны)
	if pos.y < 120 or pos.y > 1200:  # Верхняя панель и слишком низко
		return ""
	
	if pos.x < 0 or pos.x > grid_width * square_size:
		return ""
	
	var adjusted_y = pos.y - 120
	var grid_x = int(pos.x / square_size)
	var grid_y = int(adjusted_y / square_size)
	
	# Проверяем границы с увеличенной высотой
	if grid_x < 0 or grid_x >= grid_width or grid_y < 0 or grid_y >= grid_height:
		return ""
	
	var square_id = "%d_%d" % [grid_x, grid_y]
	return square_id

func get_square_center(square_id: String) -> Vector2:
	if not grid_squares.has(square_id):
		return Vector2.ZERO
	var square = grid_squares[square_id]
	return square["position"] + Vector2(square_size / 2, square_size / 2)

func get_square_data(square_id: String) -> Dictionary:
	return grid_squares.get(square_id, {})

func set_building(square_id: String, building_name: String):
	if grid_squares.has(square_id):
		grid_squares[square_id]["building"] = building_name
		if draw_control:
			draw_control.queue_redraw()
		print("🏢 '%s' → %s" % [building_name, square_id])

func get_building(square_id: String) -> String:
	if grid_squares.has(square_id):
		var building_value = grid_squares[square_id].get("building", null)
		if building_value != null:
			return building_value
	return ""

func select_square(square_id: String):
	selected_square = square_id
	if draw_control:
		draw_control.queue_redraw()

func deselect_square():
	selected_square = ""
	if draw_control:
		draw_control.queue_redraw()

func set_player_square(square_id: String):
	player_square = square_id
	if draw_control:
		draw_control.queue_redraw()
	print("🚶 Игрок → " + square_id)

func get_player_square() -> String:
	return player_square

func get_square_district(square_id: String) -> String:
	if grid_squares.has(square_id):
		return grid_squares[square_id]["district"]
	return ""

func get_district_squares(p_district_name: String) -> Array:
	if districts.has(p_district_name):
		return districts[p_district_name]["squares"]
	return []

func is_adjacent(square_a: String, square_b: String) -> bool:
	if not grid_squares.has(square_a) or not grid_squares.has(square_b):
		return false
	var a = grid_squares[square_a]
	var b = grid_squares[square_b]
	var dx = abs(a["grid_x"] - b["grid_x"])
	var dy = abs(a["grid_y"] - b["grid_y"])
	return (dx == 1 and dy == 0) or (dx == 0 and dy == 1)

func get_distance(square_a: String, square_b: String) -> int:
	if not grid_squares.has(square_a) or not grid_squares.has(square_b):
		return -1
	var a = grid_squares[square_a]
	var b = grid_squares[square_b]
	return abs(a["grid_x"] - b["grid_x"]) + abs(a["grid_y"] - b["grid_y"])

func toggle_grid_visibility():
	grid_visible = !grid_visible
	draw_control.queue_redraw()
	print("🗺️ Сетка: " + ("ВКЛ" if grid_visible else "ВЫКЛ"))
	return grid_visible

func is_grid_visible() -> bool:
	return grid_visible
