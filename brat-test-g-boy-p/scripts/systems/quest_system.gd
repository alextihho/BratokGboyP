# quest_system.gd (ИСПРАВЛЕНО - КВЕСТЫ РАБОТАЮТ!)
extends Node

signal quest_completed(quest_id: String)

var available_quests = {}
var active_quests = []
var completed_quests = []

func _ready():
	initialize_quests()
	print("📜 QuestSystem готов")

func initialize_quests():
	"""Инициализация всех доступных квестов"""
	available_quests = {
		"first_fight": {
			"title": "Первый бой",
			"description": "Победи в бою",
			"type": "combat",
			"target": 1,
			"reward": {"money": 100, "reputation": 10}
		},
		"win_fights": {
			"title": "Победить в боях",
			"description": "Победите в 3 боях",
			"type": "combat",
			"target": 3,
			"reward": {"money": 300, "reputation": 20}
		},
		"earn_money": {
			"title": "Заработать деньги",
			"description": "Накопи 500 рублей",
			"type": "collect_money",
			"target": 500,
			"reward": {"money": 200, "reputation": 5}
		},
		"first_money": {
			"title": "Первые деньги",
			"description": "Заработайте 200 рублей",
			"type": "collect_money",
			"target": 200,
			"reward": {"money": 50, "reputation": 5}
		},
		"recruit_gang": {
			"title": "Собрать банду",
			"description": "Наймите 2 бойцов",
			"type": "recruit",
			"target": 2,
			"reward": {"money": 300, "reputation": 15}
		},
		"capture_district": {
			"title": "Захватить район",
			"description": "Захватите любой район",
			"type": "capture",
			"target": 1,
			"reward": {"money": 500, "reputation": 25}
		},
		"buy_weapon": {
			"title": "Вооружиться",
			"description": "Купите любое оружие (бита, нож, ПМ)",
			"type": "buy_item",
			"target": 1,
			"reward": {"money": 150, "reputation": 5}
		},
		"visit_locations": {
			"title": "Исследователь",
			"description": "Посетите 5 разных локаций",
			"type": "visit_location",
			"target": 5,
			"reward": {"money": 200, "reputation": 10}
		}
	}
	
	print("📜 Квесты инициализированы: %d доступно" % available_quests.size())

# ✅ НОВАЯ ФУНКЦИЯ: Запуск квеста
func start_quest(quest_id: String):
	"""Активирует квест если он ещё не активен"""
	if not available_quests.has(quest_id):
		print("⚠️ Квест не существует: " + quest_id)
		return
	
	# Проверяем не активен ли уже
	for quest_data in active_quests:
		if quest_data.get("id", "") == quest_id:
			print("⚠️ Квест уже активен: " + quest_id)
			return
	
	# Активируем
	active_quests.append({
		"id": quest_id,
		"progress": 0,
		"completed": false
	})
	
	print("✅ Квест запущен: " + quest_id)

# ✅ ИСПРАВЛЕНО: Правильная обработка прогресса квестов
func progress_quest(quest_id: String, amount: int = 1):
	"""Увеличивает прогресс квеста (универсальный метод)"""
	for quest_data in active_quests:
		if quest_data.get("id", "") == quest_id:
			if quest_data.get("completed", false):
				return  # Уже завершён
			
			quest_data["progress"] = quest_data.get("progress", 0) + amount
			
			if available_quests.has(quest_id):
				var quest_info = available_quests[quest_id]
				var target = quest_info.get("target", 1)
				
				print("📜 Квест '%s': %d/%d (+%d)" % [
					quest_info.get("title", ""),
					quest_data["progress"],
					target,
					amount
				])
				
				# Проверяем завершение
				if quest_data["progress"] >= target:
					quest_data["completed"] = true
					completed_quests.append(quest_id)
					print("✅ КВЕСТ ВЫПОЛНЕН: %s" % quest_info.get("title", ""))
					emit_signal("quest_completed", quest_id)
			
			break

# ✅ ИСПРАВЛЕНО: Универсальный метод обновления (алиас для progress_quest)
func update_quest(quest_id: String, amount: int = 1):
	"""Алиас для progress_quest (для совместимости)"""
	progress_quest(quest_id, amount)

func show_quests_menu(main_node):
	"""Отображение меню квестов"""
	var quest_menu = CanvasLayer.new()
	quest_menu.name = "QuestMenu"
	quest_menu.layer = 200
	main_node.add_child(quest_menu)
	
	# Overlay
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	quest_menu.add_child(overlay)
	
	# Фон
	var bg = ColorRect.new()
	bg.size = Vector2(700, 1000)
	bg.position = Vector2(10, 140)
	bg.color = Color(0.05, 0.05, 0.05, 0.95)
	quest_menu.add_child(bg)
	
	# Заголовок
	var title = Label.new()
	title.text = "📜 КВЕСТЫ"
	title.position = Vector2(280, 160)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	quest_menu.add_child(title)
	
	var y_pos = 220
	
	# Проверяем наличие квестов
	if active_quests.size() == 0:
		var no_quests = Label.new()
		no_quests.text = "Нет активных квестов"
		no_quests.position = Vector2(250, 400)
		no_quests.add_theme_font_size_override("font_size", 20)
		no_quests.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
		quest_menu.add_child(no_quests)
	else:
		# Отображаем активные квесты
		for quest_data in active_quests:
			var quest_id = quest_data.get("id", "")
			
			if not available_quests.has(quest_id):
				print("⚠️ Квест не найден: " + quest_id)
				continue
			
			var quest_info = available_quests[quest_id]
			
			# Фон квеста
			var quest_bg = ColorRect.new()
			quest_bg.size = Vector2(680, 140)
			quest_bg.position = Vector2(20, y_pos)
			
			if quest_data.get("completed", false):
				quest_bg.color = Color(0.2, 0.3, 0.2, 1.0)  # Зелёный для завершённых
			else:
				quest_bg.color = Color(0.15, 0.15, 0.2, 1.0)
			
			quest_menu.add_child(quest_bg)
			
			# Название квеста
			var quest_title = Label.new()
			quest_title.text = "📌 " + quest_info.get("title", "Квест")
			if quest_data.get("completed", false):
				quest_title.text += " ✅"
			quest_title.position = Vector2(30, y_pos + 10)
			quest_title.add_theme_font_size_override("font_size", 20)
			quest_title.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
			quest_menu.add_child(quest_title)
			
			# Описание
			var quest_desc = Label.new()
			quest_desc.text = quest_info.get("description", "")
			quest_desc.position = Vector2(30, y_pos + 40)
			quest_desc.add_theme_font_size_override("font_size", 16)
			quest_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
			quest_menu.add_child(quest_desc)
			
			# Прогресс
			var progress = quest_data.get("progress", 0)
			var target = quest_info.get("target", 1)
			var progress_text = Label.new()
			progress_text.text = "Прогресс: %d/%d" % [progress, target]
			progress_text.position = Vector2(30, y_pos + 70)
			progress_text.add_theme_font_size_override("font_size", 16)
			
			if progress >= target:
				progress_text.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
			else:
				progress_text.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
			
			quest_menu.add_child(progress_text)
			
			# Награда
			var reward = quest_info.get("reward", {})
			var reward_text = "Награда: "
			if reward.has("money"):
				reward_text += str(reward["money"]) + "р "
			if reward.has("reputation"):
				reward_text += "+" + str(reward["reputation"]) + " репутации"
			
			var reward_label = Label.new()
			reward_label.text = reward_text
			reward_label.position = Vector2(30, y_pos + 100)
			reward_label.add_theme_font_size_override("font_size", 14)
			reward_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1.0))
			quest_menu.add_child(reward_label)
			
			y_pos += 160
	
	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(680, 50)
	close_btn.position = Vector2(20, 1070)
	close_btn.text = "ЗАКРЫТЬ"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): quest_menu.queue_free())
	
	quest_menu.add_child(close_btn)

func check_quest_conditions(main_node):
	"""Проверка условий квестов (вызывается периодически)"""
	for quest_data in active_quests:
		if quest_data.get("completed", false):
			continue
		
		var quest_id = quest_data.get("id", "")
		if not available_quests.has(quest_id):
			continue
		
		var quest_info = available_quests[quest_id]
		var quest_type = quest_info.get("type", "")
		
		match quest_type:
			"collect_money":
				var current_money = main_node.player_data.get("balance", 0)
				var target = quest_info.get("target", 1)
				if current_money >= target:
					quest_data["progress"] = target
					if not quest_data.get("completed", false):
						quest_data["completed"] = true
						completed_quests.append(quest_id)
						emit_signal("quest_completed", quest_id)
			
			"recruit":
				var gang_size = main_node.gang_members.size() - 1  # Минус главный
				var target = quest_info.get("target", 1)
				quest_data["progress"] = gang_size
				if gang_size >= target:
					if not quest_data.get("completed", false):
						quest_data["completed"] = true
						completed_quests.append(quest_id)
						emit_signal("quest_completed", quest_id)

func get_active_quests() -> Array:
	return active_quests

func get_completed_quests() -> Array:
	return completed_quests

func add_quest(quest_id: String):
	"""Добавление нового квеста (алиас для start_quest)"""
	start_quest(quest_id)
