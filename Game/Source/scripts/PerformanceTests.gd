extends Node
var game
var done=false
var failures=0
func check(ok,label):
	print("PERF ","PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func count_nodes(root):
	var total=1
	for child in root.get_children():total+=count_nodes(child)
	return total
func fill(pool):
	for s in pool.slots:
		s.life=3.0;s.p=Vector3(5000,4000,5000);s.v=Vector3(0,0,-800);s.owner=game.player
func _process(_dt):
	if done:return
	done=true
	game.graphics.set_preset(0);game.graphics.apply(game);game.start_battle()
	var arrays=game.terrain.ground_mesh.mesh.surface_get_arrays(0)
	var upward=true
	for n in arrays[Mesh.ARRAY_NORMAL]:
		if n.y<=0:upward=false
	check(upward,"terrain surface faces upward across whole map")
	check(game.camera.far>=15000,"terrain visible to map horizon")
	check(game.world_view.size==game.graphics.resolution*.75,"LOW reduces 3D pixel count, keeps HUD resolution")
	check(not game.sun.shadow_enabled and game.world_view.shadow_atlas_size==0,"LOW disables unused shadow atlas")
	check(game.aircraft.size()==12 and game.ground_units.size()==12,"all air and ground combat units retained")
	game.effects.emit(Vector3.ZERO,Vector3.ZERO,Color.white,1,1)
	check(game.effects.budget==256,"LOW effect budget is bounded")
	var pool=game.projectiles
	fill(pool)
	var start=OS.get_ticks_usec()
	for i in range(100):pool._physics_process(1.0/60)
	var optimized=OS.get_ticks_usec()-start
	check(pool.broadphase_rejects>100000 and pool.narrowphase_checks==0,"distant bullets skip exact collision transforms")
	print("PERF optimized bullet workload us=",optimized)
	if ResourceLoader.exists("res://scripts/LegacyProjectilePool.gd"):
		var legacy=load("res://scripts/LegacyProjectilePool.gd").new()
		legacy.game=game;game.world.add_child(legacy)
		fill(legacy);start=OS.get_ticks_usec()
		for i in range(100):legacy._physics_process(1.0/60)
		var baseline=OS.get_ticks_usec()-start
		print("PERF same workload baseline us=",baseline," optimized us=",optimized," ratio=",float(baseline)/optimized)
		legacy.queue_free()
	game.graphics.set_preset(2);game.graphics.apply(game)
	check(game.terrain.ground_mesh.material_override==game.terrain.high_material,"HIGH terrain material retained")
	game.graphics.set_preset(0);game.graphics.apply(game)
	var effects=game.effects
	effects.clear()
	var idle_start=OS.get_ticks_usec()
	for i in range(1000):effects._process(1.0/60.0)
	print("PERF idle effect workload us=",OS.get_ticks_usec()-idle_start)
	effects.emit(game.player.translation,Vector3.ZERO,Color.white,1,0.1)
	check(effects.active.size()==1,"effect pool tracks live particles")
	for i in range(8):effects._process(1.0/60.0)
	check(effects.active.empty(),"expired effects leave the active set")
	var nodes_before=count_nodes(game.world)
	for i in range(6):
		game.player.die()
		game.respawn(game.player)
	check(count_nodes(game.world)==nodes_before,"six player respawns do not add scene nodes")
	check(game.aircraft.size()==12 and game.ground_units.size()==12,"respawns retain original combat population")
	print("PERF failures=",failures)
	get_tree().quit(1 if failures else 0)
