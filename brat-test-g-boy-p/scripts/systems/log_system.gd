# log_system.gd - Система логов с правильным UI
extends Node

signal log_added(message: String, category: String)

# Массив всех логов
var all_logs: Array = []
var max_logs: int = 100

# UI элементы
var log_panel: CanvasLayer = null
var log_container: VBoxContainer = null
var is_visible: bool = true

func _ready():
	print("📜 Система логов готова")
	
	# Создаем UI сразу
	create_log_ui()
	
	# ✅ ТЕСТОВЫЕ ЛОГИ для проверки
	await get_tree().create_timer(0.5).timeout  # Ждём инициализацию UI
	add_news_log("Игра запущена - Тверь, 02.03.1992")
	add_success_log("Система логов работает!")
	add_attack_log("Тестовое сообщение об опасности")

# ✅ Создание UI логов (внизу справа, как на скриншоте 2)
func create_log_ui():
	# CanvasLayer для логов
	log_panel = CanvasLayer.new()
	log_panel.name = "LogPanel"
	log_panel.layer = 40  # ✅ Ниже UI (50), но выше карты
	add_child(log_panel)
	
	# ✅ Фон панели логов (темно-серый) - СПРАВА ВНИЗУ
	var bg = ColorRect.new()
	bg.size = Vector2(350, 500)  
	bg.position = Vector2(360, 720)  # ✅ Поднято на 60px вверх
	bg.color = Color(0.15, 0.15, 0.15, 0.95)
	bg.name = "LogBackground"
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ✅ НЕ блокирует клики по карте
	log_panel.add_child(bg)
	
	# Заголовок
	var title = Label.new()
	title.text = "📜 ЛОГИ СОБЫТИЙ"
	title.position = Vector2(380, 730)  # ✅ Поднято на 60px
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ✅ НЕ блокирует клики
	log_panel.add_child(title)
	
	# ScrollContainer для логов
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(370, 760)  # ✅ Поднято на 60px
	scroll.size = Vector2(330, 450)
	scroll.name = "LogScroll"
	scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE  # ✅ НЕ блокирует клики по карте
	log_panel.add_child(scroll)
	
	# VBoxContainer для логов
	log_container = VBoxContainer.new()
	log_container.name = "LogContainer"
	log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(log_container)

# ✅ Добавить лог с правильными цветами
func add_log(message: String, category: String = "info"):
	var timestamp = Time.get_datetime_dict_from_system()
	var log_entry = {
		"message": message,
		"category": category,
		"time": "%02d:%02d" % [timestamp.hour, timestamp.minute]
	}
	
	all_logs.insert(0, log_entry)
	
	if all_logs.size() > max_logs:
		all_logs.resize(max_logs)
	
	log_added.emit(message, category)
	
	# Обновляем UI
	update_log_display()
	
	print("📜 [%s] %s: %s" % [log_entry["time"], category.to_upper(), message])

# ✅ Специализированные методы
func add_news_log(message: String):
	"""Городские новости - бежево-желтый"""
	add_log(message, "news")

func add_attack_log(message: String):
	"""Атаки, нападения - красный"""
	add_log(message, "attack")

func add_success_log(message: String):
	"""Удача, лечение, заработок - зеленый"""
	add_log(message, "success")

func add_combat_log(message: String):
	add_log(message, "combat")

func add_money_log(message: String):
	add_log(message, "money")

func add_quest_log(message: String):
	add_log(message, "quest")

func add_event_log(message: String):
	add_log(message, "event")

func add_movement_log(message: String):
	add_log(message, "movement")

func add_time_log(message: String):
	"""Обновление времени - голубой цвет"""
	add_log(message, "time")

# ✅ Обновление отображения
func update_log_display():
	if not log_container or not is_instance_valid(log_container):
		return
	
	# Очищаем старые записи
	for child in log_container.get_children():
		child.queue_free()
	
	# Показываем последние 20 логов
	var logs_to_show = min(20, all_logs.size())
	
	for i in range(logs_to_show):
		var log_entry = all_logs[i]
		var log_label = Label.new()
		
		# Форматируем текст
		var display_text = "[%s] %s" % [log_entry["time"], log_entry["message"]]
		log_label.text = display_text
		
		# ✅ ПРАВИЛЬНЫЕ ЦВЕТА как просили
		var color = get_category_color(log_entry["category"])
		log_label.add_theme_color_override("font_color", color)
		log_label.add_theme_font_size_override("font_size", 12)
		log_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		log_label.custom_minimum_size = Vector2(360, 0)
		
		log_container.add_child(log_label)

# ✅ ПРАВИЛЬНЫЕ ЦВЕТА как просили
func get_category_color(category: String) -> Color:
	match category:
		"news":  # Городские новости
			return Color(0.95, 0.85, 0.55)  # Бежево-желтый
		"attack", "combat":  # Нападения, атаки
			return Color(1.0, 0.3, 0.3)  # Красный
		"success", "money":  # Удача, заработок, лечение
			return Color(0.3, 1.0, 0.3)  # Зеленый
		"quest":
			return Color(0.3, 0.8, 1.0)  # Голубой
		"event":
			return Color(1.0, 0.7, 0.3)  # Оранжевый
		"movement":
			return Color(0.7, 0.7, 0.7)  # Серый
		"time":  # Время
			return Color(0.6, 0.9, 1.0)  # Светло-голубой
		_:
			return Color(0.9, 0.9, 0.9)  # Почти белый

# Показать/скрыть логи
func toggle_logs():
	if log_panel:
		is_visible = !is_visible
		log_panel.visible = is_visible

func show_logs():
	if log_panel:
		is_visible = true
		log_panel.visible = true

func hide_logs():
	if log_panel:
		is_visible = false
		log_panel.visible = false

# Получить последние N логов
func get_recent_logs(count: int = 10) -> Array:
	return all_logs.slice(0, min(count, all_logs.size()))

# Очистить логи
func clear_logs():
	all_logs.clear()
	update_log_display()

# Получить логи по категории
func get_logs_by_category(category: String) -> Array:
	var filtered = []
	for log in all_logs:
		if log["category"] == category:
			filtered.append(log)
	return filtered
