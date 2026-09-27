extends Reference
var entries = []
func _init():
	var f = File.new()
	if f.open("res://data/aircraft.json", File.READ) == OK:
		entries = parse_json(f.get_as_text())
		f.close()
func get_aircraft(index):
	return entries[index].duplicate(true)
