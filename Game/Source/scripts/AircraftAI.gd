extends Reference
var landing_approach=preload("res://scripts/LandingApproach.gd").new()
var targeting = preload("res://scripts/TargetingSystem.gd").new()
var target = null
var timer = 0.0
var direction = Vector3.FORWARD
var fire = false
var skill = 1
var state_name = "SEARCH"
var phase = 0.0
var retarget_timer=0.0
var break_until=0.0
var break_direction=Vector3.FORWARD
var burst_wait=false
func update(a, dt):
	timer -= dt
	phase += dt
	retarget_timer-=dt
	if timer > 0:
		return
	timer = [0.32,0.19,0.11][skill]
	if target==null or target.dead:
		target=choose_target(a);retarget_timer=2.0
	elif retarget_timer<=0:
		var candidate=choose_target(a)
		if candidate!=null and a.translation.distance_squared_to(candidate.translation)<a.translation.distance_squared_to(target.translation)*0.42:
			target=candidate
		retarget_timer=2.0
	fire = false
	a.airbrake=false
	var altitude = a.translation.y - a.game.terrain.height_at(a.translation.x,a.translation.z)
	var speed = a.linear_velocity.length()
	var floor_height = 250.0 if a.data.id == "biplane" else 700.0
	if altitude < floor_height or a.linear_velocity.y < -altitude*0.25:
		direction = Vector3(-a.global_transform.basis.z.x,0.65,-a.global_transform.basis.z.z).normalized()
		a.throttle = 1.0
		state_name = "CLIMB"
	elif speed < a.data.stall_speed * 1.35:
		direction = Vector3(-a.global_transform.basis.z.x,-0.13,-a.global_transform.basis.z.z).normalized()
		a.throttle = 1.0
		state_name = "RECOVER ENERGY"
	elif Vector2(a.translation.x,a.translation.z).length() > 10500:
		direction = (Vector3(0,900,0)-a.translation).normalized()
		state_name = "RETURN"
	elif target != null:
		var distance = a.translation.distance_to(target.translation)
		var aim = targeting.lead(a,target,a.data.bullet_speed)
		var forward = -a.global_transform.basis.z
		if distance > 1000:
			aim = target.translation + target.global_transform.basis.z * 250
			aim.y += 60
		direction = (aim-a.translation).normalized()
		direction.y=clamp(direction.y,-0.4,0.4)
		direction=direction.normalized()
		state_name = "PURSUE"
		if distance<220 and forward.dot(direction)<0.3 and phase>break_until:
			break_until=phase+3.0
			break_direction=Vector3(forward.x,0.15,forward.z).normalized()
		if phase<break_until:
			direction=break_direction;state_name="EXTEND"
		elif forward.dot(direction) < -0.2:
			state_name = "REPOSITION"
		if a.damage.health < 0.7 and sin(phase*0.7) > 0.65 and skill > 0:
			direction = (direction + a.global_transform.basis.x*sin(phase*2)*0.5 + Vector3.UP*0.25).normalized()
			state_name = "EVADE"
		var cone = [0.996,0.998,0.999][skill]
		fire = distance < [650,1000,1400][skill] and forward.dot(direction) > cone
		if fire:
			state_name = "ATTACK"
		a.airbrake=distance<1000 and speed>250 and forward.dot(direction)<.3
		var desired_speed=210.0 if a.data.id=="su27" else 45.0
		if distance<600:desired_speed=min(desired_speed,max(a.data.stall_speed*1.6,target.linear_velocity.length()))
		a.throttle=clamp((0.42 if a.data.id=="su27" else 0.72)+(desired_speed-speed)*(0.006 if a.data.id=="su27" else 0.04),0.25,1.0)
		if speed < a.data.stall_speed * 1.8:
			a.throttle = 1.0
	else:
		direction = (Vector3(0,800,0)-a.translation).normalized()


	if a.game.combat.needs_service(a) or landing_approach.phase!="":
		if landing_approach.update(a):return
	var incoming=a.game.missiles.threat(a)
	if incoming!=null and altitude>floor_height*.7:
		var toward=(incoming.p-a.translation).normalized()
		var side=toward.cross(Vector3.UP).normalized()
		direction=(-a.global_transform.basis.z*.35+side*(1 if sin(phase*.65)>0 else -1)+Vector3.UP*.12).normalized()
		a.throttle=1.0;state_name="DEFENSIVE BREAK"
		if skill>0 or incoming.p.distance_to(a.translation)<850:a.game.missiles.release_flares(a)

	if skill>0:
		if a.weapons.heat>.8:burst_wait=true
		if a.weapons.heat<.25:burst_wait=false
		if burst_wait:fire=false

func choose_target(a):
	var best=null;var cost=1e20
	for enemy in a.game.aircraft:
		if enemy==a or enemy.dead or enemy.team==a.team or enemy.spawn_protection>0:continue
		var attackers=0
		for friend in a.game.aircraft:
			if friend!=a and not friend.dead and friend.team==a.team and friend.ai.target==enemy:attackers+=1
		var delta=enemy.translation-a.translation
		var value=delta.length()*(1+attackers*.65)+(1-(-a.global_transform.basis.z).dot(delta.normalized()))*500
		if value<cost:
			cost=value;best=enemy
	return best
