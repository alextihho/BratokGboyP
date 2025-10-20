# battle_combat.gd (модуль расчётов боя)
extends Node

enum HitZone { TORSO = 0, HEAD = 1, ARMS = 2, LEGS = 3 }

var hit_zones = [
	{"id": 0, "name": "Торс", "icon": "💪", "damage_mult": 1.0, "hit_chance": 80},
	{"id": 1, "name": "Голова", "icon": "👤", "damage_mult": 2.0, "hit_chance": 50},
	{"id": 2, "name": "Руки", "icon": "✋", "damage_mult": 0.7, "hit_chance": 70},
	{"id": 3, "name": "Ноги", "icon": "🦵", "damage_mult": 0.6, "hit_chance": 75}
]

func get_hit_zones() -> Array:
	return hit_zones

func get_zone_name(zone_id: int) -> String:
	if zone_id >= 0 and zone_id < hit_zones.size():
		return hit_zones[zone_id]["name"]
	return "Торс"

func create_enemy_team(enemy_type: String, is_first: bool) -> Array:
	var team = []
	
	match enemy_type:
		"drunkard":
			add_enemies(team, "Пьяный", 2, 30, 3)
		"gopnik":
			if is_first:
				add_enemies(team, "Гопник", 2, 50, 4)
			else:
				add_enemies(team, "Гопник", 3, 50, 4)
		"thug":
			add_enemies(team, "Хулиган", 3, 70, 6)
		"bandit":
			add_enemies(team, "Бандит", 4, 80, 8)
		"guard":
			add_enemies(team, "Охранник", 2, 100, 10)
		"boss":
			add_enemies(team, "Главарь", 1, 200, 15)
			add_enemies(team, "Телохранитель", 2, 80, 8)
	
	return team

func add_enemies(team: Array, name: String, count: int, hp: int, str: int):
	for i in range(count):
		team.append({
			"name": name + " " + str(i + 1),
			"health": hp,
			"max_health": hp,
			"strength": str,
			"agility": 4,
			"accuracy": 5
		})

func calculate_attack(attacker: Dictionary, target: Dictionary, zone_id: int) -> Dictionary:
	var zone = hit_zones[zone_id]
	var result = {
		"hit": false,
		"damage": 0,
		"zone_name": zone["name"]
	}
	
	# Проверка попадания
	var hit_chance = zone["hit_chance"]
	hit_chance += attacker.get("agility", 5) * 2
	hit_chance = clamp(hit_chance, 10, 95)
	
	if randf() * 100 >= hit_chance:
		return result
	
	result["hit"] = true
	
	# Расчёт урона
	var base_damage = attacker["strength"]
	var damage = int(base_damage * zone["damage_mult"] * randf_range(0.8, 1.2))
	
	# Учёт брони
	var armor = 0
	if target.get("equipment", {}).get("armor"):
		var items_db = get_node("/root/ItemsDB")
		if items_db:
			var armor_data = items_db.get_item(target["equipment"]["armor"])
			if armor_data and armor_data.has("defense"):
				armor = armor_data["defense"]
	
	damage = max(1, damage - armor)
	result["damage"] = damage
	
	# Эффекты по зонам
	var critical = randf() < 0.15
	
	match zone_id:
		HitZone.HEAD:
			if critical:
				result["effect"] = "💫 КРИТ! Оглушение!"
		HitZone.ARMS:
			if critical:
				result["effect"] = "💥 КРИТ! Обезоружен!"
		HitZone.LEGS:
			if critical:
				result["effect"] = "🦵 КРИТ! Не может двигаться!"
		HitZone.TORSO:
			if critical:
				result["effect"] = "🩸 КРИТ! Кровотечение!"
	
	return result

func calculate_run_chance(team: Array) -> float:
	var total_agi = 0
	for fighter in team:
		if fighter["health"] > 0:
			total_agi += fighter.get("agility", 5)
	
	return 0.3 + (total_agi * 0.02)
