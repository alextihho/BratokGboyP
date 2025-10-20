extends Node

var first_names = [
	"Серёга", "Витёк", "Димон", "Санёк", "Максим",
	"Антон", "Женька", "Артём", "Игорь", "Влад",
	"Денис", "Олег", "Паша", "Юра", "Костя",
	"Миша", "Вадим", "Никита", "Егор", "Гриша"
]

var nicknames = [
	"Бритва", "Шрам", "Молот", "Бык", "Волк",
	"Медведь", "Тихий", "Быстрый", "Крот", "Лис",
	"Барс", "Сокол", "Змей", "Танк", "Призрак",
	"Кулак", "Железный", "Дикий", "Злой", "Хитрый"
]

var backgrounds = [
	"Уличный боец",
	"Бывший спортсмен",
	"Механик",
	"Водитель",
	"Вор-домушник",
	"Бывший военный",
	"Качок из качалки",
	"Хулиган со двора",
	"Барыга с рынка",
	"Грузчик из порта"
]

func generate_random_member(min_level: int = 1, max_level: int = 3) -> Dictionary:
	var level = randi_range(min_level, max_level)
	
	var member = {
		"name": generate_name(),
		"background": backgrounds[randi() % backgrounds.size()],
		"level": level,
		"health": 80 + level * 10,
		"max_health": 80 + level * 10,
		"strength": 5 + level * 2 + randi_range(-1, 2),
		"agility": 5 + level * 2 + randi_range(-1, 2),
		"accuracy": 5 + level * 2 + randi_range(-1, 2),
		"equipment": {
			"helmet": null,
			"armor": null,
			"melee": null,
			"ranged": null,
			"gadget": null
		},
		"inventory": [],
		"pockets": [null, null, null]
	}
	
	if randf() < 0.3:
		member["equipment"]["melee"] = random_starting_weapon()
	
	if randf() < 0.2:
		member["equipment"]["armor"] = random_starting_armor()
	
	return member

func generate_name() -> String:
	var use_nickname = randf() < 0.4
	if use_nickname:
		return nicknames[randi() % nicknames.size()]
	else:
		return first_names[randi() % first_names.size()]

func random_starting_weapon() -> String:
	var weapons = ["Нож", "Бита", "Кастет"]
	return weapons[randi() % weapons.size()]

func random_starting_armor() -> String:
	var armors = ["Куртка", "Кожанка"]
	return armors[randi() % armors.size()]

func calculate_hire_cost(member: Dictionary) -> int:
	var base_cost = 200
	var level_cost = member["level"] * 150
	var stats_cost = (member["strength"] + member["agility"] + member["accuracy"]) * 10
	
	var equipment_bonus = 0
	if member["equipment"]["melee"] != null:
		equipment_bonus += 50
	if member["equipment"]["armor"] != null:
		equipment_bonus += 100
	if member["equipment"]["ranged"] != null:
		equipment_bonus += 200
	
	return base_cost + level_cost + stats_cost + equipment_bonus

func get_member_description(member: Dictionary) -> String:
	var desc = member["name"] + " - " + member["background"] + "\n"
	desc += "Уровень: " + str(member["level"]) + "\n"
	desc += "HP: " + str(member["health"]) + "\n"
	desc += "💪 Сила: " + str(member["strength"]) + " | "
	desc += "🤸 Ловкость: " + str(member["agility"]) + " | "
	desc += "🎯 Меткость: " + str(member["accuracy"]) + "\n"
	
	if member["equipment"]["melee"] != null:
		desc += "⚔️ Оружие: " + member["equipment"]["melee"] + "\n"
	
	if member["equipment"]["armor"] != null:
		desc += "🦺 Броня: " + member["equipment"]["armor"] + "\n"
	
	return desc
