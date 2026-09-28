extends Node
var game
var done=false
var failures=0
func check(ok,label):
	print("AIRFIELD ","PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func _process(_dt):
	if done:return
	done=true
	game.start_freeflight()
	var a=game.player
	var base=game.service_bases.fields[0]
	check(game.aircraft.size()==1 and game.ground_units.empty(),"free flight has one plane and no bots")
	check(game.terrain.outer_meshes.size()==4,"larger map uses four cullable outer strips")
	check(game.service_bases.targets.size()==18,"hangars tower and runway segments exist at both bases")
	check(game.service_bases.at_position(Vector3(160,base.y,base.z+600))==base,"parallel taxiway accepts gear contact")
	check(game.service_bases.at_position(Vector3(245,base.y,base.z+100))==base,"apron accepts gear contact")
	check(a.model.gear_pivots.size()==3 and a.model.flap_pivots.size()==2,"Su-27 has three movable gear assemblies and two visible flaps")
	a.model.set_lod(2500,game.graphics.draw_distance)
	a.landing.toggle(a)
	a.model.set_gear(a.landing.gear_down)
	a.model.set_flaps(2)
	a.model._process(1.0)
	check(a.model.simple.visible and a.model.gear_pivots[0].pivot.visible and a.model.gear_progress>0.5,"landing gear extends at low graphics quality and distant LOD")
	check(a.model.flap_pivots[0].rotation.x>0.4,"landing flaps rotate visibly")
	var hangar=null
	var runway=null
	for target in game.service_bases.targets:
		if target.team==0 and target.kind=="hangar" and hangar==null:hangar=target
		if target.team==0 and target.kind=="runway" and runway==null:runway=target
	check(hangar!=null and runway!=null,"individual airfield targets are available")
	a.translation=hangar.aim_point()+Vector3(0,350,900)
	a.look_at(hangar.aim_point(),Vector3.UP)
	a.linear_velocity=Vector3.ZERO
	a.weapons.lock_target=hangar
	a.weapons.lock_progress=1
	a.weapons.missile_cooldown=0
	check(a.weapons.fire_missile(a),"free flight launches a missile at a hangar")
	check(game.missiles.slots[0].active and game.missiles.slots[0].node.visible,"launched missile has visible geometry")
	game.missiles._physics_process(.05)
	check(game.effects.active.size()>0,"launched missile emits visible smoke particles")
	for step in range(360):
		if hangar.dead:break
		game.missiles._physics_process(1.0/60.0)
	check(hangar.dead,"guided missile flies to and destroys the hangar")
	check(game.missiles.impacts>0,"actual missile impact is counted")
	var runway_pos=runway.aim_point()
	game.service_bases.hit_segment(runway_pos+Vector3(0,0,90),runway_pos-Vector3(0,0,90),a,220)
	game.service_bases.hit_segment(runway_pos+Vector3(0,0,90),runway_pos-Vector3(0,0,90),a,220)
	check(runway.dead and not base.operational,"runway destruction disables airfield service")
	print("AIRFIELD failures=",failures)
	get_tree().quit(1 if failures else 0)
