extends Reference
var tracking=false
var zooming=false
var shake=0.0
var yaw=0.0
var pitch=0.08
var distance=33.0
var orbit_yaw=0.65
var orbit_pitch=0.2
var free_yaw=0.0
var free_pitch=0.0
var aim=Vector3.FORWARD
func reset(a):
	yaw=a.rotation.y;pitch=0.02
	distance=33 if a.data.id=="su27" else 19
func mouse(event,in_hangar,free,sensitivity=1.0,invert=false):
	var vertical=-1.0 if invert else 1.0
	var precision=.45 if zooming else 1.0
	if event is InputEventMouseMotion:
		if in_hangar:
			if Input.is_mouse_button_pressed(BUTTON_LEFT):
				orbit_yaw-=event.relative.x*.007;orbit_pitch=clamp(orbit_pitch+event.relative.y*.005,-.05,.85)
		elif free:
			free_yaw-=event.relative.x*.003*sensitivity;free_pitch=clamp(free_pitch-event.relative.y*.003*sensitivity*vertical,-1.1,1.1)
		else:
			yaw-=event.relative.x*.0025*sensitivity*precision;pitch=clamp(pitch-event.relative.y*.0025*sensitivity*precision*vertical,-1.3,1.3)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==BUTTON_WHEEL_UP:distance=max(12,distance-3)
		if event.button_index==BUTTON_WHEEL_DOWN:distance=min(80,distance+3)
func update(camera,a,dt,in_hangar):
	if in_hangar:
		camera.fov=65;tracking=false;zooming=false
		var target=Vector3(0,2,0)
		var pos=target+Vector3(sin(orbit_yaw)*cos(orbit_pitch),sin(orbit_pitch),cos(orbit_yaw)*cos(orbit_pitch))*distance
		camera.translation=camera.translation.linear_interpolate(pos,clamp(dt*8,0,1))
		camera.look_at(target,Vector3.UP);return
	if a==null:return
	aim=Vector3(-sin(yaw)*cos(pitch),sin(pitch),-cos(yaw)*cos(pitch))
	a.direction=aim
	if not Input.is_action_pressed("free_look"):
		free_yaw=lerp(free_yaw,0,1-exp(-dt*6));free_pitch=lerp(free_pitch,0,1-exp(-dt*6))
	var view_pitch=clamp(pitch+free_pitch,-1.45,1.45)
	var view=Vector3(-sin(yaw+free_yaw)*cos(view_pitch),sin(view_pitch),-cos(yaw+free_yaw)*cos(view_pitch))
	var selected=a.game.combat.selected_target
	tracking=Input.is_action_pressed("target_view") and a.game.combat.valid(selected)
	if tracking:view=(selected.translation-a.translation).normalized()
	zooming=Input.is_action_pressed("precision_zoom") and not a.dead
	camera.fov=lerp(camera.fov,32.0 if zooming else 65.0,1-exp(-dt*10))
	# Keep the horizon upright even when following an inverted aircraft or a target overhead.
	var horizontal=Vector3(view.x,0,view.z)
	if horizontal.length_squared()<0.0001:
		horizontal=Vector3(-sin(yaw+free_yaw),0,-cos(yaw+free_yaw))
	else:
		horizontal=horizontal.normalized()
	var vertical=clamp(view.y,-.995,.995)
	view=Vector3(horizontal.x*sqrt(1.0-vertical*vertical),vertical,horizontal.z*sqrt(1.0-vertical*vertical))
	var target=a.translation+Vector3.UP*3
	var desired=target-view*distance
	camera.translation=camera.translation.linear_interpolate(desired,clamp(dt*12,0,1))
	var right=view.cross(Vector3.UP).normalized()
	var up=right.cross(view).normalized()
	camera.look_at(target+view*150,up)
	shake=max(0,shake-dt)
	if shake>0:camera.translation+=camera.global_transform.basis.x*rand_range(-shake,shake)

