# battle.gd (v2.0 - ГРУППОВЫЕ БОИ ДО 10 vs 12)
extends CanvasLayer

signal battle_ended(victory: bool)

# Участники боя
var player_team: Array = []  # До 10 человек
var enemy_team: Array = []   # До 12 человек

var turn: String = "player"
var is_first_battle: bool = false
var buttons_locked: bool = false

var player_stats
var battle_log_lines: Array = []
var max_log_lines: int = 12

# Шаблоны врагов
var enemy_templates = {
	"drunkard": {"name": "Пьяный", "hp": 40, "damage": 5, "defense": 0, "morale": 30, "reward": 20},
	"gopnik": {"name": "Гопник", "hp": 60, "damage": 10, "defense": 2, "morale": 50, "reward": 50},
	"thug": {"name": "Хулиган", "hp": 80, "damage": 15, "defense": 5, "morale": 60, "reward": 80},
	"bandit": {"name": "Бандит", "hp": 100, "damage": 20, "defense": 8, "morale": 70, "reward": 120},
	"guard": {"name": "Охранник", "hp": 120, "damage": 25, "defense": 15, "morale": 80, "reward": 150},
	"boss": {"name": "Главарь", "hp": 200, "damage": 35, "defense": 20, "morale": 100, "reward": 300}
}

func _ready():
	layer = 200
	player_stats = get_node("/root/PlayerStats")

func setup(p_player_data: Dictionary, enemy_type: String = "gopnik", first_battle: bool = false, gang_members: Array = []):
	is_first_battle = first_battle
	
	# Формируем команду игрока (главный + банда)
	player_team = []
	
	# Главный герой
	var player = {
		"name": "Вы",
		"hp": p_player_data.get("health", 100),
		"max_hp": 100,
		"damage": player_stats.calculate_melee_damage() if player_stats else 10,
		"defense": player_stats.equipment_bonuses.get("defense", 0) if player_stats else 0,
		"morale": 100,
		"is_player": true,
		"alive": true
	}
	player_team.append(player)
	
	# Члены банды (максимум 9, чтобы всего было 10)
	for i in range(min(gang_members.size() - 1, 9)):
		var member = gang_members[i + 1]  # Пропускаем главного (индекс 0)
		var gang_fighter = {
			"name": member.get("name", "Боец"),
			"hp": member.get("health", 80),
			"max_hp": member.get("health", 80),
			"damage": member.get("strength", 5) + 5,
			"defense": 0,
			"morale": 80,
			"is_player": false,
			"alive": true
		}
		player_team.append(gang_fighter)
	
	# Формируем команду врагов (1-12 человек)
	enemy_team = []
	var enemy_count = get_enemy_count(enemy_type, player_team.size())
	
	for i in range(enemy_count):
		var template = enemy_templates[enemy_type]
		var enemy = {
			"name": template["name"] + " " + str(i + 1),
			"hp": template["hp"],
			"max_hp": template["hp"],
			"damage": template["damage"],
			"defense": template["defense"],
			"morale": template["morale"],
			"reward": template["reward"],
			"alive": true
		}
		enemy_team.append(enemy)
	
	create_ui()
	update_ui()
	
	if is_first_battle:
		add_to_log("⚠️ ОБУЧЕНИЕ: Убежать нельзя!")
	add_to_log("⚔️ Бой начался! %d vs %d" % [player_team.size(), enemy_team.size()])

func get_enemy_count(enemy_type: String, player_count: int) -> int:
	# Баланс: больше игроков = больше врагов
	match enemy_type:
		"drunkard":
			return clamp(player_count, 1, 3)
		"gopnik":
			return clamp(player_count + randi_range(0, 1), 1, 5)
		"thug":
			return clamp(player_count + randi_range(1, 2), 2, 6)
		"bandit":
			return clamp(player_count + randi_range(1, 3), 2, 8)
		"guard":
			return clamp(player_count + randi_range(2, 4), 3, 10)
		"boss":
			return clamp(player_count + randi_range(3, 5), 4, 12)
	return 1

func create_ui():
	var bg = ColorRect.new()
	bg.size = Vector2(700, 1100)
	bg.position = Vector2(10, 90)
	bg.color = Color(0.05, 0.02, 0.02, 0.98)
	bg.name = "BattleBG"
	add_child(bg)
	
	var title = Label.new()
	title.text = "⚔️ ГРУППОВОЙ БОЙ"
	title.position = Vector2(250, 110)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	add_child(title)
	
	# Лог боя (SCROLL)
	var log_scroll = ScrollContainer.new()
	log_scroll.custom_minimum_size = Vector2(680, 550)
	log_scroll.position = Vector2(20, 170)
	log_scroll.name = "LogScroll"
	log_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(log_scroll)
	
	var log_bg = ColorRect.new()
	log_bg.size = Vector2(680, 550)
	log_bg.position = Vector2(20, 170)
	log_bg.color = Color(0.03, 0.03, 0.03, 1.0)
	log_bg.z_index = -1
	add_child(log_bg)
	
	var log_vbox = VBoxContainer.new()
	log_vbox.name = "LogVBox"
	log_vbox.custom_minimum_size = Vector2(660, 0)
	log_scroll.add_child(log_vbox)
	
	# Статус команд
	var team_status = Label.new()
	team_status.text = "Команды загружаются..."
	team_status.position = Vector2(30, 750)
	team_status.add_theme_font_size_override("font_size", 18)
	team_status.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 1.0))
	team_status.name = "TeamStatus"
	add_child(team_status)
	
	# Кнопки
	var attack_btn = Button.new()
	attack_btn.custom_minimum_size = Vector2(200, 70)
	attack_btn.position = Vector2(40, 1000)
	attack_btn.text = "⚔️ АТАКА"
	attack_btn.name = "AttackBtn"
	
	var style_attack = StyleBoxFlat.new()
	style_attack.bg_color = Color(0.7, 0.2, 0.2, 1.0)
	attack_btn.add_theme_stylebox_override("normal", style_attack)
	attack_btn.add_theme_font_size_override("font_size", 24)
	attack_btn.pressed.connect(func(): on_attack())
	add_child(attack_btn)
	
	var defend_btn = Button.new()
	defend_btn.custom_minimum_size = Vector2(200, 70)
	defend_btn.position = Vector2(260, 1000)
	defend_btn.text = "🛡️ ЗАЩИТА"
	defend_btn.name = "DefendBtn"
	
	var style_defend = StyleBoxFlat.new()
	style_defend.bg_color = Color(0.2, 0.4, 0.7, 1.0)
	defend_btn.add_theme_stylebox_override("normal", style_defend)
	defend_btn.add_theme_font_size_override("font_size", 24)
	defend_btn.pressed.connect(func(): on_defend())
	add_child(defend_btn)
	
	var run_btn = Button.new()
	run_btn.custom_minimum_size = Vector2(200, 70)
	run_btn.position = Vector2(480, 1000)
	run_btn.text = "🏃 БЕЖАТЬ"
	run_btn.name = "RunBtn"
	
	var style_run = StyleBoxFlat.new()
	style_run.bg_color = Color(0.5, 0.5, 0.2, 1.0)
	run_btn.add_theme_stylebox_override("normal", style_run)
	run_btn.add_theme_font_size_override("font_size", 24)
	run_btn.pressed.connect(func(): on_run())
	add_child(run_btn)
	
	var turn_info = Label.new()
	turn_info.text = "Ваш ход"
	turn_info.position = Vector2(300, 1100)
	turn_info.add_theme_font_size_override("font_size", 20)
	turn_info.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	turn_info.name = "TurnInfo"
	add_child(turn_info)

func update_ui():
	# Обновляем статус команд
	var team_status = get_node_or_null("TeamStatus")
	if team_status:
		var player_alive = count_alive(player_team)
		var enemy_alive = count_alive(enemy_team)
		
		var status_text = "👥 Ваша команда: %d/%d | 💀 Враги: %d/%d" % [
			player_alive, player_team.size(),
			enemy_alive, enemy_team.size()
		]
		
		# Показываем мораль (если низкая у врагов)
		var avg_enemy_morale = get_average_morale(enemy_team)
		if avg_enemy_morale < 50:
			status_text += " | 😨 Мораль врагов: %d%%" % avg_enemy_morale
		
		team_status.text = status_text
	
	lock_buttons(buttons_locked)

func lock_buttons(locked: bool):
	var attack_btn = get_node_or_null("AttackBtn")
	var defend_btn = get_node_or_null("DefendBtn")
	var run_btn = get_node_or_null("RunBtn")
	
	if attack_btn:
		attack_btn.disabled = locked
	if defend_btn:
		defend_btn.disabled = locked
	if run_btn:
		run_btn.disabled = locked or is_first_battle

func count_alive(team: Array) -> int:
	var count = 0
	for fighter in team:
		if fighter["alive"]:
			count += 1
	return count

func get_average_morale(team: Array) -> int:
	var alive = count_alive(team)
	if alive == 0:
		return 0
	var total = 0
	for fighter in team:
		if fighter["alive"]:
			total += fighter["morale"]
	return int(total / float(alive))

func add_to_log(text: String):
	battle_log_lines.insert(0, text)
	if battle_log_lines.size() > 50:
		battle_log_lines.resize(50)
	update_log_display()

func update_log_display():
	var log_scroll = get_node_or_null("LogScroll")
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
		log_line.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		log_line.autowrap_mode = TextServer.AUTOWRAP_WORD
		log_line.custom_minimum_size = Vector2(640, 0)
		log_vbox.add_child(log_line)

# ========== ДЕЙСТВИЯ ИГРОКА ==========

func on_attack():
	if turn != "player" or buttons_locked:
		return
	
	buttons_locked = true
	lock_buttons(true)
	
	# Каждый живой союзник атакует случайного живого врага
	for fighter in player_team:
		if not fighter["alive"]:
			continue
		
		var target = get_random_alive_enemy()
		if not target:
			break
		
		var damage = fighter["damage"] + randi_range(-2, 5)
		
		if randf() > 0.85:
			add_to_log("🌫 %s промахнулся!" % fighter["name"])
		else:
			target["hp"] -= max(1, damage - target["defense"])
			add_to_log("⚔️ %s → %s: -%d HP" % [fighter["name"], target["name"], damage])
			
			# Снижение морали
			target["morale"] = max(15, target["morale"] - randi_range(5, 15))
			
			if target["hp"] <= 0:
				target["alive"] = false
				target["hp"] = 0
				add_to_log("💀 %s убит!" % target["name"])
				
				# Снижение морали у всех врагов при смерти союзника
				for enemy in enemy_team:
					if enemy["alive"]:
						enemy["morale"] = max(15, enemy["morale"] - 10)
		
		if player_stats and fighter.get("is_player", false):
			player_stats.on_melee_attack()
	
	update_ui()
	
	# Проверка побега врагов (низкая мораль)
	check_enemy_retreat()
	
	if count_alive(enemy_team) == 0:
		win_battle()
		return
	
	turn = "enemy"
	var turn_info = get_node_or_null("TurnInfo")
	if turn_info:
		turn_info.text = "Ход врагов..."
	
	await get_tree().create_timer(1.5).timeout
	enemy_turn()

func on_defend():
	if turn != "player" or buttons_locked:
		return
	
	buttons_locked = true
	lock_buttons(true)
	
	# Все живые союзники защищаются
	for fighter in player_team:
		if fighter["alive"]:
			fighter["defense"] = fighter.get("defense", 0) + 10
	
	add_to_log("🛡️ Команда приняла защитную стойку!")
	turn = "enemy"
	
	var turn_info = get_node_or_null("TurnInfo")
	if turn_info:
		turn_info.text = "Ход врагов..."
	
	await get_tree().create_timer(1.5).timeout
	enemy_turn()

func on_run():
	if turn != "player" or buttons_locked or is_first_battle:
		if is_first_battle:
			add_to_log("⚠️ В обучающем бою убежать нельзя!")
		return
	
	buttons_locked = true
	lock_buttons(true)
	
	var agi = player_stats.get_stat("AGI") if player_stats else 4
	var run_chance = 0.4 + agi * 0.05 + (player_team.size() * 0.03)
	
	if randf() < run_chance:
		add_to_log("🏃 Команда успешно отступила!")
		await get_tree().create_timer(1.5).timeout
		battle_ended.emit(false)
		queue_free()
	else:
		add_to_log("🏃 Не удалось сбежать! Враги блокируют выход!")
		turn = "enemy"
		
		var turn_info = get_node_or_null("TurnInfo")
		if turn_info:
			turn_info.text = "Ход врагов..."
		
		await get_tree().create_timer(1.5).timeout
		enemy_turn()

# ========== ХОД ВРАГОВ ==========

func enemy_turn():
	if turn != "enemy":
		return
	
	# Каждый живой враг атакует случайного живого союзника
	for enemy in enemy_team:
		if not enemy["alive"]:
			continue
		
		var target = get_random_alive_player()
		if not target:
			break
		
		var damage = enemy["damage"] + randi_range(-2, 5)
		
		if randf() > 0.85:
			add_to_log("🌫 %s промахнулся!" % enemy["name"])
		else:
			target["hp"] -= max(1, damage - target["defense"])
			add_to_log("💢 %s → %s: -%d HP" % [enemy["name"], target["name"], damage])
			
			# Снижение морали
			target["morale"] = max(15, target["morale"] - randi_range(3, 10))
			
			if target["hp"] <= 0:
				target["alive"] = false
				target["hp"] = 0
				add_to_log("💀 %s погиб!" % target["name"])
				
				# Снижение морали у игроков
				for fighter in player_team:
					if fighter["alive"]:
						fighter["morale"] = max(15, fighter["morale"] - 10)
		
		# Сбрасываем бонус защиты
		if target.has("defense"):
			target["defense"] = max(0, target.get("defense", 0) - 10)
	
	update_ui()
	
	if count_alive(player_team) == 0:
		lose_battle()
		return
	
	turn = "player"
	buttons_locked = false
	lock_buttons(false)
	
	var turn_info = get_node_or_null("TurnInfo")
	if turn_info:
		turn_info.text = "Ваш ход"

# ========== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==========

func get_random_alive_enemy():
	var alive_enemies = []
	for enemy in enemy_team:
		if enemy["alive"]:
			alive_enemies.append(enemy)
	
	if alive_enemies.size() == 0:
		return null
	return alive_enemies[randi() % alive_enemies.size()]

func get_random_alive_player():
	var alive_players = []
	for fighter in player_team:
		if fighter["alive"]:
			alive_players.append(fighter)
	
	if alive_players.size() == 0:
		return null
	return alive_players[randi() % alive_players.size()]

func check_enemy_retreat():
	# Проверка: если мораль врагов < 30, они могут сбежать
	for enemy in enemy_team:
		if enemy["alive"] and enemy["morale"] < 30:
			if randf() < 0.4:  # 40% шанс побега
				enemy["alive"] = false
				add_to_log("😨 %s в панике сбежал с поля боя!" % enemy["name"])

# ========== ЗАВЕРШЕНИЕ БОЯ ==========

func win_battle():
	add_to_log("✅ ПОБЕДА! Враги повержены!")
	
	var total_reward = 0
	for enemy in enemy_team:
		total_reward += enemy.get("reward", 0)
	
	# Главный герой получает основную награду
	if player_team.size() > 0 and player_team[0].get("is_player", false):
		var main_node = get_parent()
		if main_node and main_node.player_data:
			main_node.player_data["balance"] += total_reward
			main_node.player_data["reputation"] += 5 + enemy_team.size()
			main_node.player_data["health"] = player_team[0]["hp"]
	
	add_to_log("💰 Получено: %d руб., +%d репутации" % [total_reward, 5 + enemy_team.size()])
	
	await get_tree().create_timer(3.0).timeout
	battle_ended.emit(true)
	queue_free()

func lose_battle():
	add_to_log("💀 ПОРАЖЕНИЕ! Команда разбита...")
	
	var main_node = get_parent()
	if main_node and main_node.player_data:
		main_node.player_data["balance"] = max(0, main_node.player_data["balance"] - 100)
		main_node.player_data["health"] = 15
	
	add_to_log("💸 Потеряно: 100 руб.")
	
	await get_tree().create_timer(3.0).timeout
	battle_ended.emit(false)
	queue_free()
