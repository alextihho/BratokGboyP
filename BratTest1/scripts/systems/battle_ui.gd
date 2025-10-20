# battle_ui.gd (модуль UI боя)
extends Node

func create_ui(battle):
	var bg = ColorRect.new()
	bg.size = Vector2(700, 900)
	bg.position = Vector2(10, 190)
	bg.color = Color(0.1, 0.05, 0.05, 0.95)
	bg.name = "BattleBG"
	battle.add_child(bg)
	
	var title = Label.new()
	title.text = "⚔️ МАССОВЫЙ БОЙ"
	title.position = Vector2(280, 210)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	battle.add_child(title)
	
	var player_title = Label.new()
	player_title.text = "ВАША КОМАНДА:"
	player_title.position = Vector2(50, 260)
	player_title.add_theme_font_size_override("font_size", 20)
	player_title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	battle.add_child(player_title)
	
	var enemy_title = Label.new()
	enemy_title.text = "ПРОТИВНИКИ:"
	enemy_title.position = Vector2(400, 260)
	enemy_title.add_theme_font_size_override("font_size", 20)
	enemy_title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	battle.add_child(enemy_title)
	
	var log_scroll = ScrollContainer.new()
	log_scroll.custom_minimum_size = Vector2(660, 200)
	log_scroll.position = Vector2(30, 500)
	log_scroll.name = "LogScroll"
	log_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	battle.add_child(log_scroll)
	
	var log_bg = ColorRect.new()
	log_bg.size = Vector2(660, 200)
	log_bg.position = Vector2(30, 500)
	log_bg.color = Color(0.05, 0.05, 0.05, 1.0)
	log_bg.z_index = -1
	battle.add_child(log_bg)
	
	var log_vbox = VBoxContainer.new()
	log_vbox.name = "LogVBox"
	log_vbox.custom_minimum_size = Vector2(640, 0)
	log_scroll.add_child(log_vbox)
	
	var attack_btn = Button.new()
	attack_btn.custom_minimum_size = Vector2(200, 60)
	attack_btn.position = Vector2(40, 730)
	attack_btn.text = "⚔️ АТАКА"
	attack_btn.name = "AttackBtn"
	
	var style_attack = StyleBoxFlat.new()
	style_attack.bg_color = Color(0.7, 0.2, 0.2, 1.0)
	attack_btn.add_theme_stylebox_override("normal", style_attack)
	attack_btn.add_theme_font_size_override("font_size", 22)
	attack_btn.pressed.connect(func(): battle.on_attack())
	battle.add_child(attack_btn)
	
	var defend_btn = Button.new()
	defend_btn.custom_minimum_size = Vector2(200, 60)
	defend_btn.position = Vector2(260, 730)
	defend_btn.text = "🛡️ ЗАЩИТА"
	defend_btn.name = "DefendBtn"
	
	var style_defend = StyleBoxFlat.new()
	style_defend.bg_color = Color(0.2, 0.4, 0.7, 1.0)
	defend_btn.add_theme_stylebox_override("normal", style_defend)
	defend_btn.add_theme_font_size_override("font_size", 22)
	defend_btn.pressed.connect(func(): battle.on_defend())
	battle.add_child(defend_btn)
	
	var run_btn = Button.new()
	run_btn.custom_minimum_size = Vector2(200, 60)
	run_btn.position = Vector2(480, 730)
	run_btn.text = "🏃 БЕЖАТЬ"
	run_btn.name = "RunBtn"
	
	var style_run = StyleBoxFlat.new()
	style_run.bg_color = Color(0.5, 0.5, 0.2, 1.0)
	run_btn.add_theme_stylebox_override("normal", style_run)
	run_btn.add_theme_font_size_override("font_size", 22)
	run_btn.pressed.connect(func(): battle.on_run())
	battle.add_child(run_btn)
	
	var info_label = Label.new()
	info_label.text = "Выберите действие"
	info_label.position = Vector2(280, 820)
	info_label.add_theme_font_size_override("font_size", 20)
	info_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	info_label.name = "TurnInfo"
	battle.add_child(info_label)

func update_fighters(battle, player_team, enemy_team, current_attacker, current_target, current_turn):
	# Очищаем старые отображения
	for child in battle.get_children():
		if child is Control or child is ColorRect or child is Label:
			if child.name.begins_with("PlayerFighter_") or child.name.begins_with("EnemyFighter_"):
				child.queue_free()
	
	# Отображаем команду игрока
	var player_y = 300
	for i in range(player_team.size()):
		var fighter = player_team[i]
		create_fighter_card(battle, fighter, "player", i, player_y, current_attacker, current_turn)
		player_y += 50
	
	# Отображаем команду врага
	var enemy_y = 300
	for i in range(enemy_team.size()):
		var fighter = enemy_team[i]
		create_fighter_card(battle, fighter, "enemy", i, enemy_y, current_target, current_turn)
		
		# Кнопка для выбора цели
		if current_turn == "player" and battle.awaiting_target_selection:
			var target_btn = Button.new()
			target_btn.size = Vector2(250, 40)
			target_btn.position = Vector2(400, enemy_y)
			target_btn.modulate = Color(1, 1, 1, 0.01)
			target_btn.name = "EnemyFighter_TargetBtn_" + str(i)
			
			var target_idx = i
			target_btn.pressed.connect(func(): battle.select_target(target_idx))
			battle.add_child(target_btn)
		
		enemy_y += 50

func create_fighter_card(battle, fighter, team, index, y_pos, highlight_index, current_turn):
	var is_player = (team == "player")
	var x_pos = 50 if is_player else 400
	var color = Color(0.3, 1.0, 0.3, 1.0) if is_player else Color(1.0, 0.3, 0.3, 1.0)
	var prefix = "PlayerFighter_" if is_player else "EnemyFighter_"
	
	var bg = ColorRect.new()
	bg.size = Vector2(250, 40)
	bg.position = Vector2(x_pos, y_pos)
	bg.color = Color(0.2, 0.2, 0.2, 0.8)
	bg.name = prefix + "BG_" + str(index)
	battle.add_child(bg)
	
	var name_label = Label.new()
	name_label.text = fighter["name"] + " (" + str(fighter["health"]) + "/" + str(fighter["max_health"]) + ")"
	name_label.position = Vector2(x_pos + 5, y_pos + 5)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", color)
	name_label.name = prefix + "Name_" + str(index)
	battle.add_child(name_label)
	
	var hp_bg = ColorRect.new()
	hp_bg.size = Vector2(240, 8)
	hp_bg.position = Vector2(x_pos + 5, y_pos + 25)
	hp_bg.color = Color(0.1, 0.1, 0.1, 1.0)
	battle.add_child(hp_bg)
	
	var hp_fill = ColorRect.new()
	var hp_percent = float(fighter["health"]) / float(fighter["max_health"])
	hp_fill.size = Vector2(240 * hp_percent, 8)
	hp_fill.position = Vector2(x_pos + 5, y_pos + 25)
	hp_fill.color = color
	battle.add_child(hp_fill)
	
	# Выделение текущего бойца
	if current_turn == "player" and is_player and index == highlight_index:
		var highlight = ColorRect.new()
		highlight.size = Vector2(250, 40)
		highlight.position = Vector2(x_pos, y_pos)
		highlight.color = Color(1.0, 1.0, 0.0, 0.3)
		highlight.z_index = -1
		battle.add_child(highlight)

func update_log(battle, log_lines, max_lines):
	var log_scroll = battle.get_node_or_null("LogScroll")
	if not log_scroll:
		return
	var log_vbox = log_scroll.get_node_or_null("LogVBox")
	if not log_vbox:
		return
	
	for child in log_vbox.get_children():
		child.queue_free()
	
	for i in range(min(max_lines, log_lines.size())):
		var log_line = Label.new()
		log_line.text = log_lines[i]
		log_line.add_theme_font_size_override("font_size", 14)
		log_line.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
		log_line.autowrap_mode = TextServer.AUTOWRAP_WORD
		log_line.custom_minimum_size = Vector2(620, 0)
		log_vbox.add_child(log_line)
