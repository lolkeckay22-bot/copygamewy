extends Spatial
var game
var particles=[]
var cursor=0
var active=[]
var active_flags=[]
var has_geometry=false
var renderer
var budget=256
var uv=[Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]
var colors=[Color(1,1,1),Color(.95,.10,.08),Color(.15,.45,1),Color(.10,.85,.25),Color(1,.82,.05),Color(.8,.2,1),Color(1,.4,.05)]
func _ready():
	for i in range(1400):
		particles.append({"life":0.0,"max":1.0,"p":Vector3.ZERO,"v":Vector3.ZERO,"size":1.0,"color":Color.white,"glow":false})
		active_flags.append(false)
	renderer=ImmediateGeometry.new();var mat=SpatialMaterial.new();mat.flags_unshaded=true;mat.flags_transparent=true;mat.albedo_texture=load("res://assets/textures/particle.png");mat.vertex_color_use_as_albedo=true;mat.params_cull_mode=SpatialMaterial.CULL_DISABLED
	renderer.material_override=mat;add_child(renderer)
func emit(pos,vel,color,size,lifetime,glow=false):
	budget=[256,640,1400][game.graphics.effects]
	cursor=cursor%budget
	var slot=cursor
	var p=particles[slot];cursor=(cursor+1)%budget
	if not active_flags[slot]:
		active_flags[slot]=true
		active.append(slot)
	p.life=lifetime;p.max=lifetime;p.p=pos;p.v=vel;p.color=color;p.size=size;p.glow=glow
func burst(pos,large=true):
	var count=([12,28,65][game.graphics.effects]) if large else ([4,8,16][game.graphics.effects])
	for i in range(count):
		var v=Vector3(rand_range(-1,1),rand_range(-.2,1),rand_range(-1,1)).normalized()*rand_range(8,35)
		emit(pos,v,Color(1,.35,.04),rand_range(.5,2),rand_range(.3,.9),true)
	for i in range(count/2):emit(pos,Vector3(rand_range(-6,6),rand_range(3,15),rand_range(-6,6)),Color(.12,.13,.14),rand_range(2,5),rand_range(2,5))
func clear():
	for slot in active:
		particles[slot].life=0
		active_flags[slot]=false
	active.clear()
	renderer.clear()
	has_geometry=false
func _process(dt):
	if game==null or game.paused:return
	if active.empty():
		if has_geometry:
			renderer.clear()
			has_geometry=false
		return
	if game.camera==null:return
	var draw=game.is_in_flight()
	var right=game.camera.global_transform.basis.x
	var up=game.camera.global_transform.basis.y
	var limit=pow(min(game.graphics.draw_distance,[2200,4000,6000][game.graphics.effects]),2)
	renderer.clear()
	if draw:renderer.begin(Mesh.PRIMITIVE_TRIANGLES)
	var index=active.size()-1
	while index>=0:
		var slot=active[index]
		var p=particles[slot]
		p.life-=dt
		if p.life<=0:
			p.life=0
			active_flags[slot]=false
			active.remove(index)
			index-=1
			continue
		p.p+=p.v*dt
		p.v*=max(0,1-dt*.5)
		if draw and p.p.distance_squared_to(game.camera.translation)<=limit and not game.camera.is_position_behind(p.p):
			var age=1.0-p.life/p.max
			var size=p.size*(1+age*(.2 if p.glow else 3.0))
			var color=p.color
			color.a=clamp(p.life/p.max,0,1)*(.9 if p.glow else .22)
			var corners=[p.p-right*size-up*size,p.p+right*size-up*size,p.p+right*size+up*size,p.p-right*size+up*size]
			renderer.set_color(color)
			for i in [0,1,2,0,2,3]:
				renderer.set_uv(uv[i])
				renderer.add_vertex(corners[i])
		index-=1
	if draw:renderer.end()
	has_geometry=draw and not active.empty()
