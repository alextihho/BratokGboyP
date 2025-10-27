# time_system.gd
# Система игрового времени
extends Node

signal time_changed(hour: int, minute: int)
signal day_changed(day: int, month: int, year: int)
signal time_of_day_changed(period: String) # "утро", "день", "вечер", "ночь"

var current_time = {
	"minute": 0,
	"hour": 10,
	"day": 2,
	"month": 3,
	"year": 1992
}

var time_scale: float = 1.0  # Множитель скорости времени (1.0 = обычная)
var paused: bool = false

func _ready():
	print("⏰ Система времени инициализирована: " + get_date_time_string())

# Добавить минуты к текущему времени
func add_minutes(minutes: int):
	if paused:
		return
	
	var old_hour = current_time["hour"]
	var old_day = current_time["day"]
	
	current_time["minute"] += minutes
	
	# Перенос минут в часы
	while current_time["minute"] >= 60:
		current_time["minute"] -= 60
		current_time["hour"] += 1
	
	# Перенос часов в дни
	while current_time["hour"] >= 24:
		current_time["hour"] -= 24
		current_time["day"] += 1
	
	# Перенос дней в месяцы
	var days_in_month = get_days_in_month(current_time["month"], current_time["year"])
	while current_time["day"] > days_in_month:
		current_time["day"] -= days_in_month
		current_time["month"] += 1
		
		if current_time["month"] > 12:
			current_time["month"] = 1
			current_time["year"] += 1
		
		days_in_month = get_days_in_month(current_time["month"], current_time["year"])
	
	# Сигналы
	time_changed.emit(current_time["hour"], current_time["minute"])
	
	if old_hour != current_time["hour"]:
		check_time_of_day_change(old_hour, current_time["hour"])
	
	if old_day != current_time["day"]:
		day_changed.emit(current_time["day"], current_time["month"], current_time["year"])

# ✅ НОВОЕ: Добавить часы
func add_hours(hours: int):
	add_minutes(hours * 60)

# ✅ НОВОЕ: Добавить дни
func add_days(days: int):
	add_minutes(days * 24 * 60)

# Проверка смены периода дня
func check_time_of_day_change(old_hour: int, new_hour: int):
	var old_period = get_time_of_day(old_hour)
	var new_period = get_time_of_day(new_hour)
	
	if old_period != new_period:
		time_of_day_changed.emit(new_period)

# Получить период дня по часу
func get_time_of_day(hour: int = -1) -> String:
	if hour == -1:
		hour = current_time["hour"]
	
	if hour >= 6 and hour < 12:
		return "утро"
	elif hour >= 12 and hour < 18:
		return "день"
	elif hour >= 18 and hour < 22:
		return "вечер"
	else:
		return "ночь"

# Получить количество дней в месяце
func get_days_in_month(month: int, year: int) -> int:
	match month:
		2:
			# Високосный год
			if year % 4 == 0 and (year % 100 != 0 or year % 400 == 0):
				return 29
			return 28
		4, 6, 9, 11:
			return 30
		_:
			return 31

# Получить строку с датой и временем
func get_date_time_string() -> String:
	return "%02d.%02d.%d %02d:%02d" % [
		current_time["day"],
		current_time["month"],
		current_time["year"],
		current_time["hour"],
		current_time["minute"]
	]

# Получить только дату
func get_date_string() -> String:
	return "%02d.%02d.%d" % [
		current_time["day"],
		current_time["month"],
		current_time["year"]
	]

# Получить только время
func get_time_string() -> String:
	return "%02d:%02d" % [current_time["hour"], current_time["minute"]]

# Получить текущий час
func get_hour() -> int:
	return current_time["hour"]

# Получить текущую минуту
func get_minute() -> int:
	return current_time["minute"]

# Проверка, день ли сейчас (для действий)
func is_daytime() -> bool:
	var period = get_time_of_day()
	return period == "утро" or period == "день"

# Проверка, ночь ли сейчас (для действий)
func is_nighttime() -> bool:
	var period = get_time_of_day()
	return period == "вечер" or period == "ночь"

# Установить время (для отладки/загрузки)
func set_time(day: int, month: int, year: int, hour: int, minute: int):
	current_time = {
		"minute": minute,
		"hour": hour,
		"day": day,
		"month": month,
		"year": year
	}
	time_changed.emit(hour, minute)
	day_changed.emit(day, month, year)

# Пауза/возобновление времени
func set_paused(value: bool):
	paused = value

# Получить данные для сохранения
func get_save_data() -> Dictionary:
	return current_time.duplicate()

# Загрузить данные
func load_save_data(data: Dictionary):
	current_time = data.duplicate()
	time_changed.emit(current_time["hour"], current_time["minute"])
