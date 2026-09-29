extends Spatial
var model
func cube(pos,size,col):
	var m=MeshInstance.new();var mesh=CubeMesh.new();mesh.size=size
	var mat=SpatialMaterial.new();mat.albedo_color=col;mat.roughness=.9;mesh.material=mat;m.mesh=mesh;m.translation=pos;add_child(m)
func build():
	cube(Vector3(0,-1,0),Vector3(160,1,160),Color(.16,.19,.2))
	cube(Vector3(0,0,0),Vector3(27,.12,28),Color(.23,.27,.28))
	for x in [-25,25]:
		cube(Vector3(x,8,0),Vector3(.5,18,65),Color(.11,.15,.17))
		for z in range(-30,31,10):
			cube(Vector3(x*.96,7,z),Vector3(.7,16,.7),Color(.26,.30,.31))
	cube(Vector3(0,9,25),Vector3(50,19,.6),Color(.12,.16,.18))
	for x in range(-20,21,10):
		cube(Vector3(x,8,24.5),Vector3(.55,18,.6),Color(.24,.28,.3))
	# Floor guide lines and restrained warm service lighting.
	for x in [-12,12]:cube(Vector3(x,.07,0),Vector3(.10,.025,28),Color(.81,.51,.20))
	for z in [-14,14]:cube(Vector3(0,.07,z),Vector3(24,.025,.10),Color(.81,.51,.20))
	for x in [-18,18]:
		for z in [-18,-6,6,18]:
			cube(Vector3(x,.04,z),Vector3(3,.08,.14),Color(.65,.71,.69))
	for i in range(7):cube(Vector3(-19+i*.9,.5,18),Vector3(.7,1,.7),Color(.25,.29,.22))
func select_aircraft(data, skin="ukrainian"):
	if model!=null and is_instance_valid(model):
		model.queue_free()
		model=null
	var camo_tex = "res://assets/textures/su27_uacamo.png" if skin == "ukrainian" or skin == "camo" else null
	model=preload("res://scripts/AircraftModel.gd").new();model.build(data.id,0,true,camo_tex)
	model.translation.y=2.0 if data.id=="su27" else 1.8
	add_child(model)
