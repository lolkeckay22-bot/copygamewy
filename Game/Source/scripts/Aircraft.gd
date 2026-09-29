extends RigidBody
var data = {}
var game
var team = 0
var player = false
var dead = false
var spawn_protection=0.0
var last_damage_time=-100.0
var throttle = 0.82
var airbrake=false
var damage = preload("res://scripts/DamageModel.gd").new()
var flight_controls=preload("res://scripts/FlightControls.gd").new()
var landing=preload("res://scripts/LandingGear.gd").new()
var flight = preload("res://scripts/FlightPhysics.gd").new()
var instructor = preload("res://scripts/MouseAimInstructor.gd").new()
var ai = preload("res://scripts/AircraftAI.gd").new()
var weapons = preload("res://scripts/AircraftWeapons.gd").new()
var model
var direction = Vector3.FORWARD
var manual_pitch = 0.0
var manual_roll = 0.0
var manual_yaw = 0.0
var shoot = false
var death_time = 0.0
var last_attacker = null
var physics_accumulator = 0.0
var lod_clock=0.0
var vapor_clock=0.0
func setup(database_entry, owner_game, faction, is_player):
	data = database_entry
	landing.configure(self)
	game = owner_game
	team = faction
	player = is_player
	mass = data.mass
	custom_integrator = true
	gravity_scale = 0
	collision_layer = 0
	collision_mask = 0
	can_sleep = false
	contact_monitor=false
	weapons.ammo = int(data.ammo)
	weapons.hardpoints.missiles=data.id=="su27"
	model = preload("res://scripts/AircraftModel.gd").new()
	var camo_tex = "res://assets/textures/camo.png" if game.graphics.skin == "camo" else null
	model.build(data.id, team, false, camo_tex)
	model.set_quality(game.graphics.preset)
	add_child(model)
	ai.skill = game.difficulty
	weapons.missile_cooldown=4.0
func _exit_tree():
	game=null
	last_attacker=null
	ai.target=null
	weapons.lock_target=null
func _integrate_forces(state):
	if game==null:
		return
	if dead or not game.is_in_flight() or game.paused:
		state.linear_velocity = Vector3.ZERO if dead else state.linear_velocity
		state.angular_velocity = Vector3.ZERO
		return
	var dt = state.step
	if not player:
		if game.mode!="battle":
			state.angular_velocity=Vector3.ZERO
			return
		ai.update(self,dt)
		direction = ai.direction
		shoot = ai.fire
	physics_accumulator += dt
	if not player and translation.distance_squared_to(game.camera.translation)>6250000 and physics_accumulator<0.033:
		return
	dt=physics_accumulator
	physics_accumulator=0.0
	if dt>0.05:
		dt=0.05
	var control = instructor.command(self,direction,manual_roll,manual_yaw,manual_pitch)
	flight.step(self,state,control,dt)
	landing.step(self,state,dt)
func _physics_process(dt):
	if game==null:
		return
	if not game.is_in_flight() or game.paused:
		return
	if dead:
		death_time += dt
		if not player and game.mode=="battle" and death_time > 7:
			game.respawn(self)
		return
	flight_controls.update(self)
	weapons.update(self,dt,shoot)
	if not landing.grounded and translation.y < game.terrain.height_at(translation.x,translation.z) - 1.0:
		game.ground_losses+=1
		die()
		return
	if game.mode=="battle" and (abs(translation.x)>12000 or abs(translation.z)>12000):
		direction = (Vector3(0,900,0)-translation).normalized()
	lod_clock-=dt
	if lod_clock<=0:
		lod_clock=.15
		var dist = translation.distance_to(game.camera.translation)
		model.set_lod(dist,game.graphics.draw_distance)
	model.set_gear(landing.gear_down)
	model.set_flaps(flight_controls.flaps)
	vapor_clock-=dt
	if vapor_clock<=0:
		vapor_clock=0.05
		model.update_vapor(flight.mach,flight.aoa,flight.g_force,linear_velocity.length())
func take_hit(point,amount,attacker):
	if dead or spawn_protection>0:
		return
	if game==null or not game.is_in_flight():
		return
	last_attacker = attacker
	last_damage_time=game.combat.clock
	game.combat.damage(self,attacker,amount)
	damage.hit(to_local(point),amount,data)
	apply_damage_visual()
	if player:
		game.audio.play("hit")
		game.controller.shake=.35
	if damage.destroyed():
		die()
func apply_damage_visual():
	if model!=null:
		model.apply_damage_tint(damage.health)
func die():
	if dead:
		return
	dead = true
	death_time=0.0
	shoot=false
	physics_accumulator=0.0
	if model!=null:
		model.hide()
		model.set_vapor(0.0)
	if game!=null:
		game.aircraft_destroyed(self)
