class_name ResidentialCrossroads
extends Crossroads
## Residential crossroads (environment "residential"): narrow street without markings
## (priority to the right at the crossroads, no zebra), parking on the carriageway, narrow
## sidewalks, two-storey houses with pitched roofs behind small front gardens (low brick wall,
## lawn, shrubs, a few trees), lamps further apart.


func _init() -> void:
	environment = "residential"
	lane = 2.75
	parking = 1.9
	sidewalk = 1.8
	front_yard = 3.0
	has_zebra = false
	has_centre_line = false
	has_parking_lines = false
	has_give_way = false
	tree_chance = 0.25
	lamp_model = "street_lamp_02"
	lamp_step = 30.0
	house_style = {
		"floors": [2, 2],
		"width": [2, 3],
		"walls": [
			["red_brick_03", 2.0], ["brown_brick_02", 2.0], ["red_bricks_04", 2.0],
			["large_red_bricks", 2.0], ["whitewashed_brick", 2.0],
			["beige_wall_001", 3.0],
		],
		"roof": "pitched",
		"roofs": [["grey_roof_tiles", 1.5], ["clay_roof_tiles_02", 1.5]],
	}
	update_dimensions()


func _build_furniture(rng: RandomNumberGenerator) -> void:
	super(rng)
	# street_lamp_02 is a smaller residential lamp: its head is lower.
	for i in lamp_heads.size():
		lamp_heads[i].y = CURB_H + 3.0


## No bins nor benches on the narrow sidewalks: a few planters in the gardens instead.
func _build_street_furniture(_rng: RandomNumberGenerator) -> void:
	pass


## Front gardens along the main street: lawn, low brick wall on the sidewalk side with a gap
## for the path, and shrubs. Built on top of the paved strip (see _build_ground).
func _build_front_yards(rng: RandomNumberGenerator) -> void:
	var lawn := Pbr.material("leafy_grass", 2.0)
	var wall_mat := Pbr.material("red_brick_03", 2.0, Color(0.8, 0.8, 0.8))
	var shrubs: Array[PackedScene] = [
		load("res://assets/polyhaven/shrub_02/shrub_02.gltf"),
		load("res://assets/polyhaven/shrub_04/shrub_04.gltf"),
	]
	var x_in := road_half + sidewalk          # sidewalk / garden boundary
	var x_mid := x_in + front_yard / 2.0
	for sx: float in [-1.0, 1.0]:
		for part in [[facade, MAIN_TO], [MAIN_FROM, -facade]]:
			var z := float(part[0])
			var z_end := float(part[1])
			# One garden per 6 to 9 m (roughly one house), separated by the path to the door.
			while z < z_end - 2.0:
				var garden := minf(rng.randf_range(5.0, 8.0), z_end - z)
				var path := 1.2
				var g0 := z + path
				var g_len := garden - path
				if g_len > 1.0:
					_box(Vector3(front_yard - 0.2, 0.06, g_len), Vector3(sx * (x_mid + 0.1), CURB_H + 0.03, g0 + g_len / 2.0), lawn)
					if rng.randf() < 0.7:
						var wall_h := rng.randf_range(0.4, 0.7)
						_box(Vector3(0.2, wall_h, g_len), Vector3(sx * (x_in + 0.1), CURB_H + wall_h / 2.0, g0 + g_len / 2.0), wall_mat)
					for _k in rng.randi_range(0, 2):
						var p := Vector3(sx * rng.randf_range(x_in + 0.8, facade - 0.8), CURB_H + 0.05, g0 + rng.randf_range(0.6, g_len - 0.6))
						if not _in_tree_free(p.z):
							var shrub := _place(shrubs[rng.randi() % shrubs.size()], p, rng.randf_range(0, TAU))
							var s := rng.randf_range(0.6, 1.0)
							shrub.scale = Vector3(s, s, s)
				z += garden


func _in_tree_free(z: float) -> bool:
	for r in tree_free:
		if z > r.x - 2.0 and z < r.y + 2.0:
			return true
	return false
