extends Reference
var phase=""
var serviced=false
func update(a):
	var game=a.game;var center=game.service_bases.center(a.team);var sign_z=1 if a.team==0 else -1
	var forward=Vector3(0,0,-sign_z)
	var speed=a.linear_velocity.length()
	if phase=="":phase="JOIN"
	if phase=="JOIN":
		a.landing.gear_down=true;a.landing.brake=false
		a.flight_controls.flaps=1 if speed<a.data.flap_limit else 0
		var entry=center+Vector3(0,90,sign_z*2100)
		a.ai.direction=(entry-a.translation).normalized()
		a.throttle=clamp(.45+(a.data.stall_speed*1.5-speed)*.012,.05,.85)
		if a.translation.distance_to(entry)<180:phase="FINAL"
	elif phase=="FINAL":
		a.flight_controls.flaps=2 if speed<a.data.flap_limit else 0
		var remaining=(a.translation.z-center.z)*sign_z
		var target_height=center.y+a.landing.clearance+max(0,(remaining-500)*.055)
		var vertical=clamp((target_height-a.translation.y)*.20,-4.5,3.0)
		var lateral=clamp(-a.translation.x*.03,-.25,.25)
		var density=1.225*exp(-max(0,a.translation.y)/8500.0)
		var q_area=.5*density*max(30,speed)*max(30,speed)*a.data.area
		var needed_cl=a.data.mass*(9.81+clamp((vertical-a.linear_velocity.y)*.8,-4,4))/max(q_area*a.damage.lift_factor(),1)
		var needed_aoa=clamp((needed_cl-a.data.cl-a.data.flap_lift[a.flight_controls.flaps])/a.data.lift_slope,-.1,.24)
		var desired_pitch=atan2(a.linear_velocity.y,max(speed,30))+needed_aoa
		a.ai.direction=(forward+Vector3(lateral,tan(desired_pitch),0)).normalized()
		a.throttle=clamp(.33+(a.data.stall_speed*1.3-speed)*.018,0,.8)
		a.airbrake=speed>a.data.stall_speed*1.55
		if a.landing.grounded:phase="PARK"
		elif remaining< -850:phase="GO AROUND"
	elif phase=="PARK":
		a.throttle=0;a.landing.brake=true;a.airbrake=true;a.ai.direction=forward
		if game.combat.service_cooldowns.get(a.get_instance_id(),0)>0:phase="TAKEOFF"
	elif phase=="TAKEOFF":
		a.flight_controls.flaps=1
		a.landing.brake=false;a.airbrake=false;a.throttle=1.0
		a.ai.direction=(forward+Vector3.UP*(.16 if speed>a.data.stall_speed else .01)).normalized()
		if not a.landing.grounded and a.translation.y>center.y+60:
			a.landing.gear_down=a.data.id=="biplane";a.flight_controls.flaps=0;phase="";return false
	elif phase=="GO AROUND":
		a.throttle=1;a.landing.brake=false;a.airbrake=false;a.ai.direction=(forward+Vector3.UP*.25).normalized()
		if a.translation.y>center.y+250:phase="JOIN"
	a.ai.state_name="LAND / "+phase;a.ai.fire=false
	return true
