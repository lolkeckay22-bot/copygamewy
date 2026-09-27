extends SceneTree
func _init():
	for kind in ["su27","biplane"]:
		var model=preload("res://scripts/AircraftModel.gd").new();model.build(kind)
		var mesh=model.detailed.mesh
		var arr=mesh.surface_get_arrays(0)
		var points=[];var colors=[]
		for p in arr[Mesh.ARRAY_VERTEX]:points.append([p.x,p.y,p.z])
		for c in arr[Mesh.ARRAY_COLOR]:colors.append([c.r,c.g,c.b,c.a])
		var f=File.new();f.open("res://../tools/"+kind+".json",File.WRITE);f.store_string(JSON.print({"vertices":points,"colors":colors}));f.close();model.free()
	quit()
