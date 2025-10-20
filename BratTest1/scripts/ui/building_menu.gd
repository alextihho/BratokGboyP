# building_menu.gd (ПОЛНЫЙ ИСПРАВЛЕННЫЙ КОД)
extends CanvasLayer

signal action_selected(action_index: int)
signal menu_closed()

var location_name: String = ""
var actions: Array = []

func setup(p_location_name: String, p_actions: Array):
	layer = 20  # ✅ Выше сетки (1)
	
	location_name = p_location_name
	actions = p_actions
	
	print("🏢 Создаём меню для: " + location_name)
	print("📋 Действий в меню: " + str(actions.size()))
	
	create_ui()

func create_ui():
	# ✅ Layer = 150 (Здания выше передвижения, ниже боя)
	layer = 150
	
	print("🏢 Создаём меню для: " + location_name)
	
	# ✅ Полупрозрачный overlay (блокирует клики)
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.position = Vector2(0, 0)
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.name = "Overlay"
	add_child(overlay)
	
	# ✅ Фон меню
	var menu_bg = ColorRect.new()
	menu_bg.size = Vector2(500, 150 + actions.size() * 65)
	menu_bg.position = Vector2(110, 400)
	menu_bg.color = Color(0.05, 0.05, 0.05, 0.95)
	menu_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_bg.name = "MenuBG"
	add_child(menu_bg)
	
	# ✅ Заголовок
	var title = Label.new()
	title.text = "🏢 " + location_name
	title.position = Vector2(260, 420)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	
	# ✅ Кнопки действий
	var y_pos = 480
	
	for i in range(actions.size()):
		var action_btn = Button.new()
		action_btn.custom_minimum_size = Vector2(460, 50)
		action_btn.position = Vector2(130, y_pos)
		action_btn.text = str(i + 1) + ". " + actions[i]
		action_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.2, 0.25, 0.2, 1.0)
		action_btn.add_theme_stylebox_override("normal", style_normal)
		
		var style_hover = StyleBoxFlat.new()
		style_hover.bg_color = Color(0.3, 0.35, 0.3, 1.0)
		action_btn.add_theme_stylebox_override("hover", style_hover)
		
		action_btn.add_theme_font_size_override("font_size", 18)
		action_btn.add_theme_color_override("font_color", Color.WHITE)
		
		var action_index = i
		action_btn.pressed.connect(func():
			print("✅ Создана кнопка %d: %s" % [action_index, actions[action_index]])
			on_action_pressed(action_index)
		)
		
		add_child(action_btn)
		print("✅ Создана кнопка %d: %s" % [i, actions[i]])
		y_pos += 60
	
	# ✅ Кнопка "Закрыть"
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(460, 55)
	close_btn.position = Vector2(130, y_pos + 10)
	close_btn.text = "❌ ЗАКРЫТЬ"
	close_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.add_theme_color_override("font_color", Color.WHITE)
	
	close_btn.pressed.connect(func():
		print("❌ Закрываем меню")
		on_close_pressed()
	)
	
	add_child(close_btn)
	
	print("✅ Меню создано полностью (layer=%d, z_index=200+)" % layer)

func on_action_pressed(action_index: int):
	print("🎯 Выбрано действие %d: %s" % [action_index, actions[action_index]])
	action_selected.emit(action_index)

func on_close_pressed():
	print("✅ Закрываем BuildingMenu")
	menu_closed.emit()
