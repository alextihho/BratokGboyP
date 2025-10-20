# police_system.gd (ПОЛИЦИЯ + УА + ФСБ)
# Autoload: /root/PoliceSystem
extends Node

signal ua_changed(new_ua: int)
signal police_raid_started(location: String)
signal police_encounter(can_surrender: bool)

# === УРОВЕНЬ АГРЕССИИ (УА) ===
var ua_level: int = 0  # 0-100
var max_ua: int = 100

# === СТАТИСТИКА ===
var crimes_committed: int = 0
var bribes_given: int = 0
var surrenders: int = 0

# === РЕЙДЫ ===
var raid_timer: Timer = null
var raid_active: bool = false

func _ready():
	print("🚔 Система полиции загружена (УА: %d)" % ua_level)
	setup_raid_timer()

# === ТАЙМЕР РЕЙДОВ ===
func setup_raid_timer():
	raid_timer = Timer.new()
	raid_timer.wait_time = 60.0  # Рейды раз в минуту при УА=100
	raid_timer.one_shot = false
	raid_timer.autostart = false
	raid_timer.timeout.connect(_on_raid_check)
	add_child(raid_timer)

# === ДОБАВЛЕНИЕ УА ===
func add_ua(amount: int, reason: String = ""):
	var old_ua = ua_level
	ua_level += amount
	ua_level = clamp(ua_level, 0, max_ua)
	
	if reason != "":
		print("🚔 УА +%d (%s): %d → %d" % [amount, reason, old_ua, ua_level])
	
	ua_changed.emit(ua_level)
	
	# Включаем рейды при УА=100
	if ua_level >= 100 and not raid_timer.is_stopped():
		raid_timer.start()
		print("⚠️ ПОЛИЦИЯ НАЧАЛА РЕЙДЫ!")
	elif ua_level < 100 and not raid_timer.is_stopped():
		raid_timer.stop()

# === СНИЖЕНИЕ УА ===
func reduce_ua(amount: int):
	ua_level -= amount
	ua_level = max(0, ua_level)
	ua_changed.emit(ua_level)
	print("🚔 УА снижен на %d → %d" % [amount, ua_level])

# === ПРЕСТУПЛЕНИЯ ===
func report_crime(crime_type: String):
	crimes_committed += 1
	
	match crime_type:
		"stealth":
			add_ua(randi_range(1, 3), "подкрадывание")
		"alarm":
			add_ua(randi_range(10, 25), "срабатывание сигнализации")
		"theft":
			add_ua(randi_range(5, 15), "кража")
		"assault":
			add_ua(randi_range(15, 30), "нападение")
		"murder":
			add_ua(randi_range(30, 50), "убийство")
		"robbery":
			add_ua(randi_range(20, 40), "ограбление")

# === ВЗЯТКА В ФСБ ===
func bribe_fsb(amount: int) -> bool:
	var ua_reduction = int(amount / 100.0)  # 1 УА за 100 руб.
	ua_reduction = min(ua_reduction, ua_level)
	
	if ua_reduction > 0:
		reduce_ua(ua_reduction)
		bribes_given += 1
		print("💵 Взятка ФСБ: %d руб. → -%d УА" % [amount, ua_reduction])
		return true
	return false

# === ВСТРЕЧА С ПОЛИЦИЕЙ ===
func encounter_police(main_node: Node, player_data: Dictionary, crime_severity: int = 0) -> void:
	print("🚔 Встреча с полицией!")
	police_encounter.emit(true)
	show_police_encounter(main_node, player_data, crime_severity)

# === МЕНЮ ВСТРЕЧИ С ПОЛИЦИЕЙ ===
func show_police_encounter(main_node: Node, player_data: Dictionary, crime_severity: int):
	var police_menu = CanvasLayer.new()
	police_menu.name = "PoliceEncounter"
	police_menu.layer = 210
	main_node.add_child(police_menu)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	police_menu.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(600, 500)
	bg.position = Vector2(60, 390)
	bg.color = Color(0.1, 0.1, 0.2, 0.98)
	police_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "🚔 ПОЛИЦИЯ!"
	title.position = Vector2(260, 410)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.3, 0.5, 1.0, 1.0))
	police_menu.add_child(title)
	
	var message = Label.new()
	message.text = "Вас остановили сотрудники полиции"
	message.position = Vector2(140, 470)
	message.add_theme_font_size_override("font_size", 18)
	message.add_theme_color_override("font_color", Color.WHITE)
	police_menu.add_child(message)
	
	var ua_label = Label.new()
	ua_label.text = "⚠️ Уровень Агрессии: %d/100" % ua_level
	ua_label.position = Vector2(220, 510)
	ua_label.add_theme_font_size_override("font_size", 16)
	ua_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1.0))
	police_menu.add_child(ua_label)
	
	# Кнопка "Сдаться"
	var surrender_btn = Button.new()
	surrender_btn.custom_minimum_size = Vector2(540, 60)
	surrender_btn.position = Vector2(90, 570)
	surrender_btn.text = "🙋 СДАТЬСЯ"
	
	var style_surrender = StyleBoxFlat.new()
	style_surrender.bg_color = Color(0.2, 0.4, 0.6, 1.0)
	surrender_btn.add_theme_stylebox_override("normal", style_surrender)
	surrender_btn.add_theme_font_size_override("font_size", 22)
	
	surrender_btn.pressed.connect(func():
		handle_surrender(main_node, player_data, crime_severity, police_menu)
	)
	police_menu.add_child(surrender_btn)
	
	# Кнопка "Бежать"
	var flee_btn = Button.new()
	flee_btn.custom_minimum_size = Vector2(540, 60)
	flee_btn.position = Vector2(90, 650)
	flee_btn.text = "🏃 БЕЖАТЬ"
	
	var style_flee = StyleBoxFlat.new()
	style_flee.bg_color = Color(0.6, 0.4, 0.2, 1.0)
	flee_btn.add_theme_stylebox_override("normal", style_flee)
	flee_btn.add_theme_font_size_override("font_size", 22)
	
	flee_btn.pressed.connect(func():
		handle_flee(main_node, player_data, police_menu)
	)
	police_menu.add_child(flee_btn)
	
	# Кнопка "Драться"
	var fight_btn = Button.new()
	fight_btn.custom_minimum_size = Vector2(540, 60)
	fight_btn.position = Vector2(90, 730)
	fight_btn.text = "⚔️ ДРАТЬСЯ"
	
	var style_fight = StyleBoxFlat.new()
	style_fight.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	fight_btn.add_theme_stylebox_override("normal", style_fight)
	fight_btn.add_theme_font_size_override("font_size", 22)
	
	fight_btn.pressed.connect(func():
		handle_fight(main_node, police_menu)
	)
	police_menu.add_child(fight_btn)
	
	# Предупреждение
	var warning = Label.new()
	warning.text = "⚠️ Сопротивление полиции увеличит УА!"
	warning.position = Vector2(150, 820)
	warning.add_theme_font_size_override("font_size", 14)
	warning.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1.0))
	police_menu.add_child(warning)

# === СДАТЬСЯ ===
func handle_surrender(main_node: Node, player_data: Dictionary, crime_severity: int, police_menu: CanvasLayer):
	surrenders += 1
	
	# Проверка: УА + тяжесть + харизма + авторитет
	var player_stats = get_node("/root/PlayerStats")
	var charisma = player_stats.get_stat("Харизма") if player_stats else 0
	var reputation = player_data.get("reputation", 0)
	
	var check_value = ua_level + crime_severity - charisma - (reputation / 10)
	
	var outcome = ""
	var fine = 0
	
	if check_value < 30:
		outcome = "Отпустили с предупреждением"
		reduce_ua(5)
	elif check_value < 60:
		fine = randi_range(100, 500)
		outcome = "Штраф: %d руб." % fine
		player_data["balance"] -= fine
		reduce_ua(10)
	else:
		outcome = "Арест! Потеряно 3 дня"
		var time_system = get_node_or_null("/root/TimeSystem")
		if time_system:
			time_system.add_minutes(3 * 24 * 60)
		player_data["balance"] -= randi_range(500, 1000)
		reduce_ua(20)
	
	police_menu.queue_free()
	main_node.show_message("🚔 " + outcome)
	main_node.update_ui()

# === БЕЖАТЬ ===
func handle_flee(main_node: Node, player_data: Dictionary, police_menu: CanvasLayer):
	var player_stats = get_node("/root/PlayerStats")
	var agi = player_stats.get_stat("AGI") if player_stats else 4
	
	var flee_chance = 0.3 + agi * 0.04
	
	if randf() < flee_chance:
		add_ua(randi_range(10, 20), "бегство от полиции")
		police_menu.queue_free()
		main_node.show_message("🏃 Вы успешно сбежали! (+УА)")
	else:
		add_ua(randi_range(20, 30), "неудачное бегство")
		police_menu.queue_free()
		main_node.show_message("❌ Не удалось сбежать! Вас догнали!")
		
		# Принудительная сдача
		await main_node.get_tree().create_timer(1.5).timeout
		handle_surrender(main_node, player_data, 30, police_menu)

# === ДРАТЬСЯ ===
func handle_fight(main_node: Node, police_menu: CanvasLayer):
	add_ua(randi_range(40, 60), "сопротивление полиции")
	police_menu.queue_free()
	
	main_node.show_message("⚔️ Вступили в бой с полицией! (+40-60 УА)")
	
	await main_node.get_tree().create_timer(1.5).timeout
	
	var battle_manager = get_node_or_null("/root/BattleManager")
	if battle_manager:
		main_node.start_battle("guard")

# === РЕЙД ПОЛИЦИИ ===
func _on_raid_check():
	if ua_level < 100:
		return
	
	if raid_active:
		return
	
	# Шанс рейда 20%
	if randf() < 0.2:
		start_raid()

func start_raid():
	raid_active = true
	var districts_system = get_node_or_null("/root/DistrictsSystem")
	
	if not districts_system:
		return
	
	# Выбираем случайный контролируемый район
	var controlled_districts = []
	for district_name in districts_system.districts:
		var district = districts_system.districts[district_name]
		if district.get("owner", "") == "Игрок":
			controlled_districts.append(district_name)
	
	if controlled_districts.is_empty():
		raid_active = false
		return
	
	var target_district = controlled_districts[randi() % controlled_districts.size()]
	
	print("🚨 РЕЙД ПОЛИЦИИ В РАЙОНЕ: " + target_district)
	police_raid_started.emit(target_district)
	
	# Потеря влияния
	districts_system.add_influence(target_district, "Игрок", -randi_range(10, 20))
	
	raid_active = false

# === МЕНЮ ФСБ ===
func show_fsb_menu(main_node: Node, player_data: Dictionary):
	var fsb_menu = CanvasLayer.new()
	fsb_menu.name = "FSBMenu"
	fsb_menu.layer = 200
	main_node.add_child(fsb_menu)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	fsb_menu.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(700, 800)
	bg.position = Vector2(10, 240)
	bg.color = Color(0.05, 0.05, 0.1, 0.98)
	fsb_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "🏛️ ЗДАНИЕ ФСБ"
	title.position = Vector2(220, 260)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.5, 0.5, 1.0, 1.0))
	fsb_menu.add_child(title)
	
	var ua_info = Label.new()
	ua_info.text = "Текущий УА: %d/100" % ua_level
	ua_info.position = Vector2(260, 320)
	ua_info.add_theme_font_size_override("font_size", 20)
	ua_info.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1.0))
	fsb_menu.add_child(ua_info)
	
	var hint = Label.new()
	hint.text = "💵 1000 руб. = -10 УА"
	hint.position = Vector2(260, 360)
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	fsb_menu.add_child(hint)
	
	# Варианты взяток
	var bribes = [
		{"amount": 500, "ua_reduction": 5},
		{"amount": 1000, "ua_reduction": 10},
		{"amount": 5000, "ua_reduction": 50},
		{"amount": 10000, "ua_reduction": 100}
	]
	
	var y_pos = 420
	
	for bribe in bribes:
		var bribe_btn = Button.new()
		bribe_btn.custom_minimum_size = Vector2(680, 60)
		bribe_btn.position = Vector2(20, y_pos)
		bribe_btn.text = "💵 Дать %d руб. (-%d УА)" % [bribe["amount"], bribe["ua_reduction"]]
		
		var can_afford = player_data["balance"] >= bribe["amount"]
		bribe_btn.disabled = not can_afford
		
		var style = StyleBoxFlat.new()
		if can_afford:
			style.bg_color = Color(0.2, 0.4, 0.2, 1.0)
		else:
			style.bg_color = Color(0.3, 0.3, 0.3, 1.0)
		bribe_btn.add_theme_stylebox_override("normal", style)
		bribe_btn.add_theme_font_size_override("font_size", 20)
		
		var bribe_amount = bribe["amount"]
		bribe_btn.pressed.connect(func():
			if player_data["balance"] >= bribe_amount:
				player_data["balance"] -= bribe_amount
				bribe_fsb(bribe_amount)
				main_node.show_message("💵 Взятка принята! УА снижен")
				main_node.update_ui()
				fsb_menu.queue_free()
		)
		
		fsb_menu.add_child(bribe_btn)
		y_pos += 80
	
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(680, 60)
	close_btn.position = Vector2(20, 960)
	close_btn.text = "УЙТИ"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	close_btn.add_theme_font_size_override("font_size", 22)
	close_btn.pressed.connect(func(): fsb_menu.queue_free())
	
	fsb_menu.add_child(close_btn)

# === ПОЛУЧИТЬ ДАННЫЕ ===
func get_ua() -> int:
	return ua_level

func get_stats() -> Dictionary:
	return {
		"ua": ua_level,
		"crimes": crimes_committed,
		"bribes": bribes_given,
		"surrenders": surrenders
	}
