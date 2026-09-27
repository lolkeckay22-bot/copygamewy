extends Reference
var ammo = 0
var heat=0.0
var overheated=false
var cooldown = 0.0
var hardpoints = {"cannon":true,"missiles":false}
func update(a,dt,fire):
	update_stores(a,dt)
	heat=max(0,heat-dt*.23)
	if overheated and heat<.3:overheated=false
	cooldown = max(0,cooldown-dt)
	if fire and not overheated and cooldown <= 0 and ammo > 0:
		cooldown = 1.0/a.data.fire_rate
		ammo -= 1
		a.spawn_protection=0
		heat=min(1.0,heat+(.05 if a.data.id=="su27" else .045))
		if heat>=1:overheated=true
		var f = -a.global_transform.basis.z
		# Small arcade gun-convergence cone; no hitscan or guaranteed damage.
		# Ballistics, projectile travel, gravity and collision remain unchanged.
		if not a.player and a.ai.target!=null and not a.ai.target.dead:
			var lead=a.ai.targeting.lead(a,a.ai.target,a.data.bullet_speed)
			var correction=(lead-a.translation).normalized()
			if f.dot(correction)>0.9975:
				var spread=[0.012,0.006,0.0025][a.ai.skill]
				f=(correction+a.global_transform.basis.x*rand_range(-spread,spread)+a.global_transform.basis.y*rand_range(-spread,spread)).normalized()
		var origin = a.translation - a.global_transform.basis.z*(a.data.length*0.44)
		a.game.projectiles.spawn(origin,a.linear_velocity+f*a.data.bullet_speed,a)
		if a.player:
			a.game.audio.play("gun")

var missile_type="R-73"
var missile_stock={"R-73":4,"R-27R":2}
var missile_count=6
var missile_cooldown=0.0
var lock_target=null
var lock_progress=0.0
var flares=32
var flare_cooldown=0.0
var smoke=false
var smoke_color=0
var smoke_clock=0.0
func update_stores(a,dt):
	missile_cooldown=max(0,missile_cooldown-dt);flare_cooldown=max(0,flare_cooldown-dt)
	smoke_clock-=dt
	if smoke_clock<=0:
		smoke_clock=[.13,.07,.035][a.game.graphics.effects]
		if smoke:
			for x in [-a.data.span*.4,a.data.span*.4]:
				var p=a.translation+a.global_transform.basis.x*x+a.global_transform.basis.z*2
				a.game.effects.emit(p,Vector3.UP*.5,a.game.effects.colors[smoke_color],1.1,6.0)
		if a.damage.zones.engine<.5:a.game.effects.emit(a.translation,Vector3.UP*2,Color(.12,.13,.14),1.5,3)
		if a.data.id=="su27" and a.throttle>.93:
			for x in [-1.35,1.35]:a.game.effects.emit(a.translation+a.global_transform.basis.x*x+a.global_transform.basis.z*9,Vector3.ZERO,Color(.4,.58,1),.5,.1,true)
		if abs(a.flight.g_force)>4.5 and a.linear_velocity.length()>100:
			for x in [-a.data.span*.4,a.data.span*.4]:a.game.effects.emit(a.translation+a.global_transform.basis.x*x,Vector3.ZERO,Color(.91,.94,.96),.22,1.1)
	if a.data.id!="su27":return
	if not a.player and missile_stock[missile_type]<=0 and missile_count>0:cycle_missile()
	var candidate=a.ai.target if not a.player else lock_target
	if candidate==null or not is_instance_valid(candidate) or candidate.dead:
		candidate=a.game.targeting.nearest(a,a.game.aircraft)
		if a.player and a.game.combat.valid(a.game.combat.selected_target) and a.game.ground_units.has(a.game.combat.selected_target):candidate=null
	if candidate!=lock_target:
		lock_target=candidate
		lock_progress=0
	var previous_lock=lock_progress
	if a.game.missiles.valid_target(a,lock_target,missile_type):lock_progress=min(1,lock_progress+dt/a.game.missiles.specs[missile_type].lock_time)
	else:lock_progress=max(0,lock_progress-dt*2)
	if a.player and previous_lock<1 and lock_progress>=1:a.game.audio.play("lock")
	if not a.player and not a.ai.state_name.begins_with("LAND /") and lock_progress>=1 and missile_cooldown<=0:
		var distance=a.translation.distance_to(lock_target.translation)
		if distance>[800,550,400][a.ai.skill]:fire_missile(a)
func fire_missile(a):
	if a.data.id!="su27" or lock_progress<1 or missile_cooldown>0 or missile_stock[missile_type]<=0:return false
	if a.game.missiles.launch(a,lock_target,missile_type):
		a.spawn_protection=0
		missile_stock[missile_type]-=1;missile_count-=1;missile_cooldown=2.0 if a.player else [13,9,6][a.ai.skill]
		a.model.update_stores(missile_stock)
		return true
	return false
func cycle_missile():
	missile_type="R-27R" if missile_type=="R-73" else "R-73";lock_progress=0
func reset_stores(a):
	missile_stock={"R-73":4,"R-27R":2};missile_count=6;flares=32;lock_target=null;lock_progress=0;missile_cooldown=3
	a.model.update_stores(missile_stock)
