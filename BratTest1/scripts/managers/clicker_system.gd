# clicker_system.gd
# Система быстрого заработка (кликер)
extends Node

var player_stats
var ui_layer: CanvasLayer

var click_count: int = 0
var click_multiplier: float = 1.0

var player_data: Dictionary

func initialize(p_ui_layer, p_player_data):
	ui_layer = p_ui_layer
	player_data = p_player_data
	
	# Загружаем систему статистики
	player_stats = get_node_or_null("/root/PlayerStats")
	
	create_quick_earn_button()

func create_quick_earn_button():
	var quick_earn_btn = Button.new()
	quick_earn_btn.custom_minimum_size = Vector2(120, 50)
	quick_earn_btn.position = Vector2(590, 55)
	quick_earn_btn.text = "💰 +1р"
	quick_earn_btn.name = "QuickEarnBtn"
	
	var style_earn = StyleBoxFlat.new()
	style_earn.bg_color = Color(0.2, 0.5, 0.2, 1.0)
	quick_earn_btn.add_theme_stylebox_override("normal", style_earn)
	
	var style_earn_hover = StyleBoxFlat.new()
	style_earn_hover.bg_color = Color(0.3, 0.6, 0.3, 1.0)
	quick_earn_btn.add_theme_stylebox_override("hover", style_earn_hover)
	
	quick_earn_btn.add_theme_font_size_override("font_size", 16)
	quick_earn_btn.pressed.connect(func(): on_quick_earn_clicked())
	
	ui_layer.add_child(quick_earn_btn)

func on_quick_earn_clicked():
	click_count += 1
	
	# Базовая сумма 1-10 рублей
	var base_earn = randi_range(1, 10)
	
	# Бонус от клика (каждые 10 кликов +10%)
	click_multiplier = 1.0 + (click_count / 10) * 0.1
	
	# Бонус от удачи
	var luck_bonus = 0.0
	if player_stats:
		var luck = player_stats.get_stat("LCK")
		luck_bonus = luck * 0.05  # +5% за единицу удачи
	
	# Итоговая сумма
	var total_earn = int(base_earn * click_multiplier * (1.0 + luck_bonus))
	total_earn = max(1, total_earn)  # Минимум 1 рубль
	
	player_data["balance"] += total_earn
	
	# ВАЖНО: Обновляем UI через главную сцену
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("update_ui"):
		main_scene.update_ui()
	
	# Обновляем текст кнопки
	var btn = ui_layer.get_node_or_null("QuickEarnBtn")
	if btn:
		btn.text = "💰 +" + str(total_earn) + "р"
	
	# Показываем всплывающий текст
	show_floating_earn(total_earn)
	
	# Небольшой опыт к удаче каждые 5 кликов
	if click_count % 5 == 0 and player_stats:
		player_stats.add_stat_xp("LCK", 1)

func show_floating_earn(amount: int):
	var floating_label = Label.new()
	floating_label.text = "+" + str(amount) + " руб."
	floating_label.position = Vector2(650, 80)
	floating_label.add_theme_font_size_override("font_size", 20)
	floating_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	floating_label.z_index = 100
	ui_layer.add_child(floating_label)
	
	# Анимация вверх и исчезновение
	var parent = get_tree().current_scene
	if parent:
		var tween = parent.create_tween()
		tween.set_parallel(true)
		tween.tween_property(floating_label, "position:y", floating_label.position.y - 50, 1.0)
		tween.tween_property(floating_label, "modulate:a", 0.0, 1.0)
		
		await tween.finished
		floating_label.queue_free()
