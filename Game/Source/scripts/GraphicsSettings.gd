extends Reference
var preset=0
var render_scale=1.0
var shadows=false
var draw_distance=6000.0
var effects=0
var aa=0
var vsync=true
var fps_limit=60
var texture_quality=0
var sensitivity=1.0
var invert_y=false
var show_fps=false
var resolution=Vector2(1280,720)
var keys={"throttle_up":KEY_W,"throttle_down":KEY_S,"pitch_up":KEY_UP,"pitch_down":KEY_DOWN,"roll_left":KEY_A,"roll_right":KEY_D,"rudder_left":KEY_Q,"rudder_right":KEY_E,"fire":KEY_SPACE,"free_look":KEY_C,"respawn":KEY_R,"missile":KEY_V,"cycle_missile":KEY_X,"target":KEY_T,"flare":KEY_F,"smoke":KEY_J,"smoke_color":KEY_K,"airbrake":KEY_B,"ground_target":KEY_H,"gear":KEY_G,"flaps":KEY_Z,"target_view":KEY_ALT}
func _init():
	set_preset(0)
	var cfg=ConfigFile.new()
	if cfg.load("user://settings.cfg")==OK:
		preset=clamp(int(cfg.get_value("video","preset",0)),0,2)
		set_preset(preset)
		for property in ["render_scale","shadows","draw_distance","effects","aa","vsync","fps_limit","texture_quality","resolution"]:
			set(property,cfg.get_value("video",property,get(property)))
		render_scale=clamp(float(render_scale),0.5,1.0)
		effects=clamp(int(effects),0,2)
		aa=clamp(int(aa),0,2)
		texture_quality=clamp(int(texture_quality),0,2)
		draw_distance=clamp(float(draw_distance),2000.0,18000.0)
		for action in keys:
			keys[action]=cfg.get_value("keys",action,keys[action])
		sensitivity=clamp(cfg.get_value("controls","sensitivity",1.0),.25,2.0)
		invert_y=cfg.get_value("controls","invert_y",false)
		show_fps=cfg.get_value("interface","show_fps",false)
		if cfg.get_value("controls","bindings_version",0)<2 and keys.gear==KEY_H and keys.ground_target==KEY_G:
			keys.gear=KEY_G;keys.ground_target=KEY_H
		if cfg.get_value("video","performance_version",0)<1 and preset==0:
			render_scale=.75;aa=0;shadows=false
	bind_keys()
func bind_keys():
	if not InputMap.has_action("precision_zoom"):InputMap.add_action("precision_zoom")
	InputMap.action_erase_events("precision_zoom")
	var zoom_button=InputEventMouseButton.new()
	zoom_button.button_index=BUTTON_RIGHT
	InputMap.action_add_event("precision_zoom",zoom_button)
	for action in keys:
		if not InputMap.has_action(action):InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var key=InputEventKey.new();key.scancode=int(keys[action]);InputMap.action_add_event(action,key)
	for pair in [["throttle_up",KEY_SHIFT],["throttle_down",KEY_CONTROL]]:
		var key=InputEventKey.new();key.scancode=pair[1];InputMap.action_add_event(pair[0],key)
func set_preset(p):
	preset=p
	render_scale=.75 if p==0 else 1.0
	shadows=p>0;draw_distance=[6000.0,9000.0,12000.0][p]
	effects=p;aa=[0,1,2][p];texture_quality=p
func apply(game):
	OS.vsync_enabled=vsync
	Engine.target_fps=fps_limit
	OS.window_size=resolution
	game.world_view.size=resolution*render_scale
	game.world_view.msaa=aa
	game.camera.far=18000
	game.world_view.shadow_atlas_size=0 if not shadows else 1024
	game.sun.shadow_enabled=shadows
	game.terrain.buildings.visible_instance_count=[35,65,100][texture_quality]
	game.terrain.high_material.set_shader_param("forest_tex",load("res://assets/textures/ground.jpg" if texture_quality==2 else "res://assets/textures/ground_medium.jpg"))
	game.terrain.high_material.set_shader_param("detailed_normals",texture_quality==2)
	game.service_bases.set_quality(preset)
	game.terrain.set_quality(min(preset,texture_quality));game.foliage.quality=preset
	for a in game.aircraft:a.model.set_quality(preset)
	if game.hangar.model:game.hangar.model.set_quality(preset)
	game.sun.directional_shadow_max_distance=[130,250,650][preset]
	game.environment.ambient_light_energy=[.65,.55,.48][preset]
	save()
func save():
	var cfg=ConfigFile.new()
	for p in ["preset","render_scale","shadows","draw_distance","effects","aa","vsync","fps_limit","texture_quality","resolution"]:
		cfg.set_value("video",p,get(p))
	for action in keys:cfg.set_value("keys",action,keys[action])
	cfg.set_value("controls","sensitivity",sensitivity)
	cfg.set_value("controls","invert_y",invert_y)
	cfg.set_value("interface","show_fps",show_fps)
	cfg.set_value("controls","bindings_version",2)
	cfg.set_value("video","performance_version",1)
	cfg.save("user://settings.cfg")
