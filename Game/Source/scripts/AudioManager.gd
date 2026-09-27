extends Node
var engine
var wind
var sounds={}
var pool=[]
var index=0
func _ready():
	for name in ["engine","wind","gun","hit","explosion","ui","launch","flare","lock"]:
		sounds[name]=load("res://assets/"+name+".wav")
	for name in ["engine","wind"]:
		sounds[name].loop_mode=AudioStreamSample.LOOP_FORWARD
		sounds[name].loop_begin=0;sounds[name].loop_end=44100
	engine=AudioStreamPlayer.new();engine.stream=sounds.engine;engine.volume_db=-22;add_child(engine)
	wind=AudioStreamPlayer.new();wind.stream=sounds.wind;wind.volume_db=-25;add_child(wind)
	for i in range(12):
		var p=AudioStreamPlayer.new();add_child(p);pool.append(p)
func play(name):
	var p=pool[index];index=(index+1)%pool.size()
	p.stream=sounds[name];p.volume_db=-13 if name=="gun" else -7;p.play()
func update(a,active):
	if not active or a==null or a.dead:
		engine.stop();wind.stop();return
	if not engine.playing:engine.play()
	if not wind.playing:wind.play()
	engine.pitch_scale=(0.6+a.throttle*1.25)*(0.5+a.damage.zones.engine*0.5)
	engine.volume_db=-25+a.throttle*10-(1-a.damage.zones.engine)*25
	wind.volume_db=clamp(-40+a.linear_velocity.length()*.035,-40,-17)
