# player_stats.gd (ХАРИЗМА вместо CHA + ПРОКАЧКА ОТ ДЕЙСТВИЙ)
extends Node

signal stats_changed()
signal stat_leveled_up(stat_name: String, new_level: int)

# Базовые характеристики
var base_stats = {
	"STR": 3,         # Сила - урон ближнего боя
	"AGI": 4,         # Ловкость - уворот, скорость
	"ACC": 2,         # Меткость - стрельба
	"LCK": 1,         # Удача - лут, XP
	"INT": 3,         # Интеллект - обучение
	"ELEC": 1,        # Электроника - взлом
	"PICK": 1,        # Взлом замков
	"Харизма": 2,     # ✅ ХАРИЗМА (вместо CHA) - переговоры, УА
	"DRV": 2,         # Вождение
	"STEALTH": 2      # Скрытность
}

# Опыт для каждой характеристики
var stat_experience = {
	"STR": 0,
	"AGI": 0,
	"ACC": 0,
	"LCK": 0,
	"INT": 0,
	"ELEC": 0,
	"PICK": 0,
	"Харизма": 0,
	"DRV": 0,
	"STEALTH": 0
}

# Бонусы от экипировки
var equipment_bonuses = {
	"STR": 0,
	"AGI": 0,
	"ACC": 0,
	"defense": 0,
	"melee_damage": 0,
	"ranged_damage": 0
}

func _ready():
	print("📊 Система характеристик загружена (с Харизмой)")

# === XP И УРОВНИ ===
func get_xp_for_next_level(current_level: int) -> int:
	return 100 + (current_level - 1) * 50

func add_stat_xp(stat_name: String, amount: int):
	if stat_name not in stat_experience:
		return
	
	stat_experience[stat_name] += amount
	var current_level = base_stats[stat_name]
	var xp_needed = get_xp_for_next_level(current_level)
	
	print("📈 +%d XP к %s (%d/%d)" % [amount, stat_name, stat_experience[stat_name], xp_needed])
	
	while stat_experience[stat_name] >= xp_needed:
		stat_experience[stat_name] -= xp_needed
		base_stats[stat_name] += 1
		current_level = base_stats[stat_name]
		xp_needed = get_xp_for_next_level(current_level)
		
		stat_leveled_up.emit(stat_name, base_stats[stat_name])
		print("⭐ %s → %d!" % [stat_name, base_stats[stat_name]])
		stats_changed.emit()

# === ДЕЙСТВИЯ ДЛЯ ПРОКАЧКИ ===
func on_melee_attack():
	add_stat_xp("STR", 5)

func on_ranged_attack():
	add_stat_xp("ACC", 5)

func on_dodge_success():
	add_stat_xp("AGI", 3)

func on_hack_attempt(success: bool):
	add_stat_xp("ELEC", 15 if success else 3)

func on_lockpick_attempt(success: bool):
	add_stat_xp("PICK", 15 if success else 3)

func on_persuasion_attempt(success: bool):
	add_stat_xp("Харизма", 12 if success else 3)

func on_driving(distance: float):
	var xp = floor(distance / 10.0)
	if xp > 0:
		add_stat_xp("DRV", int(xp))

func on_stealth_action(detected: bool):
	add_stat_xp("STEALTH", 8 if not detected else 2)

func on_theft_attempt(detected: bool, value: int):
	add_stat_xp("STEALTH", (10 + floor(value / 50.0)) if not detected else 2)

# ✅ НОВЫЕ ДЕЙСТВИЯ ДЛЯ ПРОКАЧКИ
func on_robbery_attempt(success: bool, value: int):
	"""Ограбление → Скрытность + Взлом"""
	if success:
		add_stat_xp("STEALTH", 15 + int(value / 100.0))
		add_stat_xp("PICK", 10)
	else:
		add_stat_xp("STEALTH", 5)
		add_stat_xp("PICK", 3)

func on_car_theft_attempt(success: bool):
	"""Угон → Вождение + Взлом"""
	if success:
		add_stat_xp("DRV", 20)
		add_stat_xp("ELEC", 15)
	else:
		add_stat_xp("DRV", 5)
		add_stat_xp("ELEC", 5)

func on_sneaking(distance: float, detected: bool):
	"""Подкрадывание → Скрытность"""
	var xp = int(distance / 5.0)
	if not detected:
		add_stat_xp("STEALTH", 10 + xp)
	else:
		add_stat_xp("STEALTH", 2)

# === ПОЛУЧИТЬ ХАРАКТЕРИСТИКУ ===
func get_stat(stat_name: String) -> int:
	var base = base_stats.get(stat_name, 0)
	var bonus = equipment_bonuses.get(stat_name, 0)
	return base + bonus

func increase_stat(stat_name: String, amount: int = 1):
	if stat_name in base_stats:
		base_stats[stat_name] += amount
		stats_changed.emit()
		print("📈 %s → %d" % [stat_name, base_stats[stat_name]])

# === БОНУСЫ ОТ ЭКИПИРОВКИ ===
func recalculate_equipment_bonuses(equipment: Dictionary, items_db):
	for key in equipment_bonuses.keys():
		equipment_bonuses[key] = 0
	
	for slot in equipment.keys():
		var item_name = equipment[slot]
		if item_name:
			var item_data = items_db.get_item(item_name)
			if item_data:
				if "defense" in item_data:
					equipment_bonuses["defense"] += item_data["defense"]
				
				if "damage" in item_data:
					if item_data["type"] == "melee":
						equipment_bonuses["melee_damage"] += item_data["damage"]
					elif item_data["type"] == "ranged":
						equipment_bonuses["ranged_damage"] += item_data["damage"]
	
	stats_changed.emit()
	print("🔄 Бонусы пересчитаны")

# === БОЕВЫЕ РАСЧЁТЫ ===
func calculate_melee_damage() -> int:
	var str_stat = get_stat("STR")
	var weapon_base = equipment_bonuses["melee_damage"]
	if weapon_base == 0:
		weapon_base = 2
	return int(weapon_base + floor(str_stat * 0.6))

func calculate_ranged_damage() -> int:
	var acc_stat = get_stat("ACC")
	var weapon_base = equipment_bonuses["ranged_damage"]
	if weapon_base == 0:
		return 0
	return int(weapon_base * (1.0 + acc_stat * 0.02))

func calculate_evasion() -> int:
	var agi = get_stat("AGI")
	var lck = get_stat("LCK")
	return int(min(75, agi * 2 + floor(lck * 0.2)))

func calculate_move_speed() -> float:
	return 1.0 + get_stat("AGI") * 0.05

func calculate_hit_chance(weapon_accuracy: float = 0.85, target_cover: float = 0.0) -> float:
	var acc = get_stat("ACC")
	var hit = weapon_accuracy * (1.0 + acc * 0.03) * (1.0 - target_cover * 0.25)
	return clamp(hit, 0.05, 0.95)

# === НАВЫКИ ===
func calculate_hack_chance(difficulty: float = 0.5) -> float:
	var elec = get_stat("ELEC")
	return clamp(1.0 - (difficulty / (1.0 + elec * 0.08)), 0.05, 0.95)

func calculate_lockpick_chance(tool_bonus: float = 0.0) -> float:
	var pick = get_stat("PICK")
	return clamp(0.2 + pick * 0.04 + tool_bonus, 0.0, 0.95)

func calculate_persuasion_chance(base: float = 0.3) -> float:
	var cha = get_stat("Харизма")
	return clamp(base + cha * 0.05, 0.0, 0.95)

func calculate_xp_multiplier() -> float:
	var int_stat = get_stat("INT")
	var lck = get_stat("LCK")
	return 1.0 + int_stat * 0.03 + lck * 0.01

func calculate_detection_radius(base_radius: float = 100.0, visibility: float = 1.0) -> float:
	var stealth = get_stat("STEALTH")
	return base_radius * (visibility - stealth * 0.04)

# === ИНФОРМАЦИЯ ===
func get_all_stats() -> Dictionary:
	return {
		"base": base_stats.duplicate(),
		"bonuses": equipment_bonuses.duplicate(),
		"combat": {
			"melee_damage": calculate_melee_damage(),
			"ranged_damage": calculate_ranged_damage(),
			"evasion": calculate_evasion(),
			"defense": equipment_bonuses["defense"]
		},
		"skills": {
			"move_speed": calculate_move_speed(),
			"xp_mult": calculate_xp_multiplier()
		}
	}

func get_stats_text() -> String:
	var text = "═══ ХАРАКТЕРИСТИКИ ═══\n"
	text += "💪 Сила: %d | 🤸 Ловкость: %d | 🎯 Меткость: %d\n" % [get_stat("STR"), get_stat("AGI"), get_stat("ACC")]
	text += "🍀 Удача: %d | 🧠 Интеллект: %d | 🗣 Харизма: %d\n" % [get_stat("LCK"), get_stat("INT"), get_stat("Харизма")]
	text += "💻 Электроника: %d | 🔓 Взлом: %d | 🚗 Вождение: %d | 🥷 Скрытность: %d\n" % [get_stat("ELEC"), get_stat("PICK"), get_stat("DRV"), get_stat("STEALTH")]
	text += "\n═══ БОЕВЫЕ ПАРАМЕТРЫ ═══\n"
	text += "⚔ Урон ближний: %d | 🔫 Урон дальний: %d\n" % [calculate_melee_damage(), calculate_ranged_damage()]
	text += "🛡 Защита: %d | 🌀 Уклонение: %d%%\n" % [equipment_bonuses["defense"], calculate_evasion()]
	text += "🏃 Скорость: %.2f tiles/sec\n" % calculate_move_speed()
	return text
