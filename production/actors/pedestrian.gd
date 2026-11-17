class_name Pedestrian
extends Node3D
## A pedestrian following a [Timeline]. Until the realistic models are integrated (J1, after
## the reference look is approved), the body is a simple placeholder.

## Placeholder: height of the person (m) and clothing colours.
var height := 1.75
var top_color := Color(0.2, 0.25, 0.35)
var bottom_color := Color(0.15, 0.15, 0.17)
var timeline: Timeline
## Fixed facing (yaw towards this horizontal direction) used when standing still.
var idle_facing := Vector3.FORWARD

var _body: Node3D


func setup(p_timeline: Timeline, rng: RandomNumberGenerator) -> void:
	timeline = p_timeline
	height = rng.randf_range(1.62, 1.88)
	var tops := [Color(0.18, 0.24, 0.36), Color(0.45, 0.12, 0.12), Color(0.2, 0.32, 0.2), Color(0.75, 0.72, 0.65), Color(0.12, 0.12, 0.13)]
	top_color = tops[rng.randi() % tops.size()]
	bottom_color = [Color(0.12, 0.14, 0.2), Color(0.25, 0.22, 0.18), Color(0.1, 0.1, 0.1)][rng.randi() % 3]
	_build_placeholder()


func _build_placeholder() -> void:
	_body = Node3D.new()
	_body.name = "Placeholder"
	add_child(_body)
	var legs := MeshInstance3D.new()
	var legs_mesh := CapsuleMesh.new()
	legs_mesh.radius = 0.16
	legs_mesh.height = height * 0.52
	legs.mesh = legs_mesh
	legs.position.y = height * 0.26
	legs.material_override = Pbr.paint(bottom_color, 0.8)
	_body.add_child(legs)
	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.21
	torso_mesh.height = height * 0.42
	torso.mesh = torso_mesh
	torso.position.y = height * 0.64
	torso.scale = Vector3(1.0, 1.0, 0.65)
	torso.material_override = Pbr.paint(top_color, 0.8)
	_body.add_child(torso)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.11
	head_mesh.height = 0.24
	head.mesh = head_mesh
	head.position.y = height * 0.93
	head.material_override = Pbr.paint(Color(0.78, 0.6, 0.5), 0.7)
	_body.add_child(head)


## Places the pedestrian at time [param t] (seconds since the start of the clip).
func pose_at(t: float) -> void:
	position = timeline.position_at(t)
	var heading := timeline.heading_at(t)
	if heading == Vector3.ZERO:
		heading = idle_facing
	rotation.y = atan2(-heading.x, -heading.z)
	# Small vertical bob while walking, so the placeholder does not glide.
	var walking := timeline.heading_at(t) != Vector3.ZERO
	_body.position.y = absf(sin(t * TAU * 0.9)) * 0.03 if walking else 0.0
