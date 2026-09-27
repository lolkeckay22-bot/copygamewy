extends Spatial
# Shared low-resolution procedural cloud mask; 14 camera-facing quads, no particles.
func build():
	var img=Image.new();img.create(64,32,false,Image.FORMAT_RGBA8);img.lock()
	for y in range(32):
		for x in range(64):
			var p=Vector2((x-32)/32.0,(y-16)/16.0)
			var opacity=0.0
			for c in [Vector3(-.45,.1,.45),Vector3(-.14,-.12,.56),Vector3(.2,.06,.48),Vector3(.5,.1,.31)]:
				var dist=Vector2(p.x-c.x,(p.y-c.y)*.9).length()/c.z
				opacity=max(opacity,clamp((1.0-dist)*2.0,0,1))
			img.set_pixel(x,y,Color(.91,.94,.93,opacity*.63))
	img.unlock()
	var tex=ImageTexture.new();tex.create_from_image(img,Texture.FLAG_FILTER)
	var mat=SpatialMaterial.new();mat.albedo_texture=tex;mat.flags_transparent=true;mat.flags_unshaded=true;mat.params_billboard_mode=SpatialMaterial.BILLBOARD_ENABLED;mat.params_cull_mode=SpatialMaterial.CULL_DISABLED
	var mesh=QuadMesh.new();mesh.size=Vector2(900,300);mesh.material=mat
	for i in range(14):
		var m=MeshInstance.new();m.mesh=mesh;m.cast_shadow=GeometryInstance.SHADOW_CASTING_SETTING_OFF
		m.translation=Vector3(sin(i*2.7)*5400,2500+sin(i*4.1)*500,cos(i*2.7)*5400);add_child(m)
