extends Spatial
var combat=preload("res://scripts/CombatDirector.gd").new()
var database=preload("res://scripts/AircraftDatabase.gd").new()
var graphics=preload("res://scripts/GraphicsSettings.gd").new()
var controller=preload("res://scripts/CameraController.gd").new()
var targeting=preload("res://scripts/TargetingSystem.gd").new()
var match_state=preload("res://scripts/GameMode.gd").new()
var aircraft=[]
var player
var world_view
var world
var camera
var sun
var terrain
var missiles
var effects
var foliage
var ground_units=[]
var service_bases
var environment
var clouds
var hangar
var projectiles
var audio
var hud
var texture
var mode="hangar"
var selected=1
var difficulty=1
var paused=false
var settings_open=false
var hit_marker=0.0
var notification=""
var notification_time=0.0
var explosions=[]
var ground_losses=0
var test_runner
func is_in_flight():
	return mode=="battle" or mode=="freeflight"
func _ready():
	combat.game=self
	world_view=Viewport.new();world_view.name="WorldViewport";world_view.size=Vector2(1280,720)
	world_view.render_target_v_flip=true;world_view.own_world=true;world_view.render_target_update_mode=Viewport.UPDATE_ALWAYS;add_child(world_view)
	world=Spatial.new();world_view.add_child(world)
	texture=TextureRect.new();texture.texture=world_view.get_texture();texture.expand=true;texture.rect_size=get_viewport().size
	texture.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(texture)
	camera=Camera.new();camera.near=.4;camera.far=12000;camera.fov=65;world.add_child(camera);camera.current=true
	var env=WorldEnvironment.new();environment=Environment.new()
	environment.background_mode=Environment.BG_SKY
	var sky=ProceduralSky.new();sky.sky_top_color=Color(.16,.32,.48);sky.sky_horizon_color=Color(.66,.75,.76);sky.ground_horizon_color=Color(.66,.75,.76);sky.ground_bottom_color=Color(.28,.32,.26);sky.sun_latitude=36;sky.sun_longitude=-35
	environment.background_sky=sky;environment.ambient_light_color=Color(.72,.81,.85);environment.ambient_light_energy=.65
	environment.fog_enabled=true;environment.fog_color=Color(.6,.7,.73);environment.fog_depth_begin=3500;environment.fog_depth_end=12000
	env.environment=environment;world.add_child(env)
	sun=DirectionalLight.new();sun.rotation_degrees=Vector3(-38,-35,0);sun.light_color=Color(1,.91,.78);sun.light_energy=1.05;world.add_child(sun)
	sun.directional_shadow_max_distance=130
	clouds=preload("res://scripts/CloudLayer.gd").new();world.add_child(clouds);clouds.build();clouds.hide()
	terrain=preload("res://scripts/Terrain.gd").new();world.add_child(terrain);terrain.build();terrain.hide()
	service_bases=preload("res://scripts/ServiceBases.gd").new();service_bases.game=self;world.add_child(service_bases);service_bases.hide()
	foliage=preload("res://scripts/FoliageSystem.gd").new();world.add_child(foliage);foliage.build(self)
	effects=preload("res://scripts/CombatEffects.gd").new();effects.game=self;world.add_child(effects)
	missiles=preload("res://scripts/MissileSystem.gd").new();missiles.game=self;world.add_child(missiles)
	hangar=preload("res://scripts/Hangar.gd").new();world.add_child(hangar);hangar.build()
	projectiles=preload("res://scripts/ProjectilePool.gd").new();projectiles.game=self;world.add_child(projectiles)
	audio=preload("res://scripts/AudioManager.gd").new();add_child(audio)
	audio.pause_mode=Node.PAUSE_MODE_PROCESS
	hud=preload("res://scripts/HUD.gd").new();hud.game=self;hud.rect_size=get_viewport().size;add_child(hud)
	hud.pause_mode=Node.PAUSE_MODE_PROCESS
	pause_mode=Node.PAUSE_MODE_PROCESS
	get_viewport().connect("size_changed",self,"window_changed")
	initialize_effect_pool()
	graphics.apply(self);select_aircraft(selected)
	camera.translation=Vector3(24,11,29)
	print("SKY FRONT READY | GLES2 | Windows-compatible release")
	if "--performance-test" in OS.get_cmdline_args():
		test_runner=preload("res://scripts/PerformanceTests.gd").new();test_runner.game=self;add_child(test_runner)
	if "--comfort-test" in OS.get_cmdline_args():
		test_runner=preload("res://scripts/ComfortTests.gd").new();test_runner.game=self;add_child(test_runner)
	if "--landing-test" in OS.get_cmdline_args():
		test_runner=preload("res://scripts/LandingTests.gd").new();test_runner.game=self;add_child(test_runner)
	if "--gameplay-test" in OS.get_cmdline_args():
		test_runner=preload("res://scripts/GameplayTests.gd").new();test_runner.game=self;add_child(test_runner)
	if "--expansion-test" in OS.get_cmdline_args():
		test_runner=preload("res://scripts/ExpansionTests.gd").new();test_runner.game=self;add_child(test_runner)
	if "--diagnostics" in OS.get_cmdline_args():
		test_runner=preload("res://scripts/Diagnostics.gd").new();test_runner.game=self;add_child(test_runner)
	if "--smoke-test" in OS.get_cmdline_args() or "--flight-test" in OS.get_cmdline_args():
		test_runner=preload("res://scripts/TestRunner.gd").new();test_runner.game=self;add_child(test_runner)
func window_changed():
	texture.rect_size=get_viewport().size;hud.rect_size=get_viewport().size
	world_view.size=get_viewport().size*graphics.render_scale
func select_aircraft(index):
	selected=index;hangar.select_aircraft(database.get_aircraft(index));hangar.model.set_quality(graphics.preset);controller.distance=36 if index==1 else 22
func clear_transient_refs():
	combat.reset()
	missiles.clear()
	effects.clear()
	for s in projectiles.slots:
		s.life=0
		s.owner=null
func show_hangar():
	paused=false;settings_open=false;get_tree().paused=false
	mode="hangar";Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	clear_transient_refs()
	for g in ground_units:
		if is_instance_valid(g):
			g.queue_free()
	ground_units.clear()
	for a in aircraft:
		if is_instance_valid(a):
			detach_missiles_from(a)
			a.queue_free()
	aircraft.clear();player=null
	terrain.hide();clouds.hide();service_bases.hide();hangar.show();select_aircraft(selected)
	camera.translation=Vector3(24,11,29)
func start_battle():
	combat.reset()
	for shot in projectiles.slots:
		shot.life=0
		shot.owner=null
	ground_losses=0
	mode="battle";paused=false;settings_open=false;hangar.hide();terrain.show();clouds.show();match_state.reset()
	missiles.clear();effects.clear()
	for g in ground_units:
		if is_instance_valid(g):
			g.queue_free()
	ground_units.clear()
	for a in aircraft:
		if is_instance_valid(a):
			a.queue_free()
	aircraft.clear()
	for i in range(12):
		var a=preload("res://scripts/Aircraft.gd").new()
		a.setup(database.get_aircraft(selected),self,0 if i<6 else 1,i==0)
		world.add_child(a);aircraft.append(a);spawn_at(a,i%6)
		if i==0:player=a
	for i in range(12):
		var unit=preload("res://scripts/GroundVehicle.gd").new();world.add_child(unit)
		unit.translation=Vector3((i%3-1)*850,0,(700+(i%6)*170)*(1 if i<6 else -1))
		unit.build(self,0 if i<6 else 1,i%3==0);ground_units.append(unit)
	service_bases.build(self)
	controller.reset(player)
	camera.translation=player.translation+Vector3(0,5,controller.distance)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	notification="TEAM AIR BATTLE — FIRST TO 20";notification_time=5
	print("BATTLE START | aircraft=",aircraft.size()," selected=",selected)
func start_freeflight():
	combat.reset()
	match_state.reset()
	for shot in projectiles.slots:
		shot.life=0
		shot.owner=null
	ground_losses=0
	mode="freeflight";paused=false;settings_open=false;hangar.hide();terrain.show();clouds.show()
	missiles.clear();effects.clear()
	for g in ground_units:
		if is_instance_valid(g):
			g.queue_free()
	ground_units.clear()
	for a in aircraft:
		if is_instance_valid(a):
			a.queue_free()
	aircraft.clear()
	var a=preload("res://scripts/Aircraft.gd").new()
	a.setup(database.get_aircraft(selected),self,0,true)
	world.add_child(a);aircraft.append(a);player=a
	spawn_at_freeflight(a)
	service_bases.build(self)
	controller.reset(player)
	camera.translation=player.translation+Vector3(0,5,controller.distance)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	notification="FREE FLIGHT — NO ENEMIES, LAND ON RUNWAY TO REPAIR";notification_time=6
	print("FREEFLIGHT START | selected=",selected)
func spawn_at_freeflight(a):
	var speed=175.0 if a.data.id=="su27" else 47.0
	a.translation=Vector3(0,900,2400)
	a.rotation=Vector3(0,0,0)
	a.linear_velocity=Vector3(0,0,-speed);a.angular_velocity=Vector3.ZERO
	a.direction=Vector3(0,0,-1)
	a.ai.direction=a.direction
func spawn_at(a,slot):
	var speed=175.0 if a.data.id=="su27" else 47.0
	var z=(2400 if a.data.id=="su27" else 1300)*(1 if a.team==0 else -1)
	a.translation=Vector3((slot-2)*180,850+(slot%3)*70,z+slot*70)
	a.rotation=Vector3(0,0 if a.team==0 else PI,0)
	a.linear_velocity=Vector3(0,0,-speed if a.team==0 else speed);a.angular_velocity=Vector3.ZERO
	a.direction=Vector3(0,0,-1 if a.team==0 else 1)
	a.ai.direction=a.direction
func detach_missiles_from(a):
	for m in missiles.slots:
		if m.owner==a:
			m.owner=null
		if m.target==a:
			m.target=null
			m.lost=99.0
func respawn(a):
	if a==null or not is_instance_valid(a):
		return
	if not a.dead:return
	a.dead=false;a.death_time=0;a.flight.fuel=1.0;a.flight_controls.flaps=0;a.airbrake=false;a.landing.grounded=false;a.landing.configure(a);a.damage=preload("res://scripts/DamageModel.gd").new()
	a.weapons.ammo=int(a.data.ammo);a.model.show();a.model.reset_damage_visual();a.throttle=.85;a.last_attacker=null
	a.ai.target=null;a.ai.break_until=0.0;a.ai.landing_approach.phase=""
	a.weapons.reset_stores(a)
	detach_missiles_from(a)
	combat.on_respawn(a)
	if mode=="freeflight":
		spawn_at_freeflight(a)
	else:
		spawn_at(a,randi()%6)
	if a.player:
		controller.reset(a);Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("RESPAWN ",a.team," mode=",mode)
func aircraft_destroyed(a):
	detach_missiles_from(a)
	if mode=="freeflight":
		audio.play("explosion")
		spawn_explosion(a.translation)
		if a.player:Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		print("FREEFLIGHT LOSS")
		return
	match_state.kill(a.team)
	combat.destroyed(a,a.last_attacker)
	audio.play("explosion")
	spawn_explosion(a.translation)
	if a.player:Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	print("KILL | score=",match_state.scores)
	if match_state.winner>=0:
		mode="results";Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);print("MATCH COMPLETE | winner=",match_state.winner)
func initialize_effect_pool():
	var shared_mesh=SphereMesh.new();shared_mesh.radial_segments=8;shared_mesh.rings=4
	var shared_mat=SpatialMaterial.new();shared_mat.flags_unshaded=true;shared_mat.albedo_color=Color(1,.46,.1)
	shared_mesh.material=shared_mat
	for i in range(12):
		var node=MeshInstance.new()
		node.mesh=shared_mesh;world.add_child(node);node.hide()
		explosions.append({"node":node,"life":-1.0})
func spawn_explosion(pos):
	effects.burst(pos)
	for e in explosions:
		if e.life<0:
			e.life=0.0;e.node.translation=pos;e.node.scale=Vector3.ONE*3;e.node.show();return
func toggle_pause():
	if not is_in_flight():
		return
	paused=not paused;get_tree().paused=paused
	pause_mode=Node.PAUSE_MODE_PROCESS
	if paused and audio!=null:
		audio.update(null,false)
	for a in aircraft:
		if is_instance_valid(a):
			a.pause_mode=Node.PAUSE_MODE_STOP
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED)
func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if is_in_flight() and player!=null and not player.dead and not paused:
			if event.is_action_pressed("missile"):player.weapons.fire_missile(player)
			if event.is_action_pressed("cycle_missile"):player.weapons.cycle_missile()
			if event.is_action_pressed("flare"):missiles.release_flares(player)
			if event.is_action_pressed("smoke"):player.weapons.smoke=not player.weapons.smoke
			if event.is_action_pressed("smoke_color"):player.weapons.smoke_color=(player.weapons.smoke_color+1)%7
			if event.is_action_pressed("target"):combat.select_target(false)
			if event.is_action_pressed("ground_target"):combat.select_target(true)
			if event.is_action_pressed("gear"):player.landing.toggle(player)
			if event.is_action_pressed("flaps"):player.flight_controls.cycle(player)
		if event.scancode==KEY_F11:OS.window_fullscreen=not OS.window_fullscreen
		if event.scancode==KEY_ESCAPE:
			if settings_open:settings_open=false
			elif is_in_flight():toggle_pause()
		if event.is_action_pressed("respawn") and is_in_flight() and not paused and player!=null and is_instance_valid(player) and player.dead:respawn(player)
	if not paused and not settings_open:
		controller.mouse(event,mode=="hangar",Input.is_action_pressed("free_look") or Input.is_action_pressed("target_view"),graphics.sensitivity,graphics.invert_y)
func _process(dt):
	if paused:return
	hit_marker=max(0,hit_marker-dt);notification_time=max(0,notification_time-dt)
	controller.update(camera,player,dt,mode=="hangar")
	audio.update(player,is_in_flight())
	if mode=="battle":
		match_state.elapsed+=dt
		combat.update(dt)
		if match_state.elapsed>=match_state.time_limit:
			match_state.winner=0 if match_state.scores[0]>match_state.scores[1] else 1
			if match_state.scores[0]==match_state.scores[1]:match_state.winner=2
			mode="results";Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			print("MATCH TIME LIMIT | scores=",match_state.scores)
	elif mode=="freeflight":
		combat.update(dt)
	if is_in_flight() and player!=null and is_instance_valid(player) and not player.dead:
		player.airbrake=Input.is_action_pressed("airbrake")
		player.landing.brake=player.airbrake
		player.throttle=clamp(player.throttle+(Input.get_action_strength("throttle_up")-Input.get_action_strength("throttle_down"))*dt*.35,0,1)
		player.manual_roll=Input.get_action_strength("roll_right")-Input.get_action_strength("roll_left")
		player.manual_yaw=Input.get_action_strength("rudder_left")-Input.get_action_strength("rudder_right")
		player.shoot=Input.is_action_pressed("fire") or Input.is_mouse_button_pressed(BUTTON_LEFT)
		if mode=="battle" and Vector2(player.translation.x,player.translation.z).length()>7100:
			var home=(Vector3(0,max(player.translation.y,1100),0)-player.translation).normalized()
			player.direction=home
			controller.yaw=atan2(-home.x,-home.z)
			controller.pitch=asin(home.y)
			notification="MISSION BOUNDARY — RETURNING";notification_time=1
	for e in explosions:
		if e.life<0:continue
		e.life+=dt;e.node.scale=Vector3.ONE*(3+e.life*12)
		if e.life>1.6:
			e.node.hide()
			e.life=-1
func check_victory():
	if match_state.winner>=0 and mode=="battle":
		mode="results"
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
