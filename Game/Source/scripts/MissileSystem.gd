extends Spatial
# Arcade seek/steer model. Public mass/type references do not imply engineering fidelity.
var game
var specs={"R-73":{"mesh":"r73","mass":105.0,"max_speed":850.0,"turn_g":40.0,"range":5000.0,"life":22.0,"ir":true,"lock_time":.85},"R-27R":{"mesh":"r27r","mass":253.0,"max_speed":1150.0,"turn_g":30.0,"range":10000.0,"life":35.0,"ir":false,"lock_time":1.6}}
var slots=[]
var flares=[]
var launched=0
var impacts=0
var decoyed=0
var clock=0.0
func _ready():
	for i in range(40):
		var node=MeshInstance.new();node.hide();add_child(node)
		slots.append({"active":false,"node":node,"p":Vector3.ZERO,"v":Vector3.ZERO,"owner":null,"target":null,"type":"R-73","age":0.0,"lost":0.0,"decoy":-1,"trail":0.0})
	for i in range(128):flares.append({"life":0.0,"p":Vector3.ZERO,"v":Vector3.ZERO,"owner":null})
func clear():
	for m in slots:
		m.active=false
		m.owner=null
		m.target=null
		m.node.hide()
	for f in flares:
		f.life=0
		f.owner=null
func valid_target(a,t,kind):
	if t==null or not is_instance_valid(t) or t.dead or t.team==a.team:return false
	var offset=t.translation-a.translation
	return offset.length()<specs[kind].range and (-a.global_transform.basis.z).dot(offset.normalized())>cos(deg2rad(40 if specs[kind].ir else 55))
func launch(a,t,kind):
	if not valid_target(a,t,kind):return false
	for m in slots:
		if m.active:continue
		m.active=true;m.owner=a;m.target=t;m.type=kind;m.age=0;m.lost=0;m.decoy=-1;m.trail=0
		m.p=a.translation+a.global_transform.basis.x*(2 if a.weapons.missile_count%2==0 else -2)-a.global_transform.basis.y*1.3
		m.v=a.linear_velocity-a.global_transform.basis.z*45
		m.node.mesh=load("res://assets/models/"+specs[kind].mesh+".res");m.node.translation=m.p;m.node.show()
		var vdir=m.v.normalized()
		if abs(vdir.y)<0.995:
			m.node.look_at(m.p+vdir,Vector3.UP)
		launched+=1;game.audio.play("launch");return true
	return false
func release_flares(a):
	if a.weapons.flares<=0 or a.weapons.flare_cooldown>0:return false
	if a.player:game.audio.play("flare")
	a.weapons.flares-=1;a.weapons.flare_cooldown=.35
	var count=0
	for f in flares:
		if f.life>0:continue
		f.life=3.0;f.owner=a;f.p=a.translation+a.global_transform.basis.z*4
		f.v=a.linear_velocity*.7+a.global_transform.basis.x*(35 if count==0 else -35)-Vector3.UP*12
		count+=1
		if count==2:break
	return true
func threat(a):
	for m in slots:
		if m.active and m.target==a and m.p.distance_squared_to(a.translation)<9000000:return m
	return null
func _physics_process(dt):
	if game==null or not game.is_in_flight() or game.paused:return
	clock+=dt
	for i in range(flares.size()):
		var f=flares[i]
		if f.life<=0:continue
		f.life-=dt;f.v+=Vector3.DOWN*9.81*dt;f.v*=1-dt*.8;f.p+=f.v*dt
		game.effects.emit(f.p,Vector3.ZERO,Color(1,.78,.3),.55,.1,true)
	for m in slots:
		if not m.active:continue
		var spec=specs[m.type];m.age+=dt
		if m.owner==null or not is_instance_valid(m.owner):
			m.active=false
			m.owner=null
			m.target=null
			m.node.hide()
			continue
		var target_alive=is_instance_valid(m.target) and not m.target.dead
		var aim=m.p+m.v
		if target_alive:
			aim=m.target.translation+m.target.linear_velocity*clamp(m.p.distance_to(m.target.translation)/max(100,m.v.length()),0,2.2)*.7
			if not spec.ir and (m.owner.dead or not valid_target(m.owner,m.target,m.type)):m.lost+=dt
			else:m.lost=max(0,m.lost-dt)
			if spec.ir and m.decoy<0 and m.age>.3:
				for j in range(flares.size()):
					var f=flares[j]
					if f.life>1 and f.owner==m.target and f.p.distance_squared_to(m.p)<1000000 and m.v.normalized().dot((f.p-m.p).normalized())>.85:
						# Probability is frame-rate independent and uses only arcade decoy strength.
						if randf()<1-exp(-dt*.8):
							m.decoy=j
							decoyed+=1
							break
		if m.decoy>=0:
			if flares[m.decoy].life>0:aim=flares[m.decoy].p
			else:m.lost+=dt
		var vdir=m.v.normalized()
		if m.lost<1.2:
			var desired=(aim-m.p).normalized();var angle=vdir.angle_to(desired)
			var fraction=min(1.0,(spec.turn_g*9.81/max(m.v.length(),100))*dt/max(angle,.001))
			vdir=vdir.slerp(desired,fraction).normalized()
		var speed=min(spec.max_speed,m.v.length()+(170 if m.age<4.0 else -5.0)*dt)
		m.v=vdir*max(speed,50)+Vector3.DOWN*9.81*dt
		var old=m.p;m.p+=m.v*dt;m.node.translation=m.p
		if abs(vdir.y)<.995:m.node.look_at(m.p+vdir,Vector3.UP)
		m.trail-=dt
		if m.trail<=0:
			m.trail=[.08,.04,.02][game.graphics.effects]
			game.effects.emit(m.p-m.v.normalized()*2,Vector3.UP,Color(.84,.87,.89),.45,2.4)
			if m.age<4:game.effects.emit(m.p-m.v.normalized()*1.8,Vector3.ZERO,Color(1,.55,.15),.4,.08,true)
		if target_alive and m.decoy<0:
			var seg=m.p-old;var t=clamp((m.target.translation-old).dot(seg)/max(seg.length_squared(),.001),0,1)
			if (old+seg*t).distance_to(m.target.translation)<7:
				m.target.take_hit(m.target.translation,220,m.owner);impacts+=1;explode(m);continue
		if m.age>spec.life:explode(m)
		elif m.p.y<500.0:
			if m.p.y<game.terrain.height_at(m.p.x,m.p.z):explode(m)
func explode(m):
	game.effects.burst(m.p);m.active=false;m.owner=null;m.target=null;m.node.hide()
