class_name Timeline
extends RefCounted
## Piecewise-linear motion: a list of (time in s, position) keys. Actors are pure functions
## of time, so a render can start at any frame and two renders give the same motion.

var times: PackedFloat32Array = []
var points: PackedVector3Array = []


func add(t: float, p: Vector3) -> Timeline:
	assert(times.is_empty() or t >= times[-1], "Timeline keys must be in time order")
	times.append(t)
	points.append(p)
	return self


## Adds a key reached by walking in a straight line from the last key at [param speed] m/s.
func walk_to(p: Vector3, speed: float) -> Timeline:
	return add(times[-1] + points[-1].distance_to(p) / speed, p)


## Stays at the last position for [param duration] seconds.
func wait(duration: float) -> Timeline:
	return add(times[-1] + duration, points[-1])


func end_time() -> float:
	return times[-1]


func position_at(t: float) -> Vector3:
	if t <= times[0]:
		return points[0]
	for i in range(1, times.size()):
		if t <= times[i]:
			var span := times[i] - times[i - 1]
			var w := 0.0 if span <= 0.0 else (t - times[i - 1]) / span
			return points[i - 1].lerp(points[i], w)
	return points[-1]


## Horizontal direction of motion at time [param t] (zero when standing still).
func heading_at(t: float) -> Vector3:
	for i in range(1, times.size()):
		if t < times[i]:
			var d := points[i] - points[i - 1]
			d.y = 0.0
			return d.normalized() if d.length() > 0.001 else Vector3.ZERO
	return Vector3.ZERO


## Time at which the actor first crosses the plane x = [param x] (or -1 if never).
func time_at_x(x: float) -> float:
	for i in range(1, times.size()):
		var a := points[i - 1].x
		var b := points[i].x
		if (a - x) * (b - x) <= 0.0 and a != b:
			return lerpf(times[i - 1], times[i], (x - a) / (b - a))
	return -1.0
