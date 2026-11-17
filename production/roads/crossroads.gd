class_name Crossroads
extends Node3D
## Urban crossroads built from code: a main street along Z (the learner drives towards -Z)
## crossed by a side street along X at z = 0. Each street has two lanes, a parking lane on
## each side, raised sidewalks and terraced houses.
##
## Cross-section from the axis: lane (LANE) | parking (PARKING) | sidewalk (SIDEWALK) | facade.

const LANE := 3.25
const PARKING := 2.0
const SIDEWALK := 2.6
const CURB_H := 0.14
const CURB_W := 0.15
const ROAD_HALF := LANE + PARKING           ## 5.25 m: asphalt half-width
const FACADE := ROAD_HALF + SIDEWALK        ## 7.85 m: facade line
const MAIN_FROM := -140.0                   ## main street extent along Z
const MAIN_TO := 240.0
const SIDE_EXTENT := 120.0                  ## side street extent along X (each side)

## Pedestrian crossing on the main street, before the crossroads (learner's side).
const CROSSWALK_Z := ROAD_HALF + 3.5        ## centre of the zebra
const CROSSWALK_W := 4.0                    ## zebra depth along Z
const STOP_LINE_Z := CROSSWALK_Z + CROSSWALK_W / 2.0 + 1.5

var _white: Material
## World positions of the street lamp heads (lit at night by Conditions).
var lamp_heads: Array[Vector3] = []


func build(rng: RandomNumberGenerator) -> void:
	_white = Pbr.paint(Color(0.86, 0.86, 0.84), 0.75)
	_build_ground()
	_build_markings()
	_build_houses(rng)
	_build_furniture(rng)


# --- Ground -----------------------------------------------------------------------------

func _build_ground() -> void:
	var asphalt := Pbr.material("asphalt_02", 3.0)
	var pavers := Pbr.material("square_concrete_pavers", 2.0)
	var curb := Pbr.material("granular_concrete", 1.5, Color(0.85, 0.85, 0.85))
	var main_len := MAIN_TO - MAIN_FROM
	var main_mid := (MAIN_TO + MAIN_FROM) / 2.0
	var side_len := SIDE_EXTENT - ROAD_HALF
	var side_mid := (SIDE_EXTENT + ROAD_HALF) / 2.0
	# Asphalt: main street in one piece, side street in two pieces (no overlap, no z-fighting).
	_box(Vector3(ROAD_HALF * 2, 0.1, main_len), Vector3(0, -0.05, main_mid), asphalt)
	for sx: float in [-1.0, 1.0]:
		_box(Vector3(side_len, 0.1, ROAD_HALF * 2), Vector3(sx * side_mid, -0.05, 0), asphalt)
	# Sidewalks and curbs, one L-shaped corner per quadrant.
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var z_end := MAIN_TO if sz > 0 else MAIN_FROM
			var z_len := absf(z_end) - ROAD_HALF
			var z_mid := sz * (ROAD_HALF + z_len / 2.0)
			var x_len := SIDE_EXTENT - FACADE
			var x_mid := sx * (FACADE + x_len / 2.0)
			# Along the main street (covers the corner square).
			_box(Vector3(SIDEWALK, CURB_H, z_len), Vector3(sx * (ROAD_HALF + SIDEWALK / 2.0), CURB_H / 2.0, z_mid), pavers)
			_box(Vector3(CURB_W, CURB_H + 0.01, z_len), Vector3(sx * (ROAD_HALF + CURB_W / 2.0), CURB_H / 2.0 + 0.005, z_mid), curb)
			# Along the side street.
			_box(Vector3(x_len, CURB_H, SIDEWALK), Vector3(x_mid, CURB_H / 2.0, sz * (ROAD_HALF + SIDEWALK / 2.0)), pavers)
			_box(Vector3(x_len + SIDEWALK, CURB_H + 0.01, CURB_W), Vector3(sx * (ROAD_HALF + (x_len + SIDEWALK) / 2.0), CURB_H / 2.0 + 0.005, sz * (ROAD_HALF + CURB_W / 2.0)), curb)


# --- Markings ---------------------------------------------------------------------------

func _build_markings() -> void:
	# Main street: dashed centre line (3 m line, 9 m gap) outside the crossroads.
	_dashes(Vector3(0, 0, 1), MAIN_FROM, -ROAD_HALF - 2.0, 0.0, 0.12, 3.0, 9.0)
	_dashes(Vector3(0, 0, 1), STOP_LINE_Z + 1.0, MAIN_TO, 0.0, 0.12, 3.0, 9.0)
	# Parking lanes: dashed separation lines.
	for sx: float in [-1.0, 1.0]:
		_dashes(Vector3(0, 0, 1), STOP_LINE_Z + 1.0, MAIN_TO, sx * LANE, 0.1, 1.0, 1.0)
		_dashes(Vector3(0, 0, 1), MAIN_FROM, -ROAD_HALF - 2.0, sx * LANE, 0.1, 1.0, 1.0)
	# Zebra crossing: bands parallel to the traffic, 0.5 m wide every metre.
	var x := -ROAD_HALF + 0.5
	while x < ROAD_HALF - 0.25:
		_mark(Vector2(0.5, CROSSWALK_W), Vector3(x + 0.25, 0, CROSSWALK_Z))
		x += 1.0
	# Stop line for the learner's lane.
	_mark(Vector2(LANE, 0.3), Vector3(LANE / 2.0, 0, STOP_LINE_Z))
	# Side street: shark teeth (give way) on both approaches.
	for sx: float in [-1.0, 1.0]:
		var tz := -LANE / 2.0 if sx < 0 else LANE / 2.0
		for k in 6:
			_tooth(Vector3(sx * (ROAD_HALF + 1.0), 0, tz - LANE / 2.0 + 0.27 + k * 0.54), sx)


func _dashes(dir: Vector3, from: float, to: float, offset: float, width: float, line: float, gap: float) -> void:
	var z := from
	while z + line <= to:
		_mark(Vector2(width, line), Vector3(offset, 0, z + line / 2.0))
		z += line + gap


func _mark(size: Vector2, center: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = size
	mi.mesh = plane
	mi.position = center + Vector3(0, 0.004, 0)
	mi.material_override = _white
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _tooth(center: Vector3, sx: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base := 0.25
	var length := 0.5 * sx
	for v in [Vector3(0, 0, -base), Vector3(length, 0, 0), Vector3(0, 0, base)]:
		st.set_normal(Vector3.UP)
		st.add_vertex(center + v + Vector3(0, 0.004, 0))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _white
	(mi.material_override as BaseMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	add_child(mi)


# --- Houses and furniture ---------------------------------------------------------------

func _build_houses(rng: RandomNumberGenerator) -> void:
	var houses := Node3D.new()
	houses.name = "Houses"
	add_child(houses)
	var gap := 0.1
	for sx: float in [-1.0, 1.0]:
		var facing := Vector3(-sx, 0, 0)
		# Main street, south part (z > 0) and north part (z < 0). Rows go "to the right".
		if sx < 0:
			FacadeKit.build_row(houses, Vector3(-FACADE, 0, FACADE + gap), facing, MAIN_TO - FACADE, rng)
			FacadeKit.build_row(houses, Vector3(-FACADE, 0, MAIN_FROM), facing, -MAIN_FROM - FACADE, rng)
		else:
			FacadeKit.build_row(houses, Vector3(FACADE, 0, MAIN_TO), facing, MAIN_TO - FACADE, rng)
			FacadeKit.build_row(houses, Vector3(FACADE, 0, -FACADE - gap), facing, -MAIN_FROM - FACADE, rng)
	for sz: float in [-1.0, 1.0]:
		var facing := Vector3(0, 0, -sz)
		if sz > 0:
			FacadeKit.build_row(houses, Vector3(FACADE + gap + FacadeKit.DEPTH, 0, FACADE), facing, SIDE_EXTENT - FACADE - FacadeKit.DEPTH, rng)
			FacadeKit.build_row(houses, Vector3(-SIDE_EXTENT, 0, FACADE), facing, SIDE_EXTENT - FACADE - FacadeKit.DEPTH, rng)
		else:
			FacadeKit.build_row(houses, Vector3(SIDE_EXTENT, 0, -FACADE), facing, SIDE_EXTENT - FACADE - FacadeKit.DEPTH, rng)
			FacadeKit.build_row(houses, Vector3(-FACADE - gap - FacadeKit.DEPTH, 0, -FACADE), facing, SIDE_EXTENT - FACADE - FacadeKit.DEPTH, rng)


func _build_furniture(rng: RandomNumberGenerator) -> void:
	var lamp: PackedScene = load("res://assets/polyhaven/street_lamp_01/street_lamp_01.gltf")
	var bin: PackedScene = load("res://assets/polyhaven/metal_trash_can/metal_trash_can.gltf")
	var planter: PackedScene = load("res://assets/polyhaven/planter_box_01/planter_box_01.gltf")
	# Lamps every 24 m on both sides of the main street, 0.5 m behind the curb.
	for sx: float in [-1.0, 1.0]:
		var z := MAIN_FROM + 10.0 + (12.0 if sx > 0 else 0.0)
		while z < MAIN_TO:
			if absf(z) > FACADE + 2.0:
				_place(lamp, Vector3(sx * (ROAD_HALF + 0.5), CURB_H, z), PI / 2.0 * sx)
				lamp_heads.append(Vector3(sx * (ROAD_HALF + 0.5), CURB_H + 3.4, z))
			z += 24.0
	# A few bins and planters near the facades.
	for k in 10:
		var sx := -1.0 if rng.randf() < 0.5 else 1.0
		var z := rng.randf_range(FACADE + 4.0, 120.0) * (1.0 if rng.randf() < 0.75 else -0.5)
		var scene: PackedScene = bin if rng.randf() < 0.5 else planter
		_place(scene, Vector3(sx * (FACADE - 0.6), CURB_H, z), rng.randf_range(0, TAU), "rust")


func _place(scene: PackedScene, pos: Vector3, yaw: float, exclude := "") -> void:
	var node: Node3D = scene.instantiate()
	if exclude != "":
		# Poly Haven sometimes ships variants side by side in one file: drop the unwanted one.
		for mi in node.find_children("*%s*" % exclude, "Node3D", true, false):
			mi.free()
	node.position = pos
	node.rotation.y = yaw
	add_child(node)


func _box(size: Vector3, center: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = center
	mi.material_override = mat
	add_child(mi)
	return mi
