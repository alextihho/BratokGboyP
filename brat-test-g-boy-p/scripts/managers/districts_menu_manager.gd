# districts_menu_manager.gd (ИСПРАВЛЕНО - без get_district)
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
	districts_menu.layer = 200
	main_node.add_child(districts_menu)
	
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
		
		# Кнопка действий
		var action_btn = Button.new()
		action_btn.custom_minimum_size = Vector2(200, 40)
		action_btn.position = Vector2(480, y_pos + 110)
		action_btn.text = "⚙️ ДЕЙСТВИЯ"
		
		var style_action = StyleBoxFlat.new()
		style_action.bg_color = Color(0.2, 0.4, 0.6, 1.0)
		action_btn.add_theme_stylebox_override("normal", style_action)
		
		var style_action_hover = StyleBoxFlat.new()
		style_action_hover.bg_color = Color(0.3, 0.5, 0.7, 1.0)
		action_btn.add_theme_stylebox_override("hover", style_action_hover)
		
		action_btn.add_theme_font_size_override("font_size", 16)
		
		# ✅ ИСПРАВЛЕНО: Передаём весь district, а не только имя
		var current_district = district.duplicate(true)
		action_btn.pressed.connect(func():
			show_district_actions(main_node, current_district, districts_menu)
		)
		
		districts_menu.add_child(action_btn)
		
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

# ✅ ИСПРАВЛЕНО: Принимает district Dictionary вместо имени
func show_district_actions(main_node, district: Dictionary, parent_menu):
	var actions_menu = CanvasLayer.new()
	actions_menu.name = "DistrictActionsMenu"
	actions_menu.layer = 210
	main_node.add_child(actions_menu)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.position = Vector2(0, 0)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	actions_menu.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(600, 500)
	bg.position = Vector2(60, 390)
	bg.color = Color(0.05, 0.05, 0.05, 0.98)
	actions_menu.add_child(bg)
	
	# ✅ ИСПРАВЛЕНО: Получаем имя из district
	var district_name = district.get("name", "Неизвестно")
	
	var title = Label.new()
	title.text = "📍 " + district_name
	title.position = Vector2(240, 410)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	actions_menu.add_child(title)
	
	var owner = district.get("owner", "Нейтральный")
	var influence_dict = district.get("influence", {})
	var player_influence = int(influence_dict.get("Игрок", 0))
	
	var info = Label.new()
	info.text = "Владелец: %s\nВаше влияние: %d%%" % [owner, player_influence]
	info.position = Vector2(80, 460)
	info.add_theme_font_size_override("font_size", 16)
	info.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	actions_menu.add_child(info)
	
	var y_pos = 540
	
	# 1. Захватить район
	if owner != "Игрок":
		var capture_btn = Button.new()
		capture_btn.custom_minimum_size = Vector2(560, 50)
		capture_btn.position = Vector2(80, y_pos)
		capture_btn.text = "🏴 Захватить район (100 репутации)"
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.6, 0.2, 0.2, 1.0)
		capture_btn.add_theme_stylebox_override("normal", style)
		
		capture_btn.add_theme_font_size_override("font_size", 18)
		capture_btn.pressed.connect(func():
			handle_capture_district(main_node, district_name, actions_menu)
		)
		actions_menu.add_child(capture_btn)
		y_pos += 60
	
	# 2. Собрать дань
	if owner == "Игрок":
		var collect_btn = Button.new()
		collect_btn.custom_minimum_size = Vector2(560, 50)
		collect_btn.position = Vector2(80, y_pos)
		collect_btn.text = "💰 Собрать дань"
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.5, 0.2, 1.0)
		collect_btn.add_theme_stylebox_override("normal", style)
		
		collect_btn.add_theme_font_size_override("font_size", 18)
		collect_btn.pressed.connect(func():
			handle_collect_tribute(main_node, district_name, actions_menu)
		)
		actions_menu.add_child(collect_btn)
		y_pos += 60
	
	# 3. Повысить влияние
	var influence_btn = Button.new()
	influence_btn.custom_minimum_size = Vector2(560, 50)
	influence_btn.position = Vector2(80, y_pos)
	influence_btn.text = "📈 Повысить влияние (50р, +10%)"
	
	var style_inf = StyleBoxFlat.new()
	style_inf.bg_color = Color(0.2, 0.3, 0.5, 1.0)
	influence_btn.add_theme_stylebox_override("normal", style_inf)
	
	influence_btn.add_theme_font_size_override("font_size", 18)
	influence_btn.pressed.connect(func():
		handle_increase_influence(main_node, district_name, actions_menu)
	)
	actions_menu.add_child(influence_btn)
	y_pos += 60
	
	# 4. Разместить людей
	var deploy_btn = Button.new()
	deploy_btn.custom_minimum_size = Vector2(560, 50)
	deploy_btn.position = Vector2(80, y_pos)
	deploy_btn.text = "👥 Разместить людей"
	
	var style_dep = StyleBoxFlat.new()
	style_dep.bg_color = Color(0.3, 0.3, 0.3, 1.0)
	deploy_btn.add_theme_stylebox_override("normal", style_dep)
	
	deploy_btn.add_theme_font_size_override("font_size", 18)
	deploy_btn.pressed.connect(func():
		main_node.show_message("🚧 В разработке")
		actions_menu.queue_free()
	)
	actions_menu.add_child(deploy_btn)
	y_pos += 80
	
	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(560, 50)
	close_btn.position = Vector2(80, y_pos)
	close_btn.text = "ЗАКРЫТЬ"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): actions_menu.queue_free())
	
	actions_menu.add_child(close_btn)

func handle_capture_district(main_node, district_name: String, actions_menu):
	if main_node.player_data["reputation"] < 100:
		main_node.show_message("❌ Нужно 100 репутации!")
		return
	
	main_node.player_data["reputation"] -= 100
	districts_system.capture_district(district_name, "Игрок")
	main_node.show_message("✅ Район %s захвачен!" % district_name)
	main_node.update_ui()
	
	actions_menu.queue_free()
	
	var old_menu = main_node.get_node_or_null("DistrictsMenu")
	if old_menu:
		old_menu.queue_free()
		await main_node.get_tree().process_frame
	
	show_districts_menu(main_node)

func handle_collect_tribute(main_node, district_name: String, actions_menu):
	var income = districts_system.get_district_income(district_name, "Игрок")
	
	if income <= 0:
		main_node.show_message("❌ Нет дохода с этого района!")
		return
	
	var tribute = income * 3
	main_node.player_data["balance"] += tribute
	main_node.show_message("💰 Собрано: %d руб." % tribute)
	main_node.update_ui()
	
	actions_menu.queue_free()

func handle_increase_influence(main_node, district_name, actions_menu):
	# ✅ Проверяем тип district_name
	var name_str = ""
	if district_name is String:
		name_str = district_name
	elif district_name is Dictionary:
		name_str = district_name.get("name", "")
	else:
		name_str = str(district_name)
	
	if main_node.player_data["balance"] < 50:
		main_node.show_message("❌ Нужно 50 рублей!")
		return
	
	main_node.player_data["balance"] -= 50
	# ✅ ИСПРАВЛЕНО: Используем add_influence вместо modify_influence
	districts_system.add_influence(name_str, "Игрок", 10)
	main_node.show_message("📈 Влияние в %s увеличено на 10%%!" % name_str)
	main_node.update_ui()
	
	actions_menu.queue_free()
	
	var old_menu = main_node.get_node_or_null("DistrictsMenu")
	if old_menu:
		old_menu.queue_free()
		await main_node.get_tree().process_frame
	
	show_districts_menu(main_node)

func show_district_captured_notification(main_node, district_name: String, by_gang: String):
	var notification = CanvasLayer.new()
	notification.name = "DistrictCapturedNotification"
	notification.layer = 200
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
