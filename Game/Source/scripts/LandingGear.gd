extends Reference
var grounded=false
var gear_down=false
var brake=false
var touchdown_speed=0.0
var clearance=2.4
func configure(a):
	gear_down=a.data.id=="biplane"
	clearance=2.4 if a.data.id=="su27" else 1.9
func toggle(a):
	if a.data.id=="biplane" or grounded:return
	gear_down=not gear_down
func step(a,state,dt):
	var pos=state.transform.origin
	var base=a.game.service_bases.at_position(pos)
	var surface=a.game.terrain.height_at(pos.x,pos.z)
	if base!=null:surface=base.y
	var floor_y=surface+clearance
	var v=state.linear_velocity
	var next_y=pos.y+v.y*dt
	if (pos.y>floor_y+.25 and next_y>floor_y) or (pos.y>=floor_y-.03 and v.y>.05 and v.length()>a.data.stall_speed*1.05):
		grounded=false
		return
	if base==null or not gear_down:
		grounded=false
		if pos.y<floor_y or next_y<floor_y:crash(a)
		return
	var basis=state.transform.basis.orthonormalized()
	var roll=abs(atan2(basis.x.y,basis.y.y))
	var pitch=asin(clamp(-basis.z.y,-1,1))
	if not grounded:
		touchdown_speed=abs(v.y)
		var approach_speed=Vector2(v.x,v.z).length()
		var limit=120.0 if a.data.id=="su27" else 45.0
		if v.y < -10.0 or roll>deg2rad(28) or pitch<deg2rad(-15) or pitch>deg2rad(25) or approach_speed>limit:
			crash(a);return
		if v.y < -4.5:
			a.damage.apply("fuselage",(abs(v.y)-4.5)*5,a.data)
		if a.player:
			a.game.notification="TOUCHDOWN — HOLD B TO BRAKE";a.game.notification_time=3
	grounded=true
	# Contact constraint corrects penetration; propulsion/lift remain force-integrated.
	var transform=state.transform
	transform.origin.y=floor_y
	var forward=-basis.z;var yaw=atan2(-forward.x,-forward.z)
	# Runway steering and suspension stabilize bank; nose rotation remains available.
	var desired_pitch=max(0,min(pitch,deg2rad(12)))
	transform.basis=Basis(Vector3(desired_pitch,yaw,0))
	state.transform=transform
	v.y=max(0,v.y)
	var along=Vector3(-sin(yaw),0,-cos(yaw))
	var side=Vector3(cos(yaw),0,-sin(yaw))
	v-=side*v.dot(side)*min(1,dt*5)
	var horizontal=Vector3(v.x,0,v.z)
	var deceleration=0.55+(9.0 if brake else 0.0)
	if horizontal.length()>0:
		horizontal=horizontal.normalized()*max(0,horizontal.length()-deceleration*dt)
	v.x=horizontal.x;v.z=horizontal.z
	# Wheel steering works at taxi speeds; instructor may raise the nose for takeoff.
	var angular=state.angular_velocity
	angular.z=0
	angular.y=a.manual_yaw*.35*clamp(horizontal.length()/8,0,1)
	if brake or horizontal.length()<a.data.stall_speed*.7:angular.x=0
	state.angular_velocity=angular;state.linear_velocity=v
	if v.y>1.2 and horizontal.length()>a.data.stall_speed*1.05:grounded=false

func crash(a):
	if not a.dead:a.game.ground_losses+=1
	a.die()
