# battle.gd - АДАПТИРОВАН ПОД ВАШ battle_logic_full.gd
extends CanvasLayer

signal battle_ended(victory: bool)

# Модули
var battle_logic
var battle_avatars

# UI элементы
var battle_log_lines: Array = []
var max_log_lines: int = 8

# Системы
var player_stats
var player_data
var gang_members: Array = []

# Шаблоны врагов
var enemy_templates = {
	"drunkard": {"name": "Пьяный", "hp": 40, "damage": 5, "defense": 0, "morale": 30, "accuracy": 0.5, "reward": 20},
	"gopnik": {"name": "Гопник", "hp": 60, "damage": 10, "defense": 2, "morale": 50, "accuracy": 0.65, "reward": 50},
	"thug": {"name": "Хулиган", "hp": 80, "damage": 15, "defense": 5, "morale": 60, "accuracy": 0.70, "reward": 80},
	"bandit": {"name": "Бандит", "hp": 100, "damage": 20, "defense": 8, "morale": 70, "accuracy": 0.75, "reward": 120},
	"guard": {"name": "Охранник", "hp": 120, "damage": 25, "defense": 15, "morale": 80, "accuracy": 0.80, "reward": 150},
	"boss": {"name": "Главарь", "hp": 200, "damage": 35, "defense": 20, "morale": 100, "accuracy": 0.85, "reward": 300}
}

func _ready():
	layer = 200
	player_stats = get_node("/root/PlayerStats")
	
	# Создаём модули
	battle_logic = Node.new()
	battle_logic.set_script(load("res://scripts/battle/battle_logic_full.gd"))
	battle_logic.name = "BattleLogic"
	add_child(battle_logic)
	
	battle_avatars = Node.new()
	battle_avatars.set_script(load("res://scripts/battle/battle_avatars.gd"))
	battle_avatars.name = "BattleAvatars"
	add_child(battle_avatars)
	
	# Подключаем сигналы
	battle_logic.turn_completed.connect(_on_turn_completed)
	battle_logic.battle_state_changed.connect(_on_battle_state_changed)
	battle_avatars.target_selected.connect(_on_target_selected)
	battle_avatars.avatar_clicked.connect(_on_avatar_clicked)

func setup(p_player_data: Dictionary, enemy_type: String = "gopnik", first_battle: bool = false, p_gang_members: Array = []):
	player_data = p_player_data
	gang_members = p_gang_members
	
	# Формируем команду игрока
	var player_team = []
	
	# Главный игрок
	var player = {
		"name": "Вы",
		"hp": p_player_data.get("health", 100),
		"max_hp": 100,
		"damage": player_stats.calculate_melee_damage() if player_stats else 10,
		"defense": player_stats.equipment_bonuses.get("defense", 0) if player_stats else 0,
		"morale": 100,
		"accuracy": 0.75,
		"is_player": true,
		"alive": true,
		"status_effects": {},
		"weapon": p_player_data.get("equipment", {}).get("melee", "Кулаки"),
		"avatar": p_player_data.get("avatar", "res://assets/avatars/player.png"),
		"is_main_player": true,
		"inventory": p_player_data.get("inventory", []),
		"equipment": p_player_data.get("equipment", {})
	}
	player_team.append(player)
	
	# Члены банды
	if gang_members.size() > 0:
		add_to_log("👥 Ваша банда присоединилась к бою!")
		
		for i in range(gang_members.size()):
			var member = gang_members[i]
			var gang_fighter = {
				"name": member.get("name", "Боец " + str(i + 1)),
				"hp": member.get("hp", 80),
				"max_hp": member.get("max_hp", 80),
				"damage": member.get("damage", 10),
				"defense": member.get("defense", 0),
				"morale": member.get("morale", 80),
				"accuracy": member.get("accuracy", 0.65),
				"is_player": true,
				"alive": true,
				"status_effects": {},
				"weapon": member.get("weapon", "Кулаки"),
				"avatar": member.get("avatar", "res://assets/avatars/gang_member.png"),
				"is_gang_member": true,
				"inventory": member.get("inventory", []),
				"equipment": member.get("equipment", {})
			}
			player_team.append(gang_fighter)
			add_to_log("➕ %s присоединился к бою" % gang_fighter["name"])
	else:
		add_to_log("ℹ️ Вы один против всех...")

	# Формируем команду врагов
	var enemy_team = []
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
			"accuracy": template["accuracy"],
			"reward": template["reward"],
			"alive": true,
			"status_effects": {},
			"weapon": "Кулаки",
			"avatar": "res://assets/avatars/enemy_" + enemy_type + ".png",
			"is_enemy": true,
			"inventory": [],
			"equipment": {}
		}
		enemy_team.append(enemy)
	
	# Инициализируем боевую логику
	battle_logic.initialize(player_team, enemy_team)
	
	create_ui()
	
	# Создаём аватарки
	battle_avatars.initialize(battle_logic, self)
	
	add_to_log("⚔️ Бой начался! %d vs %d" % [player_team.size(), enemy_team.size()])
	add_to_log("💪 Ваша команда: %d бойцов" % player_team.size())

func get_enemy_count(enemy_type: String, player_count: int) -> int:
	var base_count = 0
	match enemy_type:
		"drunkard": base_count = clamp(player_count, 1, 3)
		"gopnik": base_count = clamp(player_count + randi_range(0, 1), 1, 5)
		"thug": base_count = clamp(player_count + randi_range(1, 2), 2, 6)
		"bandit": base_count = clamp(player_count + randi_range(1, 3), 2, 8)
		"guard": base_count = clamp(player_count + randi_range(2, 4), 3, 10)
		"boss": base_count = clamp(player_count + randi_range(3, 5), 4, 12)
	
	add_to_log("👹 Врагов: %d (тип: %s)" % [base_count, enemy_type])
	return base_count

func create_ui():
	# Фон
	var bg = ColorRect.new()
	bg.size = Vector2(700, 1100)
	bg.position = Vector2(10, 90)
	bg.color = Color(0.05, 0.02, 0.02, 0.98)
	bg.name = "BattleBG"
	add_child(bg)
	
	# Заголовок
	var title = Label.new()
	title.text = "⚔️ ГРУППОВОЙ БОЙ"
	title.position = Vector2(250, 110)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	add_child(title)
	
	# Информация о командах
	var teams_info = Label.new()
	teams_info.text = "Ваша команда: %d | Враги: %d" % [
		get_alive_player_count(), 
		get_alive_enemy_count()
	]
	teams_info.position = Vector2(200, 150)
	teams_info.add_theme_font_size_override("font_size", 16)
	teams_info.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 1.0))
	teams_info.name = "TeamsInfo"
	add_child(teams_info)
	
	# === ЛОГ БОЯ ===
	var log_scroll = ScrollContainer.new()
	log_scroll.custom_minimum_size = Vector2(680, 300)
	log_scroll.position = Vector2(20, 500)
	log_scroll.name = "LogScroll"
	log_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(log_scroll)
	
	var log_bg = ColorRect.new()
	log_bg.size = Vector2(680, 300)
	log_bg.position = Vector2(20, 500)
	log_bg.color = Color(0.03, 0.03, 0.03, 1.0)
	log_bg.z_index = -1
	add_child(log_bg)
	
	var log_vbox = VBoxContainer.new()
	log_vbox.name = "LogVBox"
	log_vbox.custom_minimum_size = Vector2(660, 0)
	log_scroll.add_child(log_vbox)
	
	# === ИНФОРМАЦИЯ О ХОДЕ ===
	var turn_info = Label.new()
	turn_info.text = "Ваш ход: Выберите цель"
	turn_info.position = Vector2(200, 820)
	turn_info.add_theme_font_size_override("font_size", 20)
	turn_info.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	turn_info.name = "TurnInfo"
	add_child(turn_info)
	
	# === КНОПКИ ===
	create_battle_buttons()
	
	update_turn_info()
	update_teams_info()

# ✅ АДАПТИРОВАННЫЕ ФУНКЦИИ ДЛЯ ВАШЕГО КОДА
func get_alive_player_count() -> int:
	return battle_logic.count_alive(battle_logic.player_team)

func get_alive_enemy_count() -> int:
	return battle_logic.count_alive(battle_logic.enemy_team)

func get_total_player_count() -> int:
	return battle_logic.player_team.size()

func get_total_enemy_count() -> int:
	return battle_logic.enemy_team.size()

func create_battle_buttons():
	# Кнопка "Атака"
	var attack_btn = Button.new()
	attack_btn.custom_minimum_size = Vector2(200, 70)
	attack_btn.position = Vector2(40, 1000)
	attack_btn.text = "⚔️ АТАКА"
	attack_btn.name = "AttackBtn"
	
	var style_attack = StyleBoxFlat.new()
	style_attack.bg_color = Color(0.7, 0.2, 0.2, 1.0)
	attack_btn.add_theme_stylebox_override("normal", style_attack)
	attack_btn.add_theme_font_size_override("font_size", 24)
	attack_btn.pressed.connect(func(): on_attack_button())
	add_child(attack_btn)
	
	# Кнопка "Защита"
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
	
	# Кнопка "Бежать"
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

# ========== ОБРАБОТКА ДЕЙСТВИЙ ==========
func on_attack_button():
	if battle_logic.is_buttons_locked():
		return
	
	# ✅ ИСПРАВЛЕНО: Проверяем, что цель выбрана
	if not battle_logic.selected_target:
		add_to_log("⚠️ Сначала выберите цель!")
		return
	
	if not battle_logic.selected_target["alive"]:
		add_to_log("⚠️ Выбранная цель мертва!")
		battle_logic.clear_target()
		return
	
	# Показываем меню прицеливания
	if battle_logic.start_attack():
		show_bodypart_menu()

func show_bodypart_menu():
	var bodypart_menu = Control.new()
	bodypart_menu.name = "BodypartMenu"
	bodypart_menu.position = Vector2(200, 850)
	add_child(bodypart_menu)
	
	var bg = ColorRect.new()
	bg.size = Vector2(320, 140)
	bg.color = Color(0.1, 0.1, 0.1, 0.95)
	bodypart_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "🎯 ПРИЦЕЛИТЬСЯ"
	title.position = Vector2(80, 10)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	bodypart_menu.add_child(title)
	
	var y = 40
	for part_key in ["head", "torso", "arms", "legs"]:
		var part = battle_logic.body_parts[part_key]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(300, 20)
		btn.position = Vector2(10, y)
		btn.text = part["name"] + " (x%.1f урона)" % part["damage_mult"]
		btn.add_theme_font_size_override("font_size", 14)
		
		var pk = part_key
		btn.pressed.connect(func(): on_bodypart_selected(pk))
		bodypart_menu.add_child(btn)
		y += 25

func on_bodypart_selected(part_key: String):
	var menu = get_node_or_null("BodypartMenu")
	if menu:
		menu.queue_free()
	
	battle_logic.select_bodypart(part_key)
	
	# ✅ ВАЖНО: НЕ очищаем selected_target - цель остаётся выбранной!
	# battle_logic.clear_target()  <-- УДАЛИТЕ ЭТУ СТРОКУ ЕСЛИ ОНА ЕСТЬ
	
	# Автоматически переходит к следующему атакующему

func on_defend():
	if battle_logic.turn != "player" or battle_logic.is_buttons_locked():
		return
	
	battle_logic.defend()
	add_to_log("🛡️ Вы приняли защитную стойку!")
	lock_buttons(true)
	
	await get_tree().create_timer(1.5).timeout
	execute_enemy_turn()

func on_run():
	if battle_logic.turn != "player" or battle_logic.is_buttons_locked():
		return
	
	var result = battle_logic.try_run()
	
	if result["success"]:
		add_to_log("🏃 Успешное отступление!")
		await get_tree().create_timer(1.5).timeout
		battle_ended.emit(false)
		queue_free()
	else:
		add_to_log("🏃 Не удалось сбежать!")
		lock_buttons(true)
		await get_tree().create_timer(1.5).timeout
		execute_enemy_turn()

# ========== ХОД ВРАГА ==========
func execute_enemy_turn():
	var actions = battle_logic.enemy_turn()
	
	for action in actions:
		if action["hit"]:
			var log_text = "💢 %s → %s (%s): -%d HP" % [
				action["attacker"],
				action["target"],
				action["bodypart"],
				action["damage"]
			]
			if action["is_crit"]:
				add_to_log("💥 КРИТИЧЕСКИЙ УДАР врага!")
			add_to_log(log_text)
		else:
			add_to_log("🌫 %s промахнулся!" % action["attacker"])
		
		battle_avatars.update_all_avatars()
		update_teams_info()
		await get_tree().create_timer(0.5).timeout
	
	check_battle_end()

# ========== ПРОВЕРКА ОКОНЧАНИЯ БОЯ ==========
func check_battle_end():
	var result = battle_logic.check_battle_end()
	
	if result["ended"]:
		if result["victory"]:
			win_battle()
		else:
			lose_battle()
	else:
		lock_buttons(false)

func win_battle():
	add_to_log("✅ ПОБЕДА!")
	
	var total_reward = 0
	var alive_members = 0
	
	# Считаем награду за врагов
	for enemy in battle_logic.enemy_team:
		total_reward += enemy.get("reward", 0)
	
	# Считаем выживших членов банды для бонуса
	for player in battle_logic.player_team:
		if player.get("alive", false) and player.get("is_gang_member", false):
			alive_members += 1
	
	var main_node = get_parent()
	if main_node and main_node.has("player_data"):
		main_node.player_data["balance"] += total_reward
		main_node.player_data["reputation"] += 5 + battle_logic.enemy_team.size()
		
		# Бонус за выживших членов банды
		if alive_members > 0:
			var bonus = alive_members * 20
			main_node.player_data["balance"] += bonus
			add_to_log("👥 Бонус за выживших: +%d руб." % bonus)
	
	add_to_log("💰 +%d руб., +%d репутации" % [total_reward, 5 + battle_logic.enemy_team.size()])
	
	await get_tree().create_timer(3.0).timeout
	battle_ended.emit(true)
	queue_free()

func lose_battle():
	add_to_log("💀 ПОРАЖЕНИЕ!")
	
	# Проверяем, выжил ли главный игрок
	var main_player_alive = false
	for player in battle_logic.player_team:
		if player.get("is_main_player", false) and player.get("alive", false):
			main_player_alive = true
			break
	
	if not main_player_alive:
		add_to_log("🏥 Главный герой тяжело ранен...")
	else:
		add_to_log("🏃 Вы чудом спаслись...")
	
	await get_tree().create_timer(3.0).timeout
	battle_ended.emit(false)
	queue_free()

# ========== ОБРАБОТКА СИГНАЛОВ ==========
func _on_turn_completed():
	update_turn_info()
	battle_avatars.update_all_avatars()
	update_teams_info()

func _on_battle_state_changed(new_state: String):
	match new_state:
		"enemy_turn":
			execute_enemy_turn()
		"player_turn":
			lock_buttons(false)
			update_turn_info()
		"selecting_bodypart":
			# Ожидаем выбора части тела
			pass
		"next_attacker":
			update_turn_info()

func _on_target_selected(enemy_index: int):
	if battle_logic.select_target(enemy_index):
		var target = battle_logic.enemy_team[enemy_index]
		add_to_log("🎯 Цель выбрана: " + target["name"])

func _on_avatar_clicked(character_data: Dictionary, is_player_team: bool):
	show_character_info(character_data, is_player_team)

func show_character_info(character_data: Dictionary, is_player_team: bool):
	# Создаем окно информации о персонаже
	var info_window = CanvasLayer.new()
	info_window.layer = 300
	add_child(info_window)
	
	var bg = ColorRect.new()
	bg.size = Vector2(600, 800)
	bg.position = Vector2(60, 200)
	bg.color = Color(0.1, 0.1, 0.1, 0.95)
	info_window.add_child(bg)
	
	# Заголовок
	var title = Label.new()
	title.text = "📊 Информация: " + character_data["name"]
	title.position = Vector2(200, 220)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	info_window.add_child(title)
	
	# Статистика
	var stats_text = "❤️ HP: %d/%d\n" % [character_data["hp"], character_data.get("max_hp", 100)]
	stats_text += "⚔️ Урон: %d\n" % character_data["damage"]
	stats_text += "🛡️ Защита: %d\n" % character_data["defense"]
	stats_text += "🎯 Меткость: %.1f\n" % character_data["accuracy"]
	stats_text += "💪 Мораль: %d\n" % character_data["morale"]
	stats_text += "🔫 Оружие: %s\n" % character_data.get("weapon", "Кулаки")
	
	# Статус-эффекты
	var status_text = battle_logic.get_status_text(character_data)
	if status_text != "":
		stats_text += "📋 Статусы: %s\n" % status_text
	
	var stats_label = Label.new()
	stats_label.text = stats_text
	stats_label.position = Vector2(80, 280)
	stats_label.add_theme_font_size_override("font_size", 18)
	info_window.add_child(stats_label)
	
	# Инвентарь (только просмотр)
	if character_data.has("inventory") and character_data["inventory"].size() > 0:
		var inv_title = Label.new()
		inv_title.text = "🎒 Инвентарь:"
		inv_title.position = Vector2(80, 450)
		inv_title.add_theme_font_size_override("font_size", 20)
		info_window.add_child(inv_title)
		
		var y_offset = 490
		for item in character_data["inventory"]:
			var item_label = Label.new()
			item_label.text = "• " + item
			item_label.position = Vector2(100, y_offset)
			item_label.add_theme_font_size_override("font_size", 16)
			info_window.add_child(item_label)
			y_offset += 25
	
	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(200, 50)
	close_btn.position = Vector2(200, 700)
	close_btn.text = "ЗАКРЫТЬ"
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): info_window.queue_free())
	info_window.add_child(close_btn)

# ========== UI ОБНОВЛЕНИЯ ==========
func update_turn_info():
	var turn_info = get_node_or_null("TurnInfo")
	if not turn_info:
		return
	
	if battle_logic.turn == "player":
		var attacker = battle_logic.get_current_attacker()
		if attacker:
			if attacker.get("is_main_player", false):
				turn_info.text = "Ваш ход: Выберите цель и атакуйте"
			else:
				turn_info.text = "Ход: %s (атакует автоматически)" % attacker["name"]
		else:
			turn_info.text = "Ваш ход завершён"
	else:
		turn_info.text = "Ход врагов..."

func update_teams_info():
	var teams_info = get_node_or_null("TeamsInfo")
	if teams_info:
		teams_info.text = "Ваша команда: %d/%d | Враги: %d/%d" % [
			get_alive_player_count(),
			get_total_player_count(),
			get_alive_enemy_count(), 
			get_total_enemy_count()
		]

func lock_buttons(locked: bool):
	var attack_btn = get_node_or_null("AttackBtn")
	var defend_btn = get_node_or_null("DefendBtn")
	var run_btn = get_node_or_null("RunBtn")
	
	if attack_btn:
		attack_btn.disabled = locked
	if defend_btn:
		defend_btn.disabled = locked
	if run_btn:
		run_btn.disabled = locked

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
		log_line.add_theme_font_size_override("font_size", 14)
		log_line.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		log_line.autowrap_mode = TextServer.AUTOWRAP_WORD
		log_line.custom_minimum_size = Vector2(640, 0)
		log_vbox.add_child(log_line)

func show_message(text: String):
	add_to_log(text)
