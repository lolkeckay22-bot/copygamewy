extends Reference
var flaps=0
func cycle(a):
	var next=(flaps+1)%3
	if next>0 and a.linear_velocity.length()>a.data.flap_limit:
		message(a,"СЛИШКОМ БЫСТРО ДЛЯ ЗАКРЫЛКОВ — СНИЗЬТЕ СКОРОСТЬ")
		return false
	flaps=next
	message(a,"ЗАКРЫЛКИ: "+["УБРАНЫ","ВЗЛЁТ","ПОСАДКА"][flaps])
	return true
func update(a):
	if flaps>0 and a.linear_velocity.length()>a.data.flap_limit:
		flaps=0
		message(a,"ИНСТРУКТОР: ЗАКРЫЛКИ УБРАНЫ — ПРЕВЫШЕНИЕ СКОРОСТИ")
func message(a,text):
	if a.player:
		a.game.notification=text;a.game.notification_time=2.5
