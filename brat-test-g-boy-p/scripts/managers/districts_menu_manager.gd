# districts_menu_manager.gd (ИСПРАВЛЕНО - layer 150)
extends Node

var districts_system

func initialize():
	districts_system = get_node_or_null("/root/DistrictsSystem")

func show_districts_menu(main_node):
	if not districts_system:
		main_node.show_message("Система районов недоступна")
		return
	
	var districts_menu = CanvasLayer.new()
	districts_menu.name = "DistrictsMenu"
	districts_menu.layer = 200  # ✅ КРИТИЧНО! ВЫШЕ сетки (5) и UI (50)
	main_node.add_child(districts_menu)
	
	# ✅ Overlay для блокировки кликов
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.position = Vector2(0, 0)
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	districts_menu.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(700, 1100)
	bg.position = Vector2(10, 140)
	bg.color = Color(0.05, 0.05, 0.05, 0.95)
	districts_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "🏙️ РАЙОНЫ ТВЕРИ"
	title.position = Vector2(240, 160)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	districts_menu.add_child(title)
	
	var total_income = districts_system.get_total_player_income()
	var income_label = Label.new()
	income_label.text = "💰 Пассивный доход: " + str(total_income) + " руб./день"
	income_label.position = Vector2(30, 210)
	income_label.add_theme_font_size_override("font_size", 18)
	income_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	districts_menu.add_child(income_label)
	
	var districts = districts_system.get_all_districts()
	var y_pos = 260
	
	for district in districts:
		var district_bg = ColorRect.new()
		district_bg.size = Vector2(680, 160)
		district_bg.position = Vector2(20, y_pos)
		# ✅ ИСПРАВЛЕНО: Проверяем тип color перед умножением
		var district_color = district.get("color", Color.WHITE)
		if district_color is Color:
			district_bg.color = district_color * 0.3
		else:
			district_bg.color = Color(0.2, 0.2, 0.2, 1.0)
		districts_menu.add_child(district_bg)
		
		var district_name = Label.new()
		district_name.text = "📍 " + str(district.get("name", "Неизвестно"))
		district_name.position = Vector2(30, y_pos + 10)
		district_name.add_theme_font_size_override("font_size", 22)
		district_name.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
		districts_menu.add_child(district_name)
		
		var owner_label = Label.new()
		var owner_color = Color(0.7, 0.7, 0.7, 1.0)
		var owner = str(district.get("owner", "Нейтральный"))
		if owner == "Игрок":
			owner_color = Color(0.3, 1.0, 0.3, 1.0)
		elif owner != "Нейтральный":
			owner_color = Color(1.0, 0.3, 0.3, 1.0)
		
		owner_label.text = "Владелец: " + owner
		owner_label.position = Vector2(30, y_pos + 40)
		owner_label.add_theme_font_size_override("font_size", 16)
		owner_label.add_theme_color_override("font_color", owner_color)
		districts_menu.add_child(owner_label)
		
		var influence_dict = district.get("influence", {})
		var player_influence = int(influence_dict.get("Игрок", 0))
		var influence_label = Label.new()
		influence_label.text = "Ваше влияние: " + str(player_influence) + "%"
		influence_label.position = Vector2(30, y_pos + 65)
		influence_label.add_theme_font_size_override("font_size", 16)
		influence_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 1.0))
		districts_menu.add_child(influence_label)
		
		var progress_bg = ColorRect.new()
		progress_bg.size = Vector2(300, 20)
		progress_bg.position = Vector2(30, y_pos + 90)
		progress_bg.color = Color(0.2, 0.2, 0.2, 1.0)
		districts_menu.add_child(progress_bg)
		
		# ✅ ИСПРАВЛЕНО: Приводим к float перед делением
		var progress_width = 300.0 * (float(player_influence) / 100.0)
		var progress_fill = ColorRect.new()
		progress_fill.size = Vector2(progress_width, 20)
		progress_fill.position = Vector2(30, y_pos + 90)
		progress_fill.color = Color(0.3, 0.8, 1.0, 1.0)
		districts_menu.add_child(progress_fill)
		
		var dist_name = str(district.get("name", ""))
		var income = districts_system.get_district_income(dist_name, "Игрок")
		var income_text = Label.new()
		income_text.text = "💵 Ваш доход: " + str(income) + " руб./день"
		income_text.position = Vector2(30, y_pos + 120)
		income_text.add_theme_font_size_override("font_size", 14)
		income_text.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7, 1.0))
		districts_menu.add_child(income_text)
		
		y_pos += 180
	
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(680, 50)
	close_btn.position = Vector2(20, 1070)
	close_btn.text = "ЗАКРЫТЬ"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): districts_menu.queue_free())
	
	districts_menu.add_child(close_btn)

func show_district_captured_notification(main_node, district_name: String, by_gang: String):
	var notification = CanvasLayer.new()
	notification.name = "DistrictCapturedNotification"
	notification.layer = 200  # ✅ Поверх всего
	main_node.add_child(notification)
	
	var bg = ColorRect.new()
	bg.size = Vector2(600, 150)
	bg.position = Vector2(60, 565)
	bg.color = Color(0.1, 0.3, 0.1, 0.95) if by_gang == "Игрок" else Color(0.3, 0.1, 0.1, 0.95)
	notification.add_child(bg)
	
	var title = Label.new()
	title.text = "🏴 РАЙОН ЗАХВАЧЕН!"
	title.position = Vector2(220, 585)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	notification.add_child(title)
	
	var info = Label.new()
	info.text = district_name + " теперь под контролем: " + by_gang
	info.position = Vector2(100, 640)
	info.add_theme_font_size_override("font_size", 20)
	info.add_theme_color_override("font_color", Color.WHITE)
	notification.add_child(info)
	
	var timer = Timer.new()
	timer.wait_time = 4.0
	timer.one_shot = true
	main_node.add_child(timer)
	
	timer.timeout.connect(func():
		if notification and is_instance_valid(notification):
			notification.queue_free()
		timer.queue_free()
	)
	timer.start()
