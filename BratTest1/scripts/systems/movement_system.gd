# movement_system.gd (ИСПРАВЛЕННАЯ ВЕРСИЯ)
# Система передвижения по квадратам с затратой времени
extends Node

signal movement_started(from_square: String, to_square: String, duration: int)
signal movement_completed(square_id: String)
signal movement_cancelled()

var grid_system
var time_system

# Типы передвижения
enum TransportType {
	WALK,      # Пешком - 30 мин на квадрат
	CAR_LEVEL1, # Машина уровень 1 - 10 мин на квадрат
	CAR_LEVEL2  # Машина уровень 2 - 5 мин на квадрат
}

# Время на квадрат (в минутах)
var transport_time = {
	TransportType.WALK: 30,
	TransportType.CAR_LEVEL1: 10,
	TransportType.CAR_LEVEL2: 5
}

# Текущее передвижение
var is_moving: bool = false
var current_transport: TransportType = TransportType.WALK
var movement_timer: Timer = null

func _ready():
	grid_system = null  # Будет установлен при initialize
	time_system = get_node_or_null("/root/TimeSystem")

func initialize(p_grid_system):
	grid_system = p_grid_system
	print("🚶 Система передвижения инициализирована")

# Начать движение к квадрату
func move_to_square(from_square: String, to_square: String, transport: TransportType = TransportType.WALK) -> bool:
	if is_moving:
		print("⚠️ Уже в движении!")
		return false
	
	if not grid_system:
		print("❌ Grid system не инициализирована!")
		return false
	
	if from_square == to_square:
		print("⚠️ Уже на этом квадрате")
		return false
	
	# Проверяем что квадраты существуют
	if not grid_system.grid_squares.has(from_square) or not grid_system.grid_squares.has(to_square):
		print("❌ Неверные координаты квадратов")
		return false
	
	# Рассчитываем расстояние
	var distance = grid_system.get_distance(from_square, to_square)
	if distance < 0:
		return false
	
	# Рассчитываем время
	var time_per_square = transport_time[transport]
	var total_time = distance * time_per_square
	
	# Добавляем бонус/штраф за переход между районами
	var from_district = grid_system.get_square_district(from_square)
	var to_district = grid_system.get_square_district(to_square)
	
	if from_district != to_district:
		total_time = int(total_time * 1.3)  # +30% времени при смене района
	
	print("🚶 Движение: %s → %s (%d квадратов, %d мин)" % [from_square, to_square, distance, total_time])
	
	# Запускаем таймер
	start_movement_timer(from_square, to_square, total_time)
	
	is_moving = true
	current_transport = transport
	
	movement_started.emit(from_square, to_square, total_time)
	
	return true

# Запуск таймера передвижения
func start_movement_timer(from_square: String, to_square: String, duration: int):
	if movement_timer:
		movement_timer.queue_free()
	
	movement_timer = Timer.new()
	movement_timer.wait_time = 1.0  # 1 секунда реального времени
	movement_timer.one_shot = true
	add_child(movement_timer)
	
	movement_timer.timeout.connect(func():
		complete_movement(to_square, duration)
		movement_timer.queue_free()
	)
	
	movement_timer.start()

# Завершение движения
func complete_movement(to_square: String, time_spent: int):
	# Добавляем время
	if time_system:
		time_system.add_minutes(time_spent)
	
	# Обновляем позицию игрока
	if grid_system:
		grid_system.set_player_square(to_square)
	
	is_moving = false
	movement_completed.emit(to_square)
	
	print("✅ Прибыли в квадрат: " + to_square)

# Отменить движение
func cancel_movement():
	if movement_timer:
		movement_timer.stop()
		movement_timer.queue_free()
		movement_timer = null
	
	is_moving = false
	movement_cancelled.emit()

# Мгновенное перемещение (без затраты времени)
func teleport_to_square(square_id: String):
	if grid_system:
		grid_system.set_player_square(square_id)
		print("⚡ Телепорт в квадрат: " + square_id)

# Получить текущий транспорт
func get_current_transport() -> TransportType:
	return current_transport

# Установить транспорт
func set_transport(transport: TransportType):
	current_transport = transport
	print("🚗 Транспорт изменён: " + str(transport))

# Получить время на передвижение
func calculate_travel_time(from_square: String, to_square: String, transport: TransportType = TransportType.WALK) -> int:
	if not grid_system:
		return 0
	
	var distance = grid_system.get_distance(from_square, to_square)
	if distance < 0:
		return 0
	
	var time_per_square = transport_time[transport]
	var total_time = distance * time_per_square
	
	# Бонус/штраф за район
	var from_district = grid_system.get_square_district(from_square)
	var to_district = grid_system.get_square_district(to_square)
	
	if from_district != to_district:
		total_time = int(total_time * 1.3)
	
	return total_time

# Проверка, движется ли сейчас
func is_currently_moving() -> bool:
	return is_moving

# Получить название транспорта для UI
func get_transport_name(transport: TransportType) -> String:
	match transport:
		TransportType.WALK:
			return "Пешком"
		TransportType.CAR_LEVEL1:
			return "Машина"
		TransportType.CAR_LEVEL2:
			return "Улучшенная машина"
		_:
			return "Неизвестно"

# Получить время на квадрат
func get_time_per_square(transport: TransportType) -> int:
	return transport_time[transport]
