extends Node
var game
var t=0.0
var next=2.0
var started=false
func _process(dt):
	t+=dt
	if not started and t>1:
		game.select_aircraft(0 if "--biplane" in OS.get_cmdline_args() else 1)
		if "--high" in OS.get_cmdline_args():
			game.graphics.set_preset(2);game.graphics.apply(game)
		game.start_battle();started=true
		Engine.time_scale=1;Engine.target_fps=0
		if "--autoplay" in OS.get_cmdline_args():game.player.player=false
	if t>next and started:
		next+=15
		var a=game.player
		print("DIAG ",int(t)," speed=",a.linear_velocity.length()," y=",a.translation.y," pos=",a.translation," rot=",a.rotation," aoa=",a.flight.aoa," g=",a.flight.g_force," dead=",a.dead," shots=",game.projectiles.shots," hits=",game.projectiles.hits," score=",game.match_state.scores," crashes=",game.ground_losses," missiles=",game.missiles.launched," missile_hits=",game.missiles.impacts," decoyed=",game.missiles.decoyed)
		var target=game.aircraft[6]
		print("AI ",target.ai.state_name," speed=",target.linear_velocity.length()," y=",target.translation.y," rot=",target.rotation," dir=",target.direction)
	if started and game.mode=="results":
		print("NATURAL MATCH COMPLETE time=",t," scores=",game.match_state.scores," shots=",game.projectiles.shots," hits=",game.projectiles.hits," crashes=",game.ground_losses," missiles=",game.missiles.launched," missile_hits=",game.missiles.impacts," decoyed=",game.missiles.decoyed)
		get_tree().quit()
	if t>600:
		print("DIAGNOSTIC TIME LIMIT reached")
		get_tree().quit()
