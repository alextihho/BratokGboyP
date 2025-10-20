extends Node

var items_db
var player_stats

func _ready():
	items_db = get_node("/root/ItemsDB")
	player_stats = get_node("/root/PlayerStats")

func show_inventory_for_member(main_node: Node, member_index: int, gang_members: Array, player_data: Dictionary):
	var inv_menu_script = load("res://scripts/ui/inventory_menu.gd")
	var inv_menu = inv_menu_script.new()
	inv_menu.name = "InventoryMenu"
	main_node.add_child(inv_menu)
	
	if member_index == 0:
		inv_menu.setup(player_data, member_index, gang_members)
	else:
		var member_data = gang_members[member_index]
		inv_menu.setup(member_data, member_index, gang_members)
	
	inv_menu.item_clicked.connect(func(item_name, from_pocket, p_index):
		show_item_popup(main_node, item_name, from_pocket, p_index, member_index, gang_members, player_data)
	)
	
	inv_menu.back_to_gang.connect(func():
		var gang_manager = get_node("/root/GangManager")
		gang_manager.show_gang_menu(main_node, gang_members)
	)

func show_item_popup(main_node: Node, item_name: String, from_pocket: bool, pocket_idx: int, member_index: int, gang_members: Array, player_data: Dictionary):
	var popup_script = load("res://scripts/ui/item_popup.gd")
	var popup = popup_script.new()
	popup.name = "ItemPopup"
	main_node.add_child(popup)
	
	var target_data = player_data if member_index == 0 else gang_members[member_index]
	popup.setup(item_name, target_data, from_pocket, pocket_idx)
	
	popup.action_selected.connect(func(p_item_name, action, p_pocket_idx):
		handle_item_action(main_node, p_item_name, action, p_pocket_idx, member_index, gang_members, player_data)
	)

func handle_item_action(main_node: Node, item_name: String, action: String, pocket_idx: int, member_index: int, gang_members: Array, player_data: Dictionary):
	var target_data = player_data if member_index == 0 else gang_members[member_index]
	
	match action:
		"Надеть":
			equip_item(main_node, item_name, target_data, member_index, gang_members, player_data)
		"Использовать":
			use_item(main_node, item_name, pocket_idx, target_data, member_index, gang_members, player_data)
		"Выбросить":
			drop_item(main_node, item_name, pocket_idx, target_data, member_index, gang_members, player_data)
		"В карман":
			move_to_pocket(main_node, item_name, target_data, member_index, gang_members, player_data)
		"Убрать из кармана":
			remove_from_pocket(main_node, pocket_idx, target_data, member_index, gang_members, player_data)

func equip_item(main_node: Node, item_name: String, target_data: Dictionary, member_index: int, gang_members: Array, player_data: Dictionary):
	print("🎒 Попытка надеть: " + item_name)
	
	var item_data = items_db.get_item(item_name)
	if not item_data:
		print("❌ Предмет не найден в базе!")
		return
	
	var slot = item_data["type"]
	
	if slot not in target_data["equipment"]:
		main_node.show_message("Этот предмет нельзя надеть")
		return
	
	if target_data["equipment"][slot] != null:
		var old_item = target_data["equipment"][slot]
		target_data["inventory"].append(old_item)
	
	target_data["equipment"][slot] = item_name
	target_data["inventory"].erase(item_name)
	
	if member_index == 0 and player_stats:
		player_stats.recalculate_equipment_bonuses(target_data["equipment"], items_db)
	
	main_node.show_message("Надето: " + item_name)
	main_node.update_ui()
	
	close_and_reload_inventory(main_node, member_index, gang_members, player_data)

func use_item(main_node: Node, item_name: String, pocket_idx: int, target_data: Dictionary, member_index: int, gang_members: Array, player_data: Dictionary):
	var item_data = items_db.get_item(item_name)
	if not item_data:
		return
	
	if item_data["type"] != "consumable":
		main_node.show_message("Этот предмет нельзя использовать")
		return
	
	if "effect" in item_data and item_data["effect"] == "heal":
		var heal_amount = item_data.get("value", 10)
		target_data["health"] = min(target_data.get("max_health", 100), target_data["health"] + heal_amount)
		main_node.show_message("Использовано: " + item_name + " (+" + str(heal_amount) + " HP)")
	elif "effect" in item_data and item_data["effect"] == "stress":
		main_node.show_message("Использовано: " + item_name + " (стресс снят)")
	else:
		main_node.show_message("Использовано: " + item_name)
	
	if pocket_idx >= 0 and pocket_idx < target_data["pockets"].size():
		target_data["pockets"][pocket_idx] = null
	else:
		target_data["inventory"].erase(item_name)
	
	main_node.update_ui()
	
	close_and_reload_inventory(main_node, member_index, gang_members, player_data)

func drop_item(main_node: Node, item_name: String, pocket_idx: int, target_data: Dictionary, member_index: int, gang_members: Array, player_data: Dictionary):
	if pocket_idx >= 0 and pocket_idx < target_data["pockets"].size():
		target_data["pockets"][pocket_idx] = null
		main_node.show_message("Выброшено из кармана: " + item_name)
	elif item_name in target_data["inventory"]:
		target_data["inventory"].erase(item_name)
		main_node.show_message("Выброшено: " + item_name)
	
	close_and_reload_inventory(main_node, member_index, gang_members, player_data)

func move_to_pocket(main_node: Node, item_name: String, target_data: Dictionary, member_index: int, gang_members: Array, player_data: Dictionary):
	for i in range(target_data["pockets"].size()):
		if target_data["pockets"][i] == null:
			target_data["pockets"][i] = item_name
			target_data["inventory"].erase(item_name)
			main_node.show_message("В карман: " + item_name)
			
			close_and_reload_inventory(main_node, member_index, gang_members, player_data)
			return
	
	main_node.show_message("Все карманы заняты!")

func remove_from_pocket(main_node: Node, pocket_idx: int, target_data: Dictionary, member_index: int, gang_members: Array, player_data: Dictionary):
	if pocket_idx < 0 or pocket_idx >= target_data["pockets"].size():
		return
	
	var item_name = target_data["pockets"][pocket_idx]
	if item_name:
		target_data["pockets"][pocket_idx] = null
		target_data["inventory"].append(item_name)
		main_node.show_message("Убрано из кармана: " + item_name)
		
		close_and_reload_inventory(main_node, member_index, gang_members, player_data)

# НОВАЯ ФУНКЦИЯ - закрывает окна и перезагружает инвентарь
func close_and_reload_inventory(main_node: Node, member_index: int, gang_members: Array, player_data: Dictionary):
	# Закрываем popup
	var popup = main_node.get_node_or_null("ItemPopup")
	if popup:
		popup.queue_free()
	
	# Закрываем старый инвентарь
	var inv_menu = main_node.get_node_or_null("InventoryMenu")
	if inv_menu:
		inv_menu.queue_free()
	
	# Ждём один кадр чтобы ноды успели удалиться
	await main_node.get_tree().process_frame
	
	# Открываем новый инвентарь
	show_inventory_for_member(main_node, member_index, gang_members, player_data)
