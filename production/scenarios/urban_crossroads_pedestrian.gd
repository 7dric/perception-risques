extends Scenario
## J1 vertical slice: urban crossroads, a pedestrian crosses at the zebra in front of the
## learner (pedestrian_crossing) while another one waits on the right sidewalk, back to the
## road (decoy_pedestrian_static).
##
## Timeline (seconds, varied by the seed):
##   t_cue       the pedestrian, walking along the left sidewalk, turns towards the road
##               (first objective cue: start of the window, docs/hazard-catalog.md V2)
##   t_conflict  when the learner's car would reach the zebra without braking
##   window      [t_cue, t_conflict - 2 s] (3.5 to 4.5 s); ideal click 0.5 s after t_cue
##   the car brakes after the window (2.5 m/s²), stops 2 m before the zebra, waits until
##   the pedestrian has left its lane, then drives on through the crossroads.

const CRUISE := 30.0 / 3.6         ## zone 30
const BRAKE := 2.5
const ACCEL := 1.5
const EGO_X := Crossroads.LANE / 2.0
const PATH_END_Z := -135.0
const LEFT_CLEAR := 22.0

var ego_follow: PathFollow3D
var ego_profile: SpeedProfile
var follower: Car
var oncoming: Car
var oncoming_start_z := -30.0
var crossing: Pedestrian
var waiting: Pedestrian
var follower_gap := 9.0


func _init() -> void:
	scenario_id = "urban_crossroads_pedestrian"
	title_fr = "Carrefour urbain, piéton au passage"
	environment_kind = "urban"
	duration_frames = 750


func _build() -> void:
	var world := Crossroads.new()
	world.name = "Crossroads"
	add_child(world)
	world.build(rng)
	conditions = Conditions.new()
	conditions.name = "Conditions"
	add_child(conditions)
	conditions.apply(params, world.lamp_heads)

	# --- Timings from the seed -----------------------------------------------------------
	var t_cue := rng.randf_range(9.0, 11.0)
	var t_conflict := t_cue + rng.randf_range(5.5, 6.5)
	var walk := rng.randf_range(1.1, 1.4)
	var cross := rng.randf_range(1.3, 1.6)
	var zebra_near := Crossroads.CROSSWALK_Z + Crossroads.CROSSWALK_W / 2.0
	var cross_z := Crossroads.CROSSWALK_Z + rng.randf_range(-1.0, 1.0)

	# --- Learner's car on a Path3D --------------------------------------------------------
	var start_z := zebra_near + CRUISE * t_conflict
	var stop_s := CRUISE * t_conflict - 2.0
	var t_brake := (stop_s - CRUISE * CRUISE / (2.0 * BRAKE)) / CRUISE

	# --- Crossing pedestrian --------------------------------------------------------------
	var sidewalk_x := -(Crossroads.ROAD_HALF + 1.4)
	var cue_point := Vector3(sidewalk_x, Crossroads.CURB_H, cross_z)
	var tl := Timeline.new()
	tl.add(0.0, cue_point + Vector3(0, 0, walk * t_cue))   # walking away from us, towards the zebra
	tl.add(t_cue, cue_point)
	tl.walk_to(Vector3(-Crossroads.ROAD_HALF + 0.1, Crossroads.CURB_H, cross_z), cross + 0.3)
	tl.walk_to(Vector3(-Crossroads.ROAD_HALF - 0.1, 0.0, cross_z), cross)
	tl.walk_to(Vector3(Crossroads.ROAD_HALF - 0.1, 0.0, cross_z), cross)
	tl.walk_to(Vector3(Crossroads.ROAD_HALF + 0.1, Crossroads.CURB_H, cross_z), cross)
	tl.walk_to(Vector3(Crossroads.ROAD_HALF + 1.5, Crossroads.CURB_H, cross_z - 1.5), walk)
	tl.walk_to(Vector3(Crossroads.ROAD_HALF + 1.5, Crossroads.CURB_H, -60.0), walk)
	crossing = _pedestrian("CrossingPedestrian", tl, Vector3.FORWARD)
	var t_clear := tl.time_at_x(Crossroads.LANE + 0.6)
	_hazard(crossing, "h1", "pedestrian_crossing", false, t_cue, t_conflict - 2.0,
		"Piéton qui traverse",
		"Le piéton qui marchait sur le trottoir de gauche se tourne vers la route et s'engage sur le passage. Il fallait le repérer dès qu'il s'est tourné vers la chaussée.",
		["vulnerable_user", "distraction"])

	var restart := maxf(t_brake + CRUISE / BRAKE, t_clear + 0.8)
	ego_profile = SpeedProfile.new(CRUISE) \
		.phase(t_brake, 0.0) \
		.phase(restart - t_brake, -BRAKE) \
		.phase(CRUISE / ACCEL, ACCEL) \
		.bake(duration_frames)
	var path := Path3D.new()
	path.name = "EgoPath"
	var curve := Curve3D.new()
	curve.add_point(Vector3(EGO_X, 0, start_z))
	curve.add_point(Vector3(EGO_X, 0, PATH_END_Z))
	path.curve = curve
	add_child(path)
	ego_follow = PathFollow3D.new()
	ego_follow.loop = false
	ego_follow.rotation_mode = PathFollow3D.ROTATION_Y
	path.add_child(ego_follow)
	cockpit = Cockpit.new()
	cockpit.name = "Cockpit"
	ego_follow.add_child(cockpit)   # the follower's -Z points along the path, like the car

	# --- Decoy: pedestrian waiting on the right sidewalk, back to the road -----------------
	var wait_point := Vector3(Crossroads.ROAD_HALF + 1.9, Crossroads.CURB_H, rng.randf_range(35.0, 70.0))
	var wl := Timeline.new().add(0.0, wait_point).wait(60.0)
	waiting = _pedestrian("WaitingPedestrian", wl, Vector3.RIGHT)
	_hazard(waiting, "d1", "decoy_pedestrian_static", true, 0.0, 0.0, "",
		"La personne à droite attend, immobile et dos à la route : elle ne va pas traverser.", [])

	# --- Other traffic and parked cars ------------------------------------------------------
	follower = _car("Follower", false)
	follower_gap = rng.randf_range(8.0, 12.0)
	oncoming = _car("Oncoming", false)
	oncoming_start_z = rng.randf_range(-45.0, -25.0)
	_park_cars(start_z, wait_point.z)


func _pose(f: int, t: float) -> void:
	var s := ego_profile.distance(f)
	ego_follow.progress = s
	cockpit.dashboard.show_state(ego_profile.speed(f) * 3.6, t)
	var curve_len := (ego_follow.get_parent() as Path3D).curve.get_baked_length()
	var fs := ego_profile.distance(f - 36) - follower_gap - follower.length
	follower.position = (ego_follow.get_parent() as Path3D).curve.sample_baked(clampf(fs, -200.0, curve_len))
	if fs < 0.0:
		follower.position.z -= fs
	oncoming.position = Vector3(-EGO_X, 0, oncoming_start_z + CRUISE * t)
	oncoming.rotation.y = PI
	crossing.pose_at(t)
	waiting.pose_at(t)


func _pedestrian(node_name: String, tl: Timeline, facing: Vector3) -> Pedestrian:
	var p := Pedestrian.new()
	p.name = node_name
	add_child(p)
	p.setup(tl, rng)
	p.idle_facing = facing
	return p


func _hazard(actor: Node3D, id: String, type: String, decoy: bool, t_start: float, t_end: float,
		label: String, explanation: String, tags: Array) -> void:
	var h := Hazard.new()
	h.name = "Hazard_" + id
	h.hazard_id = id
	h.type = type
	h.is_decoy = decoy
	h.label_fr = label
	h.explanation_fr = explanation
	h.tags = PackedStringArray(tags)
	h.window_start = roundi(t_start * FPS)
	h.window_end = roundi(t_end * FPS)
	h.ideal_frame = h.window_start + roundi(0.5 * FPS)
	h.box_center = Vector3(0, 0.9, 0)
	h.box_size = Vector3(0.6, 1.85, 0.45)
	actor.add_child(h)


func _car(node_name: String, collide: bool) -> Car:
	var c := Car.new()
	c.name = node_name
	add_child(c)
	c.setup(rng, collide)
	return c


## Parked cars on both parking lanes, never within 5 m of the zebra (Belgian rule) nor in
## the crossroads. The right lane stays free around the waiting pedestrian (bus stop zone),
## so that the decoy can be seen.
func _park_cars(start_z: float, stop_z: float) -> void:
	for sx: float in [-1.0, 1.0]:
		var z := Crossroads.CROSSWALK_Z + Crossroads.CROSSWALK_W / 2.0 + 5.0 + rng.randf_range(0.0, 3.0)
		while z < start_z + 30.0:
			var at_stop := sx > 0 and z + Car.LENGTH > stop_z - 12.0 and z < stop_z + 6.0
			# Left side: no parking on the 22 m before the zebra, so that the crossing pedestrian
			# stays visible from the start of the window (docs/hazard-catalog.md, rule 1).
			var before_zebra := sx < 0 and z < Crossroads.CROSSWALK_Z + LEFT_CLEAR
			var length := Car.LENGTH
			if rng.randf() < 0.8 and not at_stop and not before_zebra:
				var c := _car("Parked", true)
				length = c.length
				c.position = Vector3(sx * (Crossroads.LANE + Crossroads.PARKING / 2.0), 0, z)
				c.rotation.y = 0.0 if sx > 0 else PI
				if sx < 0:
					c.position.z += length
			z += length + rng.randf_range(0.8, 2.5)
		z = -Crossroads.FACADE - 3.0 - rng.randf_range(0.0, 3.0)
		while z > Crossroads.MAIN_FROM + 10.0:
			var length := Car.LENGTH
			if rng.randf() < 0.7:
				var c := _car("Parked", true)
				length = c.length
				c.position = Vector3(sx * (Crossroads.LANE + Crossroads.PARKING / 2.0), 0, z - length)
			z -= length + rng.randf_range(0.8, 2.5)
