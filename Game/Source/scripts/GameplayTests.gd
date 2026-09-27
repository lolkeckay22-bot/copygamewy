extends Node
var game
var frame=0
var checks=[]
func check(ok,label):
	checks.append({"pass":ok,"test":label});print("GAMEPLAY ","PASS " if ok else "FAIL ",label)
func _ready():Engine.target_fps=0
func _process(_dt):
	frame+=1
	if frame==5:
		game.start_battle()
		check(game.service_bases.get_child_count()==2,"two service airfields built")
		game.combat.select_target(false)
		check(game.combat.valid(game.combat.selected_target) and game.combat.selected_target.team!=game.player.team,"air target selection selects enemy")
		game.combat.select_target(true)
		check(game.ground_units.has(game.combat.selected_target),"ground selection selects ground vehicle")
		check(game.player.weapons.lock_target==null,"ground selection clears air missile target")
		game.player.die();game.respawn(game.player)
		var a=game.player;var hp=a.damage.health
		a.take_hit(a.translation,50,game.aircraft[6])
		check(a.spawn_protection>0 and a.damage.health==hp,"spawn shield blocks damage")
		a.weapons.update(a,.01,true)
		check(a.spawn_protection==0,"firing cancels shield")
		a.weapons.cooldown=0;a.weapons.heat=0
		for i in range(25):
			a.weapons.cooldown=0;a.weapons.update(a,.001,true)
		check(a.weapons.overheated,"sustained fire overheats cannon")
		var ammo=a.weapons.ammo;a.weapons.cooldown=0;a.weapons.update(a,.001,true)
		check(a.weapons.ammo==ammo,"overheat blocks firing without wasting ammo")
		a.weapons.update(a,4,false)
		check(not a.weapons.overheated,"cannon cools and recovers")
	elif frame==15:
		var a=game.player
		a.translation=game.combat.home(a)+Vector3.UP*a.landing.clearance;a.linear_velocity=Vector3.ZERO;a.landing.grounded=true;a.throttle=0
		a.shoot=false;a.weapons.ammo=1;a.damage.zones.engine=.3;a.last_damage_time=-100
		game.combat.update(4)
		check(game.combat.service_status(a)>=4,"service zone requires dwell time")
		a.translation.x=2000;game.combat.update(.1)
		check(game.combat.service_status(a)==0,"leaving service zone resets progress")
		a.translation=game.combat.home(a)+Vector3.UP*a.landing.clearance;a.shoot=true;game.combat.update(5.1)
		check(a.weapons.ammo==1,"firing prevents service")
		a.shoot=false;game.combat.update(5.1)
		check(a.weapons.ammo==int(a.data.ammo) and a.damage.zones.engine==1,"continuous service repairs and rearms")
		check(game.combat.stats(a).services==1 and game.combat.service_cooldowns[a.get_instance_id()]>0,"service cooldown prevents repeat instant resupply")
		var ground=game.ground_units[7];var friend=game.aircraft[1]
		ground.take_hit(ground.translation,5,friend);ground.take_hit(ground.translation,1000,a)
		check(game.combat.stats(a).ground==1,"ground kill credited to player")
		check(game.combat.stats(friend).assists==1,"recent supporting attacker receives assist")
		check(game.combat.feed.size()>0,"kill feed records destruction")
		check(game.combat.stats(a).deaths==1,"death count persists after respawn")
	elif frame==30:
		var bot=game.aircraft[1]
		var enemy=game.aircraft[6]
		bot.translation=Vector3(0,1800,0);bot.rotation=Vector3.ZERO
		enemy.translation=Vector3(-30,1800,-2000);game.aircraft[7].translation=Vector3(30,1800,-2000)
		for other in [game.aircraft[2],game.aircraft[3],game.aircraft[4],game.aircraft[5]]:other.ai.target=enemy
		check(bot.ai.choose_target(bot)!=enemy,"AI avoids already crowded enemy target")
		bot.weapons.ammo=0;bot.ai.timer=0;bot.ai.update(bot,.2)
		check(bot.ai.state_name.begins_with("LAND /") and not bot.ai.fire,"empty AI withdraws for service")
	elif frame==60:
		game.show_hangar();game.start_battle()
		check(game.combat.stats(game.player).ground==0 and game.combat.feed.empty(),"rematch resets statistics and kill feed")
		var f=File.new();f.open("user://gameplay_tests.json",File.WRITE);f.store_string(JSON.print(checks,"  "));f.close()
		print("GAMEPLAY COMPLETE ",checks);get_tree().quit()
