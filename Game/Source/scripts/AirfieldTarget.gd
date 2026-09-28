extends Spatial
# Persistent scene target for airfield infrastructure; no physics body per building.
var game
var field
var team=0
var dead=false
var hp=220.0
var hit_radius=24.0
var linear_velocity=Vector3.ZERO
var data={"name":"АНГАР","hp":220.0,"span":40.0,"length":58.0,"damage":0.0}
var kind="hangar"
var model
func setup(owner,owner_field,type,position):
	game=owner
	field=owner_field
	kind=type
	team=owner_field.team
	translation=position
	if kind=="runway":
		hp=300.0
		hit_radius=58.0
		data={"name":"УЧАСТОК ВПП","hp":300.0,"span":85.0,"length":440.0,"damage":0.0}
	elif kind=="tower":
		hp=180.0
		hit_radius=18.0
		data={"name":"ДИСПЕТЧЕРСКАЯ","hp":180.0,"span":20.0,"length":20.0,"damage":0.0}
	model=MeshInstance.new()
	add_child(model)
	var builder=preload("res://scripts/AircraftModel.gd").new()
	if kind=="hangar":
		builder.box(Vector3(0,10,0),Vector3(45,20,64),Color(.31,.34,.32))
		builder.box(Vector3(-22.6,7,0),Vector3(.25,13,40),Color(.1,.13,.14))
		builder.box(Vector3(0,20.4,0),Vector3(47,.8,66),Color(.42,.44,.42))
		for rib in range(9):
			builder.box(Vector3(-22.85,7,(rib-4)*4),Vector3(.2,13,.13),Color(.4,.42,.4))
	elif kind=="tower":
		builder.box(Vector3(0,12,0),Vector3(12,24,12),Color(.42,.42,.38))
		builder.box(Vector3(0,26,0),Vector3(20,6,20),Color(.14,.24,.27))
		builder.box(Vector3(0,30,0),Vector3(22,1,22),Color(.55,.55,.51))
	else:
		builder.box(Vector3(0,.06,0),Vector3(78,.12,440),Color(.24,.25,.25))
	var result=builder.finish_mesh()
	model.mesh=result.mesh
	result.free()
	builder.free()
func aim_point():
	return translation+Vector3.UP*(0.5 if kind=="runway" else (23.0 if kind=="tower" else 12.0))
func take_hit(point,amount,_attacker):
	if dead:return
	hp=max(0.0,hp-amount)
	game.effects.burst(point,false)
	if hp>0:return
	dead=true
	if kind=="runway":
		field.operational=false
		if game.player!=null and game.player.team==team:
			game.notification="ВПП РАЗРУШЕНА — РЕМОНТ НЕДОСТУПЕН"
			game.notification_time=5
	var material=SpatialMaterial.new()
	material.albedo_color=Color(.10,.10,.09) if kind=="runway" else Color(.16,.13,.10)
	material.roughness=1
	model.material_override=material
	if kind!="runway":
		model.scale=Vector3(1,.26,1)
		model.translation.y=0.0
	game.spawn_explosion(translation+Vector3.UP*(2 if kind=="runway" else 12))
