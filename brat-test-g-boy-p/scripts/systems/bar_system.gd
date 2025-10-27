# bar_system.gd - Система бара
extends Node

signal rest_completed()
signal party_completed()

var time_system
var player_stats

func _ready():
	time_system = get_node_or_null("/root/TimeSystem")
	player_stats = get_node_or_null("/root/PlayerStats")
	print("🍺 Система бара загружена")

# Показать меню бара
func show_bar_menu(main_node: Node, player_data: Dictionary, gang_members: Array):
	var bar_menu = CanvasLayer.new()
	bar_menu.layer = 100
	bar_menu.name = "BarMenu"
	main_node.add_child(bar_menu)
	
	# Overlay
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	bar_menu.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(700, 1100)
	bg.position = Vector2(10, 90)
	bg.color = Color(0.15, 0.1, 0.05, 0.95)  # Коричневатый оттенок
	bar_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "🍺 БАР"
	title.position = Vector2(310, 110)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1.0))
	bar_menu.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Место где можно расслабиться..."
	subtitle.position = Vector2(220, 160)
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.7, 0.5, 1.0))
	bar_menu.add_child(subtitle)
	
	var y_pos = 220
	
	# === ОТДОХНУТЬ ===
	var rest_title = Label.new()
	rest_title.text = "═══ ОТДОХНУТЬ ═══"
	rest_title.position = Vector2(260, y_pos)
	rest_title.add_theme_font_size_override("font_size", 22)
	rest_title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5, 1.0))
	bar_menu.add_child(rest_title)
	y_pos += 50
	
	var rest_options = [
		{"hours": 3, "hp": 15, "cost": 30, "name": "Быстрый отдых"},
		{"hours": 6, "hp": 35, "cost": 60, "name": "Долгий отдых"}
	]
	
	for option in rest_options:
		var card_bg = ColorRect.new()
		card_bg.size = Vector2(680, 100)
		card_bg.position = Vector2(20, y_pos)
		card_bg.color = Color(0.2, 0.15, 0.1, 1.0)
		bar_menu.add_child(card_bg)
		
		var option_name = Label.new()
		option_name.text = option["name"]
		option_name.position = Vector2(40, y_pos + 15)
		option_name.add_theme_font_size_override("font_size", 20)
		option_name.add_theme_color_override("font_color", Color(1.0, 1.0, 0.5, 1.0))
		bar_menu.add_child(option_name)
		
		var option_desc = Label.new()
		option_desc.text = "⏰ %d часов | ❤️ +%d HP | 💰 %d руб." % [option["hours"], option["hp"], option["cost"]]
		option_desc.position = Vector2(40, y_pos + 45)
		option_desc.add_theme_font_size_override("font_size", 16)
		option_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
		bar_menu.add_child(option_desc)
		
		var rest_btn = Button.new()
		rest_btn.custom_minimum_size = Vector2(200, 50)
		rest_btn.position = Vector2(480, y_pos + 25)
		rest_btn.text = "ОТДОХНУТЬ"
		rest_btn.disabled = player_data["balance"] < option["cost"]
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.6, 0.3, 1.0) if not rest_btn.disabled else Color(0.3, 0.3, 0.3, 1.0)
		rest_btn.add_theme_stylebox_override("normal", style)
		
		rest_btn.add_theme_font_size_override("font_size", 16)
		
		var opt = option.duplicate()
		rest_btn.pressed.connect(func():
			rest_at_bar(main_node, player_data, opt, bar_menu)
		)
		bar_menu.add_child(rest_btn)
		
		y_pos += 120
	
	# === БУХАТЬ С БАНДОЙ ===
	y_pos += 20
	var party_title = Label.new()
	party_title.text = "═══ БУХАТЬ С БАНДОЙ ═══"
	party_title.position = Vector2(220, y_pos)
	party_title.add_theme_font_size_override("font_size", 22)
	party_title.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3, 1.0))
	bar_menu.add_child(party_title)
	y_pos += 50
	
	var party_desc = Label.new()
	party_desc.text = "Вложи деньги в веселье - подними мораль и характеристики банды!"
	party_desc.position = Vector2(80, y_pos)
	party_desc.add_theme_font_size_override("font_size", 14)
	party_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	bar_menu.add_child(party_desc)
	y_pos += 40
	
	# Активные члены банды
	var active_count = 0
	for member in gang_members:
		if member.get("is_active", false):
			active_count += 1
	
	if active_count < 2:
		var no_gang_label = Label.new()
		no_gang_label.text = "⚠️ Нужна активная банда для веселья!"
		no_gang_label.position = Vector2(180, y_pos + 20)
		no_gang_label.add_theme_font_size_override("font_size", 18)
		no_gang_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3, 1.0))
		bar_menu.add_child(no_gang_label)
	else:
		var party_btn = Button.new()
		party_btn.custom_minimum_size = Vector2(660, 60)
		party_btn.position = Vector2(30, y_pos)
		party_btn.text = "🍻 БУХАТЬ С БАНДОЙ"
		
		var style_party = StyleBoxFlat.new()
		style_party.bg_color = Color(0.6, 0.3, 0.2, 1.0)
		party_btn.add_theme_stylebox_override("normal", style_party)
		
		party_btn.add_theme_font_size_override("font_size", 22)
		party_btn.pressed.connect(func():
			bar_menu.queue_free()
			show_party_menu(main_node, player_data, gang_members)
		)
		bar_menu.add_child(party_btn)
	
	y_pos += 100
	
	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(680, 50)
	close_btn.position = Vector2(20, 1100)
	close_btn.text = "УЙТИ"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func():
		bar_menu.queue_free()
		main_node.show_location_menu("БАР")
	)
	bar_menu.add_child(close_btn)

# Отдых в баре
func rest_at_bar(main_node: Node, player_data: Dictionary, option: Dictionary, bar_menu: CanvasLayer):
	if player_data["balance"] < option["cost"]:
		main_node.show_message("❌ Недостаточно денег!")
		return
	
	# Списываем деньги
	player_data["balance"] -= option["cost"]
	
	# Восстанавливаем HP
	var old_hp = player_data["health"]
	player_data["health"] = min(100, player_data["health"] + option["hp"])
	var restored = player_data["health"] - old_hp
	
	# Добавляем время
	if time_system:
		time_system.add_hours(option["hours"])
	
	main_node.show_message("😴 Вы отдохнули %d часов\n❤️ +%d HP" % [option["hours"], restored])
	main_node.update_ui()
	
	rest_completed.emit()
	
	# Обновляем меню
	bar_menu.queue_free()
	await main_node.get_tree().create_timer(0.5).timeout
	var gang_members = main_node.gang_members if "gang_members" in main_node else []
	show_bar_menu(main_node, player_data, gang_members)

# Меню веселья с ползунком
func show_party_menu(main_node: Node, player_data: Dictionary, gang_members: Array):
	var party_menu = CanvasLayer.new()
	party_menu.layer = 110
	party_menu.name = "PartyMenu"
	main_node.add_child(party_menu)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	party_menu.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(680, 800)
	bg.position = Vector2(20, 240)
	bg.color = Color(0.15, 0.1, 0.05, 0.98)
	party_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "🍻 ВЕСЕЛЬЕ С БАНДОЙ"
	title.position = Vector2(200, 270)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3, 1.0))
	party_menu.add_child(title)
	
	var desc = Label.new()
	desc.text = "Сколько хочешь вложить в веселье?"
	desc.position = Vector2(200, 330)
	desc.add_theme_font_size_override("font_size", 18)
	desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	party_menu.add_child(desc)
	
	var balance_label = Label.new()
	balance_label.text = "💰 Баланс: %d руб." % player_data["balance"]
	balance_label.position = Vector2(260, 380)
	balance_label.add_theme_font_size_override("font_size", 20)
	balance_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	party_menu.add_child(balance_label)
	
	# Ползунок
	var slider_value = {"amount": 0}
	
	var slider_bg = ColorRect.new()
	slider_bg.size = Vector2(620, 60)
	slider_bg.position = Vector2(50, 450)
	slider_bg.color = Color(0.2, 0.2, 0.2, 1.0)
	party_menu.add_child(slider_bg)
	
	var slider = HSlider.new()
	slider.custom_minimum_size = Vector2(600, 40)
	slider.position = Vector2(60, 460)
	slider.min_value = 0
	slider.max_value = player_data["balance"]
	slider.step = 10
	slider.value = 0
	party_menu.add_child(slider)
	
	var amount_label = Label.new()
	amount_label.text = "Сумма: 0 руб."
	amount_label.position = Vector2(280, 530)
	amount_label.add_theme_font_size_override("font_size", 24)
	amount_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	amount_label.name = "AmountLabel"
	party_menu.add_child(amount_label)
	
	slider.value_changed.connect(func(value):
		slider_value["amount"] = int(value)
		amount_label.text = "Сумма: %d руб." % int(value)
	)
	
	# Эффекты
	var effects_label = Label.new()
	effects_label.text = "🎉 Эффекты:\n• Мораль: +0\n• Здоровье: +0\n• Опыт: случайно"
	effects_label.position = Vector2(200, 590)
	effects_label.add_theme_font_size_override("font_size", 18)
	effects_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5, 1.0))
	effects_label.name = "EffectsLabel"
	party_menu.add_child(effects_label)
	
	slider.value_changed.connect(func(value):
		var morale_boost = int(value / 50)
		var hp_boost = int(value / 100)
		effects_label.text = "🎉 Эффекты:\n• Мораль: +%d\n• Здоровье: +%d\n• Опыт: случайно" % [morale_boost, hp_boost]
	)
	
	# Кнопка БУХАТЬ
	var party_btn = Button.new()
	party_btn.custom_minimum_size = Vector2(300, 70)
	party_btn.position = Vector2(210, 750)
	party_btn.text = "🍺 БУХАТЬ!"
	
	var style_party = StyleBoxFlat.new()
	style_party.bg_color = Color(0.7, 0.3, 0.2, 1.0)
	party_btn.add_theme_stylebox_override("normal", style_party)
	
	var style_party_hover = StyleBoxFlat.new()
	style_party_hover.bg_color = Color(0.8, 0.4, 0.3, 1.0)
	party_btn.add_theme_stylebox_override("hover", style_party_hover)
	
	party_btn.add_theme_font_size_override("font_size", 26)
	party_btn.pressed.connect(func():
		start_party(main_node, player_data, gang_members, slider_value["amount"], party_menu)
	)
	party_menu.add_child(party_btn)
	
	# Кнопка ОТМЕНА
	var cancel_btn = Button.new()
	cancel_btn.custom_minimum_size = Vector2(640, 50)
	cancel_btn.position = Vector2(40, 960)
	cancel_btn.text = "ОТМЕНА"
	
	var style_cancel = StyleBoxFlat.new()
	style_cancel.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	cancel_btn.add_theme_stylebox_override("normal", style_cancel)
	
	cancel_btn.add_theme_font_size_override("font_size", 20)
	cancel_btn.pressed.connect(func():
		party_menu.queue_free()
		show_bar_menu(main_node, player_data, gang_members)
	)
	party_menu.add_child(cancel_btn)

# Начать веселье
func start_party(main_node: Node, player_data: Dictionary, gang_members: Array, amount: int, party_menu: CanvasLayer):
	if amount < 50:
		main_node.show_message("⚠️ Минимум 50 руб. для веселья!")
		return
	
	if player_data["balance"] < amount:
		main_node.show_message("❌ Недостаточно денег!")
		return
	
	# Списываем деньги
	player_data["balance"] -= amount
	
	# Эффекты
	var morale_boost = int(amount / 50)
	var hp_boost = int(amount / 100)
	
	# Повышаем мораль и HP всей активной банде
	for member in gang_members:
		if member.get("is_active", false):
			if member.has("morale"):
				member["morale"] = min(100, member.get("morale", 80) + morale_boost)
			if member.has("hp"):
				member["hp"] = min(member.get("max_hp", 100), member["hp"] + hp_boost)
	
	# Главный игрок
	player_data["health"] = min(100, player_data["health"] + hp_boost)
	
	# Случайный опыт случайного навыка для случайного члена банды
	if player_stats and gang_members.size() > 0:
		var stats = ["STR", "AGI"]
		var random_stat = stats[randi() % stats.size()]
		var exp_gain = int(amount / 20)
		player_stats.add_stat_xp(random_stat, exp_gain)
		
		var result_text = "🍻 ОТЛИЧНО ПОБУХАЛИ!\n\n"
		result_text += "💰 Потрачено: %d руб.\n" % amount
		result_text += "❤️ Здоровье: +%d HP\n" % hp_boost
		result_text += "💪 Мораль: +%d\n" % morale_boost
		result_text += "📈 %s: +%d опыта" % [random_stat, exp_gain]
		
		main_node.show_message(result_text)
	
	# Добавляем время
	if time_system:
		time_system.add_hours(randi_range(2, 4))
	
	main_node.update_ui()
	party_completed.emit()
	
	party_menu.queue_free()
	await main_node.get_tree().create_timer(1.0).timeout
	show_bar_menu(main_node, player_data, gang_members)
