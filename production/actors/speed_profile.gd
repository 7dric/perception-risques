class_name SpeedProfile
extends RefCounted
## Scripted speed of a vehicle along its path: a list of phases with a constant
## acceleration, integrated once at the frame rate. Distance and speed are then read per
## frame, so the motion is identical on every render.

const FPS := 30.0

## Each phase: [duration (s), acceleration (m/s²)]. The last speed is held afterwards.
var _phases: Array = []
var _v0 := 0.0
var _distance: PackedFloat32Array = []
var _speed: PackedFloat32Array = []


func _init(initial_speed: float) -> void:
	_v0 = initial_speed


func phase(duration: float, accel: float) -> SpeedProfile:
	_phases.append([duration, accel])
	return self


## Integrates the phases over [param frames] frames (semi-implicit, exact for constant
## acceleration when evaluated at frame boundaries). The speed never goes below zero.
func bake(frames: int) -> SpeedProfile:
	_distance.resize(frames)
	_speed.resize(frames)
	var dt := 1.0 / FPS
	var s := 0.0
	var v := _v0
	for f in frames:
		_distance[f] = s
		_speed[f] = v
		var a := _accel_at(f * dt)
		var v_next := maxf(v + a * dt, 0.0)
		s += (v + v_next) * 0.5 * dt
		v = v_next
	return self


func _accel_at(t: float) -> float:
	var t0 := 0.0
	for p in _phases:
		if t < t0 + p[0]:
			return p[1]
		t0 += p[0]
	return 0.0


## Distance travelled (m) at frame [param f]; negative frames extrapolate at the start speed.
func distance(f: int) -> float:
	if f < 0:
		return _v0 * f / FPS
	return _distance[mini(f, _distance.size() - 1)]


func speed(f: int) -> float:
	return _speed[clampi(f, 0, _speed.size() - 1)]
