# item_popup.gd (ПОЛНАЯ ВЕРСИЯ БЕЗ ОШИБОК)
extends CanvasLayer

signal action_selected(item_name: String, action: String, pocket_index: int)

var item_name: String = ""
var from_pocket: bool = false
var pocket_index: int = -1
var items_db
var player_data

func _ready():
	layer = 220  # ✅ КРИТИЧНО! ВЫШЕ инвентаря (200)
	items_db = get_node("/root/ItemsDB")

func setup(p_item_name: String, p_player_data = null, p_from_pocket: bool = false, p_pocket_index: int = -1):
	item_name = p_item_name
	player_data = p_player_data
	from_pocket = p_from_pocket
	pocket_index = p_pocket_index
	create_ui()

func create_ui():
	# ✅ Overlay
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.position = Vector2(0, 0)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(400, 650)
	bg.position = Vector2(160, 315)
	bg.color = Color(0.1, 0.1, 0.1, 0.98)
	bg.name = "PopupBG"
	add_child(bg)
	
	var item_title = Label.new()
	item_title.text = item_name
	item_title.position = Vector2(300, 335)
	item_title.add_theme_font_size_override("font_size", 24)
	item_title.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	add_child(item_title)
	
	var item_data = items_db.get_item(item_name)
	if item_data:
		var desc = Label.new()
		desc.text = item_data["description"]
		desc.position = Vector2(180, 380)
		desc.add_theme_font_size_override("font_size", 16)
		desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc.custom_minimum_size = Vector2(360, 0)
		add_child(desc)
		
		var stats_y = 420
		if "damage" in item_data:
			var dmg = Label.new()
			dmg.text = "⚔ Урон: +" + str(item_data["damage"])
			dmg.position = Vector2(180, stats_y)
			dmg.add_theme_font_size_override("font_size", 18)
			dmg.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
			add_child(dmg)
			stats_y += 30
		
		if "defense" in item_data:
			var def_label = Label.new()
			def_label.text = "🛡 Защита: +" + str(item_data["defense"])
			def_label.position = Vector2(180, stats_y)
			def_label.add_theme_font_size_override("font_size", 18)
			def_label.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0, 1.0))
			add_child(def_label)
			stats_y += 30
	
	var actions = get_available_actions(item_name)
	
	var action_y = 620
	for i in range(actions.size()):
		var action_btn = Button.new()
		action_btn.custom_minimum_size = Vector2(360, 45)
		action_btn.position = Vector2(180, action_y)
		action_btn.text = actions[i]
		action_btn.name = "PopupAction_" + str(i)
		
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.25, 0.3, 0.25, 1.0)
		action_btn.add_theme_stylebox_override("normal", style_normal)
		
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.35, 0.4, 0.35, 1.0)
		action_btn.add_theme_stylebox_override("hover", style_hover)
		
		action_btn.add_theme_font_size_override("font_size", 20)
		action_btn.add_theme_color_override("font_color", Color.WHITE)
		
		var current_action = actions[i]
		action_btn.pressed.connect(func():
			action_selected.emit(item_name, current_action, pocket_index)
			queue_free()
		)
		
		add_child(action_btn)
		action_y += 55
	
	var close_popup = Button.new()
	close_popup.custom_minimum_size = Vector2(360, 45)
	close_popup.position = Vector2(180, 900)
	close_popup.text = "ОТМЕНА"
	close_popup.name = "ClosePopup"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_popup.add_theme_stylebox_override("normal", style_close)
	
	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_popup.add_theme_stylebox_override("hover", style_close_hover)
	
	close_popup.add_theme_font_size_override("font_size", 20)
	close_popup.add_theme_color_override("font_color", Color.WHITE)
	
	close_popup.pressed.connect(func(): queue_free())
	
	add_child(close_popup)

func get_available_actions(p_item_name: String) -> Array:
	var actions = []
	var item_data = items_db.get_item(p_item_name)
	
	if item_data:
		var item_type = item_data["type"]
		
		if from_pocket:
			if item_type == "consumable":
				actions.append("Использовать")
			actions.append("Убрать из кармана")
			actions.append("Выбросить")
		else:
			if item_type in ["helmet", "armor", "melee", "ranged", "gadget"]:
				actions.append("Надеть")
			
			if item_type == "consumable":
				actions.append("Использовать")
				if player_data and player_data.has("pockets"):
					for i in range(player_data["pockets"].size()):
						if player_data["pockets"][i] == null:
							actions.append("В карман")
							break
			
			actions.append("Выбросить")
	
	return actions
