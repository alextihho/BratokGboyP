extends Node

var items = {
	"Кепка": {"type": "helmet", "defense": 1, "price": 50, "description": "Простая кепка. Защита +1"},
	"Шлем": {"type": "helmet", "defense": 5, "price": 300, "description": "Мотоциклетный шлем. Защита +5"},
	"Очки": {"type": "helmet", "defense": 0, "price": 100, "description": "Крутые очки. Стиль +10"},
	"Куртка": {"type": "armor", "defense": 3, "price": 150, "description": "Кожаная куртка. Защита +3"},
	"Кожанка": {"type": "armor", "defense": 5, "price": 200, "description": "Толстая кожанка. Защита +5"},
	"Бронежилет": {"type": "armor", "defense": 15, "price": 800, "description": "Военный бронежилет. Защита +15"},
	"Пальто": {"type": "armor", "defense": 2, "price": 120, "description": "Длинное пальто. Защита +2"},
	"Бита": {"type": "melee", "damage": 5, "strength_req": 2, "price": 100, "description": "Деревянная бита. Урон +5"},
	"Нож": {"type": "melee", "damage": 3, "strength_req": 1, "price": 50, "description": "Складной нож. Урон +3"},
	"Кастет": {"type": "melee", "damage": 4, "strength_req": 1, "price": 75, "description": "Латунный кастет. Урон +4"},
	"ПМ": {"type": "ranged", "damage": 15, "accuracy_req": 3, "price": 500, "description": "Пистолет Макарова. Урон +15"},
	"Обрез": {"type": "ranged", "damage": 25, "accuracy_req": 2, "price": 1200, "description": "Обрез ружья. Урон +25"},
	"Автомат Калашникова": {"type": "ranged", "damage": 35, "accuracy_req": 5, "price": 3000, "description": "АК-47. Урон +35"},
	"Рация": {"type": "gadget", "effect": "связь", "price": 150, "description": "Связь на расстоянии"},
	"Телефон": {"type": "gadget", "effect": "связь", "price": 500, "description": "Мобильный телефон. Престиж!"},
	"GPS-трекер": {"type": "gadget", "effect": "навигация", "price": 800, "description": "Высокие технологии"},
	"Отмычка": {"type": "gadget", "effect": "взлом", "price": 100, "description": "Для взлома замков"},
	"Пиво": {"type": "consumable", "price": 30, "description": "Восстанавливает 10 HP", "effect": "heal", "value": 10},
	"Сигареты": {"type": "consumable", "price": 15, "description": "Снимает стресс", "effect": "stress", "value": 5},
	"Булка": {"type": "consumable", "price": 10, "description": "Восстанавливает 15 HP", "effect": "heal", "value": 15},
	"Шаурма": {"type": "consumable", "price": 50, "description": "Восстанавливает 30 HP", "effect": "heal", "value": 30},
	"Чипсы": {"type": "consumable", "price": 25, "description": "Восстанавливает 5 HP", "effect": "heal", "value": 5},
	"Аптечка": {"type": "consumable", "price": 100, "description": "Восстанавливает 50 HP", "effect": "heal", "value": 50},
	"Сок": {"type": "consumable", "price": 20, "description": "Восстанавливает 10 HP", "effect": "heal", "value": 10},
	"Пачка сигарет": {"type": "consumable", "price": 15, "description": "Пачка сигарет. Снимает стресс", "effect": "stress", "value": 5},
	"Продукты": {"type": "consumable", "price": 25, "description": "Обычная еда. Восстанавливает 20 HP", "effect": "heal", "value": 20}
}

func get_item(item_name: String):
	if item_name in items:
		return items[item_name]
	print("⚠️ Предмет не найден в базе: " + item_name)
	return null

func get_item_price(item_name: String) -> int:
	if item_name in items:
		return items[item_name].get("price", 0)
	return 0

func get_item_type(item_name: String) -> String:
	if item_name in items:
		return items[item_name].get("type", "")
	return ""
