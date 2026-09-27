extends Reference
func nearest(aircraft, roster):
	var best = null
	var best_dist = 1e20
	for a in roster:
		if a == aircraft or a.team == aircraft.team or a.dead:
			continue
		var dist = aircraft.translation.distance_squared_to(a.translation)
		if dist < best_dist:
			best_dist = dist
			best = a
	return best
func lead(shooter, target, bullet_speed):
	var r = target.translation - shooter.translation
	var v = target.linear_velocity - shooter.linear_velocity
	var aa = v.dot(v) - bullet_speed*bullet_speed
	var bb = 2.0*r.dot(v)
	var cc = r.dot(r)
	var disc = bb*bb - 4*aa*cc
	var t = r.length()/bullet_speed
	if disc > 0 and abs(aa) > 0.001:
		var t1 = (-bb-sqrt(disc))/(2*aa)
		var t2 = (-bb+sqrt(disc))/(2*aa)
		if t1 > 0:
			t = t1
		elif t2 > 0:
			t = t2
	t = clamp(t,0,4)
	return target.translation + v*t + Vector3(0,4.905*t*t,0)
