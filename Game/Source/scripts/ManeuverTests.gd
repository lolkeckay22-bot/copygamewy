extends Node
var game
var elapsed=0.0
var started=false
var max_aoa=0.0
var max_nose=0.0
var max_pitch_rate=0.0
func _ready():
	Engine.target_fps=0
func _physics_process(dt):
	if not started:
		game.select_aircraft(1)
		game.start_freeflight()
		game.player.linear_velocity=Vector3(0,0,-165)
		game.player.throttle=0.9
		Input.action_press("pitch_up")
		started=true
		return
	elapsed+=dt
	if game.player.dead:
		print("MANEUVER FAIL aircraft crashed before high-alpha test finished")
		Input.action_release("pitch_up")
		get_tree().quit(1)
		return
	max_aoa=max(max_aoa,game.player.flight.aoa)
	max_nose=max(max_nose,-game.player.global_transform.basis.z.y)
	max_pitch_rate=max(max_pitch_rate,abs(game.player.angular_velocity.x))
	if elapsed>=2.0:
		Input.action_release("pitch_up")
		print("MANEUVER METRICS max_aoa_deg=",rad2deg(max_aoa)," max_nose_y=",max_nose," max_pitch_rate=",max_pitch_rate)
		var passed=max_aoa>0.65 and max_nose>0.6 and max_pitch_rate>0.5
		print("MANEUVER PASS high-alpha entry from direct elevator" if passed else "MANEUVER FAIL Su-27 cannot enter high-alpha")
		get_tree().quit(0 if passed else 1)
