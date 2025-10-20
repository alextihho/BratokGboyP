extends Node

var current_date = {
	"day": 1,
	"month": 1,
	"year": 1992
}

func advance_day():
	current_date["day"] += 1
	if current_date["day"] > 30:
		current_date["day"] = 1
		current_date["month"] += 1
		if current_date["month"] > 12:
			current_date["month"] = 1
			current_date["year"] += 1

func get_date_string():
	return "%02d.%02d.%d" % [current_date["day"], current_date["month"], current_date["year"]]
