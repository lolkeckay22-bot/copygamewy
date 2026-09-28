extends Spatial
var game
var fields=[]
var targets=[]
var quality=0
var detail_nodes=[]
var timer=0.0
var low_material
var high_material
func center(team):
	var z=4000 if team==0 else -4000
	return Vector3(0,game.terrain.base_height(team)+.12,z)
func at_position(p):
	for field in fields:
		var dz=abs(p.z-field.z)
		var runway=abs(p.x)<45 and dz<1600
		var taxiway=abs(p.x-160)<20 and dz<1400
		var connector=p.x>=0 and p.x<=180 and abs(dz-1100)<25
		var apron=abs(p.x-245)<90 and dz<460
		if runway or taxiway or connector or apron:return field
	return null
func create_target(field,kind,p):
	var target=preload("res://scripts/AirfieldTarget.gd").new()
	target.setup(game,field,kind,p)
	add_child(target)
	targets.append(target)
	return target
func hit_segment(old_pos,new_pos,owner,damage):
	var segment=new_pos-old_pos
	var length_sq=max(segment.length_squared(),.0001)
	for target in targets:
		if target.dead:continue
		if game.mode!="freeflight" and owner!=null and target.team==owner.team:continue
		var aim=target.aim_point()
		var t=clamp((aim-old_pos).dot(segment)/length_sq,0.0,1.0)
		var impact=old_pos+segment*t
		if impact.distance_squared_to(aim)<=target.hit_radius*target.hit_radius:
			target.take_hit(impact,damage,owner)
			return true
	return false
func paved(node,p,size):
	var strip=MeshInstance.new()
	var mesh=CubeMesh.new()
	mesh.size=size
	strip.mesh=mesh
	strip.translation=p
	strip.set_meta("runway",true)
	node.add_child(strip)
func build(owner):
	game=owner
	fields.clear()
	targets.clear()
	detail_nodes.clear()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	low_material=SpatialMaterial.new()
	low_material.albedo_color=Color(.22,.23,.23)
	low_material.roughness=1
	high_material=SpatialMaterial.new()
	high_material.albedo_texture=load("res://assets/textures/asphalt.jpg")
	high_material.normal_enabled=true
	high_material.normal_texture=load("res://assets/textures/asphalt_normal.jpg")
	high_material.normal_scale=.5
	high_material.roughness=.93
	high_material.uv1_triplanar=true
	high_material.uv1_scale=Vector3.ONE*.12
	for team in [0,1]:
		var c=center(team)
		var field={"team":team,"z":c.z,"y":c.y,"operational":true}
		fields.append(field)
		var node=Spatial.new()
		add_child(node)
		paved(node,c-Vector3.UP*.06,Vector3(80,.12,3200))
		paved(node,c+Vector3(160,-.06,0),Vector3(32,.12,2800))
		paved(node,c+Vector3(245,-.06,0),Vector3(180,.12,920))
		for end in [-1100,1100]:
			paved(node,c+Vector3(80,-.06,end),Vector3(160,.12,34))
		var builder=preload("res://scripts/AircraftModel.gd").new()
		for i in range(64):
			builder.box(c+Vector3(0,.025,(i-32)*48),Vector3(1.1,.03,24),Color(.87,.86,.75))
		for side in [-1,1]:
			builder.box(c+Vector3(side*38,.025,0),Vector3(.4,.03,3180),Color(.87,.86,.75))
			for i in range(5):
				for end in [-1,1]:
					builder.box(c+Vector3(side*(5+i*5),.03,end*1530),Vector3(2,.03,42),Color(.89,.88,.78))
		builder.box(c+Vector3(160,.025,0),Vector3(.5,.03,2770),Color(.92,.75,.18))
		for end in [-1100,1100]:
			builder.box(c+Vector3(80,.025,end),Vector3(150,.03,.5),Color(.92,.75,.18))
		var marking=builder.finish_mesh()
		node.add_child(marking)
		builder.free()
		for i in range(5):
			create_target(field,"hangar",c+Vector3(355,0,(i-2)*115))
		create_target(field,"tower",c+Vector3(-155,0,260))
		for end in [-1050,0,1050]:
			create_target(field,"runway",c+Vector3(0,0,end))
		for i in range(4):
			var p=c+Vector3(85,0,(i-2)*65)
			var detailed=load("res://assets/external/barrier/concrete_road_barrier_2k.gltf").instance()
			detailed.translation=p
			detailed.scale=Vector3.ONE*2.0
			node.add_child(detailed)
			var simple=MeshInstance.new()
			var shape=CubeMesh.new()
			shape.size=Vector3(3,1.6,.9)
			simple.mesh=shape
			simple.translation=p+Vector3.UP*.8
			var mat=SpatialMaterial.new()
			mat.albedo_color=Color(.46,.45,.4)
			shape.material=mat
			node.add_child(simple)
			detail_nodes.append({"high":detailed,"low":simple,"p":p})
	set_quality(game.graphics.preset)
	show()
func set_quality(value):
	quality=value
	for base in get_children():
		for child in base.get_children():
			if child.has_meta("runway"):
				child.material_override=high_material if value>0 else low_material
func _process(dt):
	if game==null:return
	timer-=dt
	if timer>0:return
	timer=.3
	for item in detail_nodes:
		var distance=item.p.distance_to(game.camera.translation)
		item.high.visible=quality==2 and distance<180
		item.low.visible=not item.high.visible and distance<2200
