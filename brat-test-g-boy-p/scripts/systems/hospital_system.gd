extends Node

signal treatment_completed(health_restored: int)

var player_stats
var items_db

# Типы лечения
var treatments = {
	"bandage": {
		"name": "Перевязка",
		"icon": "🩹",
		"health_restore": 20,
		"cost": 50,
		"duration": 1.0,
		"description": "Быстрая перевязка ран"
	},
	"firstaid": {
		"name": "Первая помощь",
		"icon": "💊",
		"health_restore": 40,
		"cost": 150,
		"duration": 2.0,
		"description": "Оказание первой помощи"
	},
	"treatment": {
		"name": "Лечение",
		"icon": "🏥",
		"health_restore": 70,
		"cost": 300,
		"duration": 3.0,
		"description": "Полноценное лечение"
	},
	"surgery": {
		"name": "Операция",
		"icon": "⚕️",
		"health_restore": 100,
		"cost": 800,
		"duration": 5.0,
		"description": "Серьёзная операция - полное восстановление"
	}
}

var current_treatment = null
var treatment_timer: Timer = null

func _ready():
	player_stats = get_node_or_null("/root/PlayerStats")
	items_db = get_node_or_null("/root/ItemsDB")
	print("🏥 Система больниц загружена")

# Показать меню больницы
func show_hospital_menu(main_node: Node, player_data: Dictionary, gang_members: Array = []):
	# Если есть члены банды - сначала выбираем кого лечить
	if gang_members.size() > 1:  # Больше 1 значит есть не только главный игрок
		show_character_selection(main_node, player_data, gang_members)
	else:
		# Если только главный игрок - сразу показываем меню лечения
		show_treatment_menu(main_node, player_data, 0, gang_members)

# ✅ НОВАЯ ФУНКЦИЯ: Выбор персонажа для лечения
func show_character_selection(main_node: Node, player_data: Dictionary, gang_members: Array):
	var selection_menu = CanvasLayer.new()
	selection_menu.layer = 100
	selection_menu.name = "CharacterSelectionMenu"
	main_node.add_child(selection_menu)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.position = Vector2(0, 0)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	selection_menu.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(700, 1100)
	bg.position = Vector2(10, 90)
	bg.color = Color(0.05, 0.05, 0.1, 0.95)
	selection_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "🏥 ВЫБЕРИТЕ ПАЦИЕНТА"
	title.position = Vector2(200, 110)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 1.0))
	selection_menu.add_child(title)
	
	var hint = Label.new()
	hint.text = "Кого вы хотите вылечить?"
	hint.position = Vector2(230, 170)
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	selection_menu.add_child(hint)
	
	var y_pos = 230
	
	for i in range(gang_members.size()):
		var member = gang_members[i]
		var current_hp = member.get("hp", member.get("health", 100))
		var max_hp = member.get("max_hp", 100)
		
		# Если это главный игрок - берём HP из player_data
		if i == 0:
			current_hp = player_data.get("health", 100)
			max_hp = 100
		
		var hp_percent = (float(current_hp) / float(max_hp)) * 100
		
		var card_bg = ColorRect.new()
		card_bg.size = Vector2(680, 120)
		card_bg.position = Vector2(20, y_pos)
		
		var health_color = Color.GREEN
		if hp_percent < 30:
			health_color = Color.RED
			card_bg.color = Color(0.25, 0.1, 0.1, 1.0)
		elif hp_percent < 60:
			health_color = Color.YELLOW
			card_bg.color = Color(0.2, 0.2, 0.1, 1.0)
		else:
			card_bg.color = Color(0.1, 0.2, 0.15, 1.0)
		
		selection_menu.add_child(card_bg)
		
		var name_label = Label.new()
		name_label.text = member.get("name", "Боец " + str(i))
		if i == 0:
			name_label.text += " (ВЫ)"
		name_label.position = Vector2(40, y_pos + 15)
		name_label.add_theme_font_size_override("font_size", 22)
		name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
		selection_menu.add_child(name_label)
		
		var hp_label = Label.new()
		hp_label.text = "❤️ %d/%d HP (%d%%)" % [current_hp, max_hp, int(hp_percent)]
		hp_label.position = Vector2(40, y_pos + 50)
		hp_label.add_theme_font_size_override("font_size", 18)
		hp_label.add_theme_color_override("font_color", health_color)
		selection_menu.add_child(hp_label)
		
		# HP бар
		var hp_bar_bg = ColorRect.new()
		hp_bar_bg.size = Vector2(300, 20)
		hp_bar_bg.position = Vector2(40, y_pos + 80)
		hp_bar_bg.color = Color(0.2, 0.2, 0.2, 1.0)
		selection_menu.add_child(hp_bar_bg)
		
		var hp_bar_fill = ColorRect.new()
		hp_bar_fill.size = Vector2(300 * (hp_percent / 100.0), 20)
		hp_bar_fill.position = Vector2(40, y_pos + 80)
		hp_bar_fill.color = health_color
		selection_menu.add_child(hp_bar_fill)
		
		# Кнопка выбора
		var select_btn = Button.new()
		select_btn.custom_minimum_size = Vector2(250, 60)
		select_btn.position = Vector2(430, y_pos + 30)
		
		if hp_percent >= 100:
			select_btn.text = "ЗДОРОВ"
			select_btn.disabled = true
		else:
			select_btn.text = "ЛЕЧИТЬ"
		
		var style_select = StyleBoxFlat.new()
		if select_btn.disabled:
			style_select.bg_color = Color(0.3, 0.3, 0.3, 1.0)
		else:
			style_select.bg_color = Color(0.2, 0.6, 0.8, 1.0)
		select_btn.add_theme_stylebox_override("normal", style_select)
		
		var style_select_hover = StyleBoxFlat.new()
		style_select_hover.bg_color = Color(0.3, 0.7, 0.9, 1.0)
		select_btn.add_theme_stylebox_override("hover", style_select_hover)
		
		select_btn.add_theme_font_size_override("font_size", 20)
		
		var member_index = i
		select_btn.pressed.connect(func():
			selection_menu.queue_free()
			show_treatment_menu(main_node, player_data, member_index, gang_members)
		)
		selection_menu.add_child(select_btn)
		
		y_pos += 140
	
	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(680, 50)
	close_btn.position = Vector2(20, 1100)
	close_btn.text = "ЗАКРЫТЬ"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): 
		selection_menu.queue_free()
		main_node.show_location_menu("БОЛЬНИЦА")
	)
	
	selection_menu.add_child(close_btn)

# ✅ ПЕРЕИМЕНОВАННАЯ ФУНКЦИЯ: Меню лечения для выбранного персонажа
func show_treatment_menu(main_node: Node, player_data: Dictionary, member_index: int, gang_members: Array):
	var hospital_menu = CanvasLayer.new()
	hospital_menu.layer = 100  # ✅ Поверх всего
	hospital_menu.name = "HospitalMenu"
	main_node.add_child(hospital_menu)
	
	# Определяем лечащегося персонажа
	var current_member = null
	var member_name = "Вы"
	var current_hp = player_data.get("health", 100)
	var max_hp = 100
	
	if member_index == 0:
		# Главный игрок
		current_hp = player_data.get("health", 100)
		member_name = "Вы"
	elif member_index < gang_members.size():
		# Член банды
		current_member = gang_members[member_index]
		member_name = current_member.get("name", "Боец")
		current_hp = current_member.get("hp", 100)
		max_hp = current_member.get("max_hp", 100)
	
	# ✅ Overlay на весь экран - блокирует клики по другим элементам
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.position = Vector2(0, 0)
	overlay.color = Color(0, 0, 0, 0.8)  # Полупрозрачный черный
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # Блокирует клики
	hospital_menu.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(700, 1100)
	bg.position = Vector2(10, 90)  # ✅ Выше, чтобы не перекрывалось нижним меню
	bg.color = Color(0.05, 0.05, 0.1, 0.95)
	hospital_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "🏥 БОЛЬНИЦА"
	title.position = Vector2(270, 110)  # ✅ Скорректировано
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 1.0))
	hospital_menu.add_child(title)
	
	# ✅ НОВОЕ: Имя пациента
	var patient_label = Label.new()
	patient_label.text = "Пациент: " + member_name
	patient_label.position = Vector2(250, 150)
	patient_label.add_theme_font_size_override("font_size", 20)
	patient_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	hospital_menu.add_child(patient_label)
	
	# Информация о здоровье
	var hp_percent = (float(current_hp) / float(max_hp)) * 100
	
	var health_info = Label.new()
	health_info.text = "Здоровье: " + str(current_hp) + "/" + str(max_hp) + " (" + str(int(hp_percent)) + "%)"
	health_info.position = Vector2(220, 185)  # ✅ Скорректировано
	health_info.add_theme_font_size_override("font_size", 18)
	
	var health_color = Color.GREEN
	if hp_percent < 30:
		health_color = Color.RED
	elif hp_percent < 60:
		health_color = Color.YELLOW
	
	health_info.add_theme_color_override("font_color", health_color)
	hospital_menu.add_child(health_info)
	
	# Прогресс-бар здоровья
	var hp_bar_bg = ColorRect.new()
	hp_bar_bg.size = Vector2(660, 30)
	hp_bar_bg.position = Vector2(30, 225)  # ✅ Скорректировано
	hp_bar_bg.color = Color(0.2, 0.2, 0.2, 1.0)
	hospital_menu.add_child(hp_bar_bg)
	
	var hp_bar_fill = ColorRect.new()
	hp_bar_fill.size = Vector2(660 * (hp_percent / 100.0), 30)
	hp_bar_fill.position = Vector2(30, 225)  # ✅ Скорректировано
	hp_bar_fill.color = health_color
	hospital_menu.add_child(hp_bar_fill)
	
	var hp_bar_text = Label.new()
	hp_bar_text.text = str(current_hp) + " HP"
	hp_bar_text.position = Vector2(330, 230)  # ✅ Скорректировано
	hp_bar_text.add_theme_font_size_override("font_size", 16)
	hp_bar_text.add_theme_color_override("font_color", Color.BLACK)
	hospital_menu.add_child(hp_bar_text)
	
	# Проверка, лечится ли игрок сейчас
	if current_treatment != null:
		var treating_label = Label.new()
		treating_label.text = "⏳ Лечение в процессе..."
		treating_label.position = Vector2(250, 275)  # ✅ Скорректировано
		treating_label.add_theme_font_size_override("font_size", 18)
		treating_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
		hospital_menu.add_child(treating_label)
	
	# Список видов лечения
	var y_pos = 315  # ✅ Скорректировано
	
	# Подсказка
	var hint = Label.new()
	hint.text = "Выберите вид лечения:"
	hint.position = Vector2(30, y_pos)
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	hospital_menu.add_child(hint)
	y_pos += 40
	
	for treatment_key in treatments:
		var treatment = treatments[treatment_key]
		
		# Проверяем, нужно ли лечение
		var needed_hp = max_hp - current_hp
		var is_useful = needed_hp > 0
		
		var treatment_bg = ColorRect.new()
		treatment_bg.size = Vector2(680, 130)
		treatment_bg.position = Vector2(20, y_pos)
		
		if is_useful:
			treatment_bg.color = Color(0.15, 0.2, 0.25, 1.0)
		else:
			treatment_bg.color = Color(0.1, 0.1, 0.1, 1.0)
		
		hospital_menu.add_child(treatment_bg)
		
		var icon = Label.new()
		icon.text = treatment["icon"]
		icon.position = Vector2(40, y_pos + 15)
		icon.add_theme_font_size_override("font_size", 48)
		hospital_menu.add_child(icon)
		
		var name_label = Label.new()
		name_label.text = treatment["name"]
		name_label.position = Vector2(120, y_pos + 15)
		name_label.add_theme_font_size_override("font_size", 22)
		name_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 1.0))
		hospital_menu.add_child(name_label)
		
		var desc = Label.new()
		desc.text = treatment["description"]
		desc.position = Vector2(120, y_pos + 45)
		desc.add_theme_font_size_override("font_size", 14)
		desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
		hospital_menu.add_child(desc)
		
		var restore = Label.new()
		restore.text = "❤️ Восстановление: +" + str(treatment["health_restore"]) + " HP"
		restore.position = Vector2(120, y_pos + 70)
		restore.add_theme_font_size_override("font_size", 16)
		restore.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
		hospital_menu.add_child(restore)
		
		var cost = Label.new()
		cost.text = "💰 Стоимость: " + str(treatment["cost"]) + " руб."
		cost.position = Vector2(120, y_pos + 95)
		cost.add_theme_font_size_override("font_size", 16)
		cost.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
		hospital_menu.add_child(cost)
		
		# Кнопка лечения
		var treat_btn = Button.new()
		treat_btn.custom_minimum_size = Vector2(160, 50)
		treat_btn.position = Vector2(520, y_pos + 40)
		treat_btn.text = "ЛЕЧИТЬСЯ"
		
		# Проверка доступности
		var can_afford = player_data["balance"] >= treatment["cost"]
		var is_treating = (current_treatment != null)
		
		treat_btn.disabled = (not is_useful) or (not can_afford) or is_treating
		
		var style_treat = StyleBoxFlat.new()
		if treat_btn.disabled:
			style_treat.bg_color = Color(0.3, 0.3, 0.3, 1.0)
		else:
			style_treat.bg_color = Color(0.2, 0.6, 0.8, 1.0)
		treat_btn.add_theme_stylebox_override("normal", style_treat)
		
		var style_treat_hover = StyleBoxFlat.new()
		style_treat_hover.bg_color = Color(0.3, 0.7, 0.9, 1.0)
		treat_btn.add_theme_stylebox_override("hover", style_treat_hover)
		
		treat_btn.add_theme_font_size_override("font_size", 18)
		
		var treat_id = treatment_key
		treat_btn.pressed.connect(func():
			start_treatment(treat_id, player_data, main_node, member_index, gang_members)
			# ✅ НЕ закрываем меню - пользователь может лечиться ещё
		)
		hospital_menu.add_child(treat_btn)
		
		y_pos += 150
	
	# Раздел: Использовать предметы
	var items_title = Label.new()
	items_title.text = "═══ ИСПОЛЬЗОВАТЬ ПРЕДМЕТЫ ═══"
	items_title.position = Vector2(180, y_pos + 20)
	items_title.add_theme_font_size_override("font_size", 20)
	items_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	hospital_menu.add_child(items_title)
	y_pos += 60
	
	# Показать лечебные предметы из инвентаря
	var healing_items = get_healing_items_from_inventory(player_data)
	
	if healing_items.size() > 0:
		for item_name in healing_items:
			var item_data = items_db.get_item(item_name) if items_db else null
			if not item_data:
				continue
			
			var item_btn = Button.new()
			item_btn.custom_minimum_size = Vector2(660, 45)
			item_btn.position = Vector2(30, y_pos)
			item_btn.text = item_name + " (+" + str(item_data.get("value", 0)) + " HP)"
			
			var style_item = StyleBoxFlat.new()
			style_item.bg_color = Color(0.2, 0.4, 0.2, 1.0)
			item_btn.add_theme_stylebox_override("normal", style_item)
			
			var style_item_hover = StyleBoxFlat.new()
			style_item_hover.bg_color = Color(0.3, 0.5, 0.3, 1.0)
			item_btn.add_theme_stylebox_override("hover", style_item_hover)
			
			item_btn.add_theme_font_size_override("font_size", 16)
			
			var item_to_use = item_name
			item_btn.pressed.connect(func():
				use_healing_item(item_to_use, player_data, main_node, member_index, gang_members)
				# ✅ Обновляем меню вместо закрытия
				hospital_menu.queue_free()
				show_treatment_menu(main_node, player_data, member_index, gang_members)
			)
			hospital_menu.add_child(item_btn)
			y_pos += 55
	else:
		var no_items = Label.new()
		no_items.text = "Нет лечебных предметов в инвентаре"
		no_items.position = Vector2(200, y_pos)
		no_items.add_theme_font_size_override("font_size", 14)
		no_items.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
		hospital_menu.add_child(no_items)
	
	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(680, 50)
	close_btn.position = Vector2(20, 1100)  # ✅ Выше нижнего меню (которое на 1180)
	close_btn.text = "ЗАКРЫТЬ"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): 
		hospital_menu.queue_free()
		# ✅ Возвращаем меню выбора действий
		main_node.show_location_menu("БОЛЬНИЦА")
	)
	
	hospital_menu.add_child(close_btn)

# Начать лечение
func start_treatment(treatment_key: String, player_data: Dictionary, main_node: Node, member_index: int = 0, gang_members: Array = []):
	if current_treatment != null:
		main_node.show_message("⚠️ Лечение уже идёт!")
		return
	
	if not treatments.has(treatment_key):
		return
	
	var treatment = treatments[treatment_key]
	
	# Проверка денег
	if player_data["balance"] < treatment["cost"]:
		main_node.show_message("❌ Недостаточно денег! Нужно: " + str(treatment["cost"]) + " руб.")
		return
	
	# Определяем пациента
	var current_hp = 0
	var max_hp = 100
	var member_name = "Вы"
	
	if member_index == 0:
		current_hp = player_data.get("health", 100)
		member_name = "Вы"
	elif member_index < gang_members.size():
		var member = gang_members[member_index]
		current_hp = member.get("hp", 100)
		max_hp = member.get("max_hp", 100)
		member_name = member.get("name", "Боец")
	
	# Проверка HP
	if current_hp >= max_hp:
		main_node.show_message("✅ %s полностью здоров!" % member_name)
		return
	
	# Списываем деньги
	player_data["balance"] -= treatment["cost"]
	current_treatment = treatment_key
	
	main_node.show_message(treatment["icon"] + " Начато лечение: " + member_name + " - " + treatment["name"])
	
	# Показываем прогресс
	show_treatment_progress(treatment, player_data, main_node, member_name)
	
	# Таймер лечения
	treatment_timer = Timer.new()
	treatment_timer.wait_time = treatment["duration"]
	treatment_timer.one_shot = true
	main_node.add_child(treatment_timer)
	
	treatment_timer.timeout.connect(func():
		complete_treatment(treatment_key, player_data, main_node, member_index, gang_members)
		treatment_timer.queue_free()
		
		# ✅ ДОБАВЛЕНО: Обновляем меню больницы после завершения лечения
		await main_node.get_tree().create_timer(3.5).timeout  # Ждем окончания анимации результата
		var hospital_menu = main_node.get_node_or_null("HospitalMenu")
		if hospital_menu:
			hospital_menu.queue_free()
			# Возвращаемся к выбору персонажа
			if gang_members.size() > 1:
				show_character_selection(main_node, player_data, gang_members)
			else:
				show_treatment_menu(main_node, player_data, member_index, gang_members)
	)
	treatment_timer.start()
	
	main_node.update_ui()

# Показать прогресс лечения
func show_treatment_progress(treatment: Dictionary, player_data: Dictionary, main_node: Node, patient_name: String = "Вы"):
	var progress_layer = CanvasLayer.new()
	progress_layer.name = "TreatmentProgressLayer"
	progress_layer.layer = 150  # ✅ Поверх меню больницы (layer 100)
	main_node.add_child(progress_layer)
	
	var bg = ColorRect.new()
	bg.size = Vector2(450, 180)
	bg.position = Vector2(135, 550)
	bg.color = Color(0.05, 0.1, 0.15, 0.95)
	progress_layer.add_child(bg)
	
	var icon = Label.new()
	icon.text = treatment["icon"]
	icon.position = Vector2(285, 565)
	icon.add_theme_font_size_override("font_size", 48)
	progress_layer.add_child(icon)
	
	var title = Label.new()
	title.text = treatment["name"] + " - " + patient_name
	title.position = Vector2(220, 625)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 1.0))
	progress_layer.add_child(title)
	
	# Прогресс-бар
	var progress_bg = ColorRect.new()
	progress_bg.size = Vector2(410, 25)
	progress_bg.position = Vector2(155, 670)
	progress_bg.color = Color(0.2, 0.2, 0.2, 1.0)
	progress_layer.add_child(progress_bg)
	
	var progress_fill = ColorRect.new()
	progress_fill.size = Vector2(0, 25)
	progress_fill.position = Vector2(155, 670)
	progress_fill.color = Color(0.3, 0.8, 1.0, 1.0)
	progress_fill.name = "ProgressFill"
	progress_layer.add_child(progress_fill)
	
	var progress_label = Label.new()
	progress_label.text = "0%"
	progress_label.position = Vector2(345, 673)
	progress_label.add_theme_font_size_override("font_size", 16)
	progress_label.add_theme_color_override("font_color", Color.BLACK)
	progress_label.name = "ProgressLabel"
	progress_layer.add_child(progress_label)
	
	# Анимация прогресса
	var tween = create_tween()
	tween.tween_property(progress_fill, "size:x", 410, treatment["duration"])
	
	# Обновление процентов
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.timeout.connect(func():
		var percent = int((progress_fill.size.x / 410.0) * 100)
		progress_label.text = str(percent) + "%"
	)
	progress_layer.add_child(timer)
	timer.start()

# Завершить лечение
func complete_treatment(treatment_key: String, player_data: Dictionary, main_node: Node, member_index: int = 0, gang_members: Array = []):
	if not treatments.has(treatment_key):
		return
	
	var treatment = treatments[treatment_key]
	
	# Определяем пациента и восстанавливаем здоровье
	var old_health = 0
	var restored = 0
	var member_name = "Вы"
	
	if member_index == 0:
		# Главный игрок
		old_health = player_data["health"]
		player_data["health"] = min(100, player_data["health"] + treatment["health_restore"])
		restored = player_data["health"] - old_health
		member_name = "Вы"
	elif member_index < gang_members.size():
		# Член банды
		var member = gang_members[member_index]
		old_health = member.get("hp", 100)
		var max_hp = member.get("max_hp", 100)
		member["hp"] = min(max_hp, member["hp"] + treatment["health_restore"])
		restored = member["hp"] - old_health
		member_name = member.get("name", "Боец")
	
	# Удаляем прогресс-бар
	var progress_layer = main_node.get_node_or_null("TreatmentProgressLayer")
	if progress_layer:
		progress_layer.queue_free()
	
	# Показываем результат
	show_treatment_result(treatment, restored, main_node, member_name)
	
	# Обновляем UI
	main_node.update_ui()
	
	# Сбрасываем текущее лечение
	current_treatment = null
	
	treatment_completed.emit(restored)

# Показать результат лечения
func show_treatment_result(treatment: Dictionary, restored: int, main_node: Node, patient_name: String = "Вы"):
	var result_layer = CanvasLayer.new()
	result_layer.name = "TreatmentResultLayer"
	result_layer.layer = 150  # ✅ Поверх меню больницы
	main_node.add_child(result_layer)
	
	var bg = ColorRect.new()
	bg.size = Vector2(450, 200)
	bg.position = Vector2(135, 540)
	bg.color = Color(0.1, 0.3, 0.1, 0.95)
	result_layer.add_child(bg)
	
	var icon = Label.new()
	icon.text = treatment["icon"]
	icon.position = Vector2(285, 555)
	icon.add_theme_font_size_override("font_size", 48)
	result_layer.add_child(icon)
	
	var title = Label.new()
	title.text = "ЛЕЧЕНИЕ ЗАВЕРШЕНО!"
	title.position = Vector2(200, 615)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	result_layer.add_child(title)
	
	var patient_label = Label.new()
	patient_label.text = "Пациент: " + patient_name
	patient_label.position = Vector2(230, 655)
	patient_label.add_theme_font_size_override("font_size", 18)
	patient_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	result_layer.add_child(patient_label)
	
	var restored_label = Label.new()
	restored_label.text = "❤️ Восстановлено: +" + str(restored) + " HP"
	restored_label.position = Vector2(220, 685)
	restored_label.add_theme_font_size_override("font_size", 20)
	restored_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	result_layer.add_child(restored_label)
	
	# Автоматически убираем через 3 секунды
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	main_node.add_child(timer)
	
	timer.timeout.connect(func():
		if result_layer and is_instance_valid(result_layer):
			result_layer.queue_free()
		timer.queue_free()
	)
	timer.start()

# Получить лечебные предметы из инвентаря
func get_healing_items_from_inventory(player_data: Dictionary) -> Array:
	var healing_items = []
	
	if not items_db or not player_data.has("inventory"):
		return healing_items
	
	for item_name in player_data["inventory"]:
		var item_data = items_db.get_item(item_name)
		if item_data and item_data.get("type") == "consumable" and item_data.get("effect") == "heal":
			healing_items.append(item_name)
	
	return healing_items

# Использовать лечебный предмет
func use_healing_item(item_name: String, player_data: Dictionary, main_node: Node, member_index: int = 0, gang_members: Array = []):
	if not items_db:
		return
	
	var item_data = items_db.get_item(item_name)
	if not item_data:
		return
	
	# Определяем пациента
	var heal_amount = item_data.get("value", 10)
	var old_health = 0
	var restored = 0
	var member_name = "Вы"
	
	if member_index == 0:
		# Главный игрок
		old_health = player_data["health"]
		player_data["health"] = min(100, player_data["health"] + heal_amount)
		restored = player_data["health"] - old_health
		member_name = "Вы"
	elif member_index < gang_members.size():
		# Член банды
		var member = gang_members[member_index]
		old_health = member.get("hp", 100)
		var max_hp = member.get("max_hp", 100)
		member["hp"] = min(max_hp, member["hp"] + heal_amount)
		restored = member["hp"] - old_health
		member_name = member.get("name", "Боец")
	
	# Удаляем предмет из инвентаря
	player_data["inventory"].erase(item_name)
	
	main_node.show_message("✅ %s: использовано %s (+%d HP)" % [member_name, item_name, restored])
	main_node.update_ui()

# Проверка, лечится ли игрок сейчас
func is_treating() -> bool:
	return current_treatment != null
