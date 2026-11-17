class_name Car
extends Node3D
## A car. Placeholder body (until the realistic models are integrated): lower body, cabin,
## wheels, lights. Origin: middle of the front bumper on the ground, facing -Z.

const LENGTH := 4.3
const WIDTH := 1.8

## Common car colours on Belgian roads.
const PAINTS := [
	Color(0.55, 0.56, 0.58), Color(0.06, 0.06, 0.07), Color(0.85, 0.85, 0.86),
	Color(0.12, 0.18, 0.32), Color(0.35, 0.36, 0.38), Color(0.45, 0.08, 0.08),
]

var paint := Color(0.5, 0.5, 0.5)


func setup(rng: RandomNumberGenerator, with_collision: bool) -> void:
	paint = PAINTS[rng.randi() % PAINTS.size()]
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = paint
	body_mat.metallic = 0.6
	body_mat.roughness = 0.3
	body_mat.clearcoat_enabled = true
	body_mat.clearcoat = 0.8
	var glass := Pbr.paint(Color(0.04, 0.05, 0.06), 0.05)
	var rubber := Pbr.paint(Color(0.03, 0.03, 0.03), 0.9)
	_box(Vector3(WIDTH, 0.7, LENGTH), Vector3(0, 0.55, LENGTH / 2.0), body_mat)
	_box(Vector3(WIDTH - 0.12, 0.55, 2.3), Vector3(0, 1.17, LENGTH / 2.0 + 0.3), glass)
	_box(Vector3(WIDTH - 0.2, 0.06, 2.0), Vector3(0, 1.47, LENGTH / 2.0 + 0.35), body_mat)
	for x in [-WIDTH / 2.0 + 0.12, WIDTH / 2.0 - 0.12]:
		for z in [0.85, LENGTH - 0.8]:
			var w := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.32
			cyl.bottom_radius = 0.32
			cyl.height = 0.22
			w.mesh = cyl
			w.rotation.z = PI / 2.0
			w.position = Vector3(x, 0.32, z)
			w.material_override = rubber
			add_child(w)
	if with_collision:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(WIDTH, 1.45, LENGTH)
		shape.shape = bs
		shape.position = Vector3(0, 0.75, LENGTH / 2.0)
		body.add_child(shape)
		add_child(body)


func _box(size: Vector3, center: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = center
	mi.material_override = mat
	add_child(mi)
