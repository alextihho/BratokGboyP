# battle_logic_full.gd - ИСПРАВЛЕННАЯ ВЕРСИЯ
extends Node

signal turn_completed()
signal battle_state_changed(new_state: String)
signal avatar_clicked(character_data: Dictionary, is_player_team: bool)  # ✅ ДОБАВЛЕНО

var player_team: Array = []
var enemy_team: Array = []
var turn: String = "player"
var current_attacker_index: int = 0
var buttons_locked: bool = false

# Режим выбора
var selecting_target: bool = false
var selecting_bodypart: bool = false
var selected_target = null
var selected_bodypart: String = ""

# Части тела
var body_parts = {
	"head": {"name": "Голова/Шея", "damage_mult": 3.0, "crit_effects": ["bleed", "blind_or_stun"]},
	"torso": {"name": "Торс", "damage_mult": 1.0, "crit_effects": ["bleed"]},
	"arms": {"name": "Руки", "damage_mult": 0.5, "crit_effects": ["bleed", "disarm"]},
	"legs": {"name": "Ноги", "damage_mult": 0.75, "crit_effects": ["bleed", "cripple"]}
}

var player_stats

func _ready():
	player_stats = get_node_or_null("/root/PlayerStats")

func initialize(p_player_team: Array, p_enemy_team: Array):
	player_team = p_player_team
	enemy_team = p_enemy_team
	turn = "player"
	current_attacker_index = 0
	buttons_locked = false
	selected_target = null
	selected_bodypart = ""
	
	print("⚔️ Бой: %d vs %d" % [player_team.size(), enemy_team.size()])

# ========== ВЫБОР ЦЕЛИ ==========
func select_target(enemy_index: int) -> bool:
	if enemy_index < 0 or enemy_index >= enemy_team.size():
		return false
	
	var target = enemy_team[enemy_index]
	if not target["alive"]:
		return false
	
	selected_target = target
	print("🎯 Цель выбрана: %s" % target["name"])
	return true

func get_selected_target():
	return selected_target

func clear_target():
	selected_target = null
	selected_bodypart = ""

# ========== АТАКА ==========
func start_attack() -> bool:
	# ✅ ИСПРАВЛЕНО: Проверяем что цель существует и жива
	if not selected_target:
		return false
	
	if not selected_target.get("alive", false):
		clear_target()
		return false
	
	# Показываем меню прицеливания
	selecting_bodypart = true
	buttons_locked = true
	battle_state_changed.emit("selecting_bodypart")
	return true

func select_bodypart(part_key: String):
	if part_key not in body_parts:
		return
	
	selected_bodypart = part_key
	selecting_bodypart = false
	
	perform_attack()

func perform_attack() -> Dictionary:
	# ✅ ИСПРАВЛЕНО: Проверяем что цель существует
	if not selected_target or selected_bodypart == "":
		return {"success": false}
	
	var attacker = player_team[current_attacker_index]
	var target = selected_target
	var bodypart = body_parts[selected_bodypart]
	
	var result = {
		"success": true,
		"attacker": attacker["name"],
		"target": target["name"],
		"bodypart": bodypart["name"],
		"damage": 0,
		"is_crit": false,
		"hit": true,
		"effects": []
	}
	
	# Проверка попадания
	var hit_chance = attacker["accuracy"]
	if randf() > hit_chance:
		result["hit"] = false
		next_attacker()
		return result
	
	# Расчет урона
	var base_damage = attacker["damage"]
	var damage = int(base_damage * bodypart["damage_mult"])
	
	# Критическое попадание
	var is_crit = randf() < 0.2
	if is_crit:
		damage = int(damage * 1.5)
		result["is_crit"] = true
		var crit_effects = apply_crit_effects(target, bodypart["crit_effects"])
		result["effects"] = crit_effects
	
	# Применение урона
	var final_damage = max(1, damage - target["defense"])
	target["hp"] -= final_damage
	result["damage"] = final_damage
	
	# Снижение морали
	target["morale"] = max(10, target["morale"] - randi_range(5, 15))
	
	# Проверка обморока/смерти
	check_fighter_status(target)
	
	# Следующий атакующий
	clear_target()
	next_attacker()
	
	return result

func apply_crit_effects(target: Dictionary, effects: Array) -> Array:
	var applied = []
	
	for effect in effects:
		match effect:
			"bleed":
				if not target["status_effects"].has("bleeding"):
					target["status_effects"]["bleeding"] = randi_range(3, 4)
					applied.append("bleeding")
			
			"blind_or_stun":
				if randf() < 0.5:
					target["status_effects"]["blind"] = randi_range(2, 3)
					target["accuracy"] *= 0.1
					applied.append("blind")
				else:
					target["status_effects"]["stunned"] = randi_range(1, 2)
					applied.append("stunned")
			
			"disarm":
				if randf() < 0.3:
					target["status_effects"]["disarmed"] = true
					target["damage"] = int(target["damage"] * 0.3)
					applied.append("disarmed")
			
			"cripple":
				if randf() < 0.2:
					target["status_effects"]["crippled"] = true
					applied.append("crippled")
	
	return applied

func check_fighter_status(fighter: Dictionary):
	if fighter["hp"] <= 0:
		var excess_damage = abs(fighter["hp"])
		
		# Проверка на обморок vs смерть
		if excess_damage <= (5 if not fighter.get("is_player", false) else 1):
			fighter["alive"] = false
			fighter["hp"] = 0
		else:
			fighter["alive"] = false
			fighter["hp"] = 0
		
		# Снижение морали у команды
		var team = player_team if (fighter.get("is_player", false) or player_team.has(fighter)) else enemy_team
		for member in team:
			if member["alive"]:
				member["morale"] = max(10, member["morale"] - 15)

# ========== ЗАЩИТА ==========
func defend():
	for fighter in player_team:
		if fighter["alive"]:
			fighter["defense"] = fighter.get("defense", 0) + 10
	
	turn = "enemy"
	buttons_locked = true
	battle_state_changed.emit("enemy_turn")

# ========== БЕГ ==========
func try_run() -> Dictionary:
	var agi = player_stats.get_stat("AGI") if player_stats else 4
	var run_chance = 0.4 + agi * 0.05
	
	var result = {
		"success": randf() < run_chance
	}
	
	if not result["success"]:
		turn = "enemy"
		buttons_locked = true
		battle_state_changed.emit("enemy_turn")
	
	return result

# ========== ХОД ВРАГА ==========
func enemy_turn() -> Array:
	var actions = []
	
	for i in range(enemy_team.size()):
		var enemy = enemy_team[i]
		if not enemy["alive"] or enemy["status_effects"].has("stunned"):
			continue
		
		# Выбор цели
		var target = get_random_alive_player()
		if not target:
			break
		
		# Выбор части тела (случайно)
		var parts = ["head", "torso", "arms", "legs"]
		var part_key = parts[randi() % parts.size()]
		var bodypart = body_parts[part_key]
		
		var action = {
			"attacker": enemy["name"],
			"target": target["name"],
			"bodypart": bodypart["name"],
			"damage": 0,
			"hit": true,
			"is_crit": false,
			"effects": []
		}
		
		# Атака
		if randf() > enemy["accuracy"]:
			action["hit"] = false
			actions.append(action)
			continue
		
		var damage = int(enemy["damage"] * bodypart["damage_mult"])
		var is_crit = randf() < 0.15
		
		if is_crit:
			damage = int(damage * 1.5)
			action["is_crit"] = true
			var crit_effects = apply_crit_effects(target, bodypart["crit_effects"])
			action["effects"] = crit_effects
		
		var final_damage = max(1, damage - target["defense"])
		target["hp"] -= final_damage
		action["damage"] = final_damage
		
		target["morale"] = max(10, target["morale"] - randi_range(3, 10))
		check_fighter_status(target)
		
		actions.append(action)
	
	# Проверка окончания боя
	var battle_result = check_battle_end()
	if battle_result["ended"]:
		return actions
	
	# Следующий ход
	turn = "player"
	current_attacker_index = 0
	buttons_locked = false
	battle_state_changed.emit("player_turn")
	
	return actions

# ========== СМЕНА АТАКУЮЩЕГО ==========
func next_attacker():
	current_attacker_index += 1
	
	# Пропускаем мертвых/оглушённых
	while current_attacker_index < player_team.size():
		var attacker = player_team[current_attacker_index]
		if attacker["alive"] and not attacker["status_effects"].has("stunned"):
			break
		current_attacker_index += 1
	
	# Конец хода команды
	if current_attacker_index >= player_team.size():
		var battle_result = check_battle_end()
		if not battle_result["ended"]:
			turn = "enemy"
			current_attacker_index = 0
			battle_state_changed.emit("enemy_turn")
	else:
		battle_state_changed.emit("next_attacker")
	
	turn_completed.emit()

# ========== ПРОВЕРКА ОКОНЧАНИЯ БОЯ ==========
func check_battle_end() -> Dictionary:
	var player_alive = count_alive(player_team)
	var enemy_alive = count_alive(enemy_team)
	
	return {
		"ended": (player_alive == 0 or enemy_alive == 0),
		"victory": enemy_alive == 0,
		"player_alive": player_alive,
		"enemy_alive": enemy_alive
	}

# ========== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==========
func get_current_attacker():
	if current_attacker_index < player_team.size():
		return player_team[current_attacker_index]
	return null

func get_random_alive_player():
	var alive = []
	for fighter in player_team:
		if fighter["alive"]:
			alive.append(fighter)
	
	if alive.size() == 0:
		return null
	return alive[randi() % alive.size()]

func count_alive(team: Array) -> int:
	var count = 0
	for fighter in team:
		if fighter["alive"]:
			count += 1
	return count

func is_buttons_locked() -> bool:
	return buttons_locked

func get_turn() -> String:
	return turn

func get_status_text(fighter: Dictionary) -> String:
	var statuses = []
	
	if fighter["status_effects"].has("bleeding"):
		statuses.append("🩸" + str(fighter["status_effects"]["bleeding"]))
	if fighter["status_effects"].has("blind"):
		statuses.append("👁️" + str(fighter["status_effects"]["blind"]))
	if fighter["status_effects"].has("stunned"):
		statuses.append("😵" + str(fighter["status_effects"]["stunned"]))
	if fighter["status_effects"].has("disarmed"):
		statuses.append("🔫")
	if fighter["status_effects"].has("crippled"):
		statuses.append("🦵")
	
	return " ".join(statuses)

# ✅ ДОБАВЛЕНО: Функции для доступа к командам
func get_player_team() -> Array:
	return player_team

func get_enemy_team() -> Array:
	return enemy_team

func get_alive_player_count() -> int:
	return count_alive(player_team)

func get_alive_enemy_count() -> int:
	return count_alive(enemy_team)
