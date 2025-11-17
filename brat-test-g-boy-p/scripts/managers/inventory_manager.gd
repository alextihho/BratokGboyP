# inventory_menu.gd (ИСПРАВЛЕНО - layer 200)
extends CanvasLayer

signal back_to_gang
signal item_clicked(item_name: String, from_pocket: bool, pocket_index: int)
signal equip_requested(item_name: String)

var items_db
var player_data
var current_member_index = 0
var gang_members = []

func _ready():
	layer = 200  # ✅ КРИТИЧНО! ВЫШЕ сетки (5) и UI (50)
	items_db = get_node("/root/ItemsDB")

# ✅ НОВОЕ: Функция для показа инвентаря члена банды
func show_inventory_for_member(main_node: Node, member_index: int, p_gang_members: Array, p_player_data: Dictionary):
	# Создаем новый экземпляр инвентаря
	var inventory_scene = InventoryManager.new()
	inventory_scene.name = "InventoryMenu"
	main_node.add_child(inventory_scene)

	# Настраиваем данные
	if member_index == 0:
		# Главный игрок
		inventory_scene.setup(p_player_data, member_index, p_gang_members)
	else:
		# Член банды
		if member_index < p_gang_members.size():
			inventory_scene.setup(p_gang_members[member_index], member_index, p_gang_members)

	# Подключаем сигнал возврата
	inventory_scene.back_to_gang.connect(func():
		var gang_mgr = main_node.get_node_or_null("/root/GangManager")
		if gang_mgr:
			gang_mgr.show_gang_menu(main_node, p_gang_members)
	)

func setup(p_data, member_index: int, p_gang_members: Array):
	player_data = p_data
	current_member_index = member_index
	gang_members = p_gang_members

	if not player_data.has("pockets"):
		player_data["pockets"] = [null, null, null]

	create_ui()

func create_ui():
	for child in get_children():
		child.queue_free()
	
	# ✅ Overlay для блокировки кликов
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.position = Vector2(0, 0)
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(700, 1060)
	bg.position = Vector2(10, 140)
	bg.color = Color(0.05, 0.05, 0.05, 0.95)
	bg.name = "InventoryBG"
	add_child(bg)
	
	var member_name = "ИНВЕНТАРЬ"
	if gang_members.size() > current_member_index:
		member_name = gang_members[current_member_index]["name"] + " - ИНВЕНТАРЬ"
	
	var title = Label.new()
	title.text = member_name
	title.position = Vector2(200, 160)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	add_child(title)
	
	var equip_y = 220
	var equipment_slots = [
		["helmet", "🧢 Головной убор"],
		["armor", "🦺 Броня"],
		["melee", "🔪 Ближний бой"],
		["ranged", "🔫 Дальний бой"],
		["gadget", "📱 Гаджет"]
	]
	
	for slot in equipment_slots:
		var slot_key = slot[0]
		var slot_name = slot[1]
		var equipped_item = player_data["equipment"][slot_key]
		
		var slot_bg = ColorRect.new()
		slot_bg.size = Vector2(680, 50)
		slot_bg.position = Vector2(20, equip_y)
		slot_bg.color = Color(0.2, 0.2, 0.25, 1.0)
		add_child(slot_bg)
		
		var slot_label = Label.new()
		var display_text = slot_name + ": "
		if equipped_item:
			display_text += equipped_item
		else:
			display_text += "—"
		slot_label.text = display_text
		slot_label.position = Vector2(30, equip_y + 15)
		slot_label.add_theme_font_size_override("font_size", 18)
		slot_label.add_theme_color_override("font_color", Color.WHITE)
		add_child(slot_label)
		
		equip_y += 60
	
	var pocket_title = Label.new()
	pocket_title.text = "🎒 КАРМАНЫ (быстрый доступ):"
	pocket_title.position = Vector2(30, equip_y + 20)
	pocket_title.add_theme_font_size_override("font_size", 22)
	pocket_title.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8, 1.0))
	add_child(pocket_title)
	
	equip_y += 60
	
	for i in range(3):
		var pocket_item = player_data["pockets"][i]
		
		var pocket_bg = ColorRect.new()
		pocket_bg.size = Vector2(680, 50)
		pocket_bg.position = Vector2(20, equip_y)
		pocket_bg.color = Color(0.15, 0.25, 0.15, 1.0)
		pocket_bg.name = "Pocket_" + str(i)
		add_child(pocket_bg)
		
		var pocket_label = Label.new()
		var pocket_text = "Карман " + str(i + 1) + ": "
		if pocket_item:
			pocket_text += pocket_item
		else:
			pocket_text += "пусто"
		pocket_label.text = pocket_text
		pocket_label.position = Vector2(30, equip_y + 15)
		pocket_label.add_theme_font_size_override("font_size", 18)
		pocket_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
		add_child(pocket_label)
		
		if pocket_item:
			var pocket_btn = Button.new()
			pocket_btn.custom_minimum_size = Vector2(120, 40)
			pocket_btn.position = Vector2(560, equip_y + 5)
			pocket_btn.text = "Действия"
			pocket_btn.name = "PocketBtn_" + str(i)
			
			var style_pocket = StyleBoxFlat.new()
			style_pocket.bg_color = Color(0.3, 0.5, 0.3, 1.0)
			pocket_btn.add_theme_stylebox_override("normal", style_pocket)
			
			var style_pocket_hover = StyleBoxFlat.new()
			style_pocket_hover.bg_color = Color(0.4, 0.6, 0.4, 1.0)
			pocket_btn.add_theme_stylebox_override("hover", style_pocket_hover)
			
			pocket_btn.add_theme_font_size_override("font_size", 16)
			
			var pocket_idx = i
			pocket_btn.pressed.connect(func():
				item_clicked.emit(pocket_item, true, pocket_idx)
			)
			add_child(pocket_btn)
		
		equip_y += 60
	
	var inv_title = Label.new()
	inv_title.text = "🎒 РЮКЗАК:"
	inv_title.position = Vector2(30, equip_y + 20)
	inv_title.add_theme_font_size_override("font_size", 22)
	inv_title.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 1.0))
	add_child(inv_title)
	
	equip_y += 60
	
	if player_data["inventory"].size() == 0:
		var empty_label = Label.new()
		empty_label.text = "Рюкзак пуст"
		empty_label.position = Vector2(30, equip_y)
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
		add_child(empty_label)
	else:
		for i in range(player_data["inventory"].size()):
			var item = player_data["inventory"][i]
			
			var item_bg = ColorRect.new()
			item_bg.size = Vector2(680, 45)
			item_bg.position = Vector2(20, equip_y)
			item_bg.color = Color(0.15, 0.15, 0.2, 1.0)
			item_bg.name = "InvItem_" + str(i)
			add_child(item_bg)
			
			var item_label = Label.new()
			item_label.text = "• " + item
			item_label.position = Vector2(30, equip_y + 12)
			item_label.add_theme_font_size_override("font_size", 18)
			item_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
			add_child(item_label)
			
			var action_btn = Button.new()
			action_btn.custom_minimum_size = Vector2(120, 35)
			action_btn.position = Vector2(560, equip_y + 5)
			action_btn.text = "Действия"
			action_btn.name = "ActionBtn_" + str(i)
			
			var style_action = StyleBoxFlat.new()
			style_action.bg_color = Color(0.3, 0.4, 0.5, 1.0)
			action_btn.add_theme_stylebox_override("normal", style_action)
			
			var style_action_hover = StyleBoxFlat.new()
			style_action_hover.bg_color = Color(0.4, 0.5, 0.6, 1.0)
			action_btn.add_theme_stylebox_override("hover", style_action_hover)
			
			action_btn.add_theme_font_size_override("font_size", 16)
			
			var item_name = item
			action_btn.pressed.connect(func():
				item_clicked.emit(item_name, false, -1)
			)
			add_child(action_btn)
			
			equip_y += 50
	
	var stats_btn = Button.new()
	stats_btn.custom_minimum_size = Vector2(210, 50)
	stats_btn.position = Vector2(20, 1110)
	stats_btn.text = "📊 СТАТЫ"
	stats_btn.name = "StatsButton"
	
	var style_stats = StyleBoxFlat.new()
	style_stats.bg_color = Color(0.2, 0.3, 0.5, 1.0)
	stats_btn.add_theme_stylebox_override("normal", style_stats)
	
	var style_stats_hover = StyleBoxFlat.new()
	style_stats_hover.bg_color = Color(0.3, 0.4, 0.6, 1.0)
	stats_btn.add_theme_stylebox_override("hover", style_stats_hover)
	
	stats_btn.add_theme_font_size_override("font_size", 20)
	stats_btn.pressed.connect(func(): show_stats_window())
	add_child(stats_btn)
	
	var back_btn = Button.new()
	back_btn.custom_minimum_size = Vector2(210, 50)
	back_btn.position = Vector2(245, 1110)
	back_btn.text = "← БАНДА"
	back_btn.name = "BackToGang"
	
	var style_back = StyleBoxFlat.new()
	style_back.bg_color = Color(0.4, 0.4, 0.1, 1.0)
	back_btn.add_theme_stylebox_override("normal", style_back)
	
	var style_back_hover = StyleBoxFlat.new()
	style_back_hover.bg_color = Color(0.5, 0.5, 0.2, 1.0)
	back_btn.add_theme_stylebox_override("hover", style_back_hover)
	
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.pressed.connect(func():
		back_to_gang.emit()
		queue_free()
	)
	add_child(back_btn)
	
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(210, 50)
	close_btn.position = Vector2(470, 1110)
	close_btn.text = "ЗАКРЫТЬ"
	close_btn.name = "CloseInventory"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): queue_free())
	add_child(close_btn)

func show_stats_window():
	var player_stats = get_node("/root/PlayerStats")
	if not player_stats:
		return
	
	var stats_popup = CanvasLayer.new()
	stats_popup.name = "StatsPopup"
	stats_popup.layer = 210  # ✅ Еще выше
	get_parent().add_child(stats_popup)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.position = Vector2(0, 0)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	stats_popup.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(680, 950)
	bg.position = Vector2(20, 165)
	bg.color = Color(0.05, 0.05, 0.05, 0.98)
	stats_popup.add_child(bg)
	
	var title = Label.new()
	title.text = "📊 СТАТИСТИКА ПЕРСОНАЖА"
	title.position = Vector2(180, 185)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	stats_popup.add_child(title)
	
	var stats_text = player_stats.get_stats_text()
	var label = Label.new()
	label.text = stats_text
	label.position = Vector2(40, 235)
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color.WHITE)
	stats_popup.add_child(label)
	
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(640, 50)
	close_btn.position = Vector2(40, 1050)
	close_btn.text = "ЗАКРЫТЬ"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): stats_popup.queue_free())
	
	stats_popup.add_child(close_btn)
