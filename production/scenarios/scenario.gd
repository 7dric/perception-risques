class_name Scenario
extends Node3D
## Base class of a scenario. Everything is a pure function of the frame number, driven from
## _physics_process (one physics tick per rendered frame with --fixed-fps 30), and every
## random choice comes from one RandomNumberGenerator seeded on the command line.
##
## Modes:
## - clip (default): plays duration_frames frames, records the annotations, writes the JSON
##   in --out and quits. Rendered with Movie Maker (--write-movie).
## - still (--still-frame=N --still=file.png): jumps to frame N, lets the lighting settle,
##   saves one PNG and quits.

const FPS := 30
const GENERATOR_VERSION := "0.1.0"
## Frames rendered before saving a still, so that SDFGI and the shadows converge.
const STILL_SETTLE_FRAMES := 120

var scenario_id := "scenario"
var title_fr := ""
var environment_kind := "urban"
var duration_frames := 750

var params: ScenarioParams
var rng := RandomNumberGenerator.new()
var cockpit: Cockpit
var conditions: Conditions
var recorder: AnnotationRecorder
var frame := 0


func _ready() -> void:
	params = ScenarioParams.from_command_line()
	if not params.errors.is_empty():
		for e in params.errors:
			printerr(e)
		get_tree().quit(2)
		return
	rng.seed = params.rng_seed
	_build()
	if params.frames > 0:
		duration_frames = mini(params.frames, duration_frames)
	recorder = AnnotationRecorder.new()
	recorder.views = cockpit.recorder_views()
	recorder.overlays = cockpit.overlays()
	add_child(recorder)
	for h in find_children("*", "Hazard", true, false):
		recorder.add(h)
	if params.still_frame >= 0:
		set_physics_process(false)
		_still()
	else:
		_apply(0)


func _physics_process(_delta: float) -> void:
	_apply(frame)
	recorder.capture()
	frame += 1
	if frame >= duration_frames:
		set_physics_process(false)
		_write_annotations()
		get_tree().quit()


## Places everything for frame [param f].
func _apply(f: int) -> void:
	_pose(f, float(f) / FPS)
	cockpit.update_mirrors()
	conditions.follow(cockpit.windshield.global_position)


func _still() -> void:
	_apply(params.still_frame)
	for i in STILL_SETTLE_FRAMES:
		await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(params.still_path)
	print("STILL|%s|%dx%d|%s" % [params.still_path, img.get_width(), img.get_height(), error_string(err)])
	get_tree().quit(0 if err == OK else 1)


func _write_annotations() -> void:
	if params.out_dir == "":
		return
	var id := clip_id()
	var header := {
		"schemaVersion": 0,
		"id": id,
		"title": {"fr": title_fr},
		"kind": "exam",
		"generation": {"scenario": scenario_id, "seed": params.rng_seed, "generatorVersion": GENERATOR_VERSION},
		"conditions": params.conditions(environment_kind),
		"video": {"fps": FPS, "width": 1920, "height": 1080, "frameCount": recorder.frame_count()},
	}
	DirAccess.make_dir_recursive_absolute(params.out_dir)
	var path := params.out_dir.path_join(id + ".json")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(recorder.build(header), "  ", false) + "\n")
	f.close()
	print("ANNOTATIONS|%s|%d frames" % [path, recorder.frame_count()])


## Identifier of the clip: scenario, seed and conditions (schema pattern ^[a-z0-9][a-z0-9-]*$).
func clip_id() -> String:
	return ("%s-s%d-%s-%s" % [scenario_id, params.rng_seed, params.time_of_day, params.weather]).replace("_", "-")


# --- To implement in each scenario -------------------------------------------------------

## Builds the world, the actors, the cockpit (self.cockpit) and the conditions
## (self.conditions). Hazards are Hazard nodes anywhere below the scenario.
func _build() -> void:
	pass


## Places the actors at frame [param f] / time [param t].
func _pose(_f: int, _t: float) -> void:
	pass
