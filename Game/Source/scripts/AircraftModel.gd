extends Spatial
# Original procedural geometry. Forward axis: -Z. All dimensions in metres.
var vertices = []
var colors = []
var normal_color = Color(0.40,0.51,0.57)
var gear_visual
var gear_state=false
var gear_progress=0.0
var gear_pivots=[]
var flap_pivots=[]
var flap_position=0.0
var hangar_gear=false
var high_model
var stores=[]
var kind_id=""
var quality=0
var detailed
var simple
var propeller
var spin_speed=0.0
var vapor_mesh=null
var vapor_mat=null
var vapor_level=0.0
func tri(a,b,c,col):
	if (b-a).cross(c-a).length_squared()<0.00000001:return
	vertices.append(a); vertices.append(b); vertices.append(c)
	colors.append(col); colors.append(col); colors.append(col)
func quad(a,b,c,d,col):
	tri(a,b,c,col);tri(a,c,d,col)
func box(center,size,col):
	var p = []
	for x in [-1,1]:
		for y in [-1,1]:
			for z in [-1,1]:
				p.append(center+Vector3(x*size.x,y*size.y,z*size.z)*0.5)
	for q in [[0,1,3,2],[4,6,7,5],[0,4,5,1],[2,3,7,6],[0,2,6,4],[1,5,7,3]]:
		quad(p[q[0]],p[q[1]],p[q[2]],p[q[3]],col)
func fuselage(sections, cx, cy, col, n=16):
	for s in range(sections.size()-1):
		var a=sections[s];var b=sections[s+1]
		for i in range(n):
			var t=float(i)/n*TAU;var u=float(i+1)/n*TAU
			quad(Vector3(cx+cos(t)*a[1],cy+sin(t)*a[2],a[0]),Vector3(cx+cos(u)*a[1],cy+sin(u)*a[2],a[0]),Vector3(cx+cos(u)*b[1],cy+sin(u)*b[2],b[0]),Vector3(cx+cos(t)*b[1],cy+sin(t)*b[2],b[0]),col)
func foil(points,thickness,col):
	var up=Vector3(0,thickness*0.5,0)
	for i in range(1,points.size()-1):
		tri(points[0]+up,points[i]+up,points[i+1]+up,col)
		tri(points[0]-up,points[i+1]-up,points[i]-up,col.darkened(0.18))
	for i in range(points.size()):
		var j=(i+1)%points.size()
		quad(points[i]+up,points[j]+up,points[j]-up,points[i]-up,col.darkened(0.28))
func fin(x,col):
	var a=Vector3(x,0.45,4.1);var b=Vector3(x,3.9,6.3);var c=Vector3(x,3.5,8.5);var d=Vector3(x,0.4,8.7)
	var e=Vector3(0.08,0,0)
	quad(a+e,b+e,c+e,d+e,col);quad(d-e,c-e,b-e,a-e,col)
	quad(b+e,b-e,c-e,c+e,col.darkened(0.2))
	# Dark leading-edge dielectric panel and original faction stripe.
	quad(b+e+Vector3(0.012,0,0),b+Vector3(0.012,-0.45,0)+e,c+Vector3(0.012,-0.4,0)+e,c+e+Vector3(0.012,0,0),Color(0.15,0.23,0.28))
func finish_mesh():
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(vertices.size()):
		st.add_color(colors[i]);st.add_vertex(vertices[i])
	st.generate_normals()
	var material=SpatialMaterial.new()
	material.vertex_color_use_as_albedo=true
	material.params_cull_mode=SpatialMaterial.CULL_DISABLED
	material.roughness=0.75
	st.set_material(material)
	var mi=MeshInstance.new();mi.mesh=st.commit()
	vertices.clear();colors.clear()
	return mi
func add_gear(p,side,col,dark):
	var pivot=Spatial.new();pivot.translation=p;add_child(pivot)
	box(Vector3(0,-.62,0),Vector3(.16,1.3,.16),col.lightened(.12))
	box(Vector3(0,-1.24,.12),Vector3(.48,.64,.78),dark)
	var mesh=finish_mesh();pivot.add_child(mesh)
	gear_pivots.append({"pivot":pivot,"side":side})
func add_flap(side,col):
	var pivot=Spatial.new();pivot.translation=Vector3(0,.14,2.85);add_child(pivot)
	foil([Vector3(side*2.55,0,0),Vector3(side*6.83,0,.13),Vector3(side*6.65,0,.91),Vector3(side*2.35,0,.42)],.06,col.darkened(.20))
	pivot.add_child(finish_mesh());flap_pivots.append(pivot)
func build(kind,team=0,gear=false):
	kind_id=kind
	var col=Color(0.48,0.59,0.65) if team==0 else Color(0.57,0.51,0.43)
	var dark=Color(0.12,0.17,0.19)
	var accent=Color(0.96,0.53,0.19) if team==0 else Color(0.7,0.16,0.12)
	if kind=="su27":
		# Slender nose, blended fuselage, twin nacelles, swept wings and twin fins.
		fuselage([[-11,0.025,0.025],[-9.7,0.29,0.32],[-7.5,0.65,0.58],[-5.5,0.9,0.75],[-2.5,1.25,0.65],[1.0,1.43,0.62],[5.0,1.25,0.55],[8.6,0.62,0.35],[10,0.14,0.15]],0,0,col,20)
		fuselage([[-11.1,0.02,0.02],[-9.6,0.3,0.33],[-8.3,0.50,0.47]],0,0,Color(0.25,0.32,0.35),20)
		for side in [-1,1]:
			var x=side*1.35
			fuselage([[-3.5,0.63,0.6],[-1,0.70,0.70],[4.5,0.70,0.70],[7.8,0.60,0.57],[8.8,0.51,0.5]],x,-0.48,col,16)
			fuselage([[7.5,0.61,0.59],[8.5,0.56,0.55],[9.05,0.49,0.49]],x,-0.48,dark,20)
			fuselage([[9.055,0.46,0.46],[9.06,0.0,0.0]],x,-0.48,Color(0.055,0.065,0.07),16)
			box(Vector3(x,-0.4,-3.6),Vector3(1.2,1.0,0.12),dark)
			foil([Vector3(side*.7,0.12,-5.8),Vector3(side*2.7,0.07,-1.0),Vector3(side*7.35,0.06,2.6),Vector3(side*7.0,0.06,4.2),Vector3(side*2.0,0.12,3.6)],0.17,col)
			# A separate trailing-edge surface rotates with the physical flap state.
			foil([Vector3(side*1.0,0.15,5.3),Vector3(side*4.4,0.15,7.0),Vector3(side*4.6,0.15,8.6),Vector3(side*1.1,0.15,8.1)],0.12,col)
			box(Vector3(side*7.24,0.07,3.3),Vector3(0.16,0.18,2.25),dark)
			fin(side*1.6,col)
			box(Vector3(side*1.69,2.3,7.05),Vector3(0.03,0.28,1.1),accent)
		# Canopy with dark glazing and segmented metallic frame.
		fuselage([[-7.5,0.01,0.01],[-6.8,0.45,0.38],[-5.8,0.57,0.65],[-4.7,0.48,0.59],[-3.7,0.1,0.08]],0,0.63,Color(0.075,0.20,0.25),16)
		fuselage([[-6.1,0.565,0.62],[-6.0,0.565,0.64]],0,0.63,col.lightened(.15),16)
		box(Vector3(0,1.26,-5.2),Vector3(.075,.06,1.8),col)
		box(Vector3(-.94,.22,-5.2),Vector3(.13,.16,1.6),dark)
		box(Vector3(0,0,-11.35),Vector3(.025,.025,.7),dark)
		for side in [-1,1]:
			quad(Vector3(side*1.5,-.7,5.7),Vector3(side*1.7,-1.7,7),Vector3(side*1.7,-1.6,8),Vector3(side*1.5,-.6,8),col.darkened(.1))
			for z in [-1,0,1,2,3,4]:
				box(Vector3(side*1.35,.245,z),Vector3(.85,.015,.035),col.darkened(.22))
		if gear:
			for p in [Vector3(0,-1.35,-5.5),Vector3(-1.9,-1.35,1.2),Vector3(1.9,-1.35,1.2)]:
				box(p,Vector3(.12,1.4,.12),col.lightened(.1))
				box(p+Vector3(0,-.65,0),Vector3(.4,.7,.75),dark)
	else:
		col=Color(0.71,0.63,0.40)
		fuselage([[-4.1,.36,.4],[-3.3,.65,.69],[-1.7,.63,.67],[.5,.48,.48],[2.8,.19,.23],[4.1,.06,.1]],0,0,col,14)
		fuselage([[-4.25,.39,.43],[-3.5,.63,.68]],0,0,dark,16)
		for y in [-.45,1.55]:
			foil([Vector3(-5,y,-1.8),Vector3(5,y,-1.8),Vector3(5.2,y,.0),Vector3(-5.2,y,.0)],.14,col)
			for x in [-4,-3,-2,-1,1,2,3,4]:
				box(Vector3(x,y+.08,-.9),Vector3(.025,.012,1.6),col.darkened(.2))
		for side in [-1,1]:
			for z in [-1.5,-.05]:
				box(Vector3(side*3.4,.55,z),Vector3(.09,2,.09),dark)
			box(Vector3(side*.8,.9,-1),Vector3(.065,1.3,.065),dark)
			foil([Vector3(0,.15,2.5),Vector3(side*1.8,.15,2.9),Vector3(side*1.9,.15,3.8),Vector3(0,.15,3.8)],.09,col)
			box(Vector3(side*.9,-1.05,-1.7),Vector3(.1,1.1,.12),dark)
			box(Vector3(side*.95,-1.58,-1.7),Vector3(.25,.6,.6),Color(.07,.08,.075))
			box(Vector3(side*.29,.57,-2.7),Vector3(.095,.12,1.4),dark)
		foil([Vector3(-.46,.66,-1.6),Vector3(.46,.66,-1.6),Vector3(.43,.66,-.55),Vector3(-.43,.66,-.55)],.03,Color(.12,.23,.26))
		quad(Vector3(0,.1,2.7),Vector3(0,1.6,3.0),Vector3(0,1.5,3.9),Vector3(0,.1,4.1),col)
		# Propeller is merged with main model for low draw count; no transparency.
	# Everything is merged into one opaque mesh per aircraft.
	detailed=finish_mesh();add_child(detailed)
	if kind=="biplane":
		box(Vector3.ZERO,Vector3(.14,3,.08),Color(.24,.15,.08))
		propeller=finish_mesh();propeller.translation=Vector3(0,0,-4.3);add_child(propeller)
		spin_speed=0.0 if gear else 30.0
	var span=7.35 if kind=="su27" else 5.1
	var length=10.5 if kind=="su27" else 4.1
	foil([Vector3(0,0,-length),Vector3(span,0,length*.25),Vector3(0,0,length*.5),Vector3(-span,0,length*.25)],.18,col)
	box(Vector3(0,0,length*.55),Vector3(.5,.5,length*.7),col)
	simple=finish_mesh();add_child(simple);simple.hide()
	if kind=="su27":
		high_model=MeshInstance.new();high_model.mesh=load("res://assets/models/su27"+("_gear" if gear else "")+".res");add_child(high_model);high_model.hide()
		if not gear:
			for side in [-1,1]:add_flap(side,col)
			add_gear(Vector3(0,-.55,-5.5),0,col,dark)
			for side in [-1,1]:add_gear(Vector3(side*1.9,-.55,1.2),side,col,dark)
		for i in range(6):
			var missile=MeshInstance.new();var type="R-73" if i<4 else "R-27R"
			missile.mesh=load("res://assets/models/"+("r73" if i<4 else "r27r")+".res")
			var positions=[Vector3(-6.8,-.35,1.8),Vector3(6.8,-.35,1.8),Vector3(-4.5,-.55,1),Vector3(4.5,-.55,1),Vector3(-2.8,-.8,.3),Vector3(2.8,-.8,.3)]
			missile.translation=positions[i];add_child(missile);stores.append({"node":missile,"type":type,"index":i if i<4 else i-4,"loaded":true})
	else:
		high_model=MeshInstance.new();high_model.mesh=detailed.mesh.duplicate(true)
		var material=high_model.mesh.surface_get_material(0).duplicate();material.albedo_texture=load("res://assets/textures/fabric.png");material.uv1_triplanar=true;material.uv1_scale=Vector3.ONE*3;material.roughness=.8
		high_model.mesh.surface_set_material(0,material);add_child(high_model);high_model.hide()
	hangar_gear=gear
	build_vapor()
func build_vapor():
	if vapor_mesh!=null:
		return
	vapor_mesh=MeshInstance.new()
	var cone=CylinderMesh.new()
	cone.top_radius=1.1
	cone.bottom_radius=2.6
	cone.height=9.0
	cone.radial_segments=12
	cone.rings=1
	vapor_mat=SpatialMaterial.new()
	vapor_mat.flags_transparent=true
	vapor_mat.flags_unshaded=true
	vapor_mat.albedo_color=Color(0.92,0.95,0.97,0.0)
	vapor_mat.params_cull_mode=SpatialMaterial.CULL_DISABLED
	cone.material=vapor_mat
	vapor_mesh.mesh=cone
	vapor_mesh.translation=Vector3(0,0.2,1.5)
	vapor_mesh.rotation_degrees=Vector3(-90,0,0)
	add_child(vapor_mesh)
	vapor_mesh.hide()
func reset_damage_visual():
	apply_damage_tint(1.0)
	set_vapor(0.0)
func apply_damage_tint(health):
	var tint=Color.white.darkened((1.0-health)*0.6)
	if detailed!=null and is_instance_valid(detailed) and detailed.mesh!=null:
		var mat=detailed.mesh.surface_get_material(0)
		if mat!=null:
			mat.albedo_color=tint
func set_vapor(level):
	vapor_level=clamp(level,0.0,1.0)
	if vapor_mesh==null:
		return
	if vapor_level<0.02:
		vapor_mesh.hide()
		return
	if not visible:
		vapor_mesh.hide()
		return
	vapor_mesh.show()
	var c=vapor_mat.albedo_color
	c.a=vapor_level*0.42
	vapor_mat.albedo_color=c
	var s=0.7+vapor_level*0.6
	vapor_mesh.scale=Vector3(s,s,1.0)
func update_vapor(mach,aoa,g_force,speed):
	var cone=0.0
	if mach>0.75 and mach<1.35:
		var d=abs(mach-0.98)
		cone=clamp(1.0-d/0.28,0.0,1.0)
		if speed>120:
			cone*=clamp((speed-120.0)/180.0,0.25,1.0)
	var wing=clamp((abs(aoa)-0.20)*2.4,0.0,1.0)
	wing=max(wing,clamp((abs(g_force)-4.0)/5.0,0.0,0.8))
	if speed<60:
		wing*=speed/60.0
		cone*=clamp(speed/150.0,0.0,1.0)
	set_vapor(clamp(cone*0.95+wing*0.55,0.0,1.0))
func set_gear(down):
	if kind_id!="su27" or hangar_gear:return
	gear_state=down

func set_flaps(position):
	flap_position=clamp(int(position),0,2)

func set_lod(distance,max_distance):
	visible=distance<max_distance
	var use_simple=distance>(1600 if quality>0 else 900)
	var use_high=quality>0 and distance<(1100 if quality==2 else 650)
	detailed.visible=not use_simple and not use_high
	simple.visible=use_simple
	if high_model:high_model.visible=use_high
	if propeller:propeller.visible=not use_simple
	for store in stores:store.node.visible=store.loaded and distance<1400
func set_quality(value):
	quality=value
	set_lod(0,12000)
func update_stores(stock):
	for store in stores:
		store.loaded=store.index<stock[store.type]
		store.node.visible=store.loaded

func _process(dt):
	if propeller!=null and is_visible_in_tree():propeller.rotation.z+=dt*spin_speed
	if kind_id=="su27" and not hangar_gear:
		gear_progress=move_toward(gear_progress,1.0 if gear_state else 0.0,dt*.55)
		for part in gear_pivots:
			var hinge=part.pivot
			hinge.visible=gear_progress>.015
			hinge.rotation.x=-(1.0-gear_progress)*1.38 if part.side==0 else 0.0
			hinge.rotation.z=-part.side*(1.0-gear_progress)*1.35
		for flap in flap_pivots:
			flap.rotation.x=move_toward(flap.rotation.x,[0.0,.22,.48][flap_position],dt*.85)
