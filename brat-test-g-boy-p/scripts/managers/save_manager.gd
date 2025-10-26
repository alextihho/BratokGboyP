# save_manager.gd v2.0 - ПОЛНАЯ СИСТЕМА СОХРАНЕНИЙ
extends Node

const SAVE_PATH = "user://savegame.json"
const VERSION = "2.0"

signal save_completed(success: bool)
signal load_completed(success: bool)

func save_game(player_data: Dictionary, gang_members: Array) -> bool:
	print("💾 Начинаем сохранение v%s..." % VERSION)
	
	# Собираем данные из всех систем
	var save_data = {
		"version": VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		
		# Игрок
		"player": {
			"balance": player_data.get("balance", 0),
			"health": player_data.get("health", 100),
			"reputation": player_data.get("reputation", 0),
			"completed_quests": player_data.get("completed_quests", []),
			"equipment": player_data.get("equipment", {}).duplicate(true),
			"inventory": player_data.get("inventory", []).duplicate(true),
			"pockets": player_data.get("pockets", [null, null, null]).duplicate(true),
			"current_square": player_data.get("current_square", "6_2")
		},
		
		# Банда
		"gang": gang_members.duplicate(true),
		
		# Квесты
		"quests": get_quest_data(),
		
		# Районы
		"districts": get_districts_data(),
		
		# Время
		"time": get_time_data(),
		
		# Статистика
		"stats": get_stats_data(),
		
		# Полиция
		"police": get_police_data()
	}
	
	# Запись в файл
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		printerr("❌ Не удалось создать файл сохранения!")
		save_completed.emit(false)
		return false
	
	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()
	
	print("✅ Сохранение завершено: %s" % SAVE_PATH)
	print("   📦 Размер: %.2f KB" % (json_string.length() / 1024.0))
	
	save_completed.emit(true)
	return true

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		printerr("⚠️ Файл сохранения не найден")
		load_completed.emit(false)
		return {}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		printerr("❌ Ошибка чтения файла!")
		load_completed.emit(false)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		printerr("❌ Ошибка парсинга JSON!")
		load_completed.emit(false)
		return {}
	
	var save_data = json.data
	
	print("📂 Загружаем сохранение v%s от %s" % [
		save_data.get("version", "unknown"),
		save_data.get("timestamp", "unknown")
	])
	
	# Восстанавливаем данные в системы
	restore_quest_data(save_data.get("quests", {}))
	restore_districts_data(save_data.get("districts", {}))
	restore_time_data(save_data.get("time", {}))
	restore_stats_data(save_data.get("stats", {}))
	restore_police_data(save_data.get("police", {}))
	
	print("✅ Загрузка завершена")
	load_completed.emit(true)
	
	return save_data

# === СБОР ДАННЫХ ===

func get_quest_data() -> Dictionary:
	var quest_system = get_node_or_null("/root/QuestSystem")
	if not quest_system:
		return {}
	
	var stats_data = {}
	# ✅ Правильная проверка для GDScript - используем get() с default значением
	if "player_stats_data" in quest_system:
		stats_data = quest_system.player_stats_data.duplicate(true)
	
	return {
		"active_quests": quest_system.active_quests.duplicate(true),
		"completed_quests": quest_system.completed_quests.duplicate(true),
		"stats": stats_data
	}

func get_districts_data() -> Dictionary:
	var districts_system = get_node_or_null("/root/DistrictsSystem")
	if not districts_system:
		return {}
	
	return {
		"districts": districts_system.districts.duplicate(true),
		"rival_gangs": districts_system.rival_gangs.duplicate(true)
	}

func get_time_data() -> Dictionary:
	var time_system = get_node_or_null("/root/TimeSystem")
	if not time_system:
		return {}
	
	return time_system.get_save_data()

func get_stats_data() -> Dictionary:
	var player_stats = get_node_or_null("/root/PlayerStats")
	if not player_stats:
		return {}
	
	return {
		"base_stats": player_stats.base_stats.duplicate(true),
		"stat_experience": player_stats.stat_experience.duplicate(true),
		"equipment_bonuses": player_stats.equipment_bonuses.duplicate(true)
	}

func get_police_data() -> Dictionary:
	var police_system = get_node_or_null("/root/PoliceSystem")
	if not police_system:
		return {}
	
	return police_system.get_save_data()

# === ВОССТАНОВЛЕНИЕ ДАННЫХ ===

func restore_quest_data(data: Dictionary):
	var quest_system = get_node_or_null("/root/QuestSystem")
	if not quest_system or data.is_empty():
		return
	
	quest_system.active_quests = data.get("active_quests", []).duplicate(true)
	quest_system.completed_quests = data.get("completed_quests", []).duplicate(true)
	
	# ✅ Правильная проверка для GDScript
	if "player_stats_data" in quest_system:
		quest_system.player_stats_data = data.get("stats", {}).duplicate(true)
	
	print("   📜 Квестов: %d активных, %d выполнено" % [
		quest_system.active_quests.size(),
		quest_system.completed_quests.size()
	])

func restore_districts_data(data: Dictionary):
	var districts_system = get_node_or_null("/root/DistrictsSystem")
	if not districts_system or data.is_empty():
		return
	
	if data.has("districts"):
		districts_system.districts = data["districts"].duplicate(true)
	
	if data.has("rival_gangs"):
		districts_system.rival_gangs = data["rival_gangs"].duplicate(true)
	
	print("   🏙️ Районов: %d" % districts_system.districts.size())

func restore_time_data(data: Dictionary):
	var time_system = get_node_or_null("/root/TimeSystem")
	if not time_system or data.is_empty():
		return
	
	time_system.load_save_data(data)
	print("   ⏰ Время: %s" % time_system.get_date_time_string())

func restore_stats_data(data: Dictionary):
	var player_stats = get_node_or_null("/root/PlayerStats")
	if not player_stats or data.is_empty():
		return
	
	if data.has("base_stats"):
		player_stats.base_stats = data["base_stats"].duplicate(true)
	
	if data.has("stat_experience"):
		player_stats.stat_experience = data["stat_experience"].duplicate(true)
	
	if data.has("equipment_bonuses"):
		player_stats.equipment_bonuses = data["equipment_bonuses"].duplicate(true)
	
	print("   📊 Статы восстановлены")

func restore_police_data(data: Dictionary):
	var police_system = get_node_or_null("/root/PoliceSystem")
	if not police_system or data.is_empty():
		return
	
	police_system.load_save_data(data)
	print("   🚔 УА: %d" % police_system.ua_level)

# === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ===

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> bool:
	if not has_save():
		return false
	
	DirAccess.remove_absolute(SAVE_PATH)
	print("🗑️ Сохранение удалено")
	return true

func get_save_info() -> Dictionary:
	if not has_save():
		return {}
	
	var save_data = load_game()
	if save_data.is_empty():
		return {}
	
	var player = save_data.get("player", {})
	
	# Подсчёт контролируемых районов
	var controlled_districts = 0
	var districts = save_data.get("districts", {}).get("districts", {})
	for district_name in districts:
		var district = districts[district_name]
		if district.get("owner", "") == "Игрок":
			controlled_districts += 1
	
	return {
		"timestamp": save_data.get("timestamp", "Неизвестно"),
		"version": save_data.get("version", "1.0"),
		"balance": player.get("balance", 0),
		"health": player.get("health", 100),
		"reputation": player.get("reputation", 0),
		"gang_size": save_data.get("gang", []).size(),
		"controlled_districts": controlled_districts,
		"time": save_data.get("time", {})
	}

# === АВТОСОХРАНЕНИЕ ===

var autosave_timer: Timer = null
var autosave_enabled: bool = false
var autosave_interval: float = 300.0  # 5 минут

func enable_autosave(interval: float = 300.0):
	autosave_interval = interval
	autosave_enabled = true
	
	if autosave_timer:
		autosave_timer.queue_free()
	
	autosave_timer = Timer.new()
	autosave_timer.wait_time = autosave_interval
	autosave_timer.one_shot = false
	add_child(autosave_timer)
	
	autosave_timer.timeout.connect(_on_autosave)
	autosave_timer.start()
	
	print("💾 Автосохранение: каждые %.1f мин" % (interval / 60.0))

func disable_autosave():
	autosave_enabled = false
	if autosave_timer:
		autosave_timer.stop()
		autosave_timer.queue_free()
		autosave_timer = null

func _on_autosave():
	if not autosave_enabled:
		return
	
	print("💾 Автосохранение...")
	
	# Получаем данные из главной сцены
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("get_save_data"):
		var data = main_scene.get_save_data()
		save_game(data["player_data"], data["gang_members"])

# === ЭКСПОРТ В ТЕКСТ ===

func export_to_text(path: String = "user://savegame_readable.txt") -> bool:
	var save_data = load_game()
	if save_data.is_empty():
		return false
	
	var text_file = FileAccess.open(path, FileAccess.WRITE)
	if text_file == null:
		return false
	
	text_file.store_string("═══════════════════════════════════════\n")
	text_file.store_string("    СОХРАНЕНИЕ: БРАТВА 90-х\n")
	text_file.store_string("═══════════════════════════════════════\n\n")
	
	text_file.store_string("Версия: %s\n" % save_data.get("version", "unknown"))
	text_file.store_string("Время сохранения: %s\n\n" % save_data.get("timestamp", "unknown"))
	
	# ИГРОК
	var player = save_data.get("player", {})
	text_file.store_string("─── ИГРОК ───\n")
	text_file.store_string("💰 Деньги: %d руб.\n" % player.get("balance", 0))
	text_file.store_string("❤️ Здоровье: %d/100\n" % player.get("health", 100))
	text_file.store_string("⭐ Репутация: %d\n" % player.get("reputation", 0))
	text_file.store_string("🎒 Предметов: %d\n\n" % player.get("inventory", []).size())
	
	# БАНДА
	var gang = save_data.get("gang", [])
	text_file.store_string("─── БАНДА ───\n")
	text_file.store_string("👥 Размер: %d человек\n\n" % gang.size())
	
	# РАЙОНЫ
	var districts = save_data.get("districts", {}).get("districts", {})
	text_file.store_string("─── РАЙОНЫ ───\n")
	var controlled = 0
	for district_name in districts:
		var district = districts[district_name]
		if district.get("owner", "") == "Игрок":
			controlled += 1
			text_file.store_string("🏴 %s (влияние: %d%%)\n" % [
				district_name,
				district.get("influence", {}).get("Игрок", 0)
			])
	text_file.store_string("\nКонтролируемых районов: %d\n\n" % controlled)
	
	# ВРЕМЯ
	var time = save_data.get("time", {})
	if not time.is_empty():
		text_file.store_string("─── ВРЕМЯ ───\n")
		text_file.store_string("📅 Дата: %02d.%02d.%d\n" % [
			time.get("day", 1),
			time.get("month", 1),
			time.get("year", 1992)
		])
		text_file.store_string("🕐 Время: %02d:%02d\n\n" % [
			time.get("hour", 10),
			time.get("minute", 0)
		])
	
	text_file.store_string("═══════════════════════════════════════\n")
	text_file.close()
	
	print("📄 Экспорт в текст: %s" % path)
	return true
