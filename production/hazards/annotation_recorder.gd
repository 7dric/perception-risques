class_name AnnotationRecorder
extends Node
## Records where each hazard and decoy is on screen, frame by frame, and writes the clip
## annotation JSON (schema/clip.schema.json).
##
## For each view (windshield, mirrors) the hazard box is projected with the view camera.
## The outline is the screen-space bounding rectangle of the projected box: always 4 points,
## so the player can interpolate between keyframes (ADR-018). Mirror views are flipped
## horizontally and placed in their rectangle of the video frame.

## Maximum interpolation error (normalized units) when dropping keyframes.
const EPSILON := 0.003
## Share of occlusion rays that must reach the hazard for it to count as visible.
const MIN_VISIBLE_RAYS := 0.3
## Minimum on-screen area (normalized) of a visible outline.
const MIN_AREA := 0.00002

## View name -> {"camera": Camera3D, "rect": Rect2 (normalized), "mirrored": bool}
var views: Dictionary = {}
## Screen rectangles drawn over the windshield (mirrors, dashboard): a windshield outline
## whose centre falls inside one of them is not clickable there.
var overlays: Array[Rect2] = []
var hazards: Array[Hazard] = []

## hazard id -> view name -> Array (one entry per frame: PackedVector2Array, empty = hidden)
var _samples: Dictionary = {}
var _frames := 0


func add(hazard: Hazard) -> void:
	hazards.append(hazard)
	_samples[hazard.hazard_id] = {}
	for v in views:
		_samples[hazard.hazard_id][v] = []


## Call once per simulation frame, after every actor has been placed.
func capture() -> void:
	var space := (views.windshield.camera as Camera3D).get_world_3d().direct_space_state
	for h in hazards:
		for v in views:
			_samples[h.hazard_id][v].append(_outline(h, views[v], v == "windshield", space))
	_frames += 1


func _outline(h: Hazard, view: Dictionary, is_windshield: bool, space: PhysicsDirectSpaceState3D) -> PackedVector2Array:
	var cam: Camera3D = view.camera
	var size := Vector2(cam.get_viewport().get_visible_rect().size)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for c in h.world_corners():
		if cam.is_position_behind(c):
			return PackedVector2Array()
		var p := cam.unproject_position(c) / size
		lo = lo.min(p)
		hi = hi.max(p)
	lo = lo.clamp(Vector2.ZERO, Vector2.ONE)
	hi = hi.clamp(Vector2.ZERO, Vector2.ONE)
	if (hi.x - lo.x) * (hi.y - lo.y) < MIN_AREA or not _visible(h, cam, space):
		return PackedVector2Array()
	if view.mirrored:
		var flipped_lo := 1.0 - hi.x
		hi.x = 1.0 - lo.x
		lo.x = flipped_lo
	var r: Rect2 = view.rect
	lo = r.position + lo * r.size
	hi = r.position + hi * r.size
	if is_windshield:
		var center := (lo + hi) / 2.0
		for o in overlays:
			if o.has_point(center):
				return PackedVector2Array()
	return PackedVector2Array([lo, Vector2(hi.x, lo.y), hi, Vector2(lo.x, hi.y)])


func _visible(h: Hazard, cam: Camera3D, space: PhysicsDirectSpaceState3D) -> bool:
	var samples := h.occlusion_samples()
	var free := 0
	for s in samples:
		var q := PhysicsRayQueryParameters3D.create(cam.global_position, s)
		if space.intersect_ray(q).is_empty():
			free += 1
	return float(free) / samples.size() >= MIN_VISIBLE_RAYS


## Builds the annotation dictionary. [param header] holds the clip-level fields
## (schemaVersion, id, title, kind, generation, conditions, video).
func build(header: Dictionary) -> Dictionary:
	var out := header.duplicate(true)
	var rects := {}
	for v in views:
		var r: Rect2 = views[v].rect
		rects[v] = {"x": _r(r.position.x), "y": _r(r.position.y), "w": _r(r.size.x), "h": _r(r.size.y)}
	out["views"] = rects
	var hz := []
	var dc := []
	for h in hazards:
		var d := h.describe()
		d["tracks"] = _tracks(h)
		(dc if h.is_decoy else hz).append(d)
	out["hazards"] = hz
	out["decoys"] = dc
	return out


func _tracks(h: Hazard) -> Array:
	var tracks := []
	for v in views:
		var keys := compress(_samples[h.hazard_id][v])
		if not keys.is_empty():
			tracks.append({"view": v, "keyframes": keys})
	if tracks.is_empty():
		tracks.append({"view": "windshield", "keyframes": [{"frame": 0, "visible": false}]})
	return tracks


## Turns per-frame outlines into keyframes: a keyframe at the start of each visible span,
## then only where linear interpolation would drift by more than EPSILON, and a
## "visible": false keyframe where a span ends before the end of the clip.
static func compress(seq: Array) -> Array:
	var out := []
	var i := 0
	var n := seq.size()
	while i < n:
		if (seq[i] as PackedVector2Array).is_empty():
			i += 1
			continue
		var start := i
		while i < n and not (seq[i] as PackedVector2Array).is_empty():
			i += 1
		for k in _simplify(seq, start, i - 1):
			out.append({"frame": k, "polygon": _points(seq[k])})
		if i < n:
			out.append({"frame": i, "visible": false})
	return out


static func _simplify(seq: Array, start: int, end: int) -> PackedInt32Array:
	var keys := PackedInt32Array([start])
	var a := start
	var j := a + 2
	while j <= end:
		if _max_error(seq, a, j) > EPSILON:
			a = j - 1
			keys.append(a)
		j += 1
	if keys[-1] != end:
		keys.append(end)
	return keys


static func _max_error(seq: Array, a: int, b: int) -> float:
	var pa: PackedVector2Array = seq[a]
	var pb: PackedVector2Array = seq[b]
	var worst := 0.0
	for k in range(a + 1, b):
		var w := float(k - a) / (b - a)
		var pk: PackedVector2Array = seq[k]
		for p in pk.size():
			var d := (pa[p].lerp(pb[p], w) - pk[p]).abs()
			worst = maxf(worst, maxf(d.x, d.y))
	return worst


static func _points(poly: PackedVector2Array) -> Array:
	var out := []
	for p in poly:
		out.append([_r(p.x), _r(p.y)])
	return out


static func _r(x: float) -> float:
	return snappedf(x, 0.0001)


## Frames of the hazard's window where it is visible in no view (should be 0: a hazard
## must be clickable during its whole window, docs/hazard-catalog.md rule 1).
func hidden_in_window(h: Hazard) -> int:
	var hidden := 0
	for f in range(h.window_start, mini(h.window_end + 1, _frames)):
		var seen := false
		for v in views:
			if not (_samples[h.hazard_id][v][f] as PackedVector2Array).is_empty():
				seen = true
				break
		if not seen:
			hidden += 1
	return hidden


func frame_count() -> int:
	return _frames
