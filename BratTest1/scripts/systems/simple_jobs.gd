extends Node

signal job_completed(job_name: String, earned: int)

var player_stats

# Список доступных работ
var jobs = {
	"courier": {
		"name": "Курьер",
		"icon": "📦",
		"min_pay": 20,
		"max_pay": 80,
		"duration": 2.0,  # секунды
		"description": "Доставить посылку",
		"stat_xp": {"AGI": 3, "STR": 1}
	},
	"janitor": {
		"name": "Дворник",
		"icon": "🧹",
		"min_pay": 15,
		"max_pay": 50,
		"duration": 3.0,
		"description": "Подмести двор",
		"stat_xp": {"STR": 2}
	},
	"beggar": {
		"name": "Попрошайка",
		"icon": "🙏",
		"min_pay": 1,
		"max_pay": 100,
		"duration": 1.5,
		"description": "Просить милостыню",
		"stat_xp": {"CHA": 5, "LCK": 2}
	},
	"loader": {
		"name": "Грузчик",
		"icon": "💪",
		"min_pay": 30,
		"max_pay": 70,
		"duration": 4.0,
		"description": "Разгрузить товар",
		"stat_xp": {"STR": 5, "AGI": 1}
	}
}

var current_job = null
var job_timer: Timer = null

func _ready():
	player_stats = get_node_or_null("/root/PlayerStats")
	print("💼 Система простых работ загружена")

# Показать меню работ
func show_jobs_menu(main_node: Node, player_data: Dictionary):
	var jobs_menu = CanvasLayer.new()
	jobs_menu.name = "JobsMenu"
	main_node.add_child(jobs_menu)
	
	var bg = ColorRect.new()
	bg.size = Vector2(700, 1100)
	bg.position = Vector2(10, 140)
	bg.color = Color(0.05, 0.05, 0.05, 0.95)
	jobs_menu.add_child(bg)
	
	var title = Label.new()
	title.text = "💼 ПРОСТЫЕ РАБОТЫ"
	title.position = Vector2(220, 160)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	jobs_menu.add_child(title)
	
	var hint = Label.new()
	hint.text = "Быстрый способ заработать немного денег"
	hint.position = Vector2(180, 210)
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	jobs_menu.add_child(hint)
	
	# Проверка, работает ли игрок сейчас
	if current_job != null:
		var working_label = Label.new()
		working_label.text = "⏳ Сейчас вы работаете..."
		working_label.position = Vector2(230, 250)
		working_label.add_theme_font_size_override("font_size", 18)
		working_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
		jobs_menu.add_child(working_label)
		
		var job_info = jobs[current_job]
		var current_job_label = Label.new()
		current_job_label.text = job_info["icon"] + " " + job_info["name"]
		current_job_label.position = Vector2(280, 290)
		current_job_label.add_theme_font_size_override("font_size", 22)
		current_job_label.add_theme_color_override("font_color", Color.WHITE)
		jobs_menu.add_child(current_job_label)
	
	# Список работ
	var y_pos = 350
	var job_keys = jobs.keys()
	
	for job_key in job_keys:
		var job = jobs[job_key]
		
		var job_bg = ColorRect.new()
		job_bg.size = Vector2(680, 140)
		job_bg.position = Vector2(20, y_pos)
		job_bg.color = Color(0.15, 0.15, 0.2, 1.0)
		jobs_menu.add_child(job_bg)
		
		var job_icon = Label.new()
		job_icon.text = job["icon"]
		job_icon.position = Vector2(40, y_pos + 15)
		job_icon.add_theme_font_size_override("font_size", 48)
		jobs_menu.add_child(job_icon)
		
		var job_name = Label.new()
		job_name.text = job["name"]
		job_name.position = Vector2(120, y_pos + 15)
		job_name.add_theme_font_size_override("font_size", 22)
		job_name.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
		jobs_menu.add_child(job_name)
		
		var job_desc = Label.new()
		job_desc.text = job["description"]
		job_desc.position = Vector2(120, y_pos + 45)
		job_desc.add_theme_font_size_override("font_size", 14)
		job_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
		jobs_menu.add_child(job_desc)
		
		var job_pay = Label.new()
		job_pay.text = "💰 Оплата: " + str(job["min_pay"]) + "-" + str(job["max_pay"]) + " руб."
		job_pay.position = Vector2(120, y_pos + 70)
		job_pay.add_theme_font_size_override("font_size", 16)
		job_pay.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
		jobs_menu.add_child(job_pay)
		
		var job_time = Label.new()
		job_time.text = "⏱ Время: " + str(job["duration"]) + " сек"
		job_time.position = Vector2(120, y_pos + 95)
		job_time.add_theme_font_size_override("font_size", 14)
		job_time.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
		jobs_menu.add_child(job_time)
		
		# Кнопка работы
		var work_btn = Button.new()
		work_btn.custom_minimum_size = Vector2(160, 50)
		work_btn.position = Vector2(520, y_pos + 45)
		work_btn.text = "РАБОТАТЬ"
		work_btn.disabled = (current_job != null)  # Отключаем если уже работает
		
		var style_work = StyleBoxFlat.new()
		if current_job == null:
			style_work.bg_color = Color(0.2, 0.6, 0.2, 1.0)
		else:
			style_work.bg_color = Color(0.3, 0.3, 0.3, 1.0)
		work_btn.add_theme_stylebox_override("normal", style_work)
		
		var style_work_hover = StyleBoxFlat.new()
		style_work_hover.bg_color = Color(0.3, 0.7, 0.3, 1.0)
		work_btn.add_theme_stylebox_override("hover", style_work_hover)
		
		work_btn.add_theme_font_size_override("font_size", 18)
		
		var job_id = job_key
		work_btn.pressed.connect(func():
			start_job(job_id, player_data, main_node)
			jobs_menu.queue_free()
		)
		jobs_menu.add_child(work_btn)
		
		y_pos += 160
	
	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(680, 50)
	close_btn.position = Vector2(20, 1070)
	close_btn.text = "ЗАКРЫТЬ"
	
	var style_close = StyleBoxFlat.new()
	style_close.bg_color = Color(0.5, 0.1, 0.1, 1.0)
	close_btn.add_theme_stylebox_override("normal", style_close)
	
	var style_close_hover = StyleBoxFlat.new()
	style_close_hover.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	close_btn.add_theme_stylebox_override("hover", style_close_hover)
	
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func(): jobs_menu.queue_free())
	
	jobs_menu.add_child(close_btn)

# Начать работу
func start_job(job_key: String, player_data: Dictionary, main_node: Node):
	if current_job != null:
		main_node.show_message("⚠️ Вы уже работаете!")
		return
	
	if not jobs.has(job_key):
		return
	
	current_job = job_key
	var job = jobs[job_key]
	
	main_node.show_message(job["icon"] + " Начали работать: " + job["name"])
	
	# Показываем прогресс работы
	show_job_progress(job, player_data, main_node)
	
	# Таймер выполнения работы
	job_timer = Timer.new()
	job_timer.wait_time = job["duration"]
	job_timer.one_shot = true
	main_node.add_child(job_timer)
	
	job_timer.timeout.connect(func():
		complete_job(job_key, player_data, main_node)
		job_timer.queue_free()
	)
	job_timer.start()

# Показать прогресс работы
func show_job_progress(job: Dictionary, player_data: Dictionary, main_node: Node):
	var progress_layer = CanvasLayer.new()
	progress_layer.name = "JobProgressLayer"
	main_node.add_child(progress_layer)
	
	var bg = ColorRect.new()
	bg.size = Vector2(400, 150)
	bg.position = Vector2(160, 565)
	bg.color = Color(0.1, 0.1, 0.1, 0.95)
	progress_layer.add_child(bg)
	
	var job_label = Label.new()
	job_label.text = job["icon"] + " " + job["name"]
	job_label.position = Vector2(260, 585)
	job_label.add_theme_font_size_override("font_size", 24)
	job_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	progress_layer.add_child(job_label)
	
	var desc_label = Label.new()
	desc_label.text = job["description"]
	desc_label.position = Vector2(250, 620)
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	progress_layer.add_child(desc_label)
	
	# Прогресс-бар
	var progress_bg = ColorRect.new()
	progress_bg.size = Vector2(360, 25)
	progress_bg.position = Vector2(180, 660)
	progress_bg.color = Color(0.2, 0.2, 0.2, 1.0)
	progress_layer.add_child(progress_bg)
	
	var progress_fill = ColorRect.new()
	progress_fill.size = Vector2(0, 25)
	progress_fill.position = Vector2(180, 660)
	progress_fill.color = Color(0.3, 0.8, 0.3, 1.0)
	progress_fill.name = "ProgressFill"
	progress_layer.add_child(progress_fill)
	
	var progress_label = Label.new()
	progress_label.text = "0%"
	progress_label.position = Vector2(345, 663)
	progress_label.add_theme_font_size_override("font_size", 16)
	progress_label.add_theme_color_override("font_color", Color.BLACK)
	progress_label.name = "ProgressLabel"
	progress_layer.add_child(progress_label)
	
	# Анимация прогресса
	var tween = create_tween()
	tween.tween_property(progress_fill, "size:x", 360, job["duration"])
	
	# Обновление процентов
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.timeout.connect(func():
		var percent = int((progress_fill.size.x / 360.0) * 100)
		progress_label.text = str(percent) + "%"
	)
	progress_layer.add_child(timer)
	timer.start()

# Завершить работу
func complete_job(job_key: String, player_data: Dictionary, main_node: Node):
	if not jobs.has(job_key):
		return
	
	var job = jobs[job_key]
	
	# Вычисляем заработок с влиянием удачи
	var base_pay = randi_range(job["min_pay"], job["max_pay"])
	var luck_bonus = 0
	
	if player_stats:
		var luck = player_stats.get_stat("LCK")
		luck_bonus = int(base_pay * (luck * 0.02))  # +2% за каждую единицу удачи
	
	var total_earned = base_pay + luck_bonus
	
	# Начисляем деньги
	player_data["balance"] += total_earned
	
	# Добавляем опыт к характеристикам
	if player_stats and job.has("stat_xp"):
		for stat in job["stat_xp"]:
			player_stats.add_stat_xp(stat, job["stat_xp"][stat])
	
	# Удаляем прогресс-бар
	var progress_layer = main_node.get_node_or_null("JobProgressLayer")
	if progress_layer:
		progress_layer.queue_free()
	
	# Показываем результат
	show_job_result(job, total_earned, luck_bonus, main_node)
	
	# Обновляем UI
	main_node.update_ui()
	
	# Сбрасываем текущую работу
	current_job = null
	
	job_completed.emit(job["name"], total_earned)

# Показать результат работы
func show_job_result(job: Dictionary, earned: int, bonus: int, main_node: Node):
	var result_layer = CanvasLayer.new()
	result_layer.name = "JobResultLayer"
	main_node.add_child(result_layer)
	
	var bg = ColorRect.new()
	bg.size = Vector2(450, 200)
	bg.position = Vector2(135, 540)
	bg.color = Color(0.1, 0.3, 0.1, 0.95)
	result_layer.add_child(bg)
	
	var icon = Label.new()
	icon.text = job["icon"]
	icon.position = Vector2(285, 555)
	icon.add_theme_font_size_override("font_size", 48)
	result_layer.add_child(icon)
	
	var title = Label.new()
	title.text = "РАБОТА ЗАВЕРШЕНА!"
	title.position = Vector2(220, 615)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3, 1.0))
	result_layer.add_child(title)
	
	var earned_label = Label.new()
	earned_label.text = "💰 Заработано: " + str(earned) + " руб."
	earned_label.position = Vector2(230, 655)
	earned_label.add_theme_font_size_override("font_size", 20)
	earned_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3, 1.0))
	result_layer.add_child(earned_label)
	
	if bonus > 0:
		var bonus_label = Label.new()
		bonus_label.text = "🍀 Бонус за удачу: +" + str(bonus) + " руб."
		bonus_label.position = Vector2(210, 685)
		bonus_label.add_theme_font_size_override("font_size", 14)
		bonus_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8, 1.0))
		result_layer.add_child(bonus_label)
	
	# Автоматически убираем через 3 секунды
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	main_node.add_child(timer)
	
	timer.timeout.connect(func():
		if result_layer and is_instance_valid(result_layer):
			result_layer.queue_free()
		timer.queue_free()
	)
	timer.start()

# Проверка, работает ли игрок сейчас
func is_working() -> bool:
	return current_job != null

# Получить информацию о текущей работе
func get_current_job_info() -> Dictionary:
	if current_job and jobs.has(current_job):
		return jobs[current_job]
	return {}
