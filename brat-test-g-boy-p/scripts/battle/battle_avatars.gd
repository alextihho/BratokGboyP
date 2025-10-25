# battle_avatars.gd (ИСПРАВЛЕНО - аватарки под UI, клик по HP, банда атакует)
extends Node

signal avatar_clicked(character_data: Dictionary, is_player_team: bool)
signal target_selected(enemy_index: int)

var battle_logic
var items_db
var player_stats

var avatar_nodes = {}
var selected_target_index: int = -1

func _ready():
	items_db = get_node_or_null("/root/ItemsDB")
	player_stats = get_node_or_null("/root/PlayerStats")

func initialize(p_battle_logic, parent: CanvasLayer):
	battle_logic = p_battle_logic
	create_team_avatars(parent)

# ========== СОЗДАНИЕ АВАТАРОК ==========
func create_team_avatars(parent: CanvasLayer):
	# ✅ ИСПРАВЛЕНО: Команда игрока (слева, НИЖЕ верхней панели)
	var player_x = 30
	var player_y = 250  # ✅ Было 170 → Теперь 250 (ниже UI на y=140)
	
	for i in range(battle_logic.player_team.size()):
		create_avatar(battle_logic.player_team[i], Vector2(player_x, player_y), i, true, parent)
		player_y += 130
	
	# ✅ ИСПРАВЛЕНО: Команда врагов (справа, тоже ниже UI)
	var enemy_x = 470  # ✅ Было 500 → сдвинуто левее для места под HP-панель
	var enemy_y = 250
	
	for i in range(battle_logic.enemy_team.size()):
		create_avatar(battle_logic.enemy_team[i], Vector2(enemy_x, enemy_y), i, false, parent)
		enemy_y += 130

func create_avatar(fighter: Dictionary, pos: Vector2, index: int, is_player_side: bool, parent: CanvasLayer):
	var avatar_container = Control.new()
	avatar_container.custom_minimum_size = Vector2(220, 120)  # ✅ Увеличена ширина для HP-панели
	avatar_container.position = pos
	avatar_container.name = ("Player" if is_player_side else "Enemy") + "Avatar_" + str(index)
	avatar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(avatar_container)
	
	# ✅ Фон аватарки (меньше)
	var avatar_bg = ColorRect.new()
	avatar_bg.size = Vector2(80, 80)  # ✅ Уменьшено с 100
	avatar_bg.color = Color(0.3, 0.3, 0.3, 1.0)
	avatar_bg.name = "AvatarBG"
	avatar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar_container.add_child(avatar_bg)
	
	# ✅ ИМЯ ПЕРСОНАЖА (над аватаркой)
	var name_label = Label.new()
	name_label.text = fighter["name"]
	name_label.position = Vector2(0, -20)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.name = "NameLabel"
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar_container.add_child(name_label)
	
	# ✅ HP индикатор (красная полоса сверху вниз)
	var hp_indicator = ColorRect.new()
	var hp_percent = float(fighter["hp"]) / float(fighter["max_hp"])
	hp_indicator.size = Vector2(80, 80 * (1.0 - hp_percent))
	hp_indicator.position = Vector2(0, 0)
	hp_indicator.color = Color(1.0, 0.0, 0.0, 0.6)
	hp_indicator.name = "HPIndicator"
	hp_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar_container.add_child(hp_indicator)
	
	# ✅ Иконка персонажа (эмодзи)
	var icon = Label.new()
	icon.text = "🤵" if is_player_side else "💀"
	icon.position = Vector2(20, 15)
	icon.add_theme_font_size_override("font_size", 40)
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar_container.add_child(icon)
	
	# ✅ ИНФОРМАЦИОННАЯ ПАНЕЛЬ (справа от аватарки)
	var info_panel = ColorRect.new()
	info_panel.size = Vector2(130, 100)  # ✅ Уменьшена ширина
	info_panel.position = Vector2(85, 0)  # ✅ Ближе к аватарке
	info_panel.color = Color(0.1, 0.1, 0.1, 0.9)
	info_panel.name = "InfoPanel"
	avatar_container.add_child(info_panel)
	
	# ✅ HP текст (на инфо-панели)
	var hp_label = Label.new()
	hp_label.text = "❤️ %d/%d" % [fighter["hp"], fighter["max_hp"]]
	hp_label.position = Vector2(5, 5)
	hp_label.add_theme_font_size_override("font_size", 11)
	hp_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	hp_label.name = "HPLabel"
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_panel.add_child(hp_label)
	
	# ✅ Мораль
	var morale_label = Label.new()
	morale_label.text = "💪 %d" % fighter["morale"]
	morale_label.position = Vector2(5, 22)
	morale_label.add_theme_font_size_override("font_size", 11)
	morale_label.add_theme_color_override("font_color", get_morale_color(fighter["morale"]))
	morale_label.name = "MoraleLabel"
	morale_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_panel.add_child(morale_label)
	
	# ✅ Урон
	var damage_label = Label.new()
	damage_label.text = "⚔️ %d" % fighter["damage"]
	damage_label.position = Vector2(5, 39)
	damage_label.add_theme_font_size_override("font_size", 10)
	damage_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	damage_label.name = "DamageLabel"
	damage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_panel.add_child(damage_label)
	
	# ✅ Защита
	var defense_label = Label.new()
	defense_label.text = "🛡️ %d" % fighter["defense"]
	defense_label.position = Vector2(5, 52)
	defense_label.add_theme_font_size_override("font_size", 10)
	defense_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9, 1.0))
	defense_label.name = "DefenseLabel"
	defense_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_panel.add_child(defense_label)
	
	# ✅ Статусы
	var status_label = Label.new()
	status_label.text = battle_logic.get_status_text(fighter)
	status_label.position = Vector2(5, 68)
	status_label.add_theme_font_size_override("font_size", 9)
	status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1.0))
	status_label.name = "StatusLabel"
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_panel.add_child(status_label)
	
	# ✅ КЛИКАБЕЛЬНАЯ КНОПКА (только для врагов, на инфо-панели)
	if not is_player_side:
		var click_btn = Button.new()
		click_btn.custom_minimum_size = Vector2(130, 100)
		click_btn.position = Vector2(0, 0)
		click_btn.text = ""  # Прозрачная кнопка
		click_btn.name = "ClickableArea"
		click_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
		var style_transparent = StyleBoxFlat.new()
		style_transparent.bg_color = Color(0, 0, 0, 0)
		click_btn.add_theme_stylebox_override("normal", style_transparent)
		
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.3, 0.3, 0.3, 0.3)
		click_btn.add_theme_stylebox_override("hover", style_hover)
		
		var idx = index
		click_btn.pressed.connect(func(): 
			on_target_selected(idx, fighter)
		)
		info_panel.add_child(click_btn)
	
	# ✅ КНОПКА ИНВЕНТАРЯ (на аватарке, для всех)
	var inventory_btn = Button.new()
	inventory_btn.custom_minimum_size = Vector2(80, 80)
	inventory_btn.position = Vector2(0, 0)
	inventory_btn.text = ""
	inventory_btn.name = "InventoryBtn"
	inventory_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var style_inv = StyleBoxFlat.new()
	style_inv.bg_color = Color(1, 1, 1, 0.0)
	inventory_btn.add_theme_stylebox_override("normal", style_inv)
	
	var idx = index
	var is_player = is_player_side
	inventory_btn.pressed.connect(func(): 
		on_avatar_clicked(fighter, is_player, idx)
	)
	avatar_container.add_child(inventory_btn)
	
	# Сохраняем ссылку
	var key = ("player" if is_player_side else "enemy") + "_" + str(index)
	avatar_nodes[key] = avatar_container

# ========== ОБРАБОТКА КЛИКОВ ==========
func on_avatar_clicked(fighter: Dictionary, is_player_side: bool, index: int):
	avatar_clicked.emit(fighter, is_player_side)

func on_target_selected(enemy_index: int, fighter: Dictionary):
	if not fighter["alive"]:
		return
	
	# ✅ СТАТИЧНЫЙ ВЫБОР ЦЕЛИ - сохраняется до ручной смены
	selected_target_index = enemy_index
	
	if battle_logic.select_target(enemy_index):
		target_selected.emit(enemy_index)
		highlight_selected_target(enemy_index)
		
		var main_node = get_tree().current_scene
		if main_node and main_node.has_method("show_message"):
			main_node.show_message("🎯 Цель выбрана: " + fighter["name"])

func highlight_selected_target(enemy_index: int):
	# Убираем старую подсветку
	for i in range(battle_logic.enemy_team.size()):
		var key = "enemy_" + str(i)
		if avatar_nodes.has(key):
			var avatar = avatar_nodes[key]
			var bg = avatar.get_node_or_null("AvatarBG")
			if bg:
				bg.color = Color(0.3, 0.3, 0.3, 1.0)
	
	# Подсвечиваем новую цель
	var key = "enemy_" + str(enemy_index)
	if avatar_nodes.has(key):
		var avatar = avatar_nodes[key]
		var bg = avatar.get_node_or_null("AvatarBG")
		if bg:
			bg.color = Color(0.8, 0.8, 0.2, 1.0)

# ========== ОБНОВЛЕНИЕ АВАТАРОК ==========
func update_all_avatars():
	for i in range(battle_logic.player_team.size()):
		update_avatar_ui(battle_logic.player_team[i], i, true)
	
	for i in range(battle_logic.enemy_team.size()):
		update_avatar_ui(battle_logic.enemy_team[i], i, false)

func update_avatar_ui(fighter: Dictionary, index: int, is_player_side: bool):
	var key = ("player" if is_player_side else "enemy") + "_" + str(index)
	if not avatar_nodes.has(key):
		return
	
	var avatar = avatar_nodes[key]
	
	# Обновление имени
	var name_label = avatar.get_node_or_null("NameLabel")
	if name_label:
		name_label.text = fighter["name"]
	
	# Обновление HP индикатора
	var hp_indicator = avatar.get_node_or_null("HPIndicator")
	if hp_indicator:
		var hp_percent = float(fighter["hp"]) / float(fighter["max_hp"])
		hp_indicator.size = Vector2(80, 80 * (1.0 - hp_percent))
	
	# Обновление HP текста
	var info_panel = avatar.get_node_or_null("InfoPanel")
	if info_panel:
		var hp_label = info_panel.get_node_or_null("HPLabel")
		if hp_label:
			hp_label.text = "❤️ %d/%d" % [fighter["hp"], fighter["max_hp"]]
			hp_label.add_theme_color_override("font_color", 
				Color(1.0, 0.3, 0.3, 1.0) if fighter["hp"] < fighter["max_hp"] * 0.3 else Color(0.3, 1.0, 0.3, 1.0))
		
		# Обновление морали
		var morale_label = info_panel.get_node_or_null("MoraleLabel")
		if morale_label:
			morale_label.text = "💪 %d" % fighter["morale"]
			morale_label.add_theme_color_override("font_color", get_morale_color(fighter["morale"]))
		
		# Обновление урона
		var damage_label = info_panel.get_node_or_null("DamageLabel")
		if damage_label:
			damage_label.text = "⚔️ %d" % fighter["damage"]
		
		# Обновление защиты
		var defense_label = info_panel.get_node_or_null("DefenseLabel")
		if defense_label:
			defense_label.text = "🛡️ %d" % fighter["defense"]
		
		# Обновление статусов
		var status_label = info_panel.get_node_or_null("StatusLabel")
		if status_label:
			status_label.text = battle_logic.get_status_text(fighter)
	
	# Обновление видимости для мертвых
	if not fighter["alive"]:
		var icon = avatar.get_node_or_null("Icon")
		if icon:
			icon.text = "💀"
		var bg = avatar.get_node_or_null("AvatarBG")
		if bg:
			bg.color = Color(0.1, 0.1, 0.1, 1.0)

func get_morale_color(morale: int) -> Color:
	if morale >= 70:
		return Color(0.3, 1.0, 0.3, 1.0)
	elif morale >= 40:
		return Color(1.0, 1.0, 0.3, 1.0)
	else:
		return Color(1.0, 0.3, 0.3, 1.0)

# ========== ИНВЕНТАРЬ В БОЮ ==========
func show_fighter_inventory(fighter: Dictionary, index: int, is_ally: bool):
	var main_node = get_tree().current_scene
	
	var old_inv = main_node.get_node_or_null("BattleInventory")
	if old_inv:
		old_inv.queue_free()
	
	var inv_layer = CanvasLayer.new()
	inv_layer.name = "BattleInventory"
	inv_layer.layer = 250
	main_node.add_child(inv_layer)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	inv_layer.add_child(overlay)
	
	var inv_bg = ColorRect.new()
	inv_bg.size = Vector2(600, 900)
	inv_bg.position = Vector2(60, 190)
	inv_bg.color = Color(0.05, 0.05, 0.1, 0.98)
	inv_layer.add_child(inv_bg)
	
	var title = Label.new()
	title.text = "👤 " + fighter["name"]
	title.position = Vector2(250, 210)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	inv_layer.add_child(title)
	
	var y_pos = 260
	
	# === СТАТЫ ===
	var stats_title = Label.new()
	stats_title.text = "═══ ПАРАМЕТРЫ ═══"
	stats_title.position = Vector2(240, y_pos)
	stats_title.add_theme_font_size_override("font_size", 18)
	stats_title.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 1.0))
	inv_layer.add_child(stats_title)
	y_pos += 35
	
	var stats = [
		"❤️ HP: %d/%d" % [fighter["hp"], fighter["max_hp"]],
		"⚔️ Урон: %d" % fighter["damage"],
		"🛡️ Защита: %d" % fighter["defense"],
		"🎯 Точность: %.0f%%" % (fighter["accuracy"] * 100),
		"💪 Мораль: %d" % fighter["morale"]
	]
	
	for stat in stats:
		var stat_label = Label.new()
		stat_label.text = stat
		stat_label.position = Vector2(80, y_pos)
		stat_label.add_theme_font_size_override("font_size", 16)
		stat_label.add_theme_color_override("font_color", Color.WHITE)
		inv_layer.add_child(stat_label)
		y_pos += 25
	
	y_pos += 10
	
	# === ЭКИПИРОВКА ===
	var equip_title = Label.new()
	equip_title.text = "═══ ЭКИПИРОВКА ═══"
	equip_title.position = Vector2(230, y_pos)
	equip_title.add_theme_font_size_override("font_size", 18)
	equip_title.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 1.0))
	inv_layer.add_child(equip_title)
	y_pos += 35
	
	if is_ally and main_node.has("player_data") and main_node.has("gang_members"):
		var equipment = {}
		var inventory = []
		var pockets = []
		
		if fighter.get("is_player", false):
			equipment = main_node.player_data.get("equipment", {})
			inventory = main_node.player_data.get("inventory", [])
			pockets = main_node.player_data.get("pockets", [null, null, null])
		else:
			for i in range(main_node.gang_members.size()):
				if main_node.gang_members[i]["name"] == fighter["name"]:
					var member = main_node.gang_members[i]
					equipment = member.get("equipment", {})
					inventory = member.get("inventory", [])
					pockets = member.get("pockets", [null, null, null])
					break
		
		var equip_slots = {
			"helmet": "🧢 Голова",
			"armor": "🦺 Броня",
			"melee": "🔪 Ближний бой",
			"ranged": "🔫 Дальний бой",
			"gadget": "📱 Гаджет"
		}
		
		for slot_key in equip_slots:
			var slot_name = equip_slots[slot_key]
			var equipped = equipment.get(slot_key, null)
			
			var slot_label = Label.new()
			slot_label.text = slot_name + ": " + (equipped if equipped else "—")
			slot_label.position = Vector2(80, y_pos)
			slot_label.add_theme_font_size_override("font_size", 15)
			slot_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0) if equipped else Color(0.5, 0.5, 0.5, 1.0))
			inv_layer.add_child(slot_label)
			y_pos += 25
		
		y_pos += 10
		
		# КАРМАНЫ
		if pockets.size() > 0:
			var pockets_title = Label.new()
			pockets_title.text = "═══ КАРМАНЫ ═══"
			pockets_title.position = Vector2(240, y_pos)
			pockets_title.add_theme_font_size_override("font_size", 18)
			pockets_title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
			inv_layer.add_child(pockets_title)
			y_pos += 35
			
			for i in range(pockets.size()):
				var pocket_item = pockets[i]
				
				var pocket_container = Control.new()
				pocket_container.position = Vector2(80, y_pos)
				pocket_container.size = Vector2(540, 35)
				inv_layer.add_child(pocket_container)
				
				var pocket_label = Label.new()
				pocket_label.text = "Карман %d: %s" % [i + 1, pocket_item if pocket_item else "пусто"]
				pocket_label.position = Vector2(0, 5)
				pocket_label.add_theme_font_size_override("font_size", 15)
				pocket_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8, 1.0) if pocket_item else Color(0.5, 0.5, 0.5, 1.0))
				pocket_container.add_child(pocket_label)
				
				if pocket_item:
					var use_btn = Button.new()
					use_btn.custom_minimum_size = Vector2(120, 30)
					use_btn.position = Vector2(420, 0)
					use_btn.text = "ИСПОЛЬЗОВАТЬ"
					use_btn.add_theme_font_size_override("font_size", 12)
					
					var style = StyleBoxFlat.new()
					style.bg_color = Color(0.2, 0.6, 0.2, 1.0)
					use_btn.add_theme_stylebox_override("normal", style)
					
					var item_name = pocket_item
					var fighter_ref = fighter
					use_btn.pressed.connect(func(): 
						use_item_in_battle(item_name, fighter_ref, main_node)
						inv_layer.queue_free()
					)
					pocket_container.add_child(use_btn)
				
				y_pos += 40
		
		# РЮКЗАК
		if inventory.size() > 0:
			y_pos += 10
			var inv_title = Label.new()
			inv_title.text = "═══ РЮКЗАК (просмотр) ═══"
			inv_title.position = Vector2(210, y_pos)
			inv_title.add_theme_font_size_override("font_size", 16)
			inv_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
			inv_layer.add_child(inv_title)
			y_pos += 30
			
			for item in inventory:
				var item_label = Label.new()
				item_label.text = "• " + item
				item_label.position = Vector2(90, y_pos)
				item_label.add_theme_font_size_override("font_size", 14)
				item_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
				inv_layer.add_child(item_label)
				y_pos += 22
				
				if y_pos > 1000:
					break
	else:
		var weapon_label = Label.new()
		weapon_label.text = "Оружие: " + fighter.get("weapon", "Кулаки")
		weapon_label.position = Vector2(80, y_pos)
		weapon_label.add_theme_font_size_override("font_size", 15)
		weapon_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
		inv_layer.add_child(weapon_label)
	
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(560, 50)
	close_btn.position = Vector2(80, 1020)
	close_btn.text = "ЗАКРЫТЬ"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	close_btn.add_theme_font_size_override("font_size", 20)
	
	close_btn.pressed.connect(func(): inv_layer.queue_free())
	inv_layer.add_child(close_btn)

func use_item_in_battle(item_name: String, fighter: Dictionary, main_node: Node):
	if not items_db:
		return
	
	var item_data = items_db.get_item(item_name)
	if not item_data or item_data.get("type") != "consumable":
		if main_node.has_method("show_message"):
			main_node.show_message("⚠️ Предмет нельзя использовать!")
		return
	
	if item_data.get("effect") == "heal":
		var heal_amount = item_data.get("value", 10)
		fighter["hp"] = min(fighter["max_hp"], fighter["hp"] + heal_amount)
		if main_node.has_method("show_message"):
			main_node.show_message("💚 %s использовал %s (+%d HP)" % [fighter["name"], item_name, heal_amount])
	elif item_data.get("effect") == "stress":
		fighter["morale"] = min(100, fighter["morale"] + item_data.get("value", 10))
		if main_node.has_method("show_message"):
			main_node.show_message("💪 %s использовал %s (+%d морали)" % [fighter["name"], item_name, item_data.get("value", 10)])
	
	if main_node.has("player_data") and main_node.has("gang_members"):
		if fighter.get("is_player", false):
			for i in range(main_node.player_data["pockets"].size()):
				if main_node.player_data["pockets"][i] == item_name:
					main_node.player_data["pockets"][i] = null
					break
		else:
			for member in main_node.gang_members:
				if member["name"] == fighter["name"]:
					for i in range(member.get("pockets", []).size()):
						if member["pockets"][i] == item_name:
							member["pockets"][i] = null
							break
					break
	
	update_all_avatars()

func flash_red(is_player_side: bool, index: int):
	var key = ("player" if is_player_side else "enemy") + "_" + str(index)
	if not avatar_nodes.has(key):
		return
	
	var avatar = avatar_nodes[key]
	var bg = avatar.get_node_or_null("AvatarBG")
	if not bg:
		return
	
	var original_color = bg.color
	bg.color = Color(1.0, 0.3, 0.3, 1.0)
	
	await get_tree().create_timer(0.3).timeout
	
	if bg and is_instance_valid(bg):
		bg.color = original_color

func clear_all_highlights():
	for i in range(battle_logic.enemy_team.size()):
		var key = "enemy_" + str(i)
		if avatar_nodes.has(key):
			var avatar = avatar_nodes[key]
			var bg = avatar.get_node_or_null("AvatarBG")
			if bg:
				bg.color = Color(0.3, 0.3, 0.3, 1.0)

func get_selected_target_index() -> int:
	return selected_target_index

func clear_selected_target():
	selected_target_index = -1
	clear_all_highlights()
func flash_damage(fighter_index: int, is_player: bool):
	var key = ("player" if is_player else "enemy") + "_" + str(fighter_index)
	var avatar = avatar_nodes[key]
	var icon = avatar.get_node("Icon")
	
	icon.modulate = Color(2.0, 0.5, 0.5)  # Красная вспышка
	await get_tree().create_timer(0.2).timeout
	icon.modulate = Color(1.0, 1.0, 1.0)  # Возврат
func show_damage_number(damage: int, pos: Vector2):
	var label = Label.new()
	label.text = "-%d" % damage
	label.position = pos
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.RED)
