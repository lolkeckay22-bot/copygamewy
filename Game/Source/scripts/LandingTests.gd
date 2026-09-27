extends Node
var game
var elapsed=0.0
var stage=0
var a
var checks=[]
var stopped_at=-1.0
var service_at=-1.0
var takeoff_at=-1.0
var bot_start=0.0
var bot
func check(ok,label):
	checks.append({"pass":ok,"test":label});print("LANDING ","PASS " if ok else "FAIL ",label)
func _ready():Engine.target_fps=0
func _process(dt):
	elapsed+=dt
	if stage==0 and elapsed>.2:
		game.select_aircraft(0 if "--biplane" in OS.get_cmdline_args() else 1);game.start_battle()
		for unit in game.aircraft:unit.team=0
		for unit in game.ground_units:unit.team=0
		a=game.aircraft[1];a.player=true;a.shoot=false
		a.translation=game.service_bases.center(0)+Vector3(0,a.landing.clearance+1.5,800)
		a.rotation=Vector3.ZERO;a.linear_velocity=Vector3(0,-1.5,-85 if a.data.id=="su27" else -30);a.angular_velocity=Vector3.ZERO
		a.direction=Vector3.FORWARD;a.throttle=0;a.landing.gear_down=true;a.landing.brake=true
		a.weapons.ammo=1;a.damage.zones.engine=.6
		check(abs(game.terrain.height_at(0,3000)-game.terrain.height_at(0,5000))<.001,"runway terrain is level over 2 km")
		check(game.service_bases.fields.size()==2,"two usable airfields exist")
		game.combat.update(5)
		check(game.combat.stats(a).services==0,"airborne aircraft does not receive service")
		var original=a.translation
		a.translation=game.service_bases.center(1)+Vector3.UP*a.landing.clearance;a.landing.grounded=true;a.linear_velocity=Vector3.ZERO
		game.combat.update(5)
		check(game.combat.stats(a).services==0,"enemy airfield does not service player")
		a.translation=original;a.landing.grounded=false;a.linear_velocity=Vector3(0,-1.5,-85 if a.data.id=="su27" else -30)
		game.graphics.set_preset(2);game.graphics.apply(game)
		check(game.terrain.high_material is ShaderMaterial,"HIGH uses layered photo terrain material")
		check(game.service_bases.detail_nodes.size()==8,"external detailed airport models placed")
		stage=1
	if a==null:return
	if stage==1:
		a.landing.brake=true;a.throttle=0
		if a.landing.grounded and a.linear_velocity.length()<1.5:
			check(not a.dead,a.data.name+" touches down and brakes to rest")
			stopped_at=game.combat.clock;stage=2
		elif elapsed>20:
			check(false,a.data.name+" touches down and brakes to rest");finish()
	elif stage==2:
		a.landing.brake=true;a.throttle=0
		if game.combat.stats(a).services>0:
			service_at=game.combat.clock
			check(service_at-stopped_at>=4.5 and service_at-stopped_at<5.3,"repair completes after five stopped seconds")
			check(a.weapons.ammo==int(a.data.ammo) and a.damage.zones.engine==1,"runway repair and rearm complete")
			a.landing.brake=false;a.throttle=1;a.direction=Vector3(0,.20,-1).normalized();takeoff_at=elapsed;stage=3
		elif elapsed>30:
			check(false,"runway servicing occurs");finish()
	elif stage==3:
		a.landing.brake=false;a.throttle=1;a.direction=Vector3(0,.20,-1).normalized()
		if not a.landing.grounded and a.translation.y>game.service_bases.center(0).y+20:
			check(not a.dead,"repaired "+a.data.name+" accelerates and takes off")
			var speed=a.linear_velocity.length()
			check(speed>a.data.stall_speed*1.05,"takeoff uses airspeed and aerodynamic lift")
			print("LANDING CYCLE seconds=",elapsed," takeoff_speed=",speed)
			stage=4
		elif elapsed-takeoff_at>45:
			check(false,"repaired "+a.data.name+" accelerates and takes off");print("STATE ",a.translation," v=",a.linear_velocity," dead=",a.dead);finish()
	elif stage==4:
		# A separate belly-landing fixture must fail, not silently receive service.
		var b=game.aircraft[2];b.player=true;b.team=0;b.landing.gear_down=false
		b.translation=game.service_bases.center(0)+Vector3(10,1,500);b.linear_velocity=Vector3(0,-3,-80 if a.data.id=="su27" else -30)
		stage=5
	elif stage==5:
		if game.aircraft[2].dead:
			check(true,"gear-up runway contact is destructive")
			if a.data.id=="biplane":
				finish();return
			bot=game.aircraft[3];bot.player=false;bot.team=0;bot.weapons.ammo=0;bot.landing.gear_down=true;bot.ai.landing_approach.phase="FINAL"
			bot.translation=game.service_bases.center(0)+Vector3(0,40,1100);bot.rotation=Vector3.ZERO;bot.linear_velocity=Vector3(0,-2,-110);bot.angular_velocity=Vector3.ZERO
			bot_start=elapsed;stage=6
	elif stage==6:
		if bot.dead:
			check(false,"AI landing and service");print("AI LANDING CRASH ",bot.translation," velocity=",bot.linear_velocity);finish()
		elif game.combat.stats(bot).services>0:
			check(true,"AI lands and receives five-second ground service");finish()
		elif elapsed-bot_start>65:
			check(false,"AI landing and service timeout");print("AI STATE ",bot.ai.landing_approach.phase," p=",bot.translation," v=",bot.linear_velocity);finish()
	if elapsed>110:
		check(false,"landing cycle time limit");finish()
func finish():
	print("LANDING COMPLETE ",checks)
	var f=File.new();f.open("user://landing_tests.json",File.WRITE);f.store_string(JSON.print(checks,"  "));f.close()
	get_tree().quit()
