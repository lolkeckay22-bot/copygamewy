extends Node
var game
var frame=0
var checks=[]
var before_impacts=0
var before_ground_hits=0
func check(ok,label):
	checks.append({"pass":ok,"test":label});print("EXPANSION ","PASS " if ok else "FAIL ",label)
func _ready():
	Engine.target_fps=0
func _process(_dt):
	frame+=1
	if frame==5:
		game.graphics.set_preset(2);game.graphics.apply(game)
		check(game.hangar.model.high_model.visible,"HIGH selects external aircraft mesh")
		check(game.terrain.ground_mesh.material_override==game.terrain.high_material,"HIGH uses ground textures")
		game.start_battle()
		check(game.ground_units.size()==12,"12 ground combatants spawn")
		check(game.player.model.stores.size()==6,"six 3D missile stores mounted")
	elif frame==15:
		var a=game.player;var t=game.aircraft[6]
		for enemy in game.aircraft:
			if enemy!=a:enemy.weapons.missile_cooldown=100
		t.translation=a.translation-a.global_transform.basis.z*500;t.linear_velocity=a.linear_velocity
		a.weapons.lock_target=t;a.weapons.lock_progress=1;a.weapons.missile_cooldown=0
		check(a.weapons.fire_missile(a),"R-73 launches from locked aircraft")
		check(a.weapons.missile_stock["R-73"]==3,"launch consumes store")
		check(game.missiles.slots[0].node.mesh==load("res://assets/models/r73.res"),"external missile geometry loaded")
		check(game.missiles.release_flares(a),"thermal decoys release")
		check(a.weapons.flares==31,"flare stock consumed")
		a.weapons.smoke=true;a.weapons.smoke_color=6
	elif frame==25:
		check(game.effects.colors.size()==7,"seven smoke colors")
		var active=0
		for p in game.effects.particles:
			if p.life>0:active+=1
		check(active>0,"smoke and flare effects emit")
		var ground=game.ground_units[6];var old=ground.hp
		ground.take_hit(ground.translation,50,game.player)
		check(ground.hp<old and ground.move_speed<10,"ground damage affects mobility")
		ground.take_hit(ground.translation,2000,game.player)
		check(ground.dead,"ground target can be destroyed")
		game.player.weapons.cycle_missile();game.player.weapons.lock_progress=1;game.player.weapons.missile_cooldown=0
		check(game.player.weapons.fire_missile(game.player),"R-27R launches")
	elif frame==60:
		var same=game.missiles.slots[0].node.mesh
		game.graphics.set_preset(0);game.graphics.apply(game)
		check(game.missiles.slots[0].node.mesh==same,"missile mesh unchanged between HIGH and LOW")
		check(not game.player.model.high_model.visible,"LOW uses cheaper aircraft")
		check(game.terrain.ground_mesh.material_override==game.terrain.low_material,"LOW terrain restored")
		game.player.airbrake=true
	elif frame==80:
		var m=game.missiles.slots[0];var t=game.aircraft[7]
		if t.dead:game.respawn(t)
		before_impacts=game.missiles.impacts
		m.active=true;m.owner=game.player;m.target=t;m.type="R-73";m.decoy=-1;m.lost=0;m.age=1
		m.p=t.translation+Vector3(0,0,3);m.v=Vector3(0,0,-400);m.node.show()
	elif frame==85:
		check(game.missiles.impacts>before_impacts,"missile swept proximity detonates on target")
		var ground=game.ground_units[7]
		before_ground_hits=game.projectiles.hits
		game.projectiles.spawn(ground.translation+Vector3(0,.8,8),Vector3(0,0,-700),game.player)
	elif frame==90:
		check(game.projectiles.hits>before_ground_hits,"live cannon projectile hits ground vehicle")
	elif frame==100:
		var a=game.player;var t=game.aircraft[8];var m=game.missiles.slots[2]
		if t.dead:game.respawn(t)
		t.translation=a.translation+a.global_transform.basis.z*3000
		m.active=true;m.owner=a;m.target=t;m.type="R-27R";m.decoy=-1;m.lost=0;m.age=1
		m.p=a.translation+Vector3.UP*200;m.v=-a.global_transform.basis.z*500
	elif frame==200:
		check(game.missiles.slots[2].lost>1.2,"SARH guidance loses target outside carrier cone")
	elif frame==240:
		check(game.projectiles.shots>0,"AI ground/air guns fire")
		check(game.missiles.launched>=2,"missile simulations remain active")
		var f=File.new();f.open("user://expansion_tests.json",File.WRITE);f.store_string(JSON.print(checks,"  "));f.close()
		print("EXPANSION COMPLETE ",checks)
		get_tree().quit()
