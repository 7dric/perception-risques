class_name Crossroads
extends Node3D
## Crossroads built from code: a main street along Z (the learner drives towards -Z) crossed
## by a side street along X at z = 0. Each street has two lanes, a parking lane on each side,
## raised sidewalks and houses. This class is the urban crossroads (environment "urban");
## ResidentialCrossroads changes the dimensions, the markings and the houses.
##
## Cross-section from the axis: lane | parking | sidewalk | front yard | facade.
## Dimensions are instance properties (set in _init by each kind of street) so that scenarios
## read them from the world they built (world.road_half...).

const CURB_H := 0.14
const CURB_W := 0.15
const MAIN_FROM := -140.0                   ## main street extent along Z
const MAIN_TO := 240.0
const SIDE_EXTENT := 120.0                  ## side street extent along X (each side)
const CROSSWALK_W := 4.0                    ## zebra depth along Z

## Environment of the annotation JSON (schema: conditions.environment).
var environment := "urban"
var lane := 3.25
var parking := 2.0
var sidewalk := 2.6
## Front garden between the sidewalk and the facades (0: houses on the sidewalk).
var front_yard := 0.0
## Share of the parking slots taken (drawn from the seed in build()).
var parking_density := 0.8
## Markings and signs of an urban crossroads.
var has_zebra := true
var has_centre_line := true
var has_parking_lines := true
## Side street gives way (shark teeth); false: no markings, priority to the right.
var has_give_way := true
## Houses: FacadeKit style (see FacadeKit.build_row).
var house_style := {}
## Trees along the main street: probability of a tree every TREE_STEP metres.
var tree_chance := 0.0
var lamp_model := "street_lamp_01"
var lamp_step := 24.0
var lamp_height := 3.4

var road_half: float         ## asphalt half-width
var facade: float            ## facade line (distance from the axis)
var crosswalk_z: float       ## centre of the pedestrian crossing (learner's side)
var stop_line_z: float

var _white: Material
## World positions of the street lamp heads (lit at night by Conditions).
var lamp_heads: Array[Vector3] = []
## Main street stretches without trees (z ranges), e.g. where a hazard must stay visible.
var tree_free: Array[Vector2] = []

const TREE_STEP := 12.0


func _init() -> void:
	house_style = {
		"floors": [3, 4],
		"walls": [
			["red_brick_03", 2.0], ["brown_brick_02", 2.0], ["whitewashed_brick", 2.0],
			["red_bricks_04", 2.0], ["large_red_bricks", 2.0],
			["beige_wall_001", 3.0], ["plaster_grey_04", 3.0],
		],
		"roof": "flat",
	}
	update_dimensions()


## Derived dimensions; called by _init of each kind of street, readable before build().
func update_dimensions() -> void:
	road_half = lane + parking
	facade = road_half + sidewalk + front_yard
	crosswalk_z = road_half + 3.5
	stop_line_z = crosswalk_z + CROSSWALK_W / 2.0 + 1.5


## Builds everything. Call after add_child (materials need the tree only for lights).
func build(rng: RandomNumberGenerator) -> void:
	update_dimensions()
	parking_density = rng.randf_range(0.6, 0.9) if environment == "urban" else rng.randf_range(0.35, 0.65)
	tree_chance = rng.randf_range(0.0, 0.5) if environment == "urban" else tree_chance
	_white = Pbr.paint(Color(0.86, 0.86, 0.84), 0.75)
	_build_ground()
	_build_markings()
	_build_front_yards(rng)
	_build_houses(rng)
	_build_furniture(rng)
	_build_trees(rng)


## Main street pedestrian-free zone for trees (hazard visibility); call before build().
func keep_clear(z_from: float, z_to: float) -> void:
	tree_free.append(Vector2(minf(z_from, z_to), maxf(z_from, z_to)))


# --- Ground -----------------------------------------------------------------------------

func _build_ground() -> void:
	var asphalt := Pbr.material("asphalt_02", 3.0)
	var pavers := Pbr.material("square_concrete_pavers", 2.0)
	var curb := Pbr.material("granular_concrete", 1.5, Color(0.85, 0.85, 0.85))
	var main_len := MAIN_TO - MAIN_FROM
	var main_mid := (MAIN_TO + MAIN_FROM) / 2.0
	var side_len := SIDE_EXTENT - road_half
	var side_mid := (SIDE_EXTENT + road_half) / 2.0
	var walk := sidewalk + front_yard  # paved strip; gardens are laid on top of it
	# Asphalt: main street in one piece, side street in two pieces (no overlap, no z-fighting).
	_box(Vector3(road_half * 2, 0.1, main_len), Vector3(0, -0.05, main_mid), asphalt)
	for sx: float in [-1.0, 1.0]:
		_box(Vector3(side_len, 0.1, road_half * 2), Vector3(sx * side_mid, -0.05, 0), asphalt)
	# Sidewalks and curbs, one L-shaped corner per quadrant.
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var z_end := MAIN_TO if sz > 0 else MAIN_FROM
			var z_len := absf(z_end) - road_half
			var z_mid := sz * (road_half + z_len / 2.0)
			var x_len := SIDE_EXTENT - facade
			var x_mid := sx * (facade + x_len / 2.0)
			# Along the main street (covers the corner square).
			_box(Vector3(walk, CURB_H, z_len), Vector3(sx * (road_half + walk / 2.0), CURB_H / 2.0, z_mid), pavers)
			_box(Vector3(CURB_W, CURB_H + 0.01, z_len), Vector3(sx * (road_half + CURB_W / 2.0), CURB_H / 2.0 + 0.005, z_mid), curb)
			# Along the side street.
			_box(Vector3(x_len, CURB_H, walk), Vector3(x_mid, CURB_H / 2.0, sz * (road_half + walk / 2.0)), pavers)
			_box(Vector3(x_len + walk, CURB_H + 0.01, CURB_W), Vector3(sx * (road_half + (x_len + walk) / 2.0), CURB_H / 2.0 + 0.005, sz * (road_half + CURB_W / 2.0)), curb)


# --- Markings ---------------------------------------------------------------------------

func _build_markings() -> void:
	if has_centre_line:
		# Main street: dashed centre line (3 m line, 9 m gap) outside the crossroads.
		_dashes(MAIN_FROM, -road_half - 2.0, 0.0, 0.12, 3.0, 9.0)
		_dashes(stop_line_z + 1.0, MAIN_TO, 0.0, 0.12, 3.0, 9.0)
	if has_parking_lines:
		for sx: float in [-1.0, 1.0]:
			_dashes(stop_line_z + 1.0, MAIN_TO, sx * lane, 0.1, 1.0, 1.0)
			_dashes(MAIN_FROM, -road_half - 2.0, sx * lane, 0.1, 1.0, 1.0)
	if has_zebra:
		# Zebra crossing: bands parallel to the traffic, 0.5 m wide every metre.
		var x := -road_half + 0.5
		while x < road_half - 0.25:
			_mark(Vector2(0.5, CROSSWALK_W), Vector3(x + 0.25, 0, crosswalk_z))
			x += 1.0
		# Stop line for the learner's lane.
		_mark(Vector2(lane, 0.3), Vector3(lane / 2.0, 0, stop_line_z))
	if has_give_way:
		# Side street: shark teeth (give way) on both approaches.
		for sx: float in [-1.0, 1.0]:
			var tz := -lane / 2.0 if sx < 0 else lane / 2.0
			for k in 6:
				_tooth(Vector3(sx * (road_half + 1.0), 0, tz - lane / 2.0 + 0.27 + k * 0.54), sx)


func _dashes(from: float, to: float, offset: float, width: float, line: float, gap: float) -> void:
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


# --- Houses, gardens, furniture and trees ------------------------------------------------

## Front gardens (none in the urban street; see ResidentialCrossroads).
func _build_front_yards(_rng: RandomNumberGenerator) -> void:
	pass


func _build_houses(rng: RandomNumberGenerator) -> void:
	var houses := Node3D.new()
	houses.name = "Houses"
	add_child(houses)
	var gap := 0.1
	var depth := FacadeKit.DEPTH
	for sx: float in [-1.0, 1.0]:
		var facing := Vector3(-sx, 0, 0)
		# Main street, south part (z > 0) and north part (z < 0). Rows go "to the right".
		if sx < 0:
			FacadeKit.build_row(houses, Vector3(-facade, 0, facade + gap), facing, MAIN_TO - facade, rng, house_style)
			FacadeKit.build_row(houses, Vector3(-facade, 0, MAIN_FROM), facing, -MAIN_FROM - facade, rng, house_style)
		else:
			FacadeKit.build_row(houses, Vector3(facade, 0, MAIN_TO), facing, MAIN_TO - facade, rng, house_style)
			FacadeKit.build_row(houses, Vector3(facade, 0, -facade - gap), facing, -MAIN_FROM - facade, rng, house_style)
	for sz: float in [-1.0, 1.0]:
		var facing := Vector3(0, 0, -sz)
		if sz > 0:
			FacadeKit.build_row(houses, Vector3(facade + gap + depth, 0, facade), facing, SIDE_EXTENT - facade - depth, rng, house_style)
			FacadeKit.build_row(houses, Vector3(-SIDE_EXTENT, 0, facade), facing, SIDE_EXTENT - facade - depth, rng, house_style)
		else:
			FacadeKit.build_row(houses, Vector3(SIDE_EXTENT, 0, -facade), facing, SIDE_EXTENT - facade - depth, rng, house_style)
			FacadeKit.build_row(houses, Vector3(-facade - gap - depth, 0, -facade), facing, SIDE_EXTENT - facade - depth, rng, house_style)


func _build_furniture(rng: RandomNumberGenerator) -> void:
	var lamp: PackedScene = load("res://assets/polyhaven/%s/%s.gltf" % [lamp_model, lamp_model])
	# Lamps on both sides of the main street, 0.5 m behind the curb, staggered.
	for sx: float in [-1.0, 1.0]:
		var z := MAIN_FROM + 10.0 + (lamp_step / 2.0 if sx > 0 else 0.0)
		while z < MAIN_TO:
			if absf(z) > facade + 2.0:
				_place(lamp, Vector3(sx * (road_half + 0.5), CURB_H, z), PI / 2.0 * sx)
				lamp_heads.append(Vector3(sx * (road_half + 0.5), CURB_H + lamp_height, z))
			z += lamp_step
	_build_street_furniture(rng)


## Bins, planters and benches near the facades.
func _build_street_furniture(rng: RandomNumberGenerator) -> void:
	var bin: PackedScene = load("res://assets/polyhaven/metal_trash_can/metal_trash_can.gltf")
	var planters: Array[PackedScene] = [
		load("res://assets/polyhaven/planter_box_01/planter_box_01.gltf"),
		load("res://assets/polyhaven/planter_box_02/planter_box_02.gltf"),
	]
	var bench: PackedScene = load("res://assets/polyhaven/modular_street_seating/modular_street_seating.gltf")
	var count := rng.randi_range(6, 14)
	for k in count:
		var sx := -1.0 if rng.randf() < 0.5 else 1.0
		var z := rng.randf_range(facade + 4.0, 120.0) * (1.0 if rng.randf() < 0.75 else -0.5)
		var r := rng.randf()
		if r < 0.4:
			_place(bin, Vector3(sx * (facade - 0.6), CURB_H, z), rng.randf_range(0, TAU), "rust")
		elif r < 0.8:
			_place(planters[rng.randi() % planters.size()], Vector3(sx * (facade - 0.6), CURB_H, z), rng.randf_range(0, TAU))
		else:
			# Bench against the facade, facing the street.
			_place(bench, Vector3(sx * (facade - 0.5), CURB_H, z), -PI / 2.0 * sx)


## Street trees on the sidewalks (urban) or in the front gardens (residential), never in
## tree_free ranges nor at the crossroads.
func _build_trees(rng: RandomNumberGenerator) -> void:
	if tree_chance <= 0.0:
		return
	var tree: PackedScene = load("res://assets/polyhaven/tree_small_02/tree_small_02.gltf")
	for sx: float in [-1.0, 1.0]:
		var z := MAIN_FROM + rng.randf_range(4.0, TREE_STEP)
		while z < MAIN_TO:
			var free := absf(z) > facade + 4.0
			for r in tree_free:
				if z > r.x - 2.0 and z < r.y + 2.0:
					free = false
			if free and rng.randf() < tree_chance:
				var x := road_half + (0.9 if front_yard <= 0.0 else sidewalk + front_yard * 0.6)
				var node := _place(tree, Vector3(sx * x, CURB_H, z), rng.randf_range(0, TAU))
				var s := rng.randf_range(0.8, 1.1)
				node.scale = Vector3(s, s, s)
			z += TREE_STEP


func _place(scene: PackedScene, pos: Vector3, yaw: float, exclude := "") -> Node3D:
	var node: Node3D = scene.instantiate()
	if exclude != "":
		# Poly Haven sometimes ships variants side by side in one file: drop the unwanted one.
		for mi in node.find_children("*%s*" % exclude, "Node3D", true, false):
			mi.free()
	node.position = pos
	node.rotation.y = yaw
	add_child(node)
	return node


func _box(size: Vector3, center: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = center
	mi.material_override = mat
	add_child(mi)
	return mi
