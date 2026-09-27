extends Node
var game
var done=false
var checks=[]
class State:
	var transform=Transform()
	var linear_velocity=Vector3(0,0,-100)
	var angular_velocity=Vector3.ZERO
func check(ok,label):
	checks.append(ok)
	print("COMFORT ","PASS " if ok else "FAIL ",label)
func _process(_dt):
	if done:return
	done=true
	game.select_aircraft(1)
	game.start_battle()
	var a=game.player
	check(game.graphics.keys.gear==KEY_G and game.graphics.keys.ground_target==KEY_H,"G gear / H ground target")
	var e=InputEventKey.new()
	e.scancode=KEY_G;e.pressed=true
	var previous=a.landing.gear_down
	game._unhandled_input(e)
	check(a.landing.gear_down!=previous,"G event operates landing gear")
	e.scancode=KEY_H
	game._unhandled_input(e)
	check(game.ground_units.has(game.combat.selected_target),"H event selects ground target")
	a.linear_velocity=Vector3(0,0,-100)
	e.scancode=KEY_Z
	game._unhandled_input(e)
	check(a.flight_controls.flaps==1,"Z selects takeoff flaps")
	a.flight_controls.cycle(a)
	check(a.flight_controls.flaps==2,"landing flap stage")
	a.flight_controls.cycle(a)
	check(a.flight_controls.flaps==0,"flaps retract")
	var clean=State.new()
	var deployed=State.new()
	a.throttle=0
	a.flight.step(a,clean,Vector3.ZERO,.016)
	a.flight_controls.flaps=1
	a.flight.step(a,deployed,Vector3.ZERO,.016)
	check(deployed.linear_velocity.y>clean.linear_velocity.y,"flaps increase physical lift")
	check(deployed.linear_velocity.z>clean.linear_velocity.z,"flaps increase aerodynamic drag")
	a.linear_velocity=Vector3(0,0,-160)
	a.flight_controls.update(a)
	check(a.flight_controls.flaps==0,"instructor retracts flaps at excessive speed")
	check(not a.flight_controls.cycle(a),"unsafe flap deployment rejected")
	var cam=preload("res://scripts/CameraController.gd").new()
	var motion=InputEventMouseMotion.new()
	motion.relative=Vector2(20,10)
	cam.mouse(motion,false,false,.5,false)
	check(abs(cam.yaw+.025)<.0001,"mouse sensitivity applied")
	var pitch=cam.pitch
	cam.mouse(motion,false,false,1,true)
	check(cam.pitch>pitch,"inverted vertical mouse input")
	Input.action_press("target_view")
	game.controller.update(game.camera,a,.3,false)
	check(game.controller.tracking,"Alt tracks selected target")
	check(a.direction.dot(game.controller.aim)>.999,"target view preserves flight aim")
	Input.action_release("target_view")
	check(InputMap.get_action_list("precision_zoom")[0].button_index==BUTTON_RIGHT,"RMB bound to precision zoom")
	var mouse=InputEventMouseButton.new()
	mouse.button_index=BUTTON_RIGHT;mouse.pressed=true
	Input.action_press("precision_zoom")
	game.controller.update(game.camera,a,.3,false)
	check(game.camera.fov<40,"RMB smoothly zooms camera")
	mouse.pressed=false
	Input.action_release("precision_zoom")
	game.controller.update(game.camera,a,.3,false)
	check(game.camera.fov>60,"releasing RMB restores field of view")
	game.hud.settings_tab=1
	game.settings_open=true
	game.hud._draw()
	check(game.hud.buttons.size()>=25,"all twenty bindings and mouse settings render")
	print("COMFORT TOTAL ",checks.size()," FAILED ",checks.count(false))
	get_tree().quit(1 if checks.has(false) else 0)
