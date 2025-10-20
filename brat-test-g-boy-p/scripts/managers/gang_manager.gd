extends Node

func show_gang_menu(main_node: Node, gang_members: Array):
	var gang_menu_script = load("res://scripts/ui/gang_menu.gd")
	var gang_menu = gang_menu_script.new()
	gang_menu.name = "GangMenu"
	main_node.add_child(gang_menu)
	gang_menu.setup(gang_members)
	
	gang_menu.member_inventory_clicked.connect(func(member_index):
		var inv_manager = get_node("/root/InventoryManager")
		inv_manager.show_inventory_for_member(main_node, member_index, gang_members, main_node.player_data)
	)
