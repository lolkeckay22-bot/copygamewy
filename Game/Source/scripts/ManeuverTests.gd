extends Node
var game
var elapsed=0.0
var started=false
var phase=0
var max_aoa=0.0
var max_nose=0.0
var max_speed=0.0
func _ready():
	Engine.target_fps=0
func _physics_process(dt):
	if not started:
		game.select_aircraft(1)
		game.start_freeflight()
		game.player.linear_velocity=Vector3(0,0,-165)
		game.player.throttle=1.0
		Input.action_press("pitch_up")
		started=true
		return
	elapsed+=dt
	var a=game.player
	if a.dead:
		print("MANEUVER FAIL aircraft crashed during test phase ",phase)
		get_tree().quit(1)
		return
	if phase==0:
		max_aoa=max(max_aoa,a.flight.aoa)
		max_nose=max(max_nose,-a.global_transform.basis.z.y)
		if elapsed>=1.1:
			Input.action_release("pitch_up")
			Input.action_press("pitch_down")
			phase=1;elapsed=0
	elif phase==1:
		if elapsed>=1.0:
			Input.action_release("pitch_down")
			phase=2;elapsed=0
	elif phase==2 and elapsed>=4.0:
		var recovered=a.linear_velocity.length()>85.0 and a.translation.y>300.0
		var entered=max_aoa>0.65 and max_nose>0.6
		print("MANEUVER METRICS max_aoa_deg=",rad2deg(max_aoa)," recovery_speed=",a.linear_velocity.length()," altitude=",a.translation.y)
		if not entered or not recovered:
			print("MANEUVER FAIL high-alpha entry or recovery")
			get_tree().quit(1)
			return
		print("MANEUVER PASS high-alpha entry and recovery")
		a.translation=Vector3(0,8000,1000)
		a.rotation=Vector3.ZERO
		a.linear_velocity=Vector3(0,0,-450)
		a.angular_velocity=Vector3.ZERO
		a.throttle=1.0
		game.controller.reset(a)
		phase=3;elapsed=0
	elif phase==3:
		max_speed=max(max_speed,a.linear_velocity.length())
		if elapsed>=35.0:
			print("SPEED METRICS max_kmh=",max_speed*3.6," altitude=",a.translation.y)
			var reached=max_speed>560.0
			print("SPEED PASS high-altitude transonic acceleration" if reached else "SPEED FAIL cannot approach advertised top speed")
			get_tree().quit(0 if reached else 1)
