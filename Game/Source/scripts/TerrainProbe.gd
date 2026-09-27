extends SceneTree
func _init():
	var terrain=load("res://scripts/Terrain.gd").new()
	get_root().add_child(terrain)
	terrain.build()
	var arr=terrain.ground_mesh.mesh.surface_get_arrays(0)
	print("TERRAIN normal ",arr[Mesh.ARRAY_NORMAL][0]," vertices ",arr[Mesh.ARRAY_VERTEX].size())
	quit()
