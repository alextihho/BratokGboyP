# scripts/battle/battle_logic.gd
extends Node

signal battle_won(reward: Dictionary)
signal battle_lost()
signal turn_changed(is_player_turn: bool)
signal allies_turn_started()

var player_stats

# ===== ДАННЫЕ БОЕВОЙ СЕССИИ =====
var player_hp: int = 100
var player_max_hp: int = 100
var defense: bool = false

var enemies: Array = []
var allies: Array = []

var is_first_battle: bool = false
var turn: String = "player"  # "player", "allies", "enemies"

func _ready():
	player_stats = get_node_or_null("/root/PlayerStats")

func setup(p_data: Dictionary, p_enemies: Array, first_battle: bool):
	is_first_battle = first_battle
	
	# Игрок
	player_hp = p_data.get("health", 100)
	player_max_hp = 100
	
	# Враги
	enemies = p_enemies.duplicate(true)
	
	# Союзники (TODO: добавить из банды)
	allies = []
	
	turn = "player"

# ===== ПОЛУЧИТЬ СОСТОЯНИЕ =====
func get_battle_state() -> Dictionary:
	return {
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"enemies": enemies,
		"allies": allies,
		"turn": turn,
		"defense": defense
	}

func get_player_health() -> int:
	return player_hp

# ===== ДЕЙСТВИЯ ИГРОКА =====
func player_attack(target_index: int):
	if turn != "player":
		return
	
	if target_index < 0 or target_index >= enemies.size():
		return
	
	var enemy = enemies[target_index]
	
	var damage = player_stats.calculate_melee_damage() if player_stats else 5
	
	if randf() > 0.85:
		get_ui().add_log("⚔️ Вы промахнулись!")
	else:
		enemy["hp"] -= damage
		get_ui().add_log("⚔️ Вы нанесли %d урона %s!" % [damage, enemy["name"]])
		
		if player_stats:
			player_stats.on_melee_attack()
		
		if enemy["hp"] <= 0:
			get_ui().add_log("💀 %s повержен!" % enemy["name"])
			enemies.remove_at(target_index)
			
			if enemies.size() == 0:
				win_battle()
				return
	
	next_turn()

func player_defend():
	if turn != "player":
		return
	
	defense = true
	get_ui().add_log("🛡️ Вы приняли защитную стойку")
	next_turn()

func player_run():
	if turn != "player" or is_first_battle:
		return
	
	var agi = player_stats.get_stat("AGI") if player_stats else 4
	var run_chance = 0.5 + agi * 0.05
	
	if randf() < run_chance:
		get_ui().add_log("🏃 Вы успешно сбежали!")
		if player_stats:
			player_stats.on_dodge_success()
		
		await get_tree().create_timer(1.5).timeout
		battle_lost.emit()
	else:
		get_ui().add_log("🏃 Не удалось сбежать!")
		next_turn()

# ===== ХОД СОЮЗНИКОВ (АВТОМАТИЧЕСКИЙ) =====
func process_allies_turn():
	if allies.size() == 0:
		next_turn()
		return
	
	for ally in allies:
		if ally["hp"] <= 0:
			continue
		
		# Простая логика: атакуем случайного врага
		if enemies.size() > 0:
			var target_idx = randi() % enemies.size()
			var enemy = enemies[target_idx]
			
			var damage = randi_range(5, 15)
			enemy["hp"] -= damage
			
			get_ui().add_log("🤝 %s атакует %s (-%d HP)" % [ally["name"], enemy["name"], damage])
			
			if enemy["hp"] <= 0:
				get_ui().add_log("💀 %s повержен!" % enemy["name"])
				enemies.remove_at(target_idx)
				
				if enemies.size() == 0:
					win_battle()
					return
		
		await get_tree().create_timer(0.5).timeout
	
	next_turn()

# ===== ХОД ВРАГОВ =====
func process_enemy_turn():
	if enemies.size() == 0:
		return
	
	for enemy in enemies:
		if enemy["hp"] <= 0:
			continue
		
		var damage = randi_range(8, 15)
		
		if defense:
			damage = int(damage / 2.0)
			defense = false
			get_ui().add_log("🛡️ Вы заблокировали часть урона!")
		
		var evasion = player_stats.calculate_evasion() if player_stats else 8
		if randf() * 100 < evasion:
			get_ui().add_log("🌀 Вы уклонились от атаки %s!" % enemy["name"])
			if player_stats:
				player_stats.on_dodge_success()
		else:
			player_hp -= damage
			get_ui().add_log("💢 %s нанёс вам %d урона!" % [enemy["name"], damage])
		
		if player_hp <= 0:
			lose_battle()
			return
		
		await get_tree().create_timer(0.8).timeout
	
	next_turn()

# ===== СМЕНА ХОДА =====
func next_turn():
	if turn == "player":
		if allies.size() > 0:
			turn = "allies"
			turn_changed.emit(false)
			allies_turn_started.emit()
		else:
			turn = "enemies"
			turn_changed.emit(false)
	elif turn == "allies":
		turn = "enemies"
		turn_changed.emit(false)
	else:
		turn = "player"
		turn_changed.emit(true)

# ===== ПОБЕДА/ПОРАЖЕНИЕ =====
func win_battle():
	var reward = {
		"money": randi_range(50, 150),
		"reputation": 5
	}
	
	battle_won.emit(reward)

func lose_battle():
	battle_lost.emit()

# ===== ВСПОМОГАТЕЛЬНЫЕ =====
func get_ui():
	return get_parent().ui_manager
