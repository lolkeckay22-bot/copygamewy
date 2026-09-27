from pathlib import Path
from PIL import Image
p=Path('source/assets/textures/ground.jpg');im=Image.open(p);im.resize((512,512),Image.Resampling.LANCZOS).save(p.with_name('ground_medium.jpg'),quality=85)
p=Path('source/scripts/GraphicsSettings.gd');s=p.read_text().replace('game.terrain.set_quality(preset);','game.terrain.high_material.albedo_texture=load("res://assets/textures/ground.jpg" if texture_quality==2 else "res://assets/textures/ground_medium.jpg")\n\tgame.terrain.high_material.normal_enabled=texture_quality==2\n\tgame.terrain.set_quality(min(preset,texture_quality));');p.write_text(s)
p=Path('source/scripts/ExpansionTests.gd');s=p.read_text().replace('var checks=[]','var checks=[]\nvar before_impacts=0\nvar before_ground_hits=0');s=s.replace('\telif frame==240:', '''\telif frame==80:
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
	elif frame==240:''');p.write_text(s)
# Original synthesized sound assets, no third-party audio.
import numpy as np,wave
rng=np.random.default_rng(23)
for name,duration,freq in [('launch',.7,85),('flare',.22,190),('lock',.12,1000)]:
 t=np.arange(int(44100*duration))/44100
 a=((rng.uniform(-1,1,len(t))*.65+np.sin(t*freq*6.283)*.35) if name!='lock' else np.sin(t*freq*6.283))*.35*np.minimum(t*35,1)*np.exp(-t*(3 if name=='launch' else 10))
 with wave.open('source/assets/'+name+'.wav','wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(44100);w.writeframes((a*32767).astype('<i2').tobytes())
p=Path('source/scripts/AudioManager.gd');s=p.read_text().replace('"explosion","ui"','"explosion","ui","launch","flare","lock"');p.write_text(s)
p=Path('source/scripts/MissileSystem.gd');s=p.read_text().replace('game.audio.play("gun")','game.audio.play("launch")').replace('a.weapons.flares-=1;', 'if a.player:game.audio.play("flare")\n\ta.weapons.flares-=1;');p.write_text(s)
p=Path('source/scripts/AircraftWeapons.gd');s=p.read_text().replace('if a.game.missiles.valid_target(a,lock_target,missile_type):lock_progress=', 'var previous_lock=lock_progress\n\tif a.game.missiles.valid_target(a,lock_target,missile_type):lock_progress=').replace('if not a.player and lock_progress>=1', 'if a.player and previous_lock<1 and lock_progress>=1:a.game.audio.play("lock")\n\tif not a.player and lock_progress>=1');p.write_text(s)
