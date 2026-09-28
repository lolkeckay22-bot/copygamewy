extends Spatial
var game
var team=1
var player=false
var dead=false
var data={"span":3.8,"length":7.2,"bullet_speed":780.0,"damage":13.0,"hp":180.0,"name":"НАЗЕМНАЯ / ЗСУ"}
var linear_velocity=Vector3.ZERO
var hp=180.0
var turret
var body_low
var body_high
var plan_clock=0.0
var fire_clock=0.0
var destination=Vector3.ZERO
var target=null
var move_speed=10.0
var turret_health=1.0
var is_tank=false
var phase=0.0
func build(owner,faction,tank):
	game=owner;team=faction;is_tank=tank
	hp=300 if tank else 180;data.hp=hp;data.name="ТАНК" if tank else "МОБИЛЬНАЯ ЗСУ"
	body_low=make_body(false);add_child(body_low)
	body_high=make_body(true);add_child(body_high)
	turret=Spatial.new();turret.translation.y=1.4;add_child(turret)
	var builder=preload("res://scripts/AircraftModel.gd").new()
	builder.box(Vector3(0,.15,0),Vector3(2.0,.8,2.4),Color(.24,.29,.18))
	for side in [-1,1]:
		builder.box(Vector3(side*.35,.35,-2),Vector3(.15,.15,3.8 if tank else 2.8),Color(.10,.13,.1))
	turret.add_child(builder.finish_mesh());builder.free()
	destination=translation+Vector3(400,0,300)
func make_body(high):
	var b=preload("res://scripts/AircraftModel.gd").new()
	var color=Color(.22,.28,.17) if team==0 else Color(.35,.30,.19)
	b.box(Vector3(0,.7,0),Vector3(3.3,1.2,6.5),color)
	b.box(Vector3(0,1.4,1.3),Vector3(2.6,.7,2),color.darkened(.12))
	for side in [-1,1]:
		b.box(Vector3(side*1.7,.45,0),Vector3(.6,.9,6.5),Color(.10,.12,.09))
		if high:
			for z in range(6):
				b.fuselage([[-.3,.42,.42],[.3,.42,.42]],0,0,color,16)
				# Wheel profiles are remapped to the hull sides as a separate merged primitive.
				for i in range(b.vertices.size()-96,b.vertices.size()):
					if i>=0:
						var v=b.vertices[i];b.vertices[i]=Vector3(side*1.77+v.z,v.y+.48,v.x-2.5+z)
			for z in range(24):b.box(Vector3(side*1.7,.95,-3.1+z*.27),Vector3(.64,.08,.07),Color(.27,.28,.24))
	if high:
		for z in range(12):b.box(Vector3(0,1.36,1.0+z*.13),Vector3(1.5,.04,.06),Color(.07,.09,.06))
		for x in [-1.2,1.2]:
			b.box(Vector3(x,1.45,-2.6),Vector3(.28,.22,.1),Color(.84,.78,.51))
			b.box(Vector3(x,1.45,2.3),Vector3(.5,.5,1.0),color.darkened(.2))
		b.box(Vector3(.8,2.3,1.7),Vector3(.035,2.1,.035),Color(.12,.13,.10))
	var node=b.finish_mesh()
	if high:
		var mat=node.mesh.surface_get_material(0);mat.albedo_texture=load("res://assets/textures/camo.png");mat.uv1_triplanar=true;mat.uv1_scale=Vector3.ONE*.3;mat.metallic=.25;mat.roughness=.68
	b.free();return node
func _physics_process(dt):
	if game==null or game.mode!="battle" or game.paused or dead:return
	phase+=dt;plan_clock-=dt;fire_clock-=dt
	var camera_distance_sq=translation.distance_squared_to(game.camera.translation)
	body_high.visible=game.graphics.preset>0 and camera_distance_sq<1960000.0
	body_low.visible=not body_high.visible
	visible=camera_distance_sq<game.graphics.draw_distance*game.graphics.draw_distance
	if plan_clock<=0:
		plan_clock=.25
		target=game.targeting.nearest(self,game.aircraft)
		if translation.distance_to(destination)<60 or phase<.3:
			destination=translation+Vector3(rand_range(-500,500),0,rand_range(-500,500))
		if target!=null and target.translation.distance_to(translation)<1000:
			var away=(translation-target.translation);away.y=0
			destination=translation+away.normalized()*200+Vector3(sin(phase)*140,0,cos(phase)*140)
	var move=destination-translation;move.y=0
	linear_velocity=move.normalized()*move_speed
	if move.length_squared()>1:rotation.y=lerp_angle(rotation.y,atan2(-move.x,-move.z),min(1,dt*1.2))
	translation+=linear_velocity*dt;translation.y=game.terrain.height_at(translation.x,translation.z)+.1
	if target==null:return
	var dist=translation.distance_to(target.translation)
	if dist>2200:return
	var aim=target.translation+target.linear_velocity*(dist/data.bullet_speed)+Vector3.UP*4.905*pow(dist/data.bullet_speed,2)
	var desired=(aim-turret.global_transform.origin).normalized()
	var current=-turret.global_transform.basis.z
	var look=current.slerp(desired,min(1,dt*(2.0+game.difficulty)*turret_health)).normalized()
	if abs(look.y)<.995:turret.look_at(turret.global_transform.origin+look,Vector3.UP)
	if fire_clock<=0 and current.dot(desired)>.985:
		var clear=true
		for i in range(1,6):
			var p=turret.global_transform.origin.linear_interpolate(target.translation,i/6.0)
			if p.y<game.terrain.height_at(p.x,p.z)+1:
				clear=false
				break
		if clear:
			fire_clock=[.3,.19,.12][game.difficulty]
			var spread=[.016,.009,.004][game.difficulty]
			var d=(desired+Vector3(rand_range(-spread,spread),rand_range(-spread,spread),rand_range(-spread,spread))).normalized()
			game.projectiles.spawn(turret.global_transform.origin+look*2,linear_velocity+d*data.bullet_speed,self)
			game.effects.emit(turret.global_transform.origin+look*2,Vector3.ZERO,Color(1,.6,.2),.8,.07,true)
func take_hit(point,amount,_attacker):
	if dead:return
	game.combat.damage(self,_attacker,amount*(.65 if is_tank else 1.0))
	hp-=amount*(.65 if is_tank else 1.0)
	move_speed=max(2,move_speed-amount*.025);turret_health=max(.25,hp/data.hp)
	game.effects.burst(point,false)
	if hp<=0:
		dead=true;linear_velocity=Vector3.ZERO;turret.hide()
		body_high.mesh.surface_get_material(0).albedo_color=Color(.12,.12,.12)
		body_low.mesh.surface_get_material(0).albedo_color=Color(.12,.12,.12)
		game.match_state.kill(team);game.spawn_explosion(translation)
		game.combat.destroyed(self,_attacker,true)
		game.check_victory()
