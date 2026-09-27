extends Spatial
var hangar = false
var ground_mesh
var low_material
var high_material
var base_levels=[]
var buildings
func raw_height(x,z):
	return 22.0 + sin(x*.0007)*cos(z*.0008)*85.0 + sin(x*.0018+z*.001)*28.0
func _init():
	base_levels=[raw_height(0,4000),raw_height(0,-4000)]
func base_height(team):
	return base_levels[team]
func airfield_clear(x,z):
	return abs(x)<300 and abs(abs(z)-4000)<1450
func height_at(x,z):
	var raw=raw_height(x,z)
	if not airfield_clear(x,z):return raw
	var flat=clamp((300.0-abs(x))/100.0,0,1)*clamp((1450.0-abs(abs(z)-4000))/200.0,0,1)
	flat=flat*flat*(3-2*flat)
	return lerp(raw,base_height(0 if z>0 else 1),flat)

func build():
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.add_smooth_group(true)
	var n=150;var step=100.0
	for x in range(n):
		for z in range(n):
			var p=[]
			for v in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
				var px=(x+v.x)*step-7500;var pz=(z+v.y)*step-7500
				p.append(Vector3(px,height_at(px,pz),pz))
			var color=Color(.24,.37,.16).linear_interpolate(Color(.48,.48,.25),clamp((p[0].y+55)/190,0,1))
			color=color.darkened(fmod(sin(x*13.2+z*77.1)*43758.5,1)*.035)
			for i in [0,1,2,0,2,3]:
				st.add_color(color);st.add_uv(Vector2(p[i].x,p[i].z)*.035);st.add_vertex(p[i])
	st.index();st.generate_normals();st.generate_tangents()
	var mat=SpatialMaterial.new();mat.vertex_color_use_as_albedo=true;mat.roughness=1;mat.flags_unshaded=true
	st.set_material(mat)
	var mesh=MeshInstance.new();mesh.mesh=st.commit();add_child(mesh);ground_mesh=mesh;low_material=mat
	high_material=ShaderMaterial.new();high_material.shader=load("res://assets/shaders/terrain.shader")
	high_material.set_shader_param("grass_tex",load("res://assets/textures/grass_rock.jpg"))
	high_material.set_shader_param("forest_tex",load("res://assets/textures/ground.jpg"))
	high_material.set_shader_param("grass_normal",load("res://assets/textures/grass_rock_normal.jpg"))
	high_material.set_shader_param("forest_normal",load("res://assets/textures/ground_normal.jpg"))

	# A single MultiMesh draw call for sparse low-poly scenery.
	var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D
	var cube=CubeMesh.new();cube.size=Vector3(1,1,1)
	var bm=SpatialMaterial.new();bm.albedo_color=Color(.37,.37,.32);cube.material=bm
	mm.mesh=cube;mm.instance_count=100
	for i in range(100):
		var px=sin(i*72.4)*6200;var pz=cos(i*16.8)*6200
		if airfield_clear(px,pz):px+=700
		var h=8+fmod(i*7.3,15)
		mm.set_instance_transform(i,Transform(Basis().scaled(Vector3(15+h,h,12+h)),Vector3(px,height_at(px,pz)+h*.5,pz)))
	var inst=MultiMeshInstance.new();inst.multimesh=mm;add_child(inst)
	buildings=mm

func set_quality(level):
	ground_mesh.material_override=high_material if level>0 else low_material
