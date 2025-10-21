# scripts/battle/battle_ui_full.gd
# UI с аватарками, HP барами, выбором зон, логом
extends Node

signal action_requested(action_type: String, target: int, zone: String)

var battle_log_lines: Array = []
var max_log_lines: int = 12
var ui_root: CanvasLayer

func setup(is_first_battle: bool):
	ui_root = get_parent()
	create_ui(is_first_battle)

# ===== СОЗДАНИЕ UI =====
func create_ui(first_battle: bool):
	# Фон
	var bg = ColorRect.new()
	bg.size = Vector2(700, 900)
	bg.position = Vector2(10, 190)
	bg.color = Color(0.1, 0.05, 0.05, 0.95)
	bg.name = "BattleBG"
	ui_root.add_child(bg)
	
	# Заголовок
	var title = Label.new()
	title.text = "⚔️ БОЙ"
	title.position = Vector2(320, 210)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	ui_root.add_child(title)
	
	# Зона аватарок (будет заполнена в avatar_manager)
	var avatars_container = Control.new()
	avatars_container.name = "AvatarsContainer"
	avatars_container.position = Vector2(20, 250)
	avatars_container.custom_minimum_size = Vector2(680, 200)
	ui_root.add_child(avatars_container)
	
	# Лог боя
	create_battle_log()
	
	# Кнопки управления
	create_control_buttons(first_battle)

func create_battle_log():
	var log_bg = ColorRect.new()
	log_bg.size = Vector2(660, 220)
	log_bg.position = Vector2(30, 470)
	log_bg.color = Color(0.05, 0.05, 0.05, 1.0)
	log_bg.name = "LogBG"
	ui_root.add_child(log_bg)
	
	var log_scroll = ScrollContainer.new()
	log_scroll.custom_minimum_size = Vector2(660, 220)
	log_scroll.position = Vector2(30, 470)
	log_scroll.name = "LogScroll"
	log_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui_root.add_child(log_scroll)
	
	var log_vbox = VBoxContainer.new()
	log_vbox.name = "LogVBox"
	log_vbox.custom_minimum_size = Vector2(640, 0)
	log_scroll.add_child(log_vbox)

func create_control_buttons(first_battle: bool):
	# Атака
	var attack_btn = Button.new()
	attack_btn.custom_minimum_size = Vector2(150, 55)
	attack_btn.position = Vector2(30, 710)
	attack_btn.text = "⚔️ АТАКА"
	attack_btn.name = "AttackBtn"
	
	var style_attack = StyleBoxFlat.new()
	style_attack.bg_color = Color(0.7, 0.2, 0.2, 1.0)
	attack_btn.add_theme_stylebox_override("normal", style_attack)
	attack_btn.add_theme_font_size_override("font_size", 20)
	attack_btn.pressed.connect(func(): show_target_selection())
	ui_root.add_child(attack_btn)
	
	# Защита
	var defend_btn = Button.new()
	defend_btn.custom_minimum_size = Vector2(150, 55)
	defend_btn.position = Vector2(195, 710)
	defend_btn.text = "🛡️ ЗАЩИТА"
	defend_btn.name = "DefendBtn"
	
	var style_defend = StyleBoxFlat.new()
	style_defend.bg_color = Color(0.2, 0.4, 0.7, 1.0)
	defend_btn.add_theme_stylebox_override("normal", style_defend)
	defend_btn.add_theme_font_size_override("font_size", 20)
	defend_btn.pressed.connect(func(): action_requested.emit("defend", -1, ""))
	ui_root.add_child(defend_btn)
	
	# Предметы
	var items_btn = Button.new()
	items_btn.custom_minimum_size = Vector2(150, 55)
	items_btn.position = Vector2(360, 710)
	items_btn.text = "🎒 ПРЕДМЕТ"
	items_btn.name = "ItemsBtn"
	
	var style_items = StyleBoxFlat.new()
	style_items.bg_color = Color(0.3, 0.5, 0.3, 1.0)
	items_btn.add_theme_stylebox_override("normal", style_items)
	items_btn.add_theme_font_size_override("font_size", 20)
	items_btn.pressed.connect(func(): show_items_menu())
	ui_root.add_child(items_btn)
	
	# Бежать
	var run_btn = Button.new()
	run_btn.custom_minimum_size = Vector2(150, 55)
	run_btn.position = Vector2(525, 710)
	run_btn.text = "🏃 БЕЖАТЬ"
	run_btn.name = "RunBtn"
	run_btn.disabled = first_battle
	
	var style_run = StyleBoxFlat.new()
	style_run.bg_color = Color(0.5, 0.5, 0.2, 1.0)
	run_btn.add_theme_stylebox_override("normal", style_run)
	run_btn.add_theme_font_size_override("font_size", 20)
	run_btn.pressed.connect(func(): action_requested.emit("run", -1, ""))
	ui_root.add_child(run_btn)
	
	# Инфо
	var info_label = Label.new()
	info_label.text = "Ваш ход"
	info_label.position = Vector2(300, 780)
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	info_label.name = "TurnInfo"
	ui_root.add_child(info_label)

# ===== ВЫБОР ЦЕЛИ =====
func show_target_selection():
	var battle = get_parent()
	var enemies = battle.logic_manager.get_enemies()
	
	if enemies.size() == 0:
		return
	
	var selection = CanvasLayer.new()
	selection.name = "TargetSelection"
	selection.layer = 210
	ui_root.add_child(selection)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	selection.add_child(overlay)
	
	var menu_bg = ColorRect.new()
	menu_bg.size = Vector2(600, 500)
	menu_bg.position = Vector2(60, 390)
	menu_bg.color = Color(0.1, 0.05, 0.05, 0.98)
	selection.add_child(menu_bg)
	
	var title = Label.new()
	title.text = "🎯 ВЫБЕРИ ЦЕЛЬ И ЗОНУ"
	title.position = Vector2(200, 410)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	selection.add_child(title)
	
	# ✅ Подсказка о последней цели
	var last = battle.get_last_target()
	var hint = Label.new()
	hint.text = "Последняя: %s → %s" % [enemies[last["target"]]["name"], last["zone"]]
	hint.position = Vector2(220, 450)
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	selection.add_child(hint)
	
	# ✅ Кнопка "Повторить последнюю атаку"
	var quick_attack = Button.new()
	quick_attack.custom_minimum_size = Vector2(560, 50)
	quick_attack.position = Vector2(80, 480)
	quick_attack.text = "⚡ ПОВТОРИТЬ: %s → %s" % [enemies[last["target"]]["name"], last["zone"]]
	
	var style_quick = StyleBoxFlat.new()
	style_quick.bg_color = Color(0.6, 0.3, 0.2, 1.0)
	quick_attack.add_theme_stylebox_override("normal", style_quick)
	quick_attack.add_theme_font_size_override("font_size", 18)
	
	quick_attack.pressed.connect(func():
		action_requested.emit("attack", last["target"], last["zone"])
		selection.queue_free()
	)
	selection.add_child(quick_attack)
	
	var y_pos = 550
	
	# Список врагов
	for i in range(enemies.size()):
		var enemy = enemies[i]
		
		var enemy_btn = Button.new()
		enemy_btn.custom_minimum_size = Vector2(560, 60)
		enemy_btn.position = Vector2(80, y_pos)
		enemy_btn.text = "%s (HP: %d/%d)" % [enemy["name"], enemy["health"], enemy["max_health"]]
		
		var style_normal = StyleBoxFlat.new()
		if i == last["target"]:
			style_normal.bg_color = Color(0.5, 0.3, 0.2, 1.0)  # Подсветка последней цели
		else:
			style_normal.bg_color = Color(0.3, 0.2, 0.2, 1.0)
		enemy_btn.add_theme_stylebox_override("normal", style_normal)
		
		enemy_btn.add_theme_font_size_override("font_size", 20)
		
		var idx = i
		enemy_btn.pressed.connect(func():
			show_zone_selection(idx, selection)
		)
		
		selection.add_child(enemy_btn)
		y_pos += 70
	
	# Отмена
	var cancel = Button.new()
	cancel.custom_minimum_size = Vector2(560, 50)
	cancel.position = Vector2(80, y_pos + 10)
	cancel.text = "❌ ОТМЕНА"
	
	var style_cancel = StyleBoxFlat.new()
	style_cancel.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	cancel.add_theme_stylebox_override("normal", style_cancel)
	cancel.add_theme_font_size_override("font_size", 18)
	cancel.pressed.connect(func(): selection.queue_free())
	selection.add_child(cancel)

# ===== ВЫБОР ЗОНЫ ПОПАДАНИЯ =====
func show_zone_selection(target_idx: int, parent_menu):
	parent_menu.queue_free()
	
	var zone_menu = CanvasLayer.new()
	zone_menu.name = "ZoneSelection"
	zone_menu.layer = 210
	ui_root.add_child(zone_menu)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	zone_menu.add_child(overlay)
	
	var menu_bg = ColorRect.new()
	menu_bg.size = Vector2(600, 550)
	menu_bg.position = Vector2(60, 365)
	menu_bg.color = Color(0.1, 0.05, 0.05, 0.98)
	zone_menu.add_child(menu_bg)
	
	var title = Label.new()
	title.text = "🎯 ВЫБЕРИ ЗОНУ"
	title.position = Vector2(240, 385)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	zone_menu.add_child(title)
	
	var zones = [
		{"name": "голова", "desc": "× 3 урона, крит, кровотечение", "color": Color(1.0, 0.2, 0.2, 1.0)},
		{"name": "торс", "desc": "× 1 урона, базовый", "color": Color(0.8, 0.6, 0.3, 1.0)},
		{"name": "руки", "desc": "× 0.5 урона, выбить оружие", "color": Color(0.6, 0.7, 0.9, 1.0)},
		{"name": "ноги", "desc": "× 0.75 урона, потеря скорости", "color": Color(0.5, 0.8, 0.5, 1.0)}
	]
	
	var y_pos = 450
	
	for zone in zones:
		var zone_btn = Button.new()
		zone_btn.custom_minimum_size = Vector2(560, 80)
		zone_btn.position = Vector2(80, y_pos)
		
		var style_zone = StyleBoxFlat.new()
		style_zone.bg_color = zone["color"] * 0.4
		zone_btn.add_theme_stylebox_override("normal", style_zone)
		
		var style_zone_hover = StyleBoxFlat.new()
		style_zone_hover.bg_color = zone["color"] * 0.6
		zone_btn.add_theme_stylebox_override("hover", style_zone_hover)
		
		zone_btn.add_theme_font_size_override("font_size", 22)
		
		var zone_label = Label.new()
		zone_label.text = zone["name"].to_upper()
		zone_label.position = Vector2(10, 10)
		zone_label.add_theme_font_size_override("font_size", 24)
		zone_label.add_theme_color_override("font_color", Color.WHITE)
		zone_btn.add_child(zone_label)
		
		var desc_label = Label.new()
		desc_label.text = zone["desc"]
		desc_label.position = Vector2(10, 45)
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
		zone_btn.add_child(desc_label)
		
		var zone_name = zone["name"]
		zone_btn.pressed.connect(func():
			action_requested.emit("attack", target_idx, zone_name)
			zone_menu.queue_free()
		)
		
		zone_menu.add_child(zone_btn)
		y_pos += 95
	
	# Назад
	var back = Button.new()
	back.custom_minimum_size = Vector2(560, 50)
	back.position = Vector2(80, 845)
	back.text = "← НАЗАД"
	
	var style_back = StyleBoxFlat.new()
	style_back.bg_color = Color(0.4, 0.4, 0.1, 1.0)
	back.add_theme_stylebox_override("normal", style_back)
	back.add_theme_font_size_override("font_size", 18)
	back.pressed.connect(func():
		zone_menu.queue_free()
		show_target_selection()
	)
	zone_menu.add_child(back)

# ===== ПРЕДМЕТЫ =====
func show_items_menu():
	var battle = get_parent()
	var pockets = battle.player_data.get("pockets", [null, null, null])
	
	var items_menu = CanvasLayer.new()
	items_menu.name = "ItemsMenu"
	items_menu.layer = 210
	ui_root.add_child(items_menu)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	items_menu.add_child(overlay)
	
	var menu_bg = ColorRect.new()
	menu_bg.size = Vector2(500, 400)
	menu_bg.position = Vector2(110, 440)
	menu_bg.color = Color(0.1, 0.1, 0.05, 0.98)
	items_menu.add_child(menu_bg)
	
	var title = Label.new()
	title.text = "🎒 ПРЕДМЕТЫ (КАРМАНЫ)"
	title.position = Vector2(200, 460)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	items_menu.add_child(title)
	
	var y_pos = 520
	var has_items = false
	
	for i in range(pockets.size()):
		var item = pockets[i]
		if item:
			has_items = true
			var item_btn = Button.new()
			item_btn.custom_minimum_size = Vector2(460, 60)
			item_btn.position = Vector2(130, y_pos)
			item_btn.text = "Карман %d: %s" % [i + 1, item]
			
			var style_item = StyleBoxFlat.new()
			style_item.bg_color = Color(0.2, 0.4, 0.2, 1.0)
			item_btn.add_theme_stylebox_override("normal", style_item)
			item_btn.add_theme_font_size_override("font_size", 18)
			
			var pocket_idx = i
			item_btn.pressed.connect(func():
				action_requested.emit("use_item", pocket_idx, "")
				items_menu.queue_free()
			)
			items_menu.add_child(item_btn)
			y_pos += 70
	
	if not has_items:
		var empty = Label.new()
		empty.text = "Карманы пусты"
		empty.position = Vector2(260, 580)
		empty.add_theme_font_size_override("font_size", 16)
		empty.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
		items_menu.add_child(empty)
	
	# Закрыть
	var close = Button.new()
	close.custom_minimum_size = Vector2(460, 50)
	close.position = Vector2(130, 780)
	close.text = "ЗАКРЫТЬ"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close.add_theme_stylebox_override("normal", style_close)
	close.add_theme_font_size_override("font_size", 18)
	close.pressed.connect(func(): items_menu.queue_free())
	items_menu.add_child(close)

# ===== ЛОГ =====
func add_log(text: String):
	battle_log_lines.insert(0, text)
	if battle_log_lines.size() > 50:
		battle_log_lines.resize(50)
	update_log_display()

func update_log_display():
	var log_scroll = ui_root.get_node_or_null("LogScroll")
	if not log_scroll:
		return
	var log_vbox = log_scroll.get_node_or_null("LogVBox")
	if not log_vbox:
		return
	
	for child in log_vbox.get_children():
		child.queue_free()
	
	for i in range(min(max_log_lines, battle_log_lines.size())):
		var log_line = Label.new()
		log_line.text = battle_log_lines[i]
		log_line.add_theme_font_size_override("font_size", 15)
		log_line.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
		log_line.autowrap_mode = TextServer.AUTOWRAP_WORD
		log_line.custom_minimum_size = Vector2(620, 0)
		log_vbox.add_child(log_line)

# ===== УПРАВЛЕНИЕ =====
func set_turn_info(text: String, buttons_enabled: bool):
	var info = ui_root.get_node_or_null("TurnInfo")
	if info:
		info.text = text
	
	var buttons = ["AttackBtn", "DefendBtn", "ItemsBtn", "RunBtn"]
	for btn_name in buttons:
		var btn = ui_root
