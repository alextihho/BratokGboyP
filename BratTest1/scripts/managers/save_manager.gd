extends Node

const SAVE_PATH = "user://savegame.json"

func save_game(player_data: Dictionary, gang_members: Array, quest_system_data: Dictionary = {}) -> bool:
	# Получаем данные о районах
	var districts_data = {}
	var districts_system = get_node_or_null("/root/DistrictsSystem")
	if districts_system:
		districts_data = {
			"districts": districts_system.districts.duplicate(true),
			"rival_gangs": districts_system.rival_gangs.duplicate(true)
		}
	
	var save_data = {
		"version": "1.1",  # Обновили версию
		"timestamp": Time.get_datetime_string_from_system(),
		"player_data": player_data.duplicate(true),
		"gang_members": gang_members.duplicate(true),
		"quest_system": quest_system_data.duplicate(true),
		"districts": districts_data  # НОВОЕ: Сохранение районов
	}
	
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		print("❌ Ошибка создания файла сохранения!")
		return false
	
	var json_string = JSON.stringify(save_data, "\t")
	save_file.store_string(json_string)
	save_file.close()
	
	print("✅ Игра сохранена: " + SAVE_PATH)
	print("📊 Сохранены данные о " + str(districts_data.get("districts", {}).size()) + " районах")
	return true

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		print("⚠️ Файл сохранения не найден")
		return {}
	
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file == null:
		print("❌ Ошибка чтения файла сохранения!")
		return {}
	
	var json_string = save_file.get_as_text()
	save_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("❌ Ошибка парсинга JSON!")
		return {}
	
	var save_data = json.data
	
	# НОВОЕ: Загрузка данных о районах
	if save_data.has("districts"):
		var districts_system = get_node_or_null("/root/DistrictsSystem")
		if districts_system:
			var districts_data = save_data["districts"]
			
			if districts_data.has("districts"):
				districts_system.districts = districts_data["districts"].duplicate(true)
				print("📊 Загружены данные о " + str(districts_system.districts.size()) + " районах")
			
			if districts_data.has("rival_gangs"):
				districts_system.rival_gangs = districts_data["rival_gangs"].duplicate(true)
				print("🏴 Загружены данные о " + str(districts_system.rival_gangs.size()) + " соперничающих бандах")
	
	print("✅ Игра загружена: " + str(save_data.get("timestamp", "неизвестно")))
	return save_data

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> bool:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("🗑️ Сохранение удалено")
		return true
	return false

func get_save_info() -> Dictionary:
	if not has_save():
		return {}
	
	var save_data = load_game()
	if save_data.is_empty():
		return {}
	
	# Подсчитываем контролируемые районы
	var controlled_districts = 0
	if save_data.has("districts") and save_data["districts"].has("districts"):
		for district_name in save_data["districts"]["districts"]:
			var district = save_data["districts"]["districts"][district_name]
			if district.get("owner", "") == "Игрок":
				controlled_districts += 1
	
	return {
		"timestamp": save_data.get("timestamp", "Неизвестно"),
		"version": save_data.get("version", "1.0"),
		"player_name": save_data.get("player_data", {}).get("name", "Игрок"),
		"balance": save_data.get("player_data", {}).get("balance", 0),
		"reputation": save_data.get("player_data", {}).get("reputation", 0),
		"gang_size": save_data.get("gang_members", []).size(),
		"controlled_districts": controlled_districts  # НОВОЕ
	}

# НОВОЕ: Автосохранение каждые N минут
var autosave_timer: Timer = null
var autosave_interval: float = 300.0  # 5 минут

func enable_autosave(interval: float = 300.0):
	autosave_interval = interval
	
	if autosave_timer:
		autosave_timer.queue_free()
	
	autosave_timer = Timer.new()
	autosave_timer.wait_time = autosave_interval
	autosave_timer.one_shot = false
	autosave_timer.timeout.connect(_on_autosave_timeout)
	add_child(autosave_timer)
	autosave_timer.start()
	
	print("💾 Автосохранение включено: каждые " + str(interval / 60.0) + " мин.")

func disable_autosave():
	if autosave_timer:
		autosave_timer.stop()
		autosave_timer.queue_free()
		autosave_timer = null
	print("💾 Автосохранение отключено")

func _on_autosave_timeout():
	print("💾 Автосохранение...")
	# Здесь нужно получить актуальные данные от main.gd
	# Это можно сделать через сигнал или прямое обращение к main
	# Пример будет в интеграции

# НОВОЕ: Экспорт сохранения в текстовый файл для отладки
func export_save_to_text(path: String = "user://savegame_readable.txt") -> bool:
	var save_data = load_game()
	if save_data.is_empty():
		return false
	
	var text_file = FileAccess.open(path, FileAccess.WRITE)
	if text_file == null:
		return false
	
	text_file.store_string("=== СОХРАНЕНИЕ ИГРЫ 'БРАТ ТЕСТ 1' ===\n\n")
	text_file.store_string("Версия: " + str(save_data.get("version", "1.0")) + "\n")
	text_file.store_string("Время сохранения: " + str(save_data.get("timestamp", "неизвестно")) + "\n\n")
	
	text_file.store_string("--- ДАННЫЕ ИГРОКА ---\n")
	var player_data = save_data.get("player_data", {})
	text_file.store_string("Баланс: " + str(player_data.get("balance", 0)) + " руб.\n")
	text_file.store_string("Здоровье: " + str(player_data.get("health", 0)) + "\n")
	text_file.store_string("Репутация: " + str(player_data.get("reputation", 0)) + "\n")
	text_file.store_string("Инвентарь: " + str(player_data.get("inventory", [])) + "\n\n")
	
	text_file.store_string("--- БАНДА ---\n")
	var gang = save_data.get("gang_members", [])
	text_file.store_string("Размер банды: " + str(gang.size()) + "\n\n")
	
	if save_data.has("districts"):
		text_file.store_string("--- РАЙОНЫ ---\n")
		var districts = save_data["districts"].get("districts", {})
		for district_name in districts:
			var district = districts[district_name]
			text_file.store_string("\n" + district_name + ":\n")
			text_file.store_string("  Владелец: " + str(district.get("owner", "")) + "\n")
			text_file.store_string("  Влияние игрока: " + str(district.get("influence", {}).get("Игрок", 0)) + "%\n")
	
	text_file.close()
	print("📄 Сохранение экспортировано в текстовый файл: " + path)
	return true
