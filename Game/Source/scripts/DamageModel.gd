extends Reference
var zones = {"fuselage":1.0,"left_wing":1.0,"right_wing":1.0,"tail":1.0,"engine":1.0,"pilot":1.0}
var health = 1.0
var last_zone = ""
func hit(local_point, amount, data):
	var zone = "fuselage"
	if abs(local_point.x) > data.span * 0.18:
		zone = "left_wing" if local_point.x < 0 else "right_wing"
	elif local_point.z > data.length * 0.24:
		zone = "tail"
	elif local_point.z > 0:
		zone = "engine"
	elif local_point.y > 0.55 and local_point.z < -data.length * 0.13:
		zone = "pilot"
	apply(zone, amount, data)
func apply(zone, amount, data):
	last_zone = zone
	var factor = 1.3 if zone == "pilot" else 1.0
	zones[zone] = max(0.0, zones[zone] - amount / (data.hp * 0.65) * factor)
	health = max(0.0, health - amount / data.hp * 0.65)
func destroyed():
	return health <= 0 or zones.pilot <= 0 or zones.fuselage <= 0 or zones.left_wing <= 0 or zones.right_wing <= 0
func lift_factor():
	return 0.35 + 0.325 * (zones.left_wing + zones.right_wing)
