extends Reference
# Match-only gameplay state; no extra physics bodies or per-frame scene searches.
var game
var selected_target=null
var roster={}
var recent_hits={}
var feed=[]
var service_progress={}
var service_cooldowns={}
var clock=0.0
func reset():
	selected_target=null;roster.clear();recent_hits.clear();feed.clear()
	service_progress.clear();service_cooldowns.clear();clock=0.0
func stats(a):
	var id=a.get_instance_id()
	if not roster.has(id):roster[id]={"kills":0,"ground":0,"assists":0,"deaths":0,"damage":0.0,"services":0}
	return roster[id]
func valid(t):
	return t!=null and is_instance_valid(t) and not t.dead
func select_target(ground=false):
	var a=game.player
	if a==null:return
	var candidates=[]
	var roster=game.ground_units+game.service_bases.targets if ground else game.aircraft
	for t in roster:
		if valid(t) and (t.team!=a.team or game.mode=="freeflight" and ground):candidates.append(t)
	if candidates.empty():
		selected_target=null
		game.notification="НАЗЕМНЫХ ЦЕЛЕЙ НЕТ" if ground else "ВОЗДУШНЫХ ЦЕЛЕЙ НЕТ"
		game.notification_time=2
		return
	if candidates.has(selected_target):
		selected_target=candidates[(candidates.find(selected_target)+1)%candidates.size()]
	else:
		var best=1e20
		for t in candidates:
			var delta=t.translation-a.translation
			var cost=(1.0-game.controller.aim.dot(delta.normalized()))*8000+delta.length()
			if cost<best:
				best=cost;selected_target=t
	a.weapons.lock_target=null if ground else selected_target
	a.weapons.lock_progress=0
func damage(victim,attacker,amount):
	if attacker==null or not is_instance_valid(attacker) or attacker.team==victim.team:return
	stats(attacker).damage+=amount
	var id=victim.get_instance_id()
	if not recent_hits.has(id):recent_hits[id]={}
	recent_hits[id][attacker.get_instance_id()]={"time":clock,"attacker":attacker}
func destroyed(victim,attacker,ground=false):
	var id=victim.get_instance_id()
	var hits=recent_hits.get(id,{})
	var killer=null
	if attacker!=null and is_instance_valid(attacker) and attacker.team!=victim.team:
		var record=hits.get(attacker.get_instance_id(),null)
		if record!=null and clock-record.time<12:killer=attacker
	if not ground:stats(victim).deaths+=1
	if killer!=null:
		stats(killer)["ground" if ground else "kills"]+=1
	for key in hits:
		var h=hits[key]
		if is_instance_valid(h.attacker) and h.attacker!=killer and clock-h.time<12:stats(h.attacker).assists+=1
	recent_hits.erase(id)
	var who="YOU" if killer==game.player else ("BLUE" if victim.team==1 else "RED")
	feed.push_front({"text":who+" > "+victim.data.name if killer!=null else victim.data.name+" УНИЧТОЖЕН","time":clock,"team":1-victim.team})
	if feed.size()>4:feed.pop_back()
	if killer==game.player:
		game.notification="НАЗЕМНАЯ ЦЕЛЬ УНИЧТОЖЕНА +1" if ground else "ВОЗДУШНАЯ ЦЕЛЬ УНИЧТОЖЕНА +1"
		game.notification_time=3
func home(a):
	return game.service_bases.center(a.team)
func needs_service(a):
	return a.weapons.ammo<int(a.data.ammo*.15) or a.damage.zones.engine<.45
func service_status(a):
	return service_progress.get(a.get_instance_id(),0.0)
func update(dt):
	clock+=dt
	if not valid(selected_target):selected_target=null
	for a in game.aircraft:
		if a.dead:continue
		a.spawn_protection=max(0,a.spawn_protection-dt)
		var id=a.get_instance_id()
		var cooldown=max(0,service_cooldowns.get(id,0.0)-dt);service_cooldowns[id]=cooldown
		var base=game.service_bases.at_position(a.translation)
		var eligible=base!=null and base.team==a.team and base.operational and a.landing.grounded and a.linear_velocity.length()<2.0
		eligible=eligible and not a.shoot and a.throttle<.15 and clock-a.last_damage_time>1 and cooldown<=0
		if eligible:
			service_progress[id]=service_progress.get(id,0.0)+dt
			if service_progress[id]>=5:
				a.damage=preload("res://scripts/DamageModel.gd").new()
				a.weapons.ammo=int(a.data.ammo);a.weapons.reset_stores(a);a.weapons.heat=0;a.weapons.overheated=false
				a.flight.fuel=1
				if a.model!=null:
					a.model.reset_damage_visual()
				service_progress[id]=0;service_cooldowns[id]=5;stats(a).services+=1
				if a==game.player:
					game.notification="ОБСЛУЖИВАНИЕ ЗАВЕРШЕНО — РЕМОНТ И БОЕЗАПАС";game.notification_time=4
		else:service_progress[id]=0
func on_respawn(a):
	recent_hits.erase(a.get_instance_id());service_progress[a.get_instance_id()]=0
	a.spawn_protection=4.0;a.last_damage_time=-100
	a.weapons.heat=0;a.weapons.overheated=false
