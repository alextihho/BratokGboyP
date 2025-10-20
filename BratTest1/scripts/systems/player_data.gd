extends Node

var data = {
	"balance": 150,
	"inventory": [],
	"reputation": 0,
	"completed_quests": [],
	"hp": 100,
	"car_level": 0
}

var active_quests = [
	{"id": "buy_beer", "name": "Купить пиво другу", "location": "ЛАРЁК", "completed": false, "reward": {"money": 50, "rep": 5}},
	{"id": "help_mechanic", "name": "Помочь механику с машиной", "location": "ГАРАЖ", "completed": false, "reward": {"money": 100, "rep": 10, "car": 1}},
	{"id": "steal_market", "name": "Украсть на рынке", "location": "РЫНОК", "completed": false, "reward": {"money": 200, "rep": -5}}
]

signal data_changed()

func _ready():
	print("✅ PlayerData загружен: Баланс " + str(data.balance) + ", Репутация " + str(data.reputation) + ", HP " + str(data.hp))

func spend_money(amount: int) -> bool:
	if data.balance >= amount:
		data.balance -= amount
		data_changed.emit()
		return true
	return false

func earn_money(amount: int):
	data.balance += amount
	data_changed.emit()

func add_item(item: String):
	data.inventory.append(item)
	data_changed.emit()

func remove_item(item: String):
	if item in data.inventory:
		data.inventory.erase(item)
		data_changed.emit()

func change_reputation(delta: int):
	data.reputation = clamp(data.reputation + delta, 0, 100)
	data_changed.emit()
	print("Репутация: " + str(data.reputation))

func change_hp(delta: int):
	data.hp = clamp(data.hp + delta, 0, 100)
	data_changed.emit()
	if data.hp <= 0:
		get_tree().reload_current_scene()

func upgrade_car(level: int):
	data.car_level = clamp(data.car_level + level, 0, 2)
	data_changed.emit()
	print("Машина lvl " + str(data.car_level))

func is_quest_completed(quest_id: String) -> bool:
	for quest in active_quests:
		if quest.id == quest_id:
			return quest.completed
	return false

func complete_quest(quest_id: String) -> bool:
	for quest in active_quests:
		if quest.id == quest_id and not quest.completed:
			quest.completed = true
			data.completed_quests.append(quest.name)
			if quest.reward.has("money"):
				earn_money(quest.reward.money)
			if quest.reward.has("rep"):
				change_reputation(quest.reward.rep)
			if quest.reward.has("car"):
				upgrade_car(quest.reward.car)
			print("✅ Квест завершён!")
			data_changed.emit()
			return true
	return false

func save_data():
	var file = FileAccess.open("user://player_data.save", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func load_data():
	if FileAccess.file_exists("user://player_data.save"):
		var file = FileAccess.open("user://player_data.save", FileAccess.READ)
		data = JSON.parse_string(file.get_as_text())
		file.close()
		data_changed.emit()
