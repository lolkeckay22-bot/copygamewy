extends Spatial
const CAPACITY=512
var game
var slots=[]
var cursor=0
var tracer
var shots=0
var hits=0
var broadphase_rejects=0
var narrowphase_checks=0
func _ready():
	for i in range(CAPACITY):
		slots.append({"life":0.0,"p":Vector3.ZERO,"v":Vector3.ZERO,"owner":null})
	tracer=ImmediateGeometry.new()
	var m=SpatialMaterial.new();m.flags_unshaded=true;m.albedo_color=Color(1,.72,.28);m.params_cull_mode=SpatialMaterial.CULL_DISABLED
	tracer.material_override=m;add_child(tracer)
func spawn(p,v,owner):
	var s=slots[cursor];cursor=(cursor+1)%CAPACITY
	s.life=3.0;s.p=p;s.v=v;s.owner=owner
	shots+=1
func _physics_process(dt):
	if game==null or not game.is_in_flight() or game.paused:
		return
	var any_active=false
	for s in slots:
		if s.life>0:
			if s.owner==null or not is_instance_valid(s.owner):
				s.life=0
				s.owner=null
				continue
			any_active=true
			break
	if not any_active:
		return
	var candidates=[]
	for a in game.aircraft+game.ground_units:
		if a==null or not is_instance_valid(a):
			continue
		if a.dead:continue
		var radius=Vector3(a.data.span*.47,1.25,a.data.length*.48)
		candidates.append({"a":a,"p":a.translation,"motion":a.linear_velocity*dt,"basis":a.global_transform.basis,"radius":radius,"bound":max(radius.x,max(radius.y,radius.z))})
	for s in slots:
		if s.life<=0:
			continue
		if s.owner==null or not is_instance_valid(s.owner):
			s.life=0
			s.owner=null
			continue
		s.life-=dt
		var old=s.p
		s.v.y-=9.81*dt;s.p+=s.v*dt
		for candidate in candidates:
			var a=candidate.a
			if a.dead or a.team==s.owner.team:
				continue
			# Swept relative segment / ellipsoid; accounts for moving aircraft.
			var start=old-candidate.p+candidate.motion
			var delta=s.p-old-candidate.motion
			if abs(start.x)>candidate.bound+abs(delta.x) or abs(start.z)>candidate.bound+abs(delta.z) or abs(start.y)>candidate.bound+abs(delta.y):
				broadphase_rejects+=1
				continue
			var closest=clamp(-start.dot(delta)/max(delta.length_squared(),.00001),0,1)
			if (start+delta*closest).length_squared()>candidate.bound*candidate.bound:
				broadphase_rejects+=1
				continue
			narrowphase_checks+=1
			var b=candidate.basis
			var p0=b.xform_inv(start)
			var p1=b.xform_inv(s.p-candidate.p)
			var radius=candidate.radius
			var u=p0/radius;var v=(p1-p0)/radius
			var t=clamp(-u.dot(v)/max(v.length_squared(),.00001),0,1)
			if (u+v*t).length_squared()<1.0:
				var point=old.linear_interpolate(s.p,t)
				a.take_hit(point,s.owner.data.damage,s.owner)
				hits+=1
				game.effects.burst(point,false)
				if s.owner.player:
					game.hit_marker=.16
				s.life=0;break
		if s.life>0 and s.p.y<500.0:
			if s.p.y<game.terrain.height_at(s.p.x,s.p.z):
				s.life=0
				s.owner=null
		elif s.life<=0:
			s.owner=null
func _process(_dt):
	if tracer==null:
		return
	tracer.clear()
	if game==null or not game.is_in_flight():
		return
	tracer.begin(Mesh.PRIMITIVE_LINES)
	for i in range(CAPACITY):
		var s=slots[i]
		if s.life>0 and (i%2==0 or game.graphics.effects>0):
			tracer.add_vertex(s.p);tracer.add_vertex(s.p-s.v.normalized()*14)
	tracer.end()
