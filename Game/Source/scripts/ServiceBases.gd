extends Spatial
var game
var fields=[]
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
		if abs(p.x)<110 and abs(p.z-field.z)<1200:return field
	return null
func build(owner):
	game=owner;fields.clear();detail_nodes.clear()
	for child in get_children():
		remove_child(child);child.queue_free()
	low_material=SpatialMaterial.new();low_material.albedo_color=Color(.22,.23,.23);low_material.roughness=1
	high_material=SpatialMaterial.new();high_material.albedo_texture=load("res://assets/textures/asphalt.jpg");high_material.normal_enabled=true;high_material.normal_texture=load("res://assets/textures/asphalt_normal.jpg");high_material.normal_scale=.5;high_material.roughness=.93
	high_material.uv1_triplanar=true;high_material.uv1_scale=Vector3.ONE*.12
	for team in [0,1]:
		var c=center(team);fields.append({"team":team,"z":c.z,"y":c.y})
		var node=Spatial.new();add_child(node)
		var strip=MeshInstance.new();var mesh=CubeMesh.new();mesh.size=Vector3(70,.12,2400);strip.mesh=mesh;strip.translation=c-Vector3.UP*.06;node.add_child(strip)
		strip.set_meta("runway",true)
		var builder=preload("res://scripts/AircraftModel.gd").new()
		for i in range(48):
			builder.box(c+Vector3(0,.025,(i-24)*48),Vector3(1.1,.03,24),Color(.87,.86,.75))
		for side in [-1,1]:
			builder.box(c+Vector3(side*33,.025,0),Vector3(.4,.03,2390),Color(.87,.86,.75))
			for i in range(5):
				for end in [-1,1]:builder.box(c+Vector3(side*(5+i*4),.03,end*1130),Vector3(2,.03,42),Color(.89,.88,.78))
		for i in range(4):
			var p=c+Vector3(145,0,(i-2)*90)
			builder.box(p+Vector3.UP*10,Vector3(45,20,64),Color(.31,.34,.32))
			builder.box(p+Vector3(-22.6,7,0),Vector3(.25,13,40),Color(.1,.13,.14))
			builder.box(p+Vector3.UP*20.4,Vector3(47,.8,66),Color(.42,.44,.42))
			for rib in range(9):builder.box(p+Vector3(-22.85,7,(rib-4)*4),Vector3(.2,13,.13),Color(.4,.42,.4))
		var tower=c+Vector3(-130,0,250)
		builder.box(tower+Vector3.UP*12,Vector3(12,24,12),Color(.42,.42,.38))
		builder.box(tower+Vector3.UP*26,Vector3(20,6,20),Color(.14,.24,.27))
		builder.box(tower+Vector3.UP*30,Vector3(22,1,22),Color(.55,.55,.51))
		node.add_child(builder.finish_mesh());builder.free()
		for i in range(4):
			var p=c+Vector3(85,0,(i-2)*65)
			var detailed=load("res://assets/external/barrier/concrete_road_barrier_2k.gltf").instance()
			detailed.translation=p;detailed.scale=Vector3.ONE*2.0;node.add_child(detailed)
			var simple=MeshInstance.new();var shape=CubeMesh.new();shape.size=Vector3(3,1.6,.9);simple.mesh=shape;simple.translation=p+Vector3.UP*.8
			var mat=SpatialMaterial.new();mat.albedo_color=Color(.46,.45,.4);shape.material=mat;node.add_child(simple)
			detail_nodes.append({"high":detailed,"low":simple,"p":p})
	set_quality(game.graphics.preset);show()
func set_quality(value):
	quality=value
	for base in get_children():
		for child in base.get_children():
			if child.has_meta("runway"):child.material_override=high_material if value>0 else low_material
func _process(dt):
	if game==null:return
	timer-=dt
	if timer>0:return
	timer=.3
	for item in detail_nodes:
		var distance=item.p.distance_to(game.camera.translation)
		item.high.visible=quality==2 and distance<180
		item.low.visible=not item.high.visible and distance<2200
