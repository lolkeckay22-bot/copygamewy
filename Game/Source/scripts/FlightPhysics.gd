extends Reference
# Realistic-Battles-inspired flight model (custom implementation).
# Lift = 0.5 * rho * V^2 * S * CL(AoA), Drag = 0.5 * rho * V^2 * S * CD(AoA, Mach).
# CL/CD are AoA-dependent curves with progressive post-stall, not on/off switches.
# All per-aircraft tuning lives in data/aircraft.json (+ sane defaults).
var aoa = 0.0
var sideslip = 0.0
var g_force = 1.0
var stalled = false
var stall_amount = 0.0
var fuel=1.0
var mach=0.0
var rho=1.225
var q=0.0
func _param(d, key, fallback):
	if d.has(key):
		return d[key]
	return fallback
func step(body, state, control, dt):
	var d = body.data
	var origin = state.transform.origin
	var basis = state.transform.basis.orthonormalized()
	var v = state.linear_velocity
	var speed = v.length()
	var alt = max(origin.y, 0.0)
	rho = 1.225 * exp(-alt / 8500.0)
	var a_sound = max(295.0, 340.0 - alt * 0.0035)
	mach = speed / a_sound
	# Fuel: Su-27 burns more at afterburner, flameout floor at 45% for arcade continuity.
	var burn = dt * body.throttle * (0.00011 if d.id=="su27" else 0.000035)
	if body.throttle > 0.95 and d.id=="su27":
		burn *= 1.6
	fuel = max(0.45, fuel - burn)
	var local = basis.xform_inv(v)
	var fwd_speed = max(1.0, -local.z)
	aoa = atan2(-local.y, fwd_speed)
	sideslip = atan2(local.x, max(5.0, -local.z))
	# --- Per-aircraft aero config (all optional, backward compatible) ---
	var cl0 = float(_param(d, "cl", 0.2))
	var slope = float(_param(d, "lift_slope", 4.2))
	var crit = deg2rad(float(_param(d, "critical_aoa_deg", 17.0)))
	var stall_w = float(_param(d, "stall_width", 0.28))
	var post_lift = float(_param(d, "post_stall_lift", 0.42))
	var flap_lift = _param(d, "flap_lift", [0, 0.15, 0.35])
	var flap_drag = _param(d, "flap_drag", [0, 0.014, 0.038])
	var cd0 = float(_param(d, "cd", 0.03))
	var induced_k = float(_param(d, "induced_k", 0.065))
	var max_g = float(_param(d, "max_g", 7.0))
	var stall_speed = float(_param(d, "stall_speed", 60.0))
	var max_speed = float(_param(d, "max_speed", 300.0))
	var flaps = int(body.flight_controls.flaps)
	if flaps < 0 or flaps > 2:
		flaps = 0
	# --- CL(AoA): linear -> smooth critical -> progressive post-stall plateau ---
	var cl_linear = cl0 + flap_lift[flaps] + slope * aoa
	var abs_aoa = abs(aoa)
	var cl = cl_linear
	if abs_aoa > crit:
		var excess = abs_aoa - crit
		var s = 1.0 if aoa >= 0 else -1.0
		var cl_crit = cl0 + flap_lift[flaps] + slope * crit * s
		# Flat-plate contribution keeps some lift at very high alpha (cobra/high-alpha),
		# decaying to ~0 near 90 deg where the wing is fully blanked.
		var flat = sin(2.0 * aoa) * 0.85
		var decayed = cl_crit * exp(-excess / stall_w) * post_lift / max(0.2, post_lift)
		# Blend: mostly decayed linear + partial flat plate, preserves post-stall control.
		cl = (decayed + flat * (1.0 - exp(-excess / stall_w)) * 0.7)
		cl = clamp(cl, -1.35, 1.75)
	else:
		cl = clamp(cl, -1.2, 1.65)
	stall_amount = clamp((abs_aoa - crit) / stall_w, 0.0, 1.0)
	stalled = abs_aoa > crit or speed < stall_speed * (1.0 - 0.07 * flaps)
	q = 0.5 * rho * speed * speed
	var v_norm = v / max(speed, 0.001) if speed > 0.5 else -basis.z
	var lift_dir = basis.y - v_norm * basis.y.dot(v_norm)
	if lift_dir.length_squared() < 0.0001:
		lift_dir = basis.y
	else:
		lift_dir = lift_dir.normalized()
	var lift_mag = q * float(_param(d, "area", 30.0)) * cl * body.damage.lift_factor()
	lift_mag = clamp(lift_mag, -d.mass * 9.81 * 3.0, d.mass * 9.81 * max_g * 1.15)
	# --- CD(AoA, Mach): parasite + flap + gear + induced + separation + wave + airbrake ---
	var cd = cd0 + flap_drag[flaps]
	if body.landing.gear_down:
		cd += 0.022
	cd += cl * cl * induced_k
	if stall_amount > 0.0:
		cd += 0.09 * stall_amount
	# Transonic wave drag peak near Mach 1 (all aircraft, stronger for Su-27).
	var wave_amp = 0.035 if d.id == "su27" else 0.022
	cd += wave_amp * exp(-pow((mach - 1.0) / 0.23, 2))
	if body.airbrake:
		cd += 0.045
	var drag_mag = q * float(_param(d, "area", 30.0)) * cd
	if speed > max_speed:
		drag_mag += (speed - max_speed) * d.mass * 0.6
	# --- Thrust along nose, altitude lapse, afterburner for Su-27 ---
	var ab = 1.0
	if d.id == "su27" and body.throttle > 0.95:
		ab = 1.12
	var thrust_mag = float(_param(d, "thrust", 20000.0)) * body.throttle * ab * body.damage.zones.engine * sqrt(rho / 1.225)
	var thrust = -basis.z * thrust_mag
	# --- Side force: weathervane stability, damped at very high AoA ---
	var side_k = 0.8 * exp(-max(0.0, abs_aoa - crit) * 1.2)
	var side_force = -basis.x * clamp(q * float(_param(d, "area", 30.0)) * sideslip * side_k, -d.mass * 20.0, d.mass * 20.0)
	var force = thrust + lift_dir * lift_mag - v_norm * drag_mag + side_force
	var mass_eff = d.mass * (0.9 + 0.1 * fuel)
	var acceleration = force / mass_eff + Vector3(0, -9.81, 0)
	state.linear_velocity = v + acceleration * dt
	g_force = lerp(g_force, force.dot(basis.y) / (d.mass * 9.81), 0.12)
	# --- Rotation: dynamic-pressure authority + inertia (angular momentum) ---
	var q_stall = 0.5 * 1.225 * stall_speed * stall_speed
	var q_norm = clamp(q / max(q_stall * 2.2, 1.0), 0.0, 1.3)
	var authority = clamp(q_norm, 0.15, 1.0)
	# Su-27 keeps nose authority deep into post-stall with power on (no scripted cobra).
	var cobra = d.id == "su27"
	if cobra and abs_aoa > crit and body.throttle > 0.7 and speed > 55.0 and speed < 320.0:
		authority = max(authority, 0.55)
	elif abs_aoa > crit + 0.35:
		authority = max(authority, float(_param(d, "post_stall_control", 0.28)))
	var g_rate = max_g * 9.81 / max(speed, 20.0)
	var pitch_rate = float(_param(d, "pitch_rate", 0.8))
	var roll_rate = float(_param(d, "roll_rate", 1.4))
	var yaw_rate = float(_param(d, "yaw_rate", 0.4))
	var rates = Vector3(control.x * pitch_rate, control.y * pitch_rate, control.z * roll_rate)
	# Limit each axis independently. The old shared scale used yaw's tiny
	# high-speed limit to suppress elevator and aileron input as well.
	var manual_elevator=body.player and abs(body.manual_pitch)>0.01
	var pitch_limit=pitch_rate if manual_elevator else min(pitch_rate,g_rate)
	# With direct elevator the pilot can briefly exceed the sustained G envelope;
	# aerodynamic force and drag still determine the energy loss and stall.
	rates.x=clamp(rates.x,-pitch_limit,pitch_limit)
	rates.y=clamp(rates.y,-yaw_rate,yaw_rate)
	rates.z=clamp(rates.z,-roll_rate,roll_rate)
	rates.x*=authority
	rates.y*=authority
	rates.z*=authority
	rates.x *= 0.25 + body.damage.zones.tail * 0.75
	rates.y *= 0.2 + body.damage.zones.tail * 0.8
	rates.z *= body.damage.lift_factor()
	rates.z += (body.damage.zones.left_wing - body.damage.zones.right_wing) * 0.6
	# Lower angular lerp = more inertia / momentum carried through loops and tailslides.
	var agility = 5.0 if speed > stall_speed * 1.4 else 3.2
	state.angular_velocity = state.angular_velocity.linear_interpolate(basis.xform(rates), min(1.0, dt * agility))
