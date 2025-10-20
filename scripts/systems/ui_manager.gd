extends Node

# Создание верхней панели
static func create_top_panel(ui_layer: CanvasLayer, player_data: Dictionary) -> void:
	var top_panel = ColorRect.new()
	top_panel.size = Vector2(720, 120)
	top_panel.position = Vector2(0, 0)
	top_panel.color = Color(0.1, 0.1, 0.1, 0.9)
	top_panel.name = "TopPanel"
	top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(top_panel)
	
	var avatar_bg = ColorRect.new()
	avatar_bg.size = Vector2(80, 80)
	avatar_bg.position = Vector2(20, 20)
	avatar_bg.color = Color(0.8, 0.3, 0.2, 1.0)
	avatar_bg.name = "AvatarBG"
	avatar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(avatar_bg)
	
	var avatar_label = Label.new()
	avatar_label.text = "😎"
	avatar_label.position = Vector2(35, 30)
	avatar_label.add_theme_font_size_override("font_size", 45)
	avatar_label.name = "AvatarIcon"
	avatar_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(avatar_label)
	
	var rep_label = Label.new()
	rep_label.text = "Авторитет: " + str(player_data["reputation"])
	rep_label.position = Vector2(120, 25)
	rep_label.add_theme_font_size_override("font_size", 18)
	rep_label.add_theme_color_override("font_color", Color.WHITE)
	rep_label.name = "ReputationLabel"
	rep_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(rep_label)
	
	var balance_label = Label.new()
	balance_label.text = "Деньги: " + str(player_data["balance"]) + " руб."
	balance_label.position = Vector2(120, 55)
	balance_label.add_theme_font_size_override("font_size", 18)
	balance_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	balance_label.name = "BalanceLabel"
	balance_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(balance_label)
	
	var health_label = Label.new()
	health_label.text = "Здоровье: " + str(player_data["health"])
	health_label.position = Vector2(120, 85)
	health_label.add_theme_font_size_override("font_size", 18)
	health_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
	health_label.name = "HealthLabel"
	health_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(health_label)
	
	var date_label = Label.new()
	date_label.text = "02.03.1992"
	date_label.position = Vector2(590, 25)
	date_label.add_theme_font_size_override("font_size", 16)
	date_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	date_label.name = "DateLabel"
	date_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(date_label)

# Создание кнопки кликера
static func create_quick_earn_button(ui_layer: CanvasLayer, callback: Callable) -> void:
	var quick_earn_btn = Button.new()
	quick_earn_btn.custom_minimum_size = Vector2(120, 50)
	quick_earn_btn.position = Vector2(590, 55)
	quick_earn_btn.text = "💰 +1р"
	quick_earn_btn.name = "QuickEarnBtn"
	
	var style_earn = StyleBoxFlat.new()
	style_earn.bg_color = Color(0.2, 0.5, 0.2, 1.0)
	quick_earn_btn.add_theme_stylebox_override("normal", style_earn)
	
	var style_earn_hover = StyleBoxFlat.new()
	style_earn_hover.bg_color = Color(0.3, 0.6, 0.3, 1.0)
	quick_earn_btn.add_theme_stylebox_override("hover", style_earn_hover)
	
	quick_earn_btn.add_theme_font_size_override("font_size", 16)
	quick_earn_btn.pressed.connect(callback)
	
	ui_layer.add_child(quick_earn_btn)

# Создание нижней панели с кнопками
static func create_bottom_panel(ui_layer: CanvasLayer, button_callback: Callable) -> void:
	var bottom_panel = ColorRect.new()
	bottom_panel.size = Vector2(720, 100)
	bottom_panel.position = Vector2(0, 1180)
	bottom_panel.color = Color(0.1, 0.1, 0.1, 0.9)
	bottom_panel.name = "BottomPanel"
	bottom_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(bottom_panel)
	
	var menu_buttons = ["Банда", "Работы", "Районы", "Квесты", "Меню"]
	var button_width = 135
	var spacing = 8
	
	for i in range(menu_buttons.size()):
		var button = Button.new()
		button.custom_minimum_size = Vector2(button_width, 60)
		button.position = Vector2(spacing + i * (button_width + spacing), 1200)
		button.text = menu_buttons[i]
		button.name = "MenuButton_" + menu_buttons[i]
		
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.3, 0.3, 0.35, 1.0)
		button.add_theme_stylebox_override("normal", style_normal)
		
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.4, 0.4, 0.45, 1.0)
		button.add_theme_stylebox_override("hover", style_hover)
		
		var style_pressed = StyleBoxFlat.new()
		style_pressed.bg_color = Color(0.2, 0.2, 0.25, 1.0)
		button.add_theme_stylebox_override("pressed", style_pressed)
		
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_color_override("font_color", Color.WHITE)
		
		var btn_name = menu_buttons[i]
		button.pressed.connect(func(): button_callback.call(btn_name))
		
		ui_layer.add_child(button)

# Обновление UI данных
static func update_ui_labels(ui_layer: CanvasLayer, player_data: Dictionary) -> void:
	var rep_label = ui_layer.get_node_or_null("ReputationLabel")
	if rep_label:
		rep_label.text = "Авторитет: " + str(player_data["reputation"])
	
	var balance_label = ui_layer.get_node_or_null("BalanceLabel")
	if balance_label:
		balance_label.text = "Деньги: " + str(player_data["balance"]) + " руб."
	
	var health_label = ui_layer.get_node_or_null("HealthLabel")
	if health_label:
		health_label.text = "Здоровье: " + str(player_data["health"])

# Показать всплывающий текст
static func show_floating_text(ui_layer: CanvasLayer, text: String, position: Vector2, color: Color, parent: Node) -> void:
	var floating_label = Label.new()
	floating_label.text = text
	floating_label.position = position
	floating_label.add_theme_font_size_override("font_size", 20)
	floating_label.add_theme_color_override("font_color", color)
	floating_label.z_index = 100
	ui_layer.add_child(floating_label)
	
	# Анимация вверх и исчезновение
	var tween = parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(floating_label, "position:y", position.y - 50, 1.0)
	tween.tween_property(floating_label, "modulate:a", 0.0, 1.0)
	
	await tween.finished
	floating_label.queue_free()

# Показать временное сообщение
static func show_message(ui_layer: CanvasLayer, text: String, parent: Node) -> void:
	var message = Label.new()
	message.text = text
	message.position = Vector2(200, 350)
	message.add_theme_font_size_override("font_size", 22)
	message.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.name = "MessageLabel"
	ui_layer.add_child(message)
	
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	parent.add_child(timer)
	
	timer.timeout.connect(func():
		if message and is_instance_valid(message):
			message.queue_free()
		timer.queue_free()
	)
	timer.start()
