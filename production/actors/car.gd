class_name Car
extends Node3D
## A car: a realistic model from CarLibrary when the pack is downloaded, otherwise a
## placeholder body. Origin: middle of the front bumper on the ground, facing -Z.

const LENGTH := 4.3   ## placeholder length, also the default spacing
const WIDTH := 1.8

## Car colours on Belgian roads: [name, weight, colour (sRGB), metallic]. Weights follow the
## usual European fleet (grey, black and white dominate), rare colours keep some variety.
const PAINTS := [
	["gris", 22.0, Color(0.36, 0.37, 0.39), true],
	["gris foncé", 10.0, Color(0.17, 0.18, 0.19), true],
	["argent", 10.0, Color(0.66, 0.67, 0.69), true],
	["noir", 17.0, Color(0.025, 0.025, 0.03), true],
	["blanc", 17.0, Color(0.86, 0.87, 0.87), false],
	["bleu foncé", 9.0, Color(0.05, 0.09, 0.24), true],
	["bleu", 3.0, Color(0.16, 0.33, 0.62), false],
	["rouge", 6.0, Color(0.5, 0.04, 0.04), false],
	["bordeaux", 2.0, Color(0.27, 0.03, 0.05), true],
	["beige", 2.0, Color(0.55, 0.47, 0.36), true],
	["vert", 1.5, Color(0.1, 0.22, 0.15), true],
	["jaune", 0.5, Color(0.85, 0.65, 0.08), false],
]

var paint := Color(0.5, 0.5, 0.5)
var paint_name := ""
## Real size of this car (m).
var length := LENGTH
var width := WIDTH
var height := 1.45
var model_name := "placeholder"


func setup(rng: RandomNumberGenerator, with_collision: bool) -> void:
	var p: Array = pick_paint(rng)
	paint_name = p[0]
	paint = p[2]
	if CarLibrary.available():
		var m := CarLibrary.pick(rng)
		model_name = m.name
		var body := (m.template as Node3D).duplicate()
		add_child(body)
		if m.paint:
			apply_paint(body, m, p)
		width = m.size.x
		height = m.size.y
		length = m.size.z
	else:
		_build_placeholder(p)
	if with_collision:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(width, height, length)
		shape.shape = bs
		shape.position = Vector3(0, height / 2.0, length / 2.0)
		body.add_child(shape)
		add_child(body)


## Weighted pick in PAINTS.
static func pick_paint(rng: RandomNumberGenerator) -> Array:
	var total := 0.0
	for p in PAINTS:
		total += p[1]
	var r := rng.randf() * total
	for p in PAINTS:
		r -= p[1]
		if r <= 0.0:
			return p
	return PAINTS[-1]


## Replaces the body material of every surface that uses it by paint [param p] (a PAINTS
## entry). [param body] is an instance of the template of model [param m] (CarLibrary).
static func apply_paint(body: Node3D, m: Dictionary, p: Array) -> void:
	var mat := (m.paint as ShaderMaterial).duplicate() as ShaderMaterial
	mat.set_shader_parameter("paint", p[2])
	mat.set_shader_parameter("paint_metallic", 0.7 if p[3] else 0.0)
	mat.set_shader_parameter("paint_roughness", 0.32 if p[3] else 0.22)
	mat.set_shader_parameter("paint_clearcoat", 0.8)
	var body_mats: Array = m.body_materials
	for mi: MeshInstance3D in body.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			if mi.mesh.surface_get_material(i) in body_mats:
				mi.set_surface_override_material(i, mat)


func _build_placeholder(p: Array) -> void:
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = p[2]
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


func _box(size: Vector3, center: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = center
	mi.material_override = mat
	add_child(mi)
