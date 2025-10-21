# battle_ui_helper.gd
# ВСПОМОГАТЕЛЬНЫЙ КЛАСС ДЛЯ UI БОЕВОЙ СИСТЕМЫ
class_name BattleUIHelper
extends RefCounted

# Цвета для морали
static func get_morale_color(morale: int) -> Color:
	if morale >= 70:
		return Color(0.3, 1.0, 0.3, 1.0)
	elif morale >= 40:
		return Color(1.0, 1.0, 0.3, 1.0)
	else:
		return Color(1.0, 0.3, 0.3, 1.0)

# Иконки для статусов
static func get_status_icons(fighter: Dictionary) -> String:
	var icons = []
	
	if fighter.get("status_effects", {}).has("bleeding"):
		icons.append("🩸")
	if fighter.get("status_effects", {}).has("blind"):
		icons.append("👁️")
	if fighter.get("status_effects", {}).has("stunned"):
		icons.append("😵")
	if fighter.get("status_effects", {}).has("disarmed"):
		icons.append("🔫")
	if fighter.get("status_effects", {}).has("crippled"):
		icons.append("🦵")
	
	return " ".join(icons)

# Создание прогресс-бара HP
static func create_hp_bar(parent: Control, fighter: Dictionary, pos: Vector2, size: Vector2):
	var hp_bg = ColorRect.new()
	hp_bg.size = size
	hp_bg.position = pos
	hp_bg.color = Color(0.2, 0.2, 0.2, 1.0)
	hp_bg.name = "HPBarBG"
	parent.add_child(hp_bg)
	
	var hp_percent = float(fighter["hp"]) / float(fighter["max_hp"])
	var hp_fill = ColorRect.new()
	hp_fill.size = Vector2(size.x * hp_percent, size.y)
	hp_fill.position = pos
	hp_fill.color = Color(1.0, 0.3, 0.3, 1.0)
	hp_fill.name = "HPBarFill"
	parent.add_child(hp_fill)

# Анимация попадания
static func flash_red(node: Control, tree: SceneTree):
	var original_modulate = node.modulate
	node.modulate = Color(1.5, 0.5, 0.5, 1.0)
	
	await tree.create_timer(0.3).timeout
	if node and is_instance_valid(node):
		node.modulate = original_modulate

# Форматирование текста боевого лога
static func format_log_entry(text: String, type: String = "normal") -> String:
	match type:
		"damage":
			return "⚔️ " + text
		"heal":
			return "💚 " + text
		"status":
			return "🔥 " + text
		"death":
			return "💀 " + text
		"crit":
			return "💥 " + text
		_:
			return text

# Получение эмодзи по типу бойца
static func get_fighter_emoji(fighter: Dictionary) -> String:
	if fighter.get("is_player", false):
		return "🤵"
	
	var name = fighter.get("name", "")
	if "Главарь" in name or "Босс" in name:
		return "👹"
	elif "Охранник" in name or "Мент" in name:
		return "👮"
	elif "Бандит" in name:
		return "🔫"
	else:
		return "💀"

# Создание информационной панели бойца
static func create_fighter_info_panel(parent: CanvasLayer, fighter: Dictionary, pos: Vector2):
	var panel_bg = ColorRect.new()
	panel_bg.size = Vector2(300, 200)
	panel_bg.position = pos
	panel_bg.color = Color(0.1, 0.1, 0.1, 0.95)
	panel_bg.name = "FighterInfoPanel"
	parent.add_child(panel_bg)
	
	var name_label = Label.new()
	name_label.text = fighter.get("name", "Неизвестный")
	name_label.position = pos + Vector2(10, 10)
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	parent.add_child(name_label)
	
	var hp_label = Label.new()
	hp_label.text = "❤️ HP: %d/%d" % [fighter["hp"], fighter["max_hp"]]
	hp_label.position = pos + Vector2(10, 40)
	hp_label.add_theme_font_size_override("font_size", 16)
	parent.add_child(hp_label)
	
	var morale_label = Label.new()
	morale_label.text = "💪 Мораль: %d" % fighter.get("morale", 100)
	morale_label.position = pos + Vector2(10, 65)
	morale_label.add_theme_font_size_override("font_size", 16)
	morale_label.add_theme_color_override("font_color", get_morale_color(fighter.get("morale", 100)))
	parent.add_child(morale_label)
	
	var damage_label = Label.new()
	damage_label.text = "⚔️ Урон: %d" % fighter.get("damage", 0)
	damage_label.position = pos + Vector2(10, 90)
	damage_label.add_theme_font_size_override("font_size", 14)
	parent.add_child(damage_label)
	
	var defense_label = Label.new()
	defense_label.text = "🛡️ Защита: %d" % fighter.get("defense", 0)
	defense_label.position = pos + Vector2(10, 110)
	defense_label.add_theme_font_size_override("font_size", 14)
	parent.add_child(defense_label)
	
	var accuracy_label = Label.new()
	accuracy_label.text = "🎯 Точность: %.0f%%" % (fighter.get("accuracy", 0.5) * 100)
	accuracy_label.position = pos + Vector2(10, 130)
	accuracy_label.add_theme_font_size_override("font_size", 14)
	parent.add_child(accuracy_label)
	
	var weapon_label = Label.new()
	weapon_label.text = "🔪 Оружие: %s" % fighter.get("weapon", "Кулаки")
	weapon_label.position = pos + Vector2(10, 150)
	weapon_label.add_theme_font_size_override("font_size", 14)
	parent.add_child(weapon_label)
	
	var status_label = Label.new()
	var status_text = get_status_icons(fighter)
	if status_text != "":
		status_label.text = "Статусы: " + status_text
	else:
		status_label.text = "Статусы: нет"
	status_label.position = pos + Vector2(10, 170)
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5, 1.0))
	parent.add_child(status_label)
	
	return panel_bg
