# ui_controller.gd (ИСПРАВЛЕН - С ОТОБРАЖЕНИЕМ УА)
extends Node

var ui_layer: CanvasLayer
var player_data: Dictionary
var police_system

func initialize(parent_node: Node, p_player_data: Dictionary):
	player_data = p_player_data
	police_system = get_node_or_null("/root/PoliceSystem")
	
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UILayer"
	ui_layer.layer = 50
	parent_node.add_child(ui_layer)
	
	create_top_panel(parent_node)
	create_bottom_panel(parent_node)
	
	# Подписываемся на изменения УА
	if police_system:
		police_system.ua_changed.connect(func(_ua): update_ui())

func create_top_panel(parent_node: Node):
	var top_panel = ColorRect.new()
	top_panel.size = Vector2(720, 120)
	top_panel.position = Vector2(0, 0)
	top_panel.color = Color(0.1, 0.1, 0.1, 0.9)
	top_panel.name = "TopPanel"
	top_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_layer.add_child(top_panel)
	
	# Аватар
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
	
	# ⭐ НОВОЕ: Невидимая кнопка поверх аватара для клика
	var avatar_btn = Button.new()
	avatar_btn.custom_minimum_size = Vector2(80, 80)
	avatar_btn.position = Vector2(20, 20)
	avatar_btn.name = "AvatarClickButton"
	avatar_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Делаем кнопку прозрачной
	var transparent_style = StyleBoxEmpty.new()
	avatar_btn.add_theme_stylebox_override("normal", transparent_style)
	avatar_btn.add_theme_stylebox_override("hover", transparent_style)
	avatar_btn.add_theme_stylebox_override("pressed", transparent_style)
	
	# При клике - открываем инвентарь
	avatar_btn.pressed.connect(func():
		print("🎒 Клик по аватару - открываем инвентарь")
		# Открываем инвентарь через menu_manager
		var menu_mgr = parent_node.get_node_or_null("MenuManager")
		if menu_mgr and menu_mgr.has_method("show_inventory_menu"):
			menu_mgr.show_inventory_menu(0)  # Главный игрок (индекс 0)
		else:
			print("⚠️ MenuManager не найден!")
	)
	
	ui_layer.add_child(avatar_btn)
	
	# Репутация
	var rep_label = Label.new()
	rep_label.text = "Авторитет: " + str(player_data["reputation"])
	rep_label.position = Vector2(120, 18)
	rep_label.add_theme_font_size_override("font_size", 16)
	rep_label.add_theme_color_override("font_color", Color.WHITE)
	rep_label.name = "ReputationLabel"
	rep_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(rep_label)
	
	# Деньги
	var balance_label = Label.new()
	balance_label.text = "Деньги: " + str(player_data["balance"]) + " руб."
	balance_label.position = Vector2(120, 43)
	balance_label.add_theme_font_size_override("font_size", 16)
	balance_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	balance_label.name = "BalanceLabel"
	balance_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(balance_label)
	
	# Здоровье
	var health_label = Label.new()
	health_label.text = "Здоровье: " + str(player_data["health"])
	health_label.position = Vector2(120, 68)
	health_label.add_theme_font_size_override("font_size", 16)
	health_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
	health_label.name = "HealthLabel"
	health_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(health_label)
	
	# ✅ НОВОЕ: УА полиции
	var ua_label = Label.new()
	ua_label.text = "🚔 УА: 0"
	ua_label.position = Vector2(120, 93)
	ua_label.add_theme_font_size_override("font_size", 15)
	ua_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	ua_label.name = "UALabel"
	ua_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(ua_label)
	
	# Дата
	var date_label = Label.new()
	date_label.text = "02.03.1992, 10:00"
	date_label.position = Vector2(480, 25)
	date_label.add_theme_font_size_override("font_size", 14)
	date_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	date_label.name = "DateLabel"
	date_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(date_label)
	
	# Кнопка сетки
	var grid_button = Button.new()
	grid_button.custom_minimum_size = Vector2(50, 30)
	grid_button.position = Vector2(540, 55)
	grid_button.text = "🗺️"
	grid_button.name = "GridToggleButton"
	grid_button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var style_on = StyleBoxFlat.new()
	style_on.bg_color = Color(0.2, 0.6, 0.2, 0.9)
	grid_button.add_theme_stylebox_override("normal", style_on)
	grid_button.add_theme_font_size_override("font_size", 18)
	
	grid_button.pressed.connect(func():
		var grid_system = parent_node.get_node_or_null("GridSystem")
		if grid_system:
			var is_visible = grid_system.toggle_grid_visibility()
			if is_visible:
				var style = StyleBoxFlat.new()
				style.bg_color = Color(0.2, 0.6, 0.2, 0.9)
				grid_button.add_theme_stylebox_override("normal", style)
				grid_button.text = "🗺️"
			else:
				var style = StyleBoxFlat.new()
				style.bg_color = Color(0.6, 0.2, 0.2, 0.9)
				grid_button.add_theme_stylebox_override("normal", style)
				grid_button.text = "❌"
	)
	
	ui_layer.add_child(grid_button)

func create_bottom_panel(parent_node: Node):
	var bottom_panel = ColorRect.new()
	bottom_panel.size = Vector2(720, 100)
	bottom_panel.position = Vector2(0, 1180)
	bottom_panel.color = Color(0.1, 0.1, 0.1, 0.9)
	bottom_panel.name = "BottomPanel"
	bottom_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_layer.add_child(bottom_panel)
	
	var menu_buttons = ["Банда", "Районы", "Квесты", "Меню"]
	var button_width = 160
	var spacing = 10
	
	for i in range(menu_buttons.size()):
		var button = Button.new()
		button.custom_minimum_size = Vector2(button_width, 60)
		button.position = Vector2(spacing + i * (button_width + spacing), 1200)
		button.text = menu_buttons[i]
		button.name = "MenuButton_" + menu_buttons[i]
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		
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
		button.pressed.connect(func():
			print("🎮 Кнопка нажата: " + btn_name)
			parent_node.on_bottom_button_pressed(btn_name)
		)
		
		ui_layer.add_child(button)

func update_ui():
	if not ui_layer:
		return
	
	var rep_label = ui_layer.get_node_or_null("ReputationLabel")
	if rep_label:
		rep_label.text = "Авторитет: " + str(player_data["reputation"])
	
	var balance_label = ui_layer.get_node_or_null("BalanceLabel")
	if balance_label:
		balance_label.text = "Деньги: " + str(player_data["balance"]) + " руб."
	
	var health_label = ui_layer.get_node_or_null("HealthLabel")
	if health_label:
		health_label.text = "Здоровье: " + str(player_data["health"])
	
	# ✅ НОВОЕ: Обновление УА
	var ua_label = ui_layer.get_node_or_null("UALabel")
	if ua_label and police_system:
		var ua = police_system.ua_level
		var ua_color = police_system.get_ua_color()
		ua_label.text = "🚔 УА: %d (%s)" % [ua, police_system.get_ua_status()]
		ua_label.add_theme_color_override("font_color", ua_color)

func show_message(text: String, parent_node: Node):
	var message = Label.new()
	message.text = text
	message.position = Vector2(200, 350)
	message.add_theme_font_size_override("font_size", 22)
	message.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.name = "MessageLabel"
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(message)
	
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	parent_node.add_child(timer)
	
	timer.timeout.connect(func():
		if message and is_instance_valid(message):
			message.queue_free()
		timer.queue_free()
	)
	timer.start()

func show_floating_text(text: String, position: Vector2, color: Color, parent_node: Node):
	var floating_label = Label.new()
	floating_label.text = text
	floating_label.position = position
	floating_label.add_theme_font_size_override("font_size", 20)
	floating_label.add_theme_color_override("font_color", color)
	floating_label.z_index = 100
	floating_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(floating_label)
	
	var tween = parent_node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(floating_label, "position:y", position.y - 50, 1.0)
	tween.tween_property(floating_label, "modulate:a", 0.0, 1.0)
	
	await tween.finished
	floating_label.queue_free()

func get_ui_layer() -> CanvasLayer:
	return ui_layer
