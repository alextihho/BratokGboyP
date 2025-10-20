extends Control

var inventory_vbox: VBoxContainer
var reputation_label: Label
var inventory_button: Button
var car_label: Label

var band_btn: Button
var finance_btn: Button
var activities_btn: Button
var menu_btn: Button

var leader_table: VBoxContainer

func _ready():
	# Фон
	var panel_bg = ColorRect.new()
	panel_bg.size = Vector2(720, 120)
	panel_bg.color = Color.BLACK
	add_child(panel_bg)
	
	# Репутация + HP
	reputation_label = Label.new()
	reputation_label.position = Vector2(10, 10)
	reputation_label.add_theme_font_size_override("font_size", 16)
	add_child(reputation_label)
	
	# Машина
	car_label = Label.new()
	car_label.position = Vector2(10, 30)
	car_label.add_theme_font_size_override("font_size", 14)
	add_child(car_label)
	
	# Инвентарь
	inventory_vbox = VBoxContainer.new()
	inventory_vbox.position = Vector2(150, 10)
	inventory_vbox.size = Vector2(400, 60)
	add_child(inventory_vbox)
	
	# Кнопки (HBox)
	var button_hbox = HBoxContainer.new()
	button_hbox.position = Vector2(10, 80)
	button_hbox.size = Vector2(700, 40)
	add_child(button_hbox)
	
	band_btn = Button.new()
	band_btn.text = "Банда"
	band_btn.size = Vector2(150, 40)
	band_btn.pressed.connect(_on_band_pressed)
	button_hbox.add_child(band_btn)
	
	finance_btn = Button.new()
	finance_btn.text = "Финансы"
	finance_btn.size = Vector2(150, 40)
	finance_btn.pressed.connect(_on_finance_pressed)
	button_hbox.add_child(finance_btn)
	
	activities_btn = Button.new()
	activities_btn.text = "Активности"
	activities_btn.size = Vector2(150, 40)
	activities_btn.pressed.connect(_on_activities_pressed)
	button_hbox.add_child(activities_btn)
	
	menu_btn = Button.new()
	menu_btn.text = "Меню"
	menu_btn.size = Vector2(150, 40)
	menu_btn.pressed.connect(_on_menu_pressed)
	button_hbox.add_child(menu_btn)
	
	# Таблица лидеров
	leader_table = VBoxContainer.new()
	leader_table.position = Vector2(10, 80)
	leader_table.size = Vector2(700, 200)
	leader_table.visible = false
	add_child(leader_table)
	
	var leader_title = Label.new()
	leader_title.text = "Таблица лидеров"
	leader_title.add_theme_font_size_override("font_size", 18)
	leader_table.add_child(leader_title)
	
	var leader1 = Label.new()
	leader1.text = "1. Братан - Авторитет 100"
	leader_table.add_child(leader1)
	
	var leader2 = Label.new()
	leader2.text = "2. Кент - Авторитет 80"
	leader_table.add_child(leader2)
	
	var leader3 = Label.new()
	leader3.text = "3. Пацан - Авторитет 60"
	leader_table.add_child(leader3)
	
	# Тест боя (в меню)
	var test_battle_btn = Button.new()
	test_battle_btn.text = "Тест боя"
	test_battle_btn.position = Vector2(550, 10)  # Вверху, рядом с UI
	test_battle_btn.size = Vector2(150, 40)
	test_battle_btn.pressed.connect(_on_test_battle_pressed)  # Фикс: подключено
	test_battle_btn.disabled = false  # Активна
	add_child(test_battle_btn)
	
	# Подключение
	var player_data = get_node("/root/PlayerData")
	if player_data != null:
		player_data.data_changed.connect(_on_data_changed)
	_update_ui()

func _on_data_changed():
	_update_ui()

func _update_ui():
	var player_data = get_node("/root/PlayerData")
	if player_data == null:
		print("⚠️ PlayerData null in update_ui!")
		reputation_label.text = "Реп: N/A | HP: N/A"
		car_label.text = "Машина: N/A"
		return
	
	reputation_label.text = "Реп: " + str(player_data.data.reputation) + " | HP: " + str(player_data.data.hp)
	car_label.text = "Машина: " + ["Нет", "Шестёрка", "Апгрейд"][player_data.data.car_level]
	
	for child in inventory_vbox.get_children():
		child.queue_free()
	var inv_size = player_data.data.inventory.size()
	for i in range(min(5, inv_size)):
		var label = Label.new()
		label.text = player_data.data.inventory[i]
		label.add_theme_font_size_override("font_size", 14)
		inventory_vbox.add_child(label)
	if inv_size == 0:
		var empty_label = Label.new()
		empty_label.text = "Пусто"
		empty_label.add_theme_font_size_override("font_size", 14)
		inventory_vbox.add_child(empty_label)

func _on_band_pressed():
	print("Клик: Банда")
	get_parent().show_message("Банда: Управление пацанами")

func _on_finance_pressed():
	print("Клик: Финансы")
	get_parent().show_message("Финансы: Твои бабки и траты")

func _on_activities_pressed():
	print("Клик: Активности")
	get_parent().show_message("Активности: Квесты и события")

func _on_menu_pressed():
	print("Клик: Меню")
	leader_table.visible = !leader_table.visible
	if leader_table.visible:
		get_parent().show_message("Таблица лидеров открыта")
	else:
		get_parent().show_message("Таблица закрыта")

# Фикс: Тест боя (активный, запускает battle)
func _on_test_battle_pressed():
	print("Тест боя запущен!")
	var battle_scene = preload("res://scenes/BattleUI.tscn")
	if battle_scene:
		var battle = battle_scene.instantiate()
		get_parent().add_child(battle)
	else:
		print("⚠️ BattleUI.tscn не найден!")
		get_parent().show_message("Бой не доступен")
