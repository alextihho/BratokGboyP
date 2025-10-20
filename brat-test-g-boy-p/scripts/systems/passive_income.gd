extends Node

signal income_collected(amount: int)
signal day_passed(day: int)

var districts_system
var game_time
var collection_timer: Timer

# Настройки
var income_interval: float = 60.0  # Собирать доход раз в 60 секунд (1 игровой день)
var accumulated_income: int = 0
var days_passed: int = 0

func _ready():
	districts_system = get_node_or_null("/root/DistrictsSystem")
	game_time = get_node_or_null("/root/GameTime")
	
	setup_income_timer()
	print("💰 Система пассивного дохода загружена")

func setup_income_timer():
	collection_timer = Timer.new()
	collection_timer.wait_time = income_interval
	collection_timer.one_shot = false
	collection_timer.autostart = true
	collection_timer.timeout.connect(_on_income_collection)
	add_child(collection_timer)

func _on_income_collection():
	if not districts_system:
		return
	
	# Подсчитываем доход со всех районов
	var total_income = districts_system.get_total_player_income()
	
	if total_income > 0:
		accumulated_income += total_income
		days_passed += 1
		
		print("💰 Пассивный доход за день: " + str(total_income) + " руб.")
		print("📊 Всего накоплено: " + str(accumulated_income) + " руб.")
		
		income_collected.emit(total_income)
		
		# Продвигаем игровую дату
		if game_time:
			game_time.advance_day()
			day_passed.emit(days_passed)

func collect_income(player_data: Dictionary) -> int:
	if accumulated_income <= 0:
		return 0
	
	var amount = accumulated_income
	player_data["balance"] += amount
	accumulated_income = 0
	
	print("💵 Собран пассивный доход: " + str(amount) + " руб.")
	return amount

func get_accumulated_income() -> int:
	return accumulated_income

func get_daily_income() -> int:
	if not districts_system:
		return 0
	return districts_system.get_total_player_income()

func get_time_until_next_collection() -> float:
	if collection_timer:
		return collection_timer.time_left
	return 0.0

func set_income_interval(new_interval: float):
	income_interval = new_interval
	if collection_timer:
		collection_timer.wait_time = income_interval

# Показать уведомление о доходе
func show_income_notification(main_node: Node, amount: int):
	var notification = CanvasLayer.new()
	notification.name = "IncomeNotification"
	main_node.add_child(notification)
	
	var bg = ColorRect.new()
	bg.size = Vector2(400, 120)
	bg.position = Vector2(160, 580)
	bg.color = Color(0.1, 0.3, 0.1, 0.95)
	notification.add_child(bg)
	
	var icon = Label.new()
	icon.text = "💰"
	icon.position = Vector2(260, 590)
	icon.add_theme_font_size_override("font_size", 48)
	notification.add_child(icon)
	
	var title = Label.new()
	title.text = "ДОХОД ПОЛУЧЕН!"
	title.position = Vector2(230, 640)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	notification.add_child(title)
	
	var amount_label = Label.new()
	amount_label.text = "+" + str(amount) + " руб."
	amount_label.position = Vector2(260, 665)
	amount_label.add_theme_font_size_override("font_size", 18)
	amount_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	notification.add_child(amount_label)
	
	# Автоматически убираем уведомление через 3 секунды
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	main_node.add_child(timer)
	
	timer.timeout.connect(func():
		if notification and is_instance_valid(notification):
			notification.queue_free()
		timer.queue_free()
	)
	timer.start()

# Создать UI виджет пассивного дохода для верхней панели
func create_income_widget(parent: CanvasLayer, position: Vector2) -> Control:
	var widget = Control.new()
	widget.name = "IncomeWidget"
	widget.position = position
	widget.custom_minimum_size = Vector2(200, 60)
	
	var bg = ColorRect.new()
	bg.size = Vector2(200, 60)
	bg.color = Color(0.15, 0.15, 0.15, 0.9)
	widget.add_child(bg)
	
	var icon = Label.new()
	icon.text = "💰"
	icon.position = Vector2(10, 5)
	icon.add_theme_font_size_override("font_size", 32)
	widget.add_child(icon)
	
	var daily_label = Label.new()
	daily_label.text = "Доход/день:"
	daily_label.position = Vector2(50, 8)
	daily_label.add_theme_font_size_override("font_size", 12)
	daily_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	daily_label.name = "DailyLabel"
	widget.add_child(daily_label)
	
	var amount_label = Label.new()
	amount_label.text = str(get_daily_income()) + " руб."
	amount_label.position = Vector2(50, 25)
	amount_label.add_theme_font_size_override("font_size", 16)
	amount_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	amount_label.name = "AmountLabel"
	widget.add_child(amount_label)
	
	var accumulated_label = Label.new()
	accumulated_label.text = "Накоплено: " + str(accumulated_income)
	accumulated_label.position = Vector2(50, 42)
	accumulated_label.add_theme_font_size_override("font_size", 11)
	accumulated_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	accumulated_label.name = "AccumulatedLabel"
	widget.add_child(accumulated_label)
	
	parent.add_child(widget)
	return widget

# Обновить виджет дохода
func update_income_widget(widget: Control):
	if not widget:
		return
	
	var amount_label = widget.get_node_or_null("AmountLabel")
	if amount_label:
		amount_label.text = str(get_daily_income()) + " руб."
	
	var accumulated_label = widget.get_node_or_null("AccumulatedLabel")
	if accumulated_label:
		accumulated_label.text = "Накоплено: " + str(accumulated_income)

# Получить детальную информацию о доходах
func get_income_breakdown() -> Dictionary:
	if not districts_system:
		return {}
	
	var breakdown = {}
	for district_name in districts_system.districts:
		var income = districts_system.get_district_income(district_name, "Игрок")
		if income > 0:
			breakdown[district_name] = income
	
	return breakdown

# Показать детали дохода
func show_income_details(main_node: Node):
	var details_menu = CanvasLayer.new()
	details_menu.name = "IncomeDetailsMenu"
	main_node.add_child(details_menu)
	
	var bg = ColorRect.new()
	bg.size = Vector2(500, 700)
	bg.position = Vector2(110, 290)
	bg.color = Color(0.05, 0.05, 0.05, 0.95)
	details_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "💰 ДЕТАЛИ ДОХОДА"
	title.position = Vector2(210, 310)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	details_menu.add_child(title)
	
	var total_income = get_daily_income()
	var total_label = Label.new()
	total_label.text = "Общий доход: " + str(total_income) + " руб./день"
	total_label.position = Vector2(130, 360)
	total_label.add_theme_font_size_override("font_size", 18)
	total_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	details_menu.add_child(total_label)
	
	var breakdown_title = Label.new()
	breakdown_title.text = "По районам:"
	breakdown_title.position = Vector2(130, 400)
	breakdown_title.add_theme_font_size_override("font_size", 16)
	breakdown_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	details_menu.add_child(breakdown_title)
	
	var breakdown = get_income_breakdown()
	var y_pos = 440
	
	for district_name in breakdown:
		var income = breakdown[district_name]
		
		var district_label = Label.new()
		district_label.text = "  📍 " + district_name + ": " + str(income) + " руб."
		district_label.position = Vector2(140, y_pos)
		district_label.add_theme_font_size_override("font_size", 16)
		district_label.add_theme_color_override("font_color", Color.WHITE)
		details_menu.add_child(district_label)
		
		y_pos += 30
	
	if breakdown.is_empty():
		var no_income = Label.new()
		no_income.text = "Нет контролируемых районов"
		no_income.position = Vector2(170, 440)
		no_income.add_theme_font_size_override("font_size", 14)
		no_income.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
		details_menu.add_child(no_income)
	
	var accumulated_info = Label.new()
	accumulated_info.text = "Накоплено: " + str(accumulated_income) + " руб."
	accumulated_info.position = Vector2(180, y_pos + 40)
	accumulated_info.add_theme_font_size_override("font_size", 16)
	accumulated_info.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	details_menu.add_child(accumulated_info)
	
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(460, 50)
	close_btn.position = Vector2(130, 920)
	close_btn.text = "ЗАКРЫТЬ"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(func(): details_menu.queue_free())
	
	details_menu.add_child(close_btn)
