extends CanvasLayer

signal action_selected(district_name: String, action: String)
signal back_pressed()

var districts_system
var district_name: String = ""

func _ready():
	districts_system = get_node_or_null("/root/DistrictsSystem")

func setup(p_district_name: String):
	district_name = p_district_name
	create_ui()

func create_ui():
	for child in get_children():
		child.queue_free()
	
	if not districts_system:
		return
	
	var bg = ColorRect.new()
	bg.size = Vector2(700, 1100)
	bg.position = Vector2(10, 140)
	bg.color = Color(0.05, 0.05, 0.05, 0.95)
	bg.name = "DetailsBG"
	add_child(bg)
	
	var title = Label.new()
	title.text = "📍 " + district_name
	title.position = Vector2(250, 160)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	add_child(title)
	
	# Получаем информацию о районе
	var info_text = districts_system.get_district_info(district_name)
	var info_label = Label.new()
	info_label.text = info_text
	info_label.position = Vector2(30, 220)
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(info_label)
	
	# Детальное влияние всех банд
	var y_pos = 420
	var district_data = districts_system.districts.get(district_name, {})
	
	if district_data.has("influence"):
		var influence_title = Label.new()
		influence_title.text = "═══ ВЛИЯНИЕ БАНД ═══"
		influence_title.position = Vector2(220, y_pos)
		influence_title.add_theme_font_size_override("font_size", 22)
		influence_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
		add_child(influence_title)
		y_pos += 50
		
		for gang in district_data["influence"]:
			var influence_val = district_data["influence"][gang]
			
			var gang_bg = ColorRect.new()
			gang_bg.size = Vector2(660, 60)
			gang_bg.position = Vector2(30, y_pos)
			gang_bg.color = Color(0.15, 0.15, 0.2, 1.0)
			add_child(gang_bg)
			
			var gang_label = Label.new()
			gang_label.text = gang
			gang_label.position = Vector2(40, y_pos + 10)
			gang_label.add_theme_font_size_override("font_size", 18)
			
			var gang_color = Color.WHITE
			if gang == "Игрок":
				gang_color = Color(0.3, 1.0, 0.3, 1.0)
			elif gang == "Нейтральный":
				gang_color = Color(0.7, 0.7, 0.7, 1.0)
			else:
				gang_color = Color(1.0, 0.4, 0.4, 1.0)
			
			gang_label.add_theme_color_override("font_color", gang_color)
			add_child(gang_label)
			
			# Мини прогресс-бар
			var mini_progress_bg = ColorRect.new()
			mini_progress_bg.size = Vector2(400, 15)
			mini_progress_bg.position = Vector2(40, y_pos + 35)
			mini_progress_bg.color = Color(0.2, 0.2, 0.2, 1.0)
			add_child(mini_progress_bg)
			
			var mini_progress_fill = ColorRect.new()
			mini_progress_fill.size = Vector2(400 * (influence_val / 100.0), 15)
			mini_progress_fill.position = Vector2(40, y_pos + 35)
			mini_progress_fill.color = gang_color * 0.7
			add_child(mini_progress_fill)
			
			var percent_text = Label.new()
			percent_text.text = str(influence_val) + "%"
			percent_text.position = Vector2(460, y_pos + 32)
			percent_text.add_theme_font_size_override("font_size", 16)
			percent_text.add_theme_color_override("font_color", gang_color)
			add_child(percent_text)
			
			y_pos += 70
	
	# Бизнесы в районе
	if district_data.has("businesses"):
		var business_title = Label.new()
		business_title.text = "═══ БИЗНЕСЫ В РАЙОНЕ ═══"
		business_title.position = Vector2(200, y_pos + 20)
		business_title.add_theme_font_size_override("font_size", 22)
		business_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
		add_child(business_title)
		y_pos += 70
		
		for business in district_data["businesses"]:
			var business_label = Label.new()
			business_label.text = "🏢 " + business
			business_label.position = Vector2(40, y_pos)
			business_label.add_theme_font_size_override("font_size", 16)
			business_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0, 1.0))
			add_child(business_label)
			y_pos += 30
	
	# Действия
	var actions_title = Label.new()
	actions_title.text = "═══ ДЕЙСТВИЯ ═══"
	actions_title.position = Vector2(240, y_pos + 20)
	actions_title.add_theme_font_size_override("font_size", 22)
	actions_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	add_child(actions_title)
	y_pos += 70
	
	# Кнопка "Увеличить влияние"
	var influence_btn = Button.new()
	influence_btn.custom_minimum_size = Vector2(660, 60)
	influence_btn.position = Vector2(30, y_pos)
	influence_btn.text = "🎯 УВЕЛИЧИТЬ ВЛИЯНИЕ (500 руб.)"
	influence_btn.name = "InfluenceBtn"
	
	var style_influence = StyleBoxFlat.new()
	style_influence.bg_color = Color(0.2, 0.5, 0.2, 1.0)
	influence_btn.add_theme_stylebox_override("normal", style_influence)
	
	var style_influence_hover = StyleBoxFlat.new()
	style_influence_hover.bg_color = Color(0.3, 0.6, 0.3, 1.0)
	influence_btn.add_theme_stylebox_override("hover", style_influence_hover)
	
	influence_btn.add_theme_font_size_override("font_size", 20)
	influence_btn.pressed.connect(func():
		action_selected.emit(district_name, "increase_influence")
	)
	add_child(influence_btn)
	y_pos += 70
	
	# Кнопка "Атаковать соперников"
	var attack_btn = Button.new()
	attack_btn.custom_minimum_size = Vector2(660, 60)
	attack_btn.position = Vector2(30, y_pos)
	attack_btn.text = "⚔️ АТАКОВАТЬ СОПЕРНИКОВ"
	attack_btn.name = "AttackBtn"
	
	var style_attack = StyleBoxFlat.new()
	style_attack.bg_color = Color(0.7, 0.2, 0.2, 1.0)
	attack_btn.add_theme_stylebox_override("normal", style_attack)
	
	var style_attack_hover = StyleBoxFlat.new()
	style_attack_hover.bg_color = Color(0.8, 0.3, 0.3, 1.0)
	attack_btn.add_theme_stylebox_override("hover", style_attack_hover)
	
	attack_btn.add_theme_font_size_override("font_size", 20)
	attack_btn.pressed.connect(func():
		action_selected.emit(district_name, "attack")
	)
	add_child(attack_btn)
	y_pos += 70
	
	# Кнопка "Защитить район" (если район под контролем игрока)
	var player_influence = district_data.get("influence", {}).get("Игрок", 0)
	if player_influence >= 50:
		var defend_btn = Button.new()
		defend_btn.custom_minimum_size = Vector2(660, 60)
		defend_btn.position = Vector2(30, y_pos)
		defend_btn.text = "🛡️ УСИЛИТЬ ЗАЩИТУ (300 руб.)"
		defend_btn.name = "DefendBtn"
		
		var style_defend = StyleBoxFlat.new()
		style_defend.bg_color = Color(0.2, 0.4, 0.6, 1.0)
		defend_btn.add_theme_stylebox_override("normal", style_defend)
		
		var style_defend_hover = StyleBoxFlat.new()
		style_defend_hover.bg_color = Color(0.3, 0.5, 0.7, 1.0)
		defend_btn.add_theme_stylebox_override("hover", style_defend_hover)
		
		defend_btn.add_theme_font_size_override("font_size", 20)
		defend_btn.pressed.connect(func():
			action_selected.emit(district_name, "defend")
		)
		add_child(defend_btn)
		y_pos += 70
	
	# Кнопка "Назад"
	var back_btn = Button.new()
	back_btn.custom_minimum_size = Vector2(660, 60)
	back_btn.position = Vector2(30, 1000)
	back_btn.text = "← НАЗАД К РАЙОНАМ"
	back_btn.name = "BackBtn"
	
	var style_back = StyleBoxFlat.new()
	style_back.bg_color = Color(0.4, 0.4, 0.1, 1.0)
	back_btn.add_theme_stylebox_override("normal", style_back)
	
	var style_back_hover = StyleBoxFlat.new()
	style_back_hover.bg_color = Color(0.5, 0.5, 0.2, 1.0)
	back_btn.add_theme_stylebox_override("hover", style_back_hover)
	
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.pressed.connect(func():
		back_pressed.emit()
		queue_free()
	)
	add_child(back_btn)
