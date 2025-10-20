extends Node

signal district_captured(district_name: String, by_gang: String)
signal influence_changed(district_name: String, gang_name: String, influence: int)

var districts = {}
var rival_gangs = []

func _ready():
	initialize_districts()
	initialize_rival_gangs()
	print("🏙️ Система районов загружена")

func initialize_districts():
	districts = {
		"Центр": {
			"name": "Центр",
			"color": Color(0.7, 0.7, 0.7, 1.0),
			"owner": "Нейтральный",
			"influence": {
				"Игрок": 10,
				"Нейтральный": 80,
				"Волки": 5,
				"Быки": 5
			},
			"businesses": ["ВОКЗАЛ", "РЫНОК"],
			"income": 500,
			"description": "Центральный район города с вокзалом и рынком"
		},
		"Заречье": {
			"name": "Заречье",
			"color": Color(0.3, 0.5, 0.7, 1.0),
			"owner": "Нейтральный",
			"influence": {
				"Игрок": 5,
				"Нейтральный": 70,
				"Волки": 15,
				"Быки": 10
			},
			"businesses": ["ПОРТ"],
			"income": 700,
			"description": "Портовый район за рекой"
		},
		"Окраина": {
			"name": "Окраина",
			"color": Color(0.5, 0.3, 0.3, 1.0),
			"owner": "Быки",
			"influence": {
				"Игрок": 0,
				"Нейтральный": 20,
				"Волки": 20,
				"Быки": 60
			},
			"businesses": ["ОБЩЕЖИТИЕ", "ГАРАЖ"],
			"income": 400,
			"description": "Рабочий район на окраине"
		},
		"Промзона": {
			"name": "Промзона",
			"color": Color(0.4, 0.4, 0.2, 1.0),
			"owner": "Волки",
			"influence": {
				"Игрок": 0,
				"Нейтральный": 15,
				"Волки": 70,
				"Быки": 15
			},
			"businesses": [],
			"income": 800,
			"description": "Промышленная зона города"
		},
		"Спальный": {
			"name": "Спальный",
			"color": Color(0.3, 0.6, 0.3, 1.0),
			"owner": "Нейтральный",
			"influence": {
				"Игрок": 15,
				"Нейтральный": 65,
				"Волки": 10,
				"Быки": 10
			},
			"businesses": ["ЛАРЁК", "УЛИЦА"],
			"income": 300,
			"description": "Жилой спальный район"
		}
	}

func initialize_rival_gangs():
	rival_gangs = [
		{
			"name": "Волки",
			"leader": "Волчара",
			"strength": 100,
			"reputation": 75,
			"aggression": 0.7,
			"color": Color(0.6, 0.6, 0.9, 1.0),
			"description": "Опытная банда с сильным влиянием в Промзоне"
		},
		{
			"name": "Быки",
			"leader": "Бычара",
			"strength": 120,
			"reputation": 65,
			"aggression": 0.9,
			"color": Color(0.9, 0.6, 0.6, 1.0),
			"description": "Агрессивная банда, контролирующая Окраину"
		}
	]

func get_district_by_building(building_name: String) -> String:
	for district_name in districts:
		var district = districts[district_name]
		if building_name in district["businesses"]:
			return district_name
	return "Центр"  # Дефолт

func get_district_owner(district_name: String) -> String:
	if districts.has(district_name):
		return districts[district_name]["owner"]
	return "Нейтральный"

func get_player_influence(district_name: String) -> int:
	if districts.has(district_name):
		return districts[district_name]["influence"].get("Игрок", 0)
	return 0

func add_influence(district_name: String, gang_name: String, amount: int):
	if not districts.has(district_name):
		print("⚠️ Район не найден: " + district_name)
		return
	
	var district = districts[district_name]
	
	if not district["influence"].has(gang_name):
		district["influence"][gang_name] = 0
	
	var old_influence = district["influence"][gang_name]
	district["influence"][gang_name] += amount
	district["influence"][gang_name] = clamp(district["influence"][gang_name], 0, 100)
	
	print("📊 Влияние %s в %s: %d → %d (%+d)" % [gang_name, district_name, old_influence, district["influence"][gang_name], amount])
	
	# Перераспределяем влияние
	var total = 0
	for g in district["influence"]:
		total += district["influence"][g]
	
	if total > 100:
		var excess = total - 100
		# Отнимаем у других пропорционально
		var others_count = district["influence"].size() - 1
		if others_count > 0:
			for g in district["influence"]:
				if g != gang_name:
					var reduction = int(excess / others_count)
					district["influence"][g] = max(0, district["influence"][g] - reduction)
	
	# Проверяем смену владельца
	check_ownership_change(district_name)
	
	influence_changed.emit(district_name, gang_name, district["influence"][gang_name])

func check_ownership_change(district_name: String):
	var district = districts[district_name]
	var max_influence = 0
	var new_owner = "Нейтральный"
	
	for gang_name in district["influence"]:
		if district["influence"][gang_name] > max_influence:
			max_influence = district["influence"][gang_name]
			new_owner = gang_name
	
	# Для захвата нужно минимум 50% влияния
	if max_influence >= 50 and new_owner != district["owner"]:
		var old_owner = district["owner"]
		district["owner"] = new_owner
		district_captured.emit(district_name, new_owner)
		print("🏴 Район '%s' захвачен! %s → %s" % [district_name, old_owner, new_owner])

func get_district_income(district_name: String, gang_name: String) -> int:
	if not districts.has(district_name):
		return 0
	
	var district = districts[district_name]
	
	# Доход зависит от влияния
	var influence = district["influence"].get(gang_name, 0)
	var base_income = district["income"]
	
	return int(base_income * (influence / 100.0))

func get_total_player_income() -> int:
	var total = 0
	for district_name in districts:
		total += get_district_income(district_name, "Игрок")
	return total

func get_district_info(district_name: String) -> String:
	if not districts.has(district_name):
		return "Неизвестный район"
	
	var district = districts[district_name]
	var info = "📍 " + district["name"] + "\n"
	info += district.get("description", "Нет описания") + "\n\n"
	info += "Владелец: " + district["owner"] + "\n"
	info += "Доход: " + str(district["income"]) + " руб./день\n"
	info += "\nВлияние:\n"
	
	# Сортируем по убыванию влияния
	var influence_list = []
	for gang in district["influence"]:
		influence_list.append({"name": gang, "value": district["influence"][gang]})
	
	influence_list.sort_custom(func(a, b): return a["value"] > b["value"])
	
	for item in influence_list:
		info += "  " + item["name"] + ": " + str(item["value"]) + "%\n"
	
	return info

func get_all_districts() -> Array:
	var result = []
	for district_name in districts:
		result.append(districts[district_name])
	return result

func get_rival_gangs() -> Array:
	return rival_gangs

# Симуляция действий соперничающих банд
func simulate_rival_actions():
	for gang in rival_gangs:
		# Случайный шанс на действие
		if randf() < gang["aggression"] * 0.1:  # 7-9% шанс за ход
			# Выбираем случайный район
			var district_names = districts.keys()
			var target_district = district_names[randi() % district_names.size()]
			
			# Пытаемся увеличить влияние
			var influence_gain = randi_range(2, 5)
			add_influence(target_district, gang["name"], influence_gain)
			
			print("🎲 Банда '%s' усилила влияние в районе '%s' на %d%%" % [gang["name"], target_district, influence_gain])
