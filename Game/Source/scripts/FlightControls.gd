extends Reference
var flaps=0
func cycle(a):
	var next=(flaps+1)%3
	if next>0 and a.linear_velocity.length()>a.data.flap_limit:
		message(a,"TOO FAST FOR FLAPS — REDUCE SPEED")
		return false
	flaps=next
	message(a,"FLAPS: "+["RAISED","TAKEOFF","LANDING"][flaps])
	return true
func update(a):
	if flaps>0 and a.linear_velocity.length()>a.data.flap_limit:
		flaps=0
		message(a,"INSTRUCTOR: FLAPS RETRACTED — OVERSPEED")
func message(a,text):
	if a.player:
		a.game.notification=text;a.game.notification_time=2.5
