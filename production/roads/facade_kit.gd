class_name FacadeKit
## Assembles rows of terraced houses from the Poly Haven "modular urban apartments facade" kit.
## Kit conventions: each module is 3 m wide (local x from -3 to 0), the facade plane is z = 0
## and faces +z, walls are 3 m high. Windows and doors are separate meshes placed at the
## origin of their wall module.

const KIT := "res://assets/polyhaven/modular_urban_apartments_facade/modular_urban_apartments_facade.gltf"
const MODULE := 3.0
const STOREY := 3.5  ## wall (3 m) + band between floors (0.5 m)
const DEPTH := 9.0   ## depth of the building block behind the facade

## Wall textures used to tell houses apart (Poly Haven id, tile size in metres).
const BRICKS := [
	["red_brick_03", 2.0],
	["brown_brick_02", 2.0],
	["whitewashed_brick", 2.0],
	["red_brick_03", 2.0],
	["plaster_grey_04", 3.0],
]

## [wall mesh, filling mesh] per floor kind.
const GROUND := [
	["wall_door_centered_small_01", "door_centered_small_01"],
	["wall_window_centered_large_01", "window_centered_large_01"],
	["wall_window_centered_double_01", "window_centered_double_01"],
]
const UPPER := [
	["wall_window_centered_large_02", "window_centered_large_02"],
	["wall_window_centered_double_02", "window_centered_double_02"],
	["wall_window_centered_small_02", "window_centered_small_02"],
]
const TOP := [
	["wall_window_centered_large_03", "window_centered_large_03"],
	["wall_window_centered_double_03", "window_centered_double_03"],
	["wall_window_centered_small_03", "window_centered_small_03"],
]

static var _meshes: Dictionary = {}


static func _mesh(name: String) -> Mesh:
	if _meshes.is_empty():
		var scene: Node = (load(KIT) as PackedScene).instantiate()
		for n in scene.find_children("*", "MeshInstance3D", true, false):
			_meshes[n.name] = (n as MeshInstance3D).mesh
		scene.free()
	return _meshes[name]


## Builds a row of houses along the facade line starting at [param start], facing
## [param facing] (horizontal unit vector towards the street), [param length] metres long.
## The row extends to the right when seen from the street.
static func build_row(parent: Node3D, start: Vector3, facing: Vector3, length: float, rng: RandomNumberGenerator) -> void:
	var basis := Basis(Vector3.UP.cross(facing), Vector3.UP, facing)
	var along := -basis.x
	var modules := int(floor(length / MODULE))
	var i := 0
	while i < modules:
		var width := mini(rng.randi_range(2, 3), modules - i)
		var floors := rng.randi_range(3, 4)
		var brick: Array = BRICKS[rng.randi() % BRICKS.size()]
		var wall_mat := Pbr.material(brick[0], brick[1])
		var origin := start + along * (MODULE * i)
		_build_house(parent, Transform3D(basis, origin), width, floors, wall_mat, rng)
		i += width


static func _build_house(parent: Node3D, xf: Transform3D, width: int, floors: int, wall_mat: Material, rng: RandomNumberGenerator) -> void:
	var house := Node3D.new()
	house.name = "House"
	house.transform = xf
	parent.add_child(house)
	var upper: Array = UPPER[rng.randi() % UPPER.size()]
	var top: Array = TOP[rng.randi() % TOP.size()]
	var door_at := rng.randi() % width
	for m in width:
		var x := -MODULE * m
		for f in floors:
			var y := STOREY * f
			var kind: Array
			if f == 0:
				kind = GROUND[0] if m == door_at else GROUND[1 + rng.randi() % 2]
			elif f == floors - 1:
				kind = top
			else:
				kind = upper
			_add(house, kind[0], Vector3(x, y, 0), wall_mat)
			_add(house, kind[1], Vector3(x, y, 0))
			if f < floors - 1:
				_add(house, "dado_standard_standard_01", Vector3(x, y + 3.0, 0))
		_add(house, "base_standard_01", Vector3(x, 0, 0))
		var roof_y := STOREY * (floors - 1) + 3.0
		_add(house, "cornice_standard_standard_01", Vector3(x, roof_y, 0))
		_add(house, "crown_standard_standard_01", Vector3(x, roof_y + 0.2, 0))
	_add_block(house, MODULE * width, STOREY * (floors - 1) + 3.95)


static func _add(house: Node3D, mesh_name: String, pos: Vector3, override: Material = null) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _mesh(mesh_name)
	mi.position = pos
	if override:
		mi.set_surface_override_material(0, override)
	house.add_child(mi)


## Building volume behind the facade: hides the sky through gaps, gives SDFGI something to
## bounce on, and blocks the occlusion raycasts of the annotation recorder.
static func _add_block(house: Node3D, width: float, height: float) -> void:
	var size := Vector3(width, height, DEPTH)
	var center := Vector3(-width / 2.0, height / 2.0, -DEPTH / 2.0 - 0.05)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = center
	mi.material_override = Pbr.material("plaster_grey_04", 3.0, Color(0.55, 0.55, 0.55))
	house.add_child(mi)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size + Vector3(0, 0, 0.3)
	shape.shape = bs
	shape.position = center + Vector3(0, 0, 0.15)
	body.add_child(shape)
	house.add_child(body)
