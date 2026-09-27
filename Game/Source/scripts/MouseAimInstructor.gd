extends Reference
func command(aircraft, direction, manual_roll=0.0, manual_yaw=0.0):
	var basis = aircraft.global_transform.basis
	var local = basis.xform_inv(direction.normalized())
	var forward = -basis.z
	var flat_forward=Vector3(forward.x,0,forward.z).normalized()
	var flat_direction=Vector3(direction.x,0,direction.z).normalized()
	if flat_forward.length_squared()<0.001:
		flat_forward=forward
	if flat_direction.length_squared()<0.001:
		flat_direction=flat_forward
	var heading = atan2(flat_forward.cross(flat_direction).y,flat_forward.dot(flat_direction))
	var bank = atan2(basis.x.y, basis.y.y)
	var wanted_bank = clamp(heading * 0.85, -1.12, 1.12)
	var roll = clamp((wanted_bank - bank) * 2.5, -1.0, 1.0)
	if abs(manual_roll) > 0.01:
		roll = -manual_roll
	var elevation_error=asin(clamp(direction.y,-1.0,1.0))-asin(clamp(forward.y,-1.0,1.0))
	var right=forward.cross(Vector3.UP)
	if right.length_squared()<0.001:
		right=basis.x
	else:
		right=right.normalized()
	var angular_world=Vector3.UP*heading*1.7+right*elevation_error*2.4
	var angular_local=basis.xform_inv(angular_world)
	var maximum=max(1.0,max(abs(angular_local.x),abs(angular_local.y)))
	var pitch=angular_local.x/maximum
	var yaw=clamp(angular_local.y/maximum+manual_yaw,-1.0,1.0)
	# High-alpha envelope: biplane stays protected, Su-27 is allowed deep post-stall
	# so Cobra/Herbst/tailslide arise from physics, not a scripted button.
	var is_su27=aircraft.data.id=="su27"
	var aoa=aircraft.flight.aoa
	if is_su27:
		var speed=aircraft.linear_velocity.length()
		# Cobra window: enough energy to pitch through, slow enough to depart.
		if speed>90.0 and speed<330.0:
			if aoa > 0.95:
				pitch=min(pitch,-clamp((aoa-0.95)*1.6,0.0,0.5))
			if aoa < -0.6:
				pitch=max(pitch,clamp((-aoa-0.6)*1.6,0.0,0.5))
		else:
			if aoa > 0.45:
				pitch=min(pitch,-clamp((aoa-0.45)*2.2,0.0,0.65))
			if aoa < -0.4:
				pitch=max(pitch,clamp((-aoa-0.4)*2.2,0.0,0.65))
	else:
		if aoa > 0.24:
			pitch=min(pitch,-clamp((aoa-0.24)*3.0,0.0,0.65))
		if aoa < -0.22:
			pitch=max(pitch,clamp((-aoa-0.22)*3.0,0.0,0.65))
	return Vector3(pitch, yaw, roll)
