extends Control
var combat_hud=preload("res://scripts/CombatHUD.gd").new()
var game
var fonts={}
var buttons=[]
var scale_ui=1.0
var ui_offset=Vector2.ZERO
var settings_tab=0
var waiting_key=""
var ink=Color(.87,.91,.91)
var muted=Color(.49,.61,.65)
var amber=Color(1,.63,.25)
var cyan=Color(.38,.8,.9)
func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	for size in [12,14,16,20,26,38,52]:
		var f=DynamicFont.new();f.font_data=load("res://assets/UI.ttf");f.size=size;fonts[size]=f
func txt(pos,text,size=16,color=Color(.87,.91,.91)):
	draw_string(fonts[size],pos,str(text),color)
func panel(rect,col=Color(.035,.063,.076,.90)):
	draw_rect(rect,col)
func button(rect,title,action,active=false):
	var mouse=(get_global_mouse_position()-ui_offset)/scale_ui
	var hover=rect.has_point(mouse)
	var color=Color(.13,.20,.23,.95) if hover else Color(.07,.11,.135,.95)
	if active:color=Color(.72,.38,.12,.95)
	panel(rect,color)
	draw_rect(Rect2(rect.position,Vector2(3,rect.size.y)),amber if active else muted)
	txt(rect.position+Vector2(16,rect.size.y*.5+6),title,16,ink)
	buttons.append([rect,action])
var redraw_clock=0.0
func _process(dt):
	redraw_clock+=dt
	if redraw_clock>=1.0/30.0:
		redraw_clock=0.0
		update()
func _input(event):
	if waiting_key!="" and event is InputEventKey and event.pressed:
		if event.scancode!=KEY_ESCAPE:
			game.graphics.keys[waiting_key]=event.scancode
			game.graphics.bind_keys();game.graphics.save()
		waiting_key="";get_tree().set_input_as_handled();return
	if event is InputEventMouseButton and event.button_index==BUTTON_LEFT and event.pressed and Input.get_mouse_mode()!=Input.MOUSE_MODE_CAPTURED:
		var p=(event.position-ui_offset)/scale_ui
		for b in buttons:
			if b[0].has_point(p):
				game.audio.play("ui");action(b[1]);get_tree().set_input_as_handled();return
func action(a):
	if a=="fly":game.start_battle()
	elif a=="freeflight":game.start_freeflight()
	elif a=="su27":game.select_aircraft(1)
	elif a=="biplane":game.select_aircraft(0)
	elif a=="settings":game.settings_open=true
	elif a=="close_settings":game.settings_open=false
	elif a=="quit":game.get_tree().quit()
	elif a=="resume":game.toggle_pause()
	elif a=="hangar":game.show_hangar()
	elif a=="respawn":game.respawn(game.player)
	elif a=="difficulty":game.difficulty=(game.difficulty+1)%3
	elif a=="graphics_tab":settings_tab=0
	elif a=="controls_tab":settings_tab=1
	elif a=="sensitivity":
		var values=[.25,.5,.75,1.0,1.25,1.5,2.0]
		game.graphics.sensitivity=values[(values.find(game.graphics.sensitivity)+1)%values.size()]
		game.graphics.save()
	elif a=="invert_y":
		game.graphics.invert_y=not game.graphics.invert_y
		game.graphics.save()
	elif a.begins_with("key:"):waiting_key=a.substr(4)
	else:
		var g=game.graphics
		if a=="preset":g.set_preset((g.preset+1)%3)
		elif a=="show_fps":
			g.show_fps=not g.show_fps
			g.save()
		elif a=="resolution":
			var options=[Vector2(1280,720),Vector2(1600,900),Vector2(1920,1080)]
			g.resolution=options[(options.find(g.resolution)+1)%3]
		elif a=="scale":g.render_scale=0.5 if g.render_scale>=1 else g.render_scale+0.25
		elif a=="shadows":g.shadows=not g.shadows
		elif a=="textures":g.texture_quality=(g.texture_quality+1)%3
		elif a=="distance":g.draw_distance=4000 if g.draw_distance>=12000 else g.draw_distance+2000
		elif a=="effects":g.effects=(g.effects+1)%3
		elif a=="aa":g.aa=(g.aa+1)%3
		elif a=="vsync":g.vsync=not g.vsync
		elif a=="fps":
			var opts=[0,30,60,120];g.fps_limit=opts[(opts.find(g.fps_limit)+1)%4]
		g.apply(game)
func _draw():
	if game==null or fonts.empty():return
	scale_ui=min(rect_size.x/1280.0,rect_size.y/720.0)
	ui_offset=(rect_size-Vector2(1280,720)*scale_ui)*0.5
	draw_set_transform(ui_offset,0,Vector2.ONE*scale_ui)
	buttons.clear()
	if game.mode=="hangar":draw_hangar()
	else:draw_flight()
	if game.settings_open:draw_settings()
func draw_hangar():
	panel(Rect2(0,0,1280,95),Color(.026,.046,.06,.94))
	txt(Vector2(38,46),"SKY FRONT",38)
	txt(Vector2(40,73),"AIR COMBAT   /   PERFORMANCE FIX 0.6",12,muted)
	button(Rect2(938,25,162,44),"SETTINGS","settings")
	button(Rect2(1115,25,125,44),"EXIT","quit")
	txt(Vector2(41,140),"FLIGHT LINE  /  02 AIRCRAFT",14,muted)
	var d=game.database.get_aircraft(game.selected)
	panel(Rect2(38,165,305,304))
	draw_rect(Rect2(38,165,305,3),amber)
	txt(Vector2(60,208),d.name,26)
	txt(Vector2(60,237),"AIRCRAFT SPECIFICATION",12,muted)
	var specs=[["TOP @ ALT",str(int(d.max_speed*3.6))+" km/h"],["MASS",str(int(d.mass))+" kg"],["G LIMIT",str(int(d.max_g))+" G"],["AMMUNITION",str(int(d.ammo))+" rounds"],["ARMAMENT","30 mm cannon" if game.selected==1 else "Twin machine guns"]]
	var y=272
	for row in specs:
		txt(Vector2(60,y),row[0],12,muted);txt(Vector2(191,y),row[1],14);y+=35
	txt(Vector2(405,553),"DRAG TO ORBIT   ·   WHEEL TO ZOOM",12,Color(.8,.85,.84))
	panel(Rect2(0,582,1280,138),Color(.025,.045,.058,.95))
	button(Rect2(38,606,234,67),"B-2 FIELDLARK","biplane",game.selected==0)
	button(Rect2(286,606,234,67),"SU-27","su27",game.selected==1)
	button(Rect2(551,606,271,67),"AI: "+["ROOKIE","REGULAR","VETERAN"][game.difficulty],"difficulty")
	button(Rect2(891,602,170,75),"DEPLOY → BATTLE","fly",true)
	button(Rect2(1071,602,170,75),"FREE FLIGHT","freeflight")
	txt(Vector2(42,701),"6 vs 6 / FIRST TO 20 OR 8 MIN   ·   FREE FLIGHT: SOLO, NO ENEMIES",12,muted)
	txt(Vector2(903,700),"LOW / HIGH · GLES2 · LICENSED ASSETS",12,muted)
func screen_point(world):
	var p=game.camera.unproject_position(world)
	return (p/game.world_view.size*rect_size-ui_offset)/scale_ui
func crosshair(p,color):
	draw_arc(p,11,0,TAU,32,color,1.3,true)
	for v in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:draw_line(p+v*15,p+v*23,color,1.3,true)
func draw_flight():
	var a=game.player
	if a==null:return
	var p=Vector2(640,360)
	var aim_point=a.translation+game.controller.aim*2000
	if not game.camera.is_position_behind(aim_point):
		var aim_screen=screen_point(aim_point)
		if Rect2(15,85,1250,555).has_point(aim_screen):crosshair(aim_screen,Color(.8,.92,.93,.85))
	if not a.dead:
		var nose=a.translation-a.global_transform.basis.z*1000
		if not game.camera.is_position_behind(nose):
			var np=screen_point(nose)
			draw_circle(np,2,amber);draw_arc(np,5,0,TAU,20,amber,1.2,true)
	panel(Rect2(445,22,390,54),Color(.025,.045,.06,.8))
	if game.mode=="freeflight":
		txt(Vector2(560,56),"FREE FLIGHT",20,cyan)
	else:
		txt(Vector2(472,56),"BLUE  %02d"%game.match_state.scores[0],20,cyan)
		txt(Vector2(621,55),"/ 20",14,muted)
		txt(Vector2(704,56),"%02d  RED"%game.match_state.scores[1],20,Color(1,.45,.35))
		var remaining=int(max(0,game.match_state.time_limit-game.match_state.elapsed))
		txt(Vector2(615,96),"%02d:%02d"%[remaining/60,remaining%60],14,ink)
	panel(Rect2(28,470,232,192),Color(.025,.045,.06,.75))
	var values=[["SPEED","%d km/h"%int(a.linear_velocity.length()*3.6)],["ALTITUDE","%d m"%int(a.translation.y)],["THROTTLE","%d %%"%int(a.throttle*100)],["LOAD","%.1f G"%a.flight.g_force],["CANNON","%d"%a.weapons.ammo]]
	var y=502
	for row in values:
		txt(Vector2(44,y),row[0],12,muted);txt(Vector2(135,y),row[1],16);y+=31
	txt(Vector2(30,40),a.data.name,20)
	if game.graphics.show_fps:
		txt(Vector2(30,65),"%d FPS  |  %s"%[Engine.get_frames_per_second(),["LOW","MEDIUM","HIGH"][game.graphics.preset]],12,amber)
	else:
		txt(Vector2(30,65),"%s"%[["LOW","MEDIUM","HIGH"][game.graphics.preset]],12,muted)
	txt(Vector2(30,695),"W/S THRUST   UP/DOWN PITCH   A/D ROLL   Q/E RUDDER   SPACE FIRE   ESC MENU",12,ink)
	txt(Vector2(1040,695),"SKY FRONT / "+("FREE FLIGHT" if game.mode=="freeflight" else "AIR BATTLE"),12,muted)
	var y2=496
	panel(Rect2(1060,463,190,201),Color(.025,.045,.06,.75))
	for zone in ["fuselage","left_wing","right_wing","tail","engine","pilot"]:
		var health=a.damage.zones[zone]
		txt(Vector2(1074,y2),zone.replace("_"," ").to_upper(),12,muted)
		draw_rect(Rect2(1178,y2-9,56,4),Color(.2,.25,.26))
		draw_rect(Rect2(1178,y2-9,56*health,4),cyan if health>.5 else amber);y2+=27
	var target=game.combat.selected_target
	if not game.combat.valid(target):target=game.targeting.nearest(a,game.aircraft)
	for enemy in game.aircraft+game.ground_units:
		if enemy==a or enemy.dead or game.camera.is_position_behind(enemy.translation):continue
		var distance=a.translation.distance_to(enemy.translation)
		if distance>game.graphics.draw_distance:continue
		var pos=screen_point(enemy.translation)
		if pos.x<15 or pos.x>1265 or pos.y<85 or pos.y>640:continue
		var color=cyan if enemy.team==a.team else Color(1,.43,.34)
		draw_polyline(PoolVector2Array([pos+Vector2(0,-10),pos+Vector2(7,0),pos+Vector2(0,10),pos+Vector2(-7,0),pos+Vector2(0,-10)]),color,1,true)
		txt(pos+Vector2(12,-4),enemy.data.name,12,color)
		txt(pos+Vector2(12,13),"%.2f km"%(distance/1000),12,color)
	if target!=null and not a.dead:
		var lead=game.targeting.lead(a,target,a.data.bullet_speed)
		if not game.camera.is_position_behind(lead) and a.translation.distance_to(target.translation)<1800:
			var lp=screen_point(lead)
			draw_arc(lp,6,0,TAU,20,amber,1,true)
			draw_line(lp,screen_point(target.translation),Color(1,.63,.25,.3),1,true)
	if a.data.id=="su27":
		panel(Rect2(975,108,280,171),Color(.025,.045,.06,.8))
		txt(Vector2(991,137),"%s  × %d"%[a.weapons.missile_type,a.weapons.missile_stock[a.weapons.missile_type]],20,amber)
		txt(Vector2(991,165),"LOCK %d%%  |  FLARES %d"%[int(a.weapons.lock_progress*100),a.weapons.flares],14,cyan)
		txt(Vector2(991,191),"T TARGET   X WEAPON   V LAUNCH",12,ink)
		txt(Vector2(991,215),"F FLARES    J SMOKE    K COLOR",12,ink)
		txt(Vector2(991,251),"SMOKE: "+["WHITE","RED","BLUE","GREEN","YELLOW","PURPLE","ORANGE"][a.weapons.smoke_color],12,game.effects.colors[a.weapons.smoke_color])
		var locked=a.weapons.lock_target
		if locked!=null and is_instance_valid(locked) and not locked.dead and not game.camera.is_position_behind(locked.translation):
			var lp=screen_point(locked.translation)
			draw_arc(lp,22,-PI/2,-PI/2+TAU*max(.01,a.weapons.lock_progress),48,amber,2,true)
		if game.missiles.threat(a)!=null:txt(Vector2(517,160),"MISSILE INBOUND — FLARE / BREAK",16,Color(1,.23,.16))
	if a.flight.stalled and not a.dead and not a.landing.grounded:txt(Vector2(552,465),"STALL — LOWER NOSE",16,amber)
	if a.translation.y-game.terrain.height_at(a.translation.x,a.translation.z)<100 and not a.dead and not a.landing.grounded:txt(Vector2(570,500),"PULL UP",20,Color(1,.3,.2))
	if game.hit_marker>0:
		for v in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:draw_line(p+v*27,p+v*35,amber,2)
	if game.notification_time>0:txt(Vector2(466,120),game.notification,16,amber)
	combat_hud.draw(self)
	if a.dead and (game.mode=="battle" or game.mode=="freeflight"):
		panel(Rect2(422,252,438,202))
		if game.mode=="freeflight":
			txt(Vector2(477,297),"AIRCRAFT LOST",26,amber)
			txt(Vector2(477,329),"Free flight — restart instantly.",16)
		else:
			txt(Vector2(477,297),"AIRCRAFT LOST",26,amber)
			txt(Vector2(477,329),"Your squadron is still fighting.",16)
		button(Rect2(471,357,340,56),"RESPAWN  [R]","respawn",true)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if game.mode=="results":
		panel(Rect2(0,0,1280,720),Color(.02,.04,.06,.78))
		txt(Vector2(478,245),"DRAW" if game.match_state.winner==2 else ("VICTORY" if game.match_state.winner==0 else "DEFEAT"),52,amber)
		txt(Vector2(508,299),"BLUE %d  :  %d RED"%game.match_state.scores,26)
		var stat=game.combat.stats(a)
		txt(Vector2(388,339),"AIR %d   GROUND %d   ASSISTS %d   DEATHS %d"%[stat.kills,stat.ground,stat.assists,stat.deaths],16)
		button(Rect2(470,462,340,58),"PLAY AGAIN","fly")
		button(Rect2(470,385,340,58),"RETURN TO HANGAR","hangar",true)
	if game.paused and not game.settings_open and game.is_in_flight():
		panel(Rect2(0,0,1280,720),Color(.02,.04,.055,.73))
		txt(Vector2(488,233),"FLIGHT PAUSED",26)
		button(Rect2(470,270,340,52),"RESUME FLIGHT","resume",true)
		button(Rect2(470,334,340,52),"SETTINGS & CONTROLS","settings")
		button(Rect2(470,398,340,52),"RETURN TO HANGAR","hangar")
func draw_settings():
	panel(Rect2(0,0,1280,720),Color(.015,.025,.035,.97))
	txt(Vector2(69,72),"FLIGHT CONFIGURATION",26)
	button(Rect2(978,34,230,48),"BACK","close_settings")
	button(Rect2(70,109,260,45),"GRAPHICS","graphics_tab",settings_tab==0)
	button(Rect2(347,109,260,45),"CONTROLS","controls_tab",settings_tab==1)
	if settings_tab==0:
		var g=game.graphics
		var rows=[["Quality preset",["LOW / HD 7640G","MEDIUM","HIGH"][g.preset],"preset"],["Resolution","%d × %d"%[g.resolution.x,g.resolution.y],"resolution"],["Render scale","%d %%"%int(g.render_scale*100),"scale"],["Shadows","ON" if g.shadows else "OFF","shadows"],["Texture detail",["LOW","MEDIUM","HIGH"][g.texture_quality],"textures"],["Draw distance","%d m"%int(g.draw_distance),"distance"],["Effects",["LOW","MEDIUM","HIGH"][g.effects],"effects"],["Antialiasing",["OFF","2× MSAA","4× MSAA"][g.aa],"aa"],["VSync","ON" if g.vsync else "OFF","vsync"],["FPS limit",str(g.fps_limit) if g.fps_limit>0 else "UNLIMITED","fps"]]
		for i in range(rows.size()):
			var x=70+(i/5)*600;var y=186+(i%5)*79
			txt(Vector2(x,y+18),rows[i][0],16,muted)
			button(Rect2(x+210,y-6,330,47),rows[i][1],rows[i][2])
		txt(Vector2(70,600),"Show FPS",16,muted)
		button(Rect2(280,576,330,47),"ON" if g.show_fps else "OFF","show_fps",g.show_fps)
		txt(Vector2(70,642),"LOW targets weak GPUs. HIGH is substantially heavier; missile mesh geometry remains identical in both.",14,muted)
		txt(Vector2(70,659),"HIGH: textured Su-27, forest materials, detailed vegetation and vehicles; LOW: reduced geometry and effects.",12,muted)
		txt(Vector2(70,686),"60 FPS on A8-4500M / HD 7640G is a target, not a verified benchmark. Settings save automatically.",12,amber)
	else:
		var labels={"throttle_up":"Increase thrust","throttle_down":"Decrease thrust","roll_left":"Roll left","roll_right":"Roll right","rudder_left":"Rudder left","rudder_right":"Rudder right","fire":"Fire cannon","free_look":"Free look (hold)","respawn":"Respawn","missile":"Launch missile","cycle_missile":"Select missile","target":"Select / cycle air target","flare":"Thermal flares","smoke":"Toggle smoke","smoke_color":"Smoke color","airbrake":"Airbrake (hold)","ground_target":"Cycle ground target","gear":"Landing gear (Su-27)","flaps":"Cycle flaps","target_view":"Look at target (hold)"}
		var i=0
		for key in game.graphics.keys:
			var x=70+(i/10)*600;var y=184+(i%10)*42
			txt(Vector2(x,y+18),labels[key],16,muted)
			button(Rect2(x+235,y-6,305,37),"PRESS A KEY…" if waiting_key==key else OS.get_scancode_string(game.graphics.keys[key]),"key:"+key);i+=1
		button(Rect2(70,610,350,42),"Mouse sensitivity: %.2f"%game.graphics.sensitivity,"sensitivity")
		button(Rect2(440,610,350,42),"Invert Y: "+("ON" if game.graphics.invert_y else "OFF"),"invert_y")
		txt(Vector2(70,678),"Mouse: aim · RMB: precision zoom · Wheel: distance · F11: fullscreen · ESC: pause",14)
		txt(Vector2(70,703),"Shift / Ctrl are additional throttle keys. Click a binding and press a key; ESC cancels.",14,muted)
