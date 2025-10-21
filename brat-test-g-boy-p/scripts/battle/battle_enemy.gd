# scripts/battle/battle_enemy.gd
extends Node

# ===== ШАБЛОНЫ ВРАГОВ =====
var enemy_templates = {
	"drunkard": {
		"name": "Пьяный",
		"hp": 40,
		"max_hp": 40,
		"damage_min": 3,
		"damage_max": 8
	},
	"gopnik": {
		"name": "Гопник",
		"hp": 60,
		"max_hp": 60,
		"damage_min": 8,
		"damage_max": 15
	},
	"thug": {
		"name": "Хулиган",
		"hp": 80,
		"max_hp": 80,
		"damage_min": 10,
		"damage_max": 18
	},
	"bandit": {
		"name": "Бандит",
		"hp": 100,
		"max_hp": 100,
		"damage_min": 12,
		"damage_max": 22
	},
	"guard": {
		"name": "Охранник",
		"hp": 120,
		"max_hp": 120,
		"damage_min": 15,
		"damage_max": 25
	},
	"boss": {
		"name": "Главарь",
		"hp": 200,
		"max_hp": 200,
		"damage_min": 20,
		"damage_max": 35
	}
}

# ===== ГЕНЕРАЦИЯ ВРАГОВ =====
func generate_enemies(enemy_type: String, count: int = 1) -> Array:
	var result = []
	
	if not enemy_templates.has(enemy_type):
		enemy_type = "gopnik"
	
	var template = enemy_templates[enemy_type]
	
	for i in range(count):
		var enemy = template.duplicate(true)
		
		# Добавляем номер если врагов несколько
		if count > 1:
			enemy["name"] = enemy["name"] + " #" + str(i + 1)
		
		result.append(enemy)
	
	return result

# ===== ГЕНЕРАЦИЯ ПО ЛОКАЦИИ =====
func generate_by_location(location: String) -> Array:
	match location:
		"УЛИЦА":
			return generate_enemies(["gopnik", "thug"][randi() % 2], 1 + randi() % 2)
		"ПОРТ":
			return generate_enemies(["bandit", "guard"][randi() % 2], 1 + randi() % 2)
		"ВОКЗАЛ":
			return generate_enemies("gopnik", 1)
		_:
			return generate_enemies("gopnik", 1)
