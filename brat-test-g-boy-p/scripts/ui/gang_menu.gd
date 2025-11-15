# gang_menu.gd (ИСПРАВЛЕНО - кнопки активации + is_active)
extends CanvasLayer

signal member_inventory_clicked(member_index: int)
signal member_activated(member_index: int, is_active: bool)

var gang_members = []
var gang_generator

func _ready():
	layer = 200
	gang_generator = get_node("/root/GangMemberGenerator")

func setup(members):
	gang_members = members
	
	# ✅ ВАЖНО: Инициализируем is_active для всех членов
	for i in range(gang_members.size()):
		if not gang_members[i].has("is_active"):
			# Главный игрок (индекс 0) всегда активен
			gang_members[i]["is_active"] = (i == 0)
	
	create_ui()

func create_ui():
	for child in get_children():
		child.queue_free()
	
	# Overlay
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.position = Vector2(0, 0)
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(700, 1060)
	bg.position = Vector2(10, 140)
	bg.color = Color(0.05, 0.05, 0.05, 0.95)
	bg.name = "GangBG"
	add_child(bg)
	
	var title = Label.new()
	title.text = "БАНДА"
	title.position = Vector2(320, 160)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	add_child(title)
	
	# ✅ Счётчик активных бойцов
	var active_count = 0
	for member in gang_members:
		if member.get("is_active", false):
			active_count += 1
	
	var active_label = Label.new()
	active_label.text = "Активных бойцов: %d/%d" % [active_count, gang_members.size()]
	active_label.position = Vector2(30, 200)
	active_label.add_theme_font_size_override("font_size", 18)
	active_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	add_child(active_label)
	
	var hire_btn = Button.new()
	hire_btn.custom_minimum_size = Vector2(200, 50)
	hire_btn.position = Vector2(480, 155)
	hire_btn.text = "💰 НАНЯТЬ БОЙЦА"
	hire_btn.name = "HireButton"
	
	var style_hire = StyleBoxFlat.new()
	style_hire.bg_color = Color(0.2, 0.5, 0.2, 1.0)
	hire_btn.add_theme_stylebox_override("normal", style_hire)
	
	var style_hire_hover = StyleBoxFlat.new()
	style_hire_hover.bg_color = Color(0.3, 0.6, 0.3, 1.0)
	hire_btn.add_theme_stylebox_override("hover", style_hire_hover)
	
	hire_btn.add_theme_font_size_override("font_size", 16)
	hire_btn.pressed.connect(func(): show_hire_menu())
	add_child(hire_btn)
	
	var member_y = 240
	for i in range(gang_members.size()):
		var member = gang_members[i]
		var is_active = member.get("is_active", false)
		var is_main = (i == 0)
		
		# Цвет фона зависит от активности
		var bg_color = Color(0.2, 0.2, 0.25, 1.0)
		if is_active:
			bg_color = Color(0.2, 0.3, 0.25, 1.0)  # Зеленоватый для активных
		
		var member_bg = ColorRect.new()
		member_bg.size = Vector2(680, 150)
		member_bg.position = Vector2(20, member_y)
		member_bg.color = bg_color
		member_bg.name = "MemberCard_" + str(i)
		add_child(member_bg)
		
		# ✅ КНОПКА АКТИВАЦИИ (только для НЕ главного игрока)
		if not is_main:
			var activate_btn = Button.new()
			activate_btn.custom_minimum_size = Vector2(50, 50)
			activate_btn.position = Vector2(30, member_y + 50)
			activate_btn.text = "✓" if is_active else "+"
			activate_btn.name = "ActivateBtn_" + str(i)
			
			var style_activate = StyleBoxFlat.new()
			if is_active:
				style_activate.bg_color = Color(0.2, 0.7, 0.2, 1.0)  # Зеленая - активирован
			else:
				style_activate.bg_color = Color(0.5, 0.5, 0.5, 1.0)  # Серая - не активирован
			activate_btn.add_theme_stylebox_override("normal", style_activate)
			
			var style_activate_hover = StyleBoxFlat.new()
			style_activate_hover.bg_color = style_activate.bg_color * 1.2
			activate_btn.add_theme_stylebox_override("hover", style_activate_hover)
			
			activate_btn.add_theme_font_size_override("font_size", 28)
			
			var member_idx = i
			activate_btn.pressed.connect(func():
				toggle_member_activation(member_idx)
			)
			add_child(activate_btn)
		
		var member_name = Label.new()
		member_name.text = member["name"]
		if is_main:
			member_name.text += " (главный)"
		elif is_active:
			member_name.text += " ✓"
		member_name.position = Vector2(90 if not is_main else 30, member_y + 10)
		member_name.add_theme_font_size_override("font_size", 22)
		member_name.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
		add_child(member_name)
		
		if member.has("background"):
			var bg_label = Label.new()
			bg_label.text = member["background"]
			bg_label.position = Vector2(90 if not is_main else 30, member_y + 35)
			bg_label.add_theme_font_size_override("font_size", 14)
			bg_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
			add_child(bg_label)
		
		var member_hp = Label.new()
		member_hp.text = "❤ HP: " + str(member.get("hp", member.get("health", 100)))
		member_hp.position = Vector2(90 if not is_main else 30, member_y + 60)
		member_hp.add_theme_font_size_override("font_size", 16)
		member_hp.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
		add_child(member_hp)
		
		var member_str = Label.new()
		member_str.text = "💪 Сила: " + str(member.get("damage", member.get("strength", 10)))
		member_str.position = Vector2(90 if not is_main else 30, member_y + 85)
		member_str.add_theme_font_size_override("font_size", 16)
		member_str.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 1.0))
		add_child(member_str)
		
		var player_stats = get_node("/root/PlayerStats")
		if player_stats and i == 0:
			var quick_stats = Label.new()
			quick_stats.text = "⚔ Урон: %d | 🛡 Защита: %d | 🌀 Уклонение: %d%%" % [
				player_stats.calculate_melee_damage(),
				player_stats.equipment_bonuses["defense"],
				player_stats.calculate_evasion()
			]
			quick_stats.position = Vector2(30, member_y + 110)
			quick_stats.add_theme_font_size_override("font_size", 14)
			quick_stats.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7, 1.0))
			add_child(quick_stats)
		
		var inv_btn = Button.new()
		inv_btn.custom_minimum_size = Vector2(180, 45)
		inv_btn.position = Vector2(500, member_y + 25)
		inv_btn.text = "ИНВЕНТАРЬ"
		inv_btn.name = "InvBtn_" + str(i)
		
		var style_inv = StyleBoxFlat.new()
		style_inv.bg_color = Color(0.3, 0.5, 0.3, 1.0)
		inv_btn.add_theme_stylebox_override("normal", style_inv)
		
		var style_inv_hover = StyleBoxFlat.new()
		style_inv_hover.bg_color = Color(0.4, 0.6, 0.4, 1.0)
		inv_btn.add_theme_stylebox_override("hover", style_inv_hover)
		
		inv_btn.add_theme_font_size_override("font_size", 18)
		inv_btn.add_theme_color_override("font_color", Color.WHITE)
		
		var member_idx = i
		inv_btn.pressed.connect(func():
			member_inventory_clicked.emit(member_idx)
			queue_free()
		)
		add_child(inv_btn)
		
		var stats_btn = Button.new()
		stats_btn.custom_minimum_size = Vector2(180, 45)
		stats_btn.position = Vector2(500, member_y + 80)
		stats_btn.text = "📊 СТАТЫ"
		stats_btn.name = "StatsBtn_" + str(i)
		
		var style_stats = StyleBoxFlat.new()
		style_stats.bg_color = Color(0.2, 0.3, 0.5, 1.0)
		stats_btn.add_theme_stylebox_override("normal", style_stats)
		
		var style_stats_hover = StyleBoxFlat.new()
		style_stats_hover.bg_color = Color(0.3, 0.4, 0.6, 1.0)
		stats_btn.add_theme_stylebox_override("hover", style_stats_hover)
		
		stats_btn.add_theme_font_size_override("font_size", 18)
		stats_btn.add_theme_color_override("font_color", Color.WHITE)
		
		stats_btn.pressed.connect(func(): show_stats_window())
		add_child(stats_btn)
		
		member_y += 170
	
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(680, 50)
	close_btn.position = Vector2(20, 1110)
	close_btn.text = "ЗАКРЫТЬ"
	close_btn.name = "CloseGang"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	
	close_btn.pressed.connect(func(): queue_free())
	add_child(close_btn)

# ✅ НОВАЯ ФУНКЦИЯ: Переключение активации члена банды
func toggle_member_activation(member_index: int):
	if member_index == 0:
		return  # Главный игрок всегда активен
	
	if member_index >= gang_members.size():
		return
	
	var member = gang_members[member_index]
	var is_active = member.get("is_active", false)
	
	# Переключаем статус
	member["is_active"] = not is_active
	
	var main_node = get_parent()
	if main_node:
		if member["is_active"]:
			main_node.show_message("✅ %s добавлен в активную банду" % member["name"])
		else:
			main_node.show_message("❌ %s убран из активной банды" % member["name"])
	
	# Обновляем UI
	member_activated.emit(member_index, member["is_active"])
	queue_free()
	
	# Заново открываем меню банды
	var gang_manager = get_node("/root/GangManager")
	if gang_manager and main_node:
		gang_manager.show_gang_menu(main_node, gang_members)

func show_hire_menu():
	var candidates = []
	for i in range(3):
		var member = gang_generator.generate_random_member(1, 3)
		candidates.append(member)
	
	var hire_menu = CanvasLayer.new()
	hire_menu.name = "HireMenu"
	hire_menu.layer = 210
	get_parent().add_child(hire_menu)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	hire_menu.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(700, 1060)
	bg.position = Vector2(10, 140)
	bg.color = Color(0.05, 0.1, 0.05, 0.98)
	hire_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "💰 НАНЯТЬ БОЙЦА"
	title.position = Vector2(240, 160)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	hire_menu.add_child(title)
	
	var info = Label.new()
	info.text = "Доступные кандидаты:"
	info.position = Vector2(30, 210)
	info.add_theme_font_size_override("font_size", 18)
	info.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	hire_menu.add_child(info)
	
	var candidate_y = 250
	for i in range(candidates.size()):
		var candidate = candidates[i]
		var cost = gang_generator.calculate_hire_cost(candidate)
		
		var card_bg = ColorRect.new()
		card_bg.size = Vector2(680, 260)
		card_bg.position = Vector2(20, candidate_y)
		card_bg.color = Color(0.15, 0.2, 0.15, 1.0)
		hire_menu.add_child(card_bg)
		
		var desc = gang_generator.get_member_description(candidate)
		var desc_label = Label.new()
		desc_label.text = desc
		desc_label.position = Vector2(30, candidate_y + 10)
		desc_label.add_theme_font_size_override("font_size", 16)
		desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
		hire_menu.add_child(desc_label)
		
		var cost_label = Label.new()
		cost_label.text = "💰 Стоимость: " + str(cost) + " руб."
		cost_label.position = Vector2(30, candidate_y + 180)
		cost_label.add_theme_font_size_override("font_size", 20)
		cost_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
		hire_menu.add_child(cost_label)
		
		var hire_candidate_btn = Button.new()
		hire_candidate_btn.custom_minimum_size = Vector2(300, 50)
		hire_candidate_btn.position = Vector2(360, candidate_y + 190)
		hire_candidate_btn.text = "НАНЯТЬ"
		hire_candidate_btn.name = "HireCandidate_" + str(i)
		
		var style_hire_c = StyleBoxFlat.new()
		style_hire_c.bg_color = Color(0.2, 0.6, 0.2, 1.0)
		hire_candidate_btn.add_theme_stylebox_override("normal", style_hire_c)
		
		var style_hire_c_hover = StyleBoxFlat.new()
		style_hire_c_hover.bg_color = Color(0.3, 0.7, 0.3, 1.0)
		hire_candidate_btn.add_theme_stylebox_override("hover", style_hire_c_hover)
		
		hire_candidate_btn.add_theme_font_size_override("font_size", 20)
		
		var c = candidate.duplicate(true)
		var hire_cost = cost
		hire_candidate_btn.pressed.connect(func():
			hire_candidate(c, hire_cost, hire_menu)
		)
		hire_menu.add_child(hire_candidate_btn)
		
		candidate_y += 280
	
	var cancel_btn = Button.new()
	cancel_btn.custom_minimum_size = Vector2(680, 50)
	cancel_btn.position = Vector2(20, 1110)
	cancel_btn.text = "ОТМЕНА"
	
	var style_cancel = StyleBoxFlat.new()
	style_cancel.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	cancel_btn.add_theme_stylebox_override("normal", style_cancel)
	
	var style_cancel_hover = StyleBoxFlat.new()
	style_cancel_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	cancel_btn.add_theme_stylebox_override("hover", style_cancel_hover)
	
	cancel_btn.add_theme_font_size_override("font_size", 20)
	cancel_btn.pressed.connect(func(): hire_menu.queue_free())
	hire_menu.add_child(cancel_btn)

func hire_candidate(candidate: Dictionary, cost: int, hire_menu: CanvasLayer):
	var main_node = get_parent()
	if main_node.player_data["balance"] < cost:
		main_node.show_message("❌ Недостаточно денег! Нужно: " + str(cost) + " руб.")
		return
	
	main_node.player_data["balance"] -= cost
	
	# ✅ ВАЖНО: Новый член НЕ активен по умолчанию
	candidate["is_active"] = false
	
	# ✅ Стандартизируем поля
	if not candidate.has("hp"):
		candidate["hp"] = candidate.get("health", 80)
	if not candidate.has("max_hp"):
		candidate["max_hp"] = candidate["hp"]
	if not candidate.has("damage"):
		candidate["damage"] = candidate.get("strength", 10)
	if not candidate.has("defense"):
		candidate["defense"] = 0
	if not candidate.has("morale"):
		candidate["morale"] = 80
	if not candidate.has("accuracy"):
		candidate["accuracy"] = 0.65
	if not candidate.has("weapon"):
		candidate["weapon"] = "Кулаки"
	if not candidate.has("inventory"):
		candidate["inventory"] = []
	if not candidate.has("equipment"):
		candidate["equipment"] = {"helmet": null, "armor": null, "melee": null, "ranged": null, "gadget": null}
	if not candidate.has("pockets"):
		candidate["pockets"] = [null, null, null]
	
	main_node.gang_members.append(candidate)
	
	main_node.show_message("✅ " + candidate["name"] + " нанят! Активируйте его в меню банды.")
	main_node.update_ui()
	
	hire_menu.queue_free()
	queue_free()
	
	var gang_manager = get_node("/root/GangManager")
	gang_manager.show_gang_menu(main_node, main_node.gang_members)

func show_stats_window():
	var player_stats = get_node("/root/PlayerStats")
	if not player_stats:
		return
	
	var stats_popup = CanvasLayer.new()
	stats_popup.name = "StatsPopup"
	stats_popup.layer = 210
	get_parent().add_child(stats_popup)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	stats_popup.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(680, 950)
	bg.position = Vector2(20, 165)
	bg.color = Color(0.05, 0.05, 0.05, 0.98)
	stats_popup.add_child(bg)
	
	var title = Label.new()
	title.text = "📊 СТАТИСТИКА"
	title.position = Vector2(250, 185)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	stats_popup.add_child(title)
	
	var stats_text = player_stats.get_stats_text()
	var label = Label.new()
	label.text = stats_text
	label.position = Vector2(40, 235)
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color.WHITE)
	stats_popup.add_child(label)
	
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(640, 50)
	close_btn.position = Vector2(40, 1050)
	close_btn.text = "ЗАКРЫТЬ"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): stats_popup.queue_free())
	
	stats_popup.add_child(close_btn)
