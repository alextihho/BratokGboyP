# police_system.gd (Полиция и Уровень Агрессии)
extends Node

signal ua_changed(new_ua: int)
signal police_raid_started(district: String)
signal player_arrested()

var ua_level: int = 0  # Уровень Агрессии (0-100)
var raids_active: bool = false

# История преступлений (для расчёта наказания)
var crime_history = {
	"theft": 0,        # Кражи
	"robbery": 0,      # Ограбления
	"assault": 0,      # Нападения
	"murder": 0,       # Убийства
	"break_in": 0      # Взломы
}

func _ready():
	print("🚔 Система полиции загружена (УА: %d)" % ua_level)

# ========== УВЕЛИЧЕНИЕ УА ==========

func add_ua(amount: int, reason: String = ""):
	var old_ua = ua_level
	ua_level = clamp(ua_level + amount, 0, 100)
	
	if ua_level != old_ua:
		print("🚔 УА: %d → %d (%s)" % [old_ua, ua_level, reason])
		ua_changed.emit(ua_level)
		
		# При достижении 100 УА начинаются рейды
		if ua_level >= 100 and not raids_active:
			start_raids()

func reduce_ua(amount: int, reason: String = ""):
	var old_ua = ua_level
	ua_level = clamp(ua_level - amount, 0, 100)
	
	if ua_level != old_ua:
		print("🚔 УА: %d → %d (%s)" % [old_ua, ua_level, reason])
		ua_changed.emit(ua_level)
		
		# Если УА упал ниже 100, рейды прекращаются
		if ua_level < 100 and raids_active:
			stop_raids()

# ========== РЕГИСТРАЦИЯ ПРЕСТУПЛЕНИЙ ==========

func register_crime(crime_type: String, severity: int):
	if crime_history.has(crime_type):
		crime_history[crime_type] += 1
	
	add_ua(severity, crime_type)

# Примеры:
func on_stealth_detected():
	add_ua(randi_range(1, 3), "подкрадывание обнаружено")

func on_alarm_triggered():
	add_ua(randi_range(10, 25), "сработала сигнализация")

func on_body_looted():
	add_ua(randi_range(10, 20), "обыск тел")

func on_theft(value: int):
	register_crime("theft", min(5 + value / 100, 15))

func on_robbery(location: String):
	register_crime("robbery", randi_range(15, 30))

func on_assault():
	register_crime("assault", randi_range(5, 15))

func on_murder():
	register_crime("murder", randi_range(20, 40))

func on_break_in():
	register_crime("break_in", randi_range(10, 20))

# ========== РЕЙДЫ ==========

func start_raids():
	raids_active = true
	print("🚨 ПОЛИЦИЯ НАЧАЛА РЕЙДЫ!")
	
	var districts_system = get_node_or_null("/root/DistrictsSystem")
	if districts_system:
		# Рейд в случайный контролируемый район
		var player_districts = []
		for district_name in districts_system.districts:
			var district = districts_system.districts[district_name]
			if district.get("owner", "") == "Игрок":
				player_districts.append(district_name)
		
		if player_districts.size() > 0:
			var target = player_districts[randi() % player_districts.size()]
			police_raid_started.emit(target)

func stop_raids():
	raids_active = false
	print("🚔 Рейды полиции прекращены")

# ========== ВЗАИМОДЕЙСТВИЕ С ПОЛИЦИЕЙ ==========

func show_surrender_menu(main_node: Node):
	var surrender_menu = CanvasLayer.new()
	surrender_menu.name = "SurrenderMenu"
	surrender_menu.layer = 150
	main_node.add_child(surrender_menu)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	surrender_menu.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(500, 400)
	bg.position = Vector2(110, 440)
	bg.color = Color(0.1, 0.1, 0.15, 0.98)
	surrender_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "🚔 ПОЛИЦИЯ!"
	title.position = Vector2(280, 460)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.3, 0.5, 1.0, 1.0))
	surrender_menu.add_child(title)
	
	var info = Label.new()
	info.text = "Вас окружили! Сдаться или драться?"
	info.position = Vector2(180, 520)
	info.add_theme_font_size_override("font_size", 18)
	info.add_theme_color_override("font_color", Color.WHITE)
	surrender_menu.add_child(info)
	
	var ua_label = Label.new()
	ua_label.text = "Уровень Агрессии: %d/100" % ua_level
	ua_label.position = Vector2(230, 560)
	ua_label.add_theme_font_size_override("font_size", 16)
	ua_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1.0))
	surrender_menu.add_child(ua_label)
	
	# Кнопка "Сдаться"
	var surrender_btn = Button.new()
	surrender_btn.custom_minimum_size = Vector2(460, 60)
	surrender_btn.position = Vector2(130, 620)
	surrender_btn.text = "🙌 СДАТЬСЯ"
	
	var style_surrender = StyleBoxFlat.new()
	style_surrender.bg_color = Color(0.3, 0.5, 0.7, 1.0)
	surrender_btn.add_theme_stylebox_override("normal", style_surrender)
	surrender_btn.add_theme_font_size_override("font_size", 20)
	
	surrender_btn.pressed.connect(func():
		surrender_menu.queue_free()
		process_surrender(main_node)
	)
	surrender_menu.add_child(surrender_btn)
	
	# Кнопка "Драться"
	var fight_btn = Button.new()
	fight_btn.custom_minimum_size = Vector2(460, 60)
	fight_btn.position = Vector2(130, 700)
	fight_btn.text = "⚔️ ДРАТЬСЯ С ПОЛИЦИЕЙ"
	
	var style_fight = StyleBoxFlat.new()
	style_fight.bg_color = Color(0.7, 0.2, 0.2, 1.0)
	fight_btn.add_theme_stylebox_override("normal", style_fight)
	fight_btn.add_theme_font_size_override("font_size", 20)
	
	fight_btn.pressed.connect(func():
		surrender_menu.queue_free()
		start_police_fight(main_node)
	)
	surrender_menu.add_child(fight_btn)
	
	# Кнопка "Убежать"
	var run_btn = Button.new()
	run_btn.custom_minimum_size = Vector2(460, 60)
	run_btn.position = Vector2(130, 780)
	run_btn.text = "🏃 ПОПЫТАТЬСЯ УБЕЖАТЬ"
	
	var style_run = StyleBoxFlat.new()
	style_run.bg_color = Color(0.5, 0.5, 0.2, 1.0)
	run_btn.add_theme_stylebox_override("normal", style_run)
	run_btn.add_theme_font_size_override("font_size", 20)
	
	run_btn.pressed.connect(func():
		surrender_menu.queue_free()
		attempt_escape(main_node)
	)
	surrender_menu.add_child(run_btn)

func process_surrender(main_node: Node):
	var player_stats = get_node_or_null("/root/PlayerStats")
	
	# Расчёт исхода
	var base_chance = 0.3
	
	# Бонус от харизмы
	if player_stats:
		var cha = player_stats.get_stat("CHA")
		base_chance += cha * 0.05
	
	# Штраф от УА
	base_chance -= (ua_level / 100.0) * 0.3
	
	# Штраф от тяжести преступлений
	var crime_severity = crime_history.get("murder", 0) * 10 + crime_history.get("robbery", 0) * 5
	base_chance -= crime_severity * 0.01
	
	var roll = randf()
	
	if roll < base_chance:
		# Отпустили
		main_node.show_message("🚔 Полиция отпустила вас с предупреждением")
		reduce_ua(20, "сдался полиции")
	elif roll < base_chance + 0.3:
		# Штраф
		var fine = randi_range(100, 500) + ua_level * 5
		main_node.player_data["balance"] -= fine
		main_node.show_message("🚔 Штраф: " + str(fine) + " руб.")
		reduce_ua(30, "заплатил штраф")
		main_node.update_ui()
	else:
		# Арест
		arrest_player(main_node)

func arrest_player(main_node: Node):
	var jail_time = randi_range(1, 3)
	
	main_node.show_message("🚔 ВАС АРЕСТОВАЛИ НА %d ДНЯ!" % jail_time)
	
	# Штраф + потеря времени
	var fine = randi_range(300, 1000)
	main_node.player_data["balance"] = max(0, main_node.player_data["balance"] - fine)
	
	# Добавляем дни
	var time_system = get_node_or_null("/root/TimeSystem")
	if time_system:
		for i in range(jail_time):
			time_system.add_minutes(24 * 60)  # +1 день
	
	reduce_ua(50, "отсидел в тюрьме")
	player_arrested.emit()
	main_node.update_ui()

func start_police_fight(main_node: Node):
	main_node.show_message("⚔️ Вступаете в бой с полицией!")
	
	# Значительное увеличение УА
	add_ua(30, "напал на полицию")
	
	var battle_manager = main_node.get_node_or_null("BattleManager")
	if battle_manager:
		battle_manager.start_battle(main_node, "guard")  # Полиция = охранники

func attempt_escape(main_node: Node):
	var player_stats = get_node_or_null("/root/PlayerStats")
	
	var escape_chance = 0.3
	if player_stats:
		var agi = player_stats.get_stat("AGI")
		var stealth = player_stats.get_stat("STEALTH")
		escape_chance += (agi + stealth) * 0.03
	
	if randf() < escape_chance:
		main_node.show_message("🏃 Вам удалось убежать!")
		add_ua(10, "убежал от полиции")
	else:
		main_node.show_message("🚔 Не удалось! Вас поймали!")
		add_ua(15, "попытка побега")
		arrest_player(main_node)

# ========== ВЗАИМОДЕЙСТВИЕ С ФСБ ==========

func show_fsb_bribe_menu(main_node: Node):
	var fsb_menu = CanvasLayer.new()
	fsb_menu.name = "FSBMenu"
	fsb_menu.layer = 150
	main_node.add_child(fsb_menu)
	
	var overlay = ColorRect.new()
	overlay.size = Vector2(720, 1280)
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	fsb_menu.add_child(overlay)
	
	var bg = ColorRect.new()
	bg.size = Vector2(600, 500)
	bg.position = Vector2(60, 390)
	bg.color = Color(0.05, 0.05, 0.1, 0.98)
	fsb_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "🏛️ ЗДАНИЕ ФСБ"
	title.position = Vector2(240, 410)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 1.0))
	fsb_menu.add_child(title)
	
	var ua_info = Label.new()
	ua_info.text = "Текущий УА: %d/100" % ua_level
	ua_info.position = Vector2(80, 470)
	ua_info.add_theme_font_size_override("font_size", 20)
	ua_info.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1.0))
	fsb_menu.add_child(ua_info)
	
	var hint = Label.new()
	hint.text = "Можно 'подарить' деньги для снижения УА"
	hint.position = Vector2(130, 510)
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	fsb_menu.add_child(hint)
	
	# Варианты взяток
	var bribes = [
		{"amount": 500, "ua_reduce": 10},
		{"amount": 1000, "ua_reduce": 25},
		{"amount": 2500, "ua_reduce": 50},
		{"amount": 5000, "ua_reduce": 100}
	]
	
	var y_pos = 560
	
	for bribe in bribes:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(560, 60)
		btn.position = Vector2(80, y_pos)
		btn.text = "💰 %d руб. → -%d УА" % [bribe["amount"], bribe["ua_reduce"]]
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.2, 0.3, 0.2, 1.0)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_font_size_override("font_size", 18)
		
		var amount = bribe["amount"]
		var reduce = bribe["ua_reduce"]
		
		btn.pressed.connect(func():
			if main_node.player_data["balance"] >= amount:
				main_node.player_data["balance"] -= amount
				reduce_ua(reduce, "взятка в ФСБ")
				main_node.show_message("💸 Взятка принята. УА снижен на %d" % reduce)
				main_node.update_ui()
				fsb_menu.queue_free()
			else:
				main_node.show_message("❌ Недостаточно денег!")
		)
		
		fsb_menu.add_child(btn)
		y_pos += 70
	
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(560, 50)
	close_btn.position = Vector2(80, 840)
	close_btn.text = "ЗАКРЫТЬ"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(func(): fsb_menu.queue_free())
	
	fsb_menu.add_child(close_btn)

# ========== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==========

func get_ua_color() -> Color:
	if ua_level < 30:
		return Color(0.3, 1.0, 0.3, 1.0)  # Зелёный
	elif ua_level < 70:
		return Color(1.0, 1.0, 0.3, 1.0)  # Жёлтый
	else:
		return Color(1.0, 0.3, 0.3, 1.0)  # Красный

func get_ua_status() -> String:
	if ua_level < 30:
		return "Низкий"
	elif ua_level < 70:
		return "Средний"
	else:
		return "ВЫСОКИЙ!"

func get_save_data() -> Dictionary:
	return {
		"ua_level": ua_level,
		"raids_active": raids_active,
		"crime_history": crime_history.duplicate()
	}

func load_save_data(data: Dictionary):
	ua_level = data.get("ua_level", 0)
	raids_active = data.get("raids_active", false)
	crime_history = data.get("crime_history", crime_history).duplicate()
	ua_changed.emit(ua_level)
