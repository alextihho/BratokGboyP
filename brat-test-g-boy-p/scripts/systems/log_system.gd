# log_system.gd - Система логов событий игры
extends Node

signal log_added(message: String)

# Массив всех логов
var all_logs: Array = []

# Максимальное количество сохраняемых логов
var max_logs: int = 100

# UI элемент (будет установлен из main)
var log_display_node = null

func _ready():
	print("📜 Система логов инициализирована")

# Добавить новый лог
func add_log(message: String, category: String = "info"):
	var timestamp = Time.get_datetime_dict_from_system()
	var log_entry = {
		"message": message,
		"category": category,
		"time": "%02d:%02d" % [timestamp.hour, timestamp.minute]
	}
	
	all_logs.insert(0, log_entry)
	
	# Ограничиваем размер массива
	if all_logs.size() > max_logs:
		all_logs.resize(max_logs)
	
	# Испускаем сигнал
	log_added.emit(message)
	
	# Обновляем UI если есть
	if log_display_node and is_instance_valid(log_display_node):
		update_log_display()
	
	# Выводим в консоль
	print("📜 [%s] %s: %s" % [log_entry["time"], category.to_upper(), message])

# Специализированные методы для разных типов логов
func add_combat_log(message: String):
	add_log(message, "combat")

func add_money_log(message: String):
	add_log(message, "money")

func add_quest_log(message: String):
	add_log(message, "quest")

func add_level_up_log(message: String):
	add_log(message, "levelup")

func add_movement_log(message: String):
	add_log(message, "movement")

func add_event_log(message: String):
	add_log(message, "event")

# Установить UI элемент для отображения
func set_display_node(node):
	log_display_node = node
	update_log_display()

# Обновить отображение логов
func update_log_display():
	if not log_display_node or not is_instance_valid(log_display_node):
		return
	
	var log_vbox = log_display_node.get_node_or_null("LogVBox")
	if not log_vbox:
		return
	
	# Очищаем старые записи
	for child in log_vbox.get_children():
		child.queue_free()
	
	# Показываем последние 10 логов
	var logs_to_show = min(10, all_logs.size())
	
	for i in range(logs_to_show):
		var log_entry = all_logs[i]
		var log_label = Label.new()
		
		# Форматируем текст с временем
		var display_text = "[%s] %s" % [log_entry["time"], log_entry["message"]]
		log_label.text = display_text
		
		# Цвет в зависимости от категории
		var color = get_category_color(log_entry["category"])
		log_label.add_theme_color_override("font_color", color)
		log_label.add_theme_font_size_override("font_size", 13)
		log_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		log_label.custom_minimum_size = Vector2(660, 0)
		
		log_vbox.add_child(log_label)

# Получить цвет для категории
func get_category_color(category: String) -> Color:
	match category:
		"combat":
			return Color(1.0, 0.3, 0.3)  # Красный
		"money":
			return Color(0.3, 1.0, 0.3)  # Зеленый
		"quest":
			return Color(1.0, 1.0, 0.3)  # Желтый
		"levelup":
			return Color(0.3, 1.0, 1.0)  # Голубой
		"movement":
			return Color(0.8, 0.8, 0.8)  # Серый
		"event":
			return Color(1.0, 0.6, 0.2)  # Оранжевый
		_:
			return Color(1.0, 1.0, 1.0)  # Белый

# Получить последние N логов
func get_recent_logs(count: int = 10) -> Array:
	return all_logs.slice(0, min(count, all_logs.size()))

# Очистить все логи
func clear_logs():
	all_logs.clear()
	update_log_display()

# Получить все логи определенной категории
func get_logs_by_category(category: String) -> Array:
	var filtered = []
	for log in all_logs:
		if log["category"] == category:
			filtered.append(log)
	return filtered
