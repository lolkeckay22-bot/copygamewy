extends SceneTree
func _init():
	for id in ["su27","r73","r27r"]:
		var f=File.new();f.open("res://assets/models/"+id+".json",File.READ);var data=parse_json(f.get_as_text());f.close()
		for gear in [false,true]:
			if id!="su27" and gear:continue
			var mesh=ArrayMesh.new()
			for part in data.surfaces:
				if part.gear and not gear:continue
				var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.add_smooth_group(true)
				for i in range(part.vertices.size()/3):
					st.add_uv(Vector2(part.uv[i*2],part.uv[i*2+1]))
					st.add_vertex(Vector3(part.vertices[i*3],part.vertices[i*3+1],part.vertices[i*3+2]))
				st.generate_normals();st.generate_tangents()
				var mat=SpatialMaterial.new();mat.params_cull_mode=SpatialMaterial.CULL_DISABLED
				mat.albedo_color=Color(part.color[0],part.color[1],part.color[2],part.alpha)
				mat.metallic=0.28;mat.roughness=0.48
				if part.texture!="":
					mat.albedo_texture=load("res://"+part.texture.trim_prefix("source/"))
				if "Glass" in part.texture:
					mat.albedo_color=Color(.16,.30,.37,.65);mat.flags_transparent=true;mat.metallic=.5;mat.roughness=.13
				st.set_material(mat);st.commit(mesh)
			ResourceSaver.save("res://assets/models/"+id+("_gear" if gear else "")+".res",mesh)
			print("BAKED ",id," gear=",gear," surfaces=",mesh.get_surface_count())
	quit()
