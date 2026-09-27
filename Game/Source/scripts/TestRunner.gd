extends Node
var game
var elapsed=0.0
var stage=0
var checks=[]
var minimum_altitude=1e9
var max_speed=0.0
func _ready():
	if OS.get_name()=="Server":Engine.target_fps=0
func check(condition,label):
	checks.append({"test":label,"pass":condition});print("TEST ","PASS " if condition else "FAIL ",label)
func shot(name):
	if OS.get_name()=="Server":return
	yield(get_tree(),"idle_frame");yield(VisualServer,"frame_post_draw")
	var img=get_viewport().get_texture().get_data();img.flip_y();img.save_png("user://"+name+".png")
func _process(dt):
	elapsed+=dt
	if elapsed>2 and stage==0:
		check(game.mode=="hangar" and game.hangar.model!=null,"3D hangar opens")
		game.hud.action("settings")
		check(game.settings_open,"settings opens")
		game.hud.action("controls_tab")
		game.hud.waiting_key="fire"
		var key=InputEventKey.new();key.scancode=KEY_G;key.pressed=true
		game.hud._input(key)
		check(game.graphics.keys.fire==KEY_G,"keyboard rebinding")
		game.graphics.keys.fire=KEY_SPACE;game.graphics.bind_keys();game.graphics.save()
		var old_scale=game.graphics.render_scale
		game.graphics.render_scale=0.75;game.graphics.apply(game)
		check(game.world_view.size==game.graphics.resolution*0.75,"render scale changes 3D viewport")
		game.graphics.render_scale=old_scale;game.graphics.apply(game)
		game.hud.action("close_settings")
		check(not game.settings_open,"settings closes")
		shot("hangar_su27");stage=1
	elif elapsed>3 and stage==1:
		game.select_aircraft(0);check(game.selected==0,"aircraft switch biplane");stage=2
	elif elapsed>4 and stage==2:
		shot("hangar_biplane");game.select_aircraft(1);game.start_battle();stage=3
		check(game.aircraft.size()==12,"6 vs 6 spawned")
	elif elapsed>7 and stage==3:
		check(game.player.linear_velocity.length()>100,"rigid body flight accelerates")
		game.controller.yaw+=.3;stage=4
	elif elapsed>10 and stage==4:
		shot("battle");check(abs(game.player.rotation.y)>.02,"mouse aim instructor turns aircraft")
		var a=game.player
		var target=game.aircraft[6]
		# Deterministic weapon hit fixture through the real swept projectile path.
		target.translation=a.translation-a.global_transform.basis.z*100
		target.linear_velocity=a.linear_velocity
		game.projectiles.spawn(a.translation-a.global_transform.basis.z*60,a.linear_velocity-a.global_transform.basis.z*880,a)
		stage=5
	elif elapsed>11 and stage==5:
		check(game.projectiles.hits>0,"swept ballistics hit aircraft")
		game.player.damage.apply("engine",45,game.player.data)
		check(game.player.damage.zones.engine<1,"engine damage reduces thrust factor")
		game.player.die();stage=6
	elif elapsed>12 and stage==6:
		game.respawn(game.player);check(not game.player.dead and game.player.weapons.ammo==150,"player respawn and rearm")
		game.toggle_pause();check(game.paused,"pause works");game.toggle_pause();stage=7
	elif elapsed>58 and stage==7:
		check(game.projectiles.shots>1,"AI fires live projectiles")
		check(game.player.translation.y>100,"level flight remains above terrain")
		print("SIM METRICS shots=",game.projectiles.shots," hits=",game.projectiles.hits," speed=",game.player.linear_velocity.length()," alt=",game.player.translation.y)
		game.match_state.scores[0]=19
		var victim=game.aircraft[7]
		if victim.dead:game.respawn(victim)
		victim.damage.apply("pilot",1000,victim.data)
		if victim.damage.destroyed():victim.die()
		check(game.mode=="results" and game.match_state.winner==0,"score limit ends match")
		shot("results");stage=8
	elif elapsed>60 and stage==8:
		game.show_hangar();game.select_aircraft(0);game.start_battle();stage=9
	elif elapsed>69 and stage==9:
		print("BIPLANE METRICS speed=",game.player.linear_velocity.length()," altitude=",game.player.translation.y," dead=",game.player.dead)
		check(game.player.linear_velocity.length()>20 and game.player.linear_velocity.length()<90,"biplane has distinct flight envelope")
		shot("battle_biplane");stage=10
	elif elapsed>71 and stage==10:
		game.show_hangar();check(game.mode=="hangar","return to hangar")
		var f=File.new();f.open("user://test_results.json",File.WRITE);f.store_string(JSON.print(checks,"  "));f.close()
		print("TEST FINISHED ",checks)
		get_tree().quit()
