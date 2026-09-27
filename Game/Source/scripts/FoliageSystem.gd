extends Spatial
var game
var chunks=[]
var clock=0.0
var quality=0
func build(owner):
	game=owner
	var bark=SpatialMaterial.new();bark.albedo_texture=load("res://assets/textures/bark.jpg");bark.roughness=1
	var leaf=SpatialMaterial.new();leaf.albedo_texture=load("res://assets/textures/foliage.png");leaf.params_use_alpha_scissor=true;leaf.params_alpha_scissor_threshold=.4;leaf.params_cull_mode=SpatialMaterial.CULL_DISABLED;leaf.roughness=1
	var tree=ArrayMesh.new()
	var trunk=CylinderMesh.new();trunk.top_radius=.12;trunk.bottom_radius=.65;trunk.height=17;trunk.radial_segments=8;trunk.rings=1
	var arrays=trunk.surface_get_arrays(0)
	var verts=arrays[Mesh.ARRAY_VERTEX]
	for i in range(verts.size()):verts[i].y+=8.5
	arrays[Mesh.ARRAY_VERTEX]=verts;tree.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);tree.surface_set_material(0,bark)
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for layer in range(7):
		var h=5.0+layer*1.65;var length=4.3-layer*.46
		for branch in range(5):
			var a=branch*TAU/5+layer*.7
			var right=Vector3(cos(a),0,sin(a));var side=Vector3(-sin(a),.32,cos(a))
			var center=Vector3(0,h,0)+right*length*.5
			var p=[center-right*length*.55-side*length*.42,center+right*length*.55-side*length*.42,center+right*length*.55+side*length*.42,center-right*length*.55+side*length*.42]
			for i in [0,1,2,0,2,3]:
				st.add_uv([Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)][i]);st.add_vertex(p[i])
	st.generate_normals();st.set_material(leaf);st.commit(tree)
	var low=CylinderMesh.new();low.bottom_radius=3.6;low.top_radius=.1;low.height=15;low.radial_segments=6;low.rings=1
	var lm=SpatialMaterial.new();lm.albedo_color=Color(.13,.23,.12);low.material=lm
	var rng=RandomNumberGenerator.new();rng.seed=91724
	for x in range(-5,6):
		for z in range(-5,6):
			var node=Spatial.new();node.translation=Vector3(x*1200,0,z*1200);add_child(node)
			var hi=MultiMesh.new();hi.transform_format=MultiMesh.TRANSFORM_3D;hi.mesh=tree;hi.instance_count=40
			var lo=MultiMesh.new();lo.transform_format=MultiMesh.TRANSFORM_3D;lo.mesh=low;lo.instance_count=40
			for i in range(40):
				var p=Vector3(rng.randf_range(-550,550),0,rng.randf_range(-550,550));p.y=game.terrain.height_at(p.x+node.translation.x,p.z+node.translation.z)
				if game.terrain.airfield_clear(p.x+node.translation.x,p.z+node.translation.z):p.x+=700
				p.y=game.terrain.height_at(p.x+node.translation.x,p.z+node.translation.z)
				var scale_factor=rng.randf_range(.7,1.4);var b=Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3.ONE*scale_factor)
				hi.set_instance_transform(i,Transform(b,p));lo.set_instance_transform(i,Transform(b,p+Vector3.UP*7.5*scale_factor))
			var hn=MultiMeshInstance.new();hn.multimesh=hi;node.add_child(hn)
			var ln=MultiMeshInstance.new();ln.multimesh=lo;node.add_child(ln)
			chunks.append({"node":node,"high":hn,"low":ln});node.hide()
func _process(dt):
	clock-=dt
	if clock>0:return
	clock=.4
	for c in chunks:
		var distance=Vector2(c.node.translation.x-game.camera.translation.x,c.node.translation.z-game.camera.translation.z).length()
		c.node.visible=game.mode!="hangar" and distance<([1600,2600,3600][quality])
		c.high.visible=quality>0 and distance<([0,1200,2300][quality])
		c.low.visible=not c.high.visible
		c.low.multimesh.visible_instance_count=[12,24,40][quality]
