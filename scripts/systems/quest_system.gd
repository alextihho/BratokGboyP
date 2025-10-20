# quest_system.gd (ИСПРАВЛЕНО - layer 200, кнопка выше)
extends Node

signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)

var active_quests: Array = []
var completed_quests: Array = []
var available_quests: Dictionary = {}

var player_stats_data = {
	"total_earned": 0,
	"battles_won": 0,
	"items_bought": []
}

func _ready():
	initialize_quests()
	print("📜 Система квестов загружена")

func initialize_quests():
	available_quests = {
		"first_money": {
			"id": "first_money",
			"name": "Первые деньги",
			"description": "Накопи 500 рублей",
			"type": "collect",
			"target": 500,
			"current": 0,
			"reward": {"money": 100, "reputation": 5}
		},
		"buy_weapon": {
			"id": "buy_weapon",
			"name": "Вооружиться",
			"description": "Купи любое оружие",
			"type": "item",
			"target_items": ["Бита", "Нож", "ПМ", "Обрез"],
			"reward": {"money": 150, "reputation": 10}
		},
		"win_fights": {
			"id": "win_fights",
			"name": "Первая кровь",
			"description": "Победи в 3 боях",
			"type": "combat",
			"target": 3,
			"current": 0,
			"reward": {"money": 300, "reputation": 15}
		},
		"earn_1000": {
			"id": "earn_1000",
			"name": "Деловой подход",
			"description": "Заработай 1000 рублей",
			"type": "earn",
			"target": 1000,
			"current": 0,
			"reward": {"money": 200, "reputation": 10}
		},
		"win_10_fights": {
			"id": "win_10_fights",
			"name": "Боец",
			"description": "Победи в 10 боях",
			"type": "combat",
			"target": 10,
			"current": 0,
			"reward": {"money": 500, "reputation": 20}
		}
	}

func start_quest(quest_id: String) -> bool:
	if quest_id in completed_quests:
		print("⚠️ Квест уже выполнен: " + quest_id)
		return false
	
	for quest in active_quests:
		if quest["id"] == quest_id:
			print("⚠️ Квест уже активен: " + quest_id)
			return false
	
	if quest_id not in available_quests:
		print("❌ Квест не найден: " + quest_id)
		return false
	
	var quest = available_quests[quest_id].duplicate(true)
	active_quests.append(quest)
	quest_started.emit(quest_id)
	print("📜 Квест начат: " + quest["name"])
	return true

func check_quest_progress(quest_type: String, data: Dictionary = {}):
	for quest in active_quests:
		if quest["type"] == quest_type:
			update_quest(quest, data)

func update_quest(quest: Dictionary, data: Dictionary):
	match quest["type"]:
		"collect":
			if data.has("balance"):
				quest["current"] = data["balance"]
				if quest["current"] >= quest["target"]:
					complete_quest(quest["id"])
		"earn":
			if data.has("earned"):
				player_stats_data["total_earned"] += data["earned"]
				quest["current"] = player_stats_data["total_earned"]
				if quest["current"] >= quest["target"]:
					complete_quest(quest["id"])
		"combat":
			if data.has("victory") and data["victory"]:
				quest["current"] += 1
				player_stats_data["battles_won"] += 1
				print("🎯 Квест прогресс: " + quest["name"] + " - " + str(quest["current"]) + "/" + str(quest["target"]))
				if quest["current"] >= quest["target"]:
					complete_quest(quest["id"])
		"item":
			if data.has("inventory"):
				for item in quest["target_items"]:
					if item in data["inventory"]:
						complete_quest(quest["id"])
						break
		"visit":
			if data.has("location"):
				if quest.has("target_location") and data["location"] == quest["target_location"]:
					complete_quest(quest["id"])
		"reputation":
			if data.has("reputation"):
				if data["reputation"] >= quest["target"]:
					complete_quest(quest["id"])

func complete_quest(quest_id: String):
	var quest_index = -1
	var quest_data = null
	
	for i in range(active_quests.size()):
		if active_quests[i]["id"] == quest_id:
			quest_index = i
			quest_data = active_quests[i]
			break
	
	if quest_index == -1:
		return
	
	active_quests.remove_at(quest_index)
	
	var completed_quest_info = {
		"id": quest_id,
		"name": quest_data["name"],
		"description": quest_data["description"],
		"reward": quest_data["reward"]
	}
	completed_quests.append(completed_quest_info)
	
	quest_completed.emit(quest_id)
	
	print("✅ Квест выполнен: " + quest_data["name"])
	
	if quest_id == "win_fights":
		start_quest("win_10_fights")
	elif quest_id == "first_money":
		start_quest("earn_1000")

func get_active_quests() -> Array:
	return active_quests

func get_completed_quests() -> Array:
	return completed_quests

func get_quest_progress_text(quest: Dictionary) -> String:
	match quest["type"]:
		"collect":
			return str(quest.get("current", 0)) + "/" + str(quest["target"]) + " руб."
		"earn":
			return str(quest.get("current", 0)) + "/" + str(quest["target"]) + " руб. заработано"
		"combat":
			return str(quest.get("current", 0)) + "/" + str(quest["target"]) + " побед"
		"item":
			return "Получить: " + ", ".join(quest["target_items"])
		"visit":
			return "Посетить: " + quest.get("target_location", "")
		"reputation":
			return "Репутация: " + str(quest.get("current", 0)) + "/" + str(quest["target"])
		_:
			return "В процессе..."

func show_quests_menu(main_node: Node):
	var quest_menu = CanvasLayer.new()
	quest_menu.name = "QuestMenu"
	quest_menu.layer = 200  # ✅ КРИТИЧНО! ВЫШЕ сетки (5) и UI (50)
	main_node.add_child(quest_menu)
	
	# ✅ Overlay
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.position = Vector2(0, 0)
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	quest_menu.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(700, 1060)  # ✅ Уменьшена высота для кнопки
	bg.position = Vector2(10, 140)
	bg.color = Color(0.05, 0.05, 0.05, 0.95)
	quest_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "📜 КВЕСТЫ"
	title.position = Vector2(280, 160)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	quest_menu.add_child(title)
	
	var active_label = Label.new()
	active_label.text = "АКТИВНЫЕ:"
	active_label.position = Vector2(30, 220)
	active_label.add_theme_font_size_override("font_size", 24)
	active_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	quest_menu.add_child(active_label)
	
	var y_pos = 270
	
	if active_quests.size() == 0:
		var no_quests = Label.new()
		no_quests.text = "Нет активных квестов"
		no_quests.position = Vector2(30, y_pos)
		no_quests.add_theme_font_size_override("font_size", 16)
		no_quests.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
		quest_menu.add_child(no_quests)
		y_pos += 50
	else:
		for quest in active_quests:
			var quest_bg = ColorRect.new()
			quest_bg.size = Vector2(680, 120)
			quest_bg.position = Vector2(20, y_pos)
			quest_bg.color = Color(0.2, 0.25, 0.2, 1.0)
			quest_menu.add_child(quest_bg)
			
			var quest_name = Label.new()
			quest_name.text = "📌 " + quest["name"]
			quest_name.position = Vector2(30, y_pos + 10)
			quest_name.add_theme_font_size_override("font_size", 20)
			quest_name.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
			quest_menu.add_child(quest_name)
			
			var quest_desc = Label.new()
			quest_desc.text = quest["description"]
			quest_desc.position = Vector2(30, y_pos + 40)
			quest_desc.add_theme_font_size_override("font_size", 16)
			quest_desc.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
			quest_menu.add_child(quest_desc)
			
			var quest_progress = Label.new()
			quest_progress.text = get_quest_progress_text(quest)
			quest_progress.position = Vector2(30, y_pos + 70)
			quest_progress.add_theme_font_size_override("font_size", 14)
			quest_progress.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 1.0))
			quest_menu.add_child(quest_progress)
			
			var reward_text = "💰 " + str(quest["reward"].get("money", 0)) + " руб."
			if quest["reward"].has("reputation"):
				reward_text += " | ⭐ +" + str(quest["reward"]["reputation"])
			
			var quest_reward = Label.new()
			quest_reward.text = "Награда: " + reward_text
			quest_reward.position = Vector2(30, y_pos + 95)
			quest_reward.add_theme_font_size_override("font_size", 14)
			quest_reward.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1.0))
			quest_menu.add_child(quest_reward)
			
			y_pos += 140
	
	var completed_header_bg = ColorRect.new()
	completed_header_bg.size = Vector2(680, 50)
	completed_header_bg.position = Vector2(20, y_pos + 20)
	completed_header_bg.color = Color(0.15, 0.15, 0.15, 1.0)
	quest_menu.add_child(completed_header_bg)
	
	var completed_label = Button.new()
	completed_label.custom_minimum_size = Vector2(680, 50)
	completed_label.position = Vector2(20, y_pos + 20)
	completed_label.text = "▼ ЗАВЕРШЕНО: " + str(completed_quests.size())
	
	var style_completed = StyleBoxFlat.new()
	style_completed.bg_color = Color(0.2, 0.2, 0.2, 1.0)
	completed_label.add_theme_stylebox_override("normal", style_completed)
	
	var style_completed_hover = StyleBoxFlat.new()
	style_completed_hover.bg_color = Color(0.3, 0.3, 0.3, 1.0)
	completed_label.add_theme_stylebox_override("hover", style_completed_hover)
	
	completed_label.add_theme_font_size_override("font_size", 20)
	completed_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	
	var completed_container = VBoxContainer.new()
	completed_container.position = Vector2(20, y_pos + 80)
	completed_container.name = "CompletedContainer"
	completed_container.visible = false
	quest_menu.add_child(completed_container)
	
	for completed in completed_quests:
		var cq_bg = ColorRect.new()
		cq_bg.custom_minimum_size = Vector2(680, 100)
		cq_bg.color = Color(0.15, 0.2, 0.15, 1.0)
		completed_container.add_child(cq_bg)
		
		var cq_name = Label.new()
		cq_name.text = "✅ " + completed["name"]
		cq_name.position = Vector2(10, 10)
		cq_name.add_theme_font_size_override("font_size", 18)
		cq_name.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5, 1.0))
		cq_bg.add_child(cq_name)
		
		var cq_desc = Label.new()
		cq_desc.text = completed["description"]
		cq_desc.position = Vector2(10, 40)
		cq_desc.add_theme_font_size_override("font_size", 14)
		cq_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
		cq_bg.add_child(cq_desc)
		
		var cq_reward = Label.new()
		var reward_text = "Получено: 💰 " + str(completed["reward"].get("money", 0)) + " руб."
		if completed["reward"].has("reputation"):
			reward_text += " | ⭐ +" + str(completed["reward"]["reputation"])
		cq_reward.text = reward_text
		cq_reward.position = Vector2(10, 70)
		cq_reward.add_theme_font_size_override("font_size", 13)
		cq_reward.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6, 1.0))
		cq_bg.add_child(cq_reward)
	
	completed_label.pressed.connect(func():
		completed_container.visible = !completed_container.visible
		if completed_container.visible:
			completed_label.text = "▲ ЗАВЕРШЕНО: " + str(completed_quests.size())
		else:
			completed_label.text = "▼ ЗАВЕРШЕНО: " + str(completed_quests.size())
	)
	
	quest_menu.add_child(completed_label)
	
	# ✅ ИСПРАВЛЕНО: Кнопка "Закрыть" поднята выше (y=1110)
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(680, 60)
	close_btn.position = Vector2(20, 1110)  # ✅ Было 1160
	close_btn.text = "ЗАКРЫТЬ"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)
	
	close_btn.add_theme_font_size_override("font_size", 24)
	close_btn.pressed.connect(func(): quest_menu.queue_free())
	
	quest_menu.add_child(close_btn)
