# scripts/battle/battle_ui.gd
extends Node

signal action_requested(action_type: String, target_index: int)

var battle_log_lines: Array = []
var max_log_lines: int = 15
var selected_enemy_index: int = 0

var ui_root: CanvasLayer

func setup(battle_state: Dictionary, is_first_battle: bool):
	ui_root = get_parent()
	create_ui(battle_state, is_first_battle)

# ===== СОЗДАНИЕ UI =====
func create_ui(state: Dictionary, first_battle: bool):
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
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	ui_root.add_child(title)
	
	# HP панели
	create_hp_panels()
	
	# Лог боя
	create_battle_log()
	
	# Кнопки управления
	create_control_buttons(first_battle)

func create_hp_panels():
	# HP игрока
	var player_label = Label.new()
	player_label.text = "ВЫ"
	player_label.position = Vector2(50, 280)
	player_label.add_theme_font_size_override("font_size", 24)
	player_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	ui_root.add_child(player_label)
	
	var player_hp_bar = ColorRect.new()
	player_hp_bar.size = Vector2(300, 30)
	player_hp_bar.position = Vector2(50, 320)
	player_hp_bar.color = Color(0.2, 0.2, 0.2, 1.0)
	player_hp_bar.name = "PlayerHPBG"
	ui_root.add_child(player_hp_bar)
	
	var player_hp_fill = ColorRect.new()
	player_hp_fill.size = Vector2(300, 30)
	player_hp_fill.position = Vector2(50, 320)
	player_hp_fill.color = Color(0.3, 1.0, 0.3, 1.0)
	player_hp_fill.name = "PlayerHPFill"
	ui_root.add_child(player_hp_fill)
	
	var player_hp_text = Label.new()
	player_hp_text.text = "HP: 100/100"
	player_hp_text.position = Vector2(150, 325)
	player_hp_text.add_theme_font_size_override("font_size", 18)
	player_hp_text.add_theme_color_override("font_color", Color.BLACK)
	player_hp_text.name = "PlayerHPText"
	ui_root.add_child(player_hp_text)
	
	# HP врагов (создаётся динамически)

func create_battle_log():
	var log_scroll = ScrollContainer.new()
	log_scroll.custom_minimum_size = Vector2(660, 250)
	log_scroll.position = Vector2(30, 380)
	log_scroll.name = "LogScroll"
	log_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui_root.add_child(log_scroll)
	
	var log_bg = ColorRect.new()
	log_bg.size = Vector2(660, 250)
	log_bg.position = Vector2(30, 380)
	log_bg.color = Color(0.05, 0.05, 0.05, 1.0)
	log_bg.z_index = -1
	ui_root.add_child(log_bg)
	
	var log_vbox = VBoxContainer.new()
	log_vbox.name = "LogVBox"
	log_vbox.custom_minimum_size = Vector2(640, 0)
	log_scroll.add_child(log_vbox)

func create_control_buttons(first_battle: bool):
	# Атака
	var attack_btn = Button.new()
	attack_btn.custom_minimum_size = Vector2(200, 60)
	attack_btn.position = Vector2(40, 670)
	attack_btn.text = "⚔️ АТАКА"
	attack_btn.name = "AttackBtn"
	
	var style_attack = StyleBoxFlat.new()
	style_attack.bg_color = Color(0.7, 0.2, 0.2, 1.0)
	attack_btn.add_theme_stylebox_override("normal", style_attack)
	attack_btn.add_theme_font_size_override("font_size", 22)
	attack_btn.pressed.connect(func(): show_enemy_selection())
	ui_root.add_child(attack_btn)
	
	# Защита
	var defend_btn = Button.new()
	defend_btn.custom_minimum_size = Vector2(200, 60)
	defend_btn.position = Vector2(260, 670)
	defend_btn.text = "🛡️ ЗАЩИТА"
	defend_btn.name = "DefendBtn"
	
	var style_defend = StyleBoxFlat.new()
	style_defend.bg_color = Color(0.2, 0.4, 0.7, 1.0)
	defend_btn.add_theme_stylebox_override("normal", style_defend)
	defend_btn.add_theme_font_size_override("font_size", 22)
	defend_btn.pressed.connect(func(): action_requested.emit("defend", -1))
	ui_root.add_child(defend_btn)
	
	# Бежать
	var run_btn = Button.new()
	run_btn.custom_minimum_size = Vector2(200, 60)
	run_btn.position = Vector2(480, 670)
	run_btn.text = "🏃 БЕЖАТЬ"
	run_btn.name = "RunBtn"
	run_btn.disabled = first_battle
	
	var style_run = StyleBoxFlat.new()
	style_run.bg_color = Color(0.5, 0.5, 0.2, 1.0)
	run_btn.add_theme_stylebox_override("normal", style_run)
	run_btn.add_theme_font_size_override("font_size", 22)
	run_btn.pressed.connect(func(): action_requested.emit("run", -1))
	ui_root.add_child(run_btn)
	
	# Инфо о ходе
	var info_label = Label.new()
	info_label.text = "Ваш ход"
	info_label.position = Vector2(300, 760)
	info_label.add_theme_font_size_override("font_size", 20)
	info_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	info_label.name = "TurnInfo"
	ui_root.add_child(info_label)

# ===== ВЫБОР ВРАГА =====
func show_enemy_selection():
	var state = get_parent().logic_manager.get_battle_state()
	var enemies = state["enemies"]
	
	if enemies.size() == 0:
		return
	
	# Если враг один - бьём сразу
	if enemies.size() == 1:
		action_requested.emit("attack", 0)
		return
	
	# Создаём окно выбора
	var selection_layer = CanvasLayer.new()
	selection_layer.name = "EnemySelection"
	selection_layer.layer = 210
	ui_root.add_child(selection_layer)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	selection_layer.add_child(overlay)
	
	var menu_bg = ColorRect.new()
	menu_bg.size = Vector2(500, 400)
	menu_bg.position = Vector2(110, 440)
	menu_bg.color = Color(0.1, 0.05, 0.05, 0.98)
	selection_layer.add_child(menu_bg)
	
	var title = Label.new()
	title.text = "🎯 ВЫБЕРИ ЦЕЛЬ"
	title.position = Vector2(260, 460)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	selection_layer.add_child(title)
	
	var hint = Label.new()
	hint.text = "Последняя цель: " + enemies[selected_enemy_index]["name"]
	hint.position = Vector2(200, 500)
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	selection_layer.add_child(hint)
	
	var y_pos = 540
	
	for i in range(enemies.size()):
		var enemy = enemies[i]
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(460, 60)
		btn.position = Vector2(130, y_pos)
		btn.text = "%s (HP: %d/%d)" % [enemy["name"], enemy["hp"], enemy["max_hp"]]
		
		var style_normal = StyleBoxFlat.new()
		if i == selected_enemy_index:
			style_normal.bg_color = Color(0.5, 0.3, 0.2, 1.0)  # Выделяем последнюю цель
		else:
			style_normal.bg_color = Color(0.3, 0.2, 0.2, 1.0)
		btn.add_theme_stylebox_override("normal", style_normal)
		
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.4, 0.3, 0.3, 1.0)
		btn.add_theme_stylebox_override("hover", style_hover)
		
		btn.add_theme_font_size_override("font_size", 20)
		
		var idx = i
		btn.pressed.connect(func():
			selected_enemy_index = idx  # ✅ Запоминаем выбор!
			action_requested.emit("attack", idx)
			selection_layer.queue_free()
		)
		
		selection_layer.add_child(btn)
		y_pos += 70
	
	# Кнопка атаки последней цели
	var quick_attack = Button.new()
	quick_attack.custom_minimum_size = Vector2(460, 50)
	quick_attack.position = Vector2(130, y_pos + 10)
	quick_attack.text = "⚡ АТАКОВАТЬ ПОСЛЕДНЮЮ ЦЕЛЬ"
	
	var style_quick = StyleBoxFlat.new()
	style_quick.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	quick_attack.add_theme_stylebox_override("normal", style_quick)
	
	quick_attack.add_theme_font_size_override("font_size", 18)
	quick_attack.pressed.connect(func():
		action_requested.emit("attack", selected_enemy_index)
		selection_layer.queue_free()
	)
	selection_layer.add_child(quick_attack)

# ===== ОБНОВЛЕНИЕ ДИСПЛЕЯ =====
func update_display(state: Dictionary):
	# HP игрока
	var player_hp_fill = ui_root.get_node_or_null("PlayerHPFill")
	if player_hp_fill:
		var hp_percent = float(state["player_hp"]) / float(state["player_max_hp"])
		player_hp_fill.size.x = 300 * hp_percent
	
	var player_hp_text = ui_root.get_node_or_null("PlayerHPText")
	if player_hp_text:
		player_hp_text.text = "HP: %d/%d" % [state["player_hp"], state["player_max_hp"]]
	
	# Обновляем HP врагов (если нужно)

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
		log_line.add_theme_font_size_override("font_size", 16)
		log_line.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
		log_line.autowrap_mode = TextServer.AUTOWRAP_WORD
		log_line.custom_minimum_size = Vector2(620, 0)
		log_vbox.add_child(log_line)

# ===== УПРАВЛЕНИЕ КНОПКАМИ =====
func lock_buttons():
	var attack_btn = ui_root.get_node_or_null("AttackBtn")
	var defend_btn = ui_root.get_node_or_null("DefendBtn")
	var run_btn = ui_root.get_node_or_null("RunBtn")
	
	if attack_btn:
		attack_btn.disabled = true
	if defend_btn:
		defend_btn.disabled = true
	if run_btn:
		run_btn.disabled = true

func unlock_buttons():
	var attack_btn = ui_root.get_node_or_null("AttackBtn")
	var defend_btn = ui_root.get_node_or_null("DefendBtn")
	var run_btn = ui_root.get_node_or_null("RunBtn")
	
	if attack_btn:
		attack_btn.disabled = false
	if defend_btn:
		defend_btn.disabled = false
	if run_btn and not get_parent().is_first_battle:
		run_btn.disabled = false

func set_turn_info(text: String):
	var info = ui_root.get_node_or_null("TurnInfo")
	if info:
		info.text = text
