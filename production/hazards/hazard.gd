class_name Hazard
extends Node3D
## A hazard (or a decoy, see ADR-011) attached to an actor. Its clickable zone is a box in
## the actor's local space; the AnnotationRecorder projects it on screen at every frame.
## Types and tags come from docs/hazard-catalog.md (closed lists, ADR-017).

var hazard_id := "h1"
var type := "pedestrian_crossing"
var is_decoy := false
var tags: PackedStringArray = []
var label_fr := ""
var explanation_fr := ""
## Frames during which a click counts, and the ideal click frame (D3). Unused for decoys.
var window_start := 0
var window_end := 0
var ideal_frame := 0
## Clickable box, local to this node: centre and size (metres).
var box_center := Vector3(0, 0.9, 0)
var box_size := Vector3(0.7, 1.8, 0.7)


## The 8 corners of the clickable box in world space.
func world_corners() -> PackedVector3Array:
	var out := PackedVector3Array()
	var h := box_size / 2.0
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				out.append(global_transform * (box_center + Vector3(sx * h.x, sy * h.y, sz * h.z)))
	return out


## Points used to test occlusion: the box centre and its corners pulled 20 % inwards.
func occlusion_samples() -> PackedVector3Array:
	var center := global_transform * box_center
	var out := PackedVector3Array([center])
	for c in world_corners():
		out.append(c.lerp(center, 0.2))
	return out


## Fields of the annotation JSON, without the tracks.
func describe() -> Dictionary:
	var d := {"id": hazard_id, "type": type}
	if is_decoy:
		d["explanation"] = {"fr": explanation_fr}
		return d
	if not tags.is_empty():
		d["tags"] = Array(tags)
	d["label"] = {"fr": label_fr}
	d["explanation"] = {"fr": explanation_fr}
	d["window"] = {"startFrame": window_start, "endFrame": window_end}
	d["idealFrame"] = ideal_frame
	return d
