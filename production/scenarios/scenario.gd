class_name Scenario
extends Node3D
## Base class of a scenario. Everything is a pure function of the frame number, driven from
## _physics_process (one physics tick per rendered frame with --fixed-fps 30), and every
## random choice comes from one RandomNumberGenerator seeded on the command line.
##
## Modes:
## - clip (default): plays duration_frames frames, records the annotations, writes the JSON
##   in --out and quits. With --movie=<file.mkv>, every rendered frame is piped to FFmpeg
##   (FfmpegPipe); Movie Maker (--write-movie) still works for PNG frames.
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
var movie: FfmpegPipe
## A physics tick ran since the last captured image (exactly one image per frame).
var _ticked := false
## --profile: measured viewports and accumulated times (ms).
var _profiled: Dictionary = {}   # name -> RID
var _prof_sum: Dictionary = {}   # key -> total ms
var _prof_frames := 0
var _prof_last_usec := 0


func _ready() -> void:
	params = ScenarioParams.from_command_line()
	if not params.errors.is_empty():
		for e in params.errors:
			printerr(e)
		get_tree().quit(2)
		return
	rng.seed = params.rng_seed
	_build()
	_apply_quality()
	if params.frames > 0:
		duration_frames = mini(params.frames, duration_frames)
	recorder = AnnotationRecorder.new()
	recorder.views = cockpit.recorder_views()
	recorder.overlays = cockpit.overlays()
	add_child(recorder)
	for h in find_children("*", "Hazard", true, false):
		recorder.add(h)
	if params.profile:
		_start_profile()
	if params.movie_path != "":
		movie = FfmpegPipe.new(params.movie_path, FPS)
		RenderingServer.frame_post_draw.connect(_capture)
	if params.still_frame >= 0:
		set_physics_process(false)
		_still()
	else:
		_apply(0)


func _physics_process(_delta: float) -> void:
	if params.profile:
		_sample_profile()
	_apply(frame)
	recorder.capture()
	_ticked = true
	frame += 1
	if frame >= duration_frames:
		set_physics_process(false)
		_write_annotations()
		if movie == null:
			_quit(0)
		# else _capture quits once the last image is written.


## Sends the image just drawn to FFmpeg (one image per physics tick).
func _capture() -> void:
	if not _ticked:
		return
	_ticked = false
	if movie.write(get_viewport().get_texture().get_image()) != OK:
		RenderingServer.frame_post_draw.disconnect(_capture)
		_quit(1)
		return
	if movie.frames >= duration_frames:
		RenderingServer.frame_post_draw.disconnect(_capture)
		_quit(0 if movie.finish() == OK else 1)


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
	_quit(0 if err == OK else 1)


func _quit(code: int) -> void:
	if params.profile:
		_print_profile()
	CarLibrary.release()
	get_tree().quit(code)


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
		"conditions": params.conditions(),
		"video": {"fps": FPS, "width": 1920, "height": 1080, "frameCount": recorder.frame_count()},
	}
	DirAccess.make_dir_recursive_absolute(params.out_dir)
	var path := params.out_dir.path_join(id + ".json")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(recorder.build(header), "  ", false) + "\n")
	f.close()
	print("ANNOTATIONS|%s|%d frames" % [path, recorder.frame_count()])
	for h in recorder.hazards:
		if not h.is_decoy and h.window_end < recorder.frame_count():
			var hidden := recorder.hidden_in_window(h)
			if hidden > 0:
				printerr("HAZARD_HIDDEN|%s|%d image(s) de la fenêtre %d-%d sans danger visible" % [h.hazard_id, hidden, h.window_start, h.window_end])


## Identifier of the clip: scenario, seed and conditions (schema pattern ^[a-z0-9][a-z0-9-]*$).
func clip_id() -> String:
	return ("%s-s%d-%s-%s" % [scenario_id, params.rng_seed, params.time_of_day, params.weather]).replace("_", "-")


# --- Quality presets (--quality) ------------------------------------------------------------

## "reference": the validated look (project settings: 4K internal render downscaled to 1080p,
## MSAA 2x, mirrors rendered the same way). "fast": cheaper settings, adopted only after a
## side-by-side comparison (ADR-020).
func _apply_quality() -> void:
	if params.quality != "fast":
		return
	var vp := get_viewport()
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = 1.5
	vp.msaa_3d = Viewport.MSAA_4X
	for sub: SubViewport in find_children("*", "SubViewport", true, false):
		sub.scaling_3d_scale = 1.0
		sub.msaa_3d = Viewport.MSAA_4X
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM)
	RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM)
	if conditions and conditions.environment:
		conditions.environment.ssr_max_steps = 64


# --- Profiling (--profile) ----------------------------------------------------------------

func _start_profile() -> void:
	_profiled["main"] = get_viewport().get_viewport_rid()
	for vp: SubViewport in find_children("*", "SubViewport", true, false):
		_profiled[String(vp.name)] = vp.get_viewport_rid()
	for n in _profiled:
		RenderingServer.viewport_set_measure_render_time(_profiled[n], true)


## Called at the start of each tick: the measures describe the previous frame.
func _sample_profile() -> void:
	var now := Time.get_ticks_usec()
	# Skip the first frames (shader compilation, SDFGI warm-up).
	if frame >= 10:
		_prof_frames += 1
		_prof_add("wall", (now - _prof_last_usec) / 1000.0)
		_prof_add("frame_setup_cpu", RenderingServer.get_frame_setup_time_cpu())
		for n in _profiled:
			_prof_add(n + "_cpu", RenderingServer.viewport_get_measured_render_time_cpu(_profiled[n]))
			_prof_add(n + "_gpu", RenderingServer.viewport_get_measured_render_time_gpu(_profiled[n]))
	_prof_last_usec = now


func _prof_add(key: String, ms: float) -> void:
	_prof_sum[key] = _prof_sum.get(key, 0.0) + ms


func _print_profile() -> void:
	if _prof_frames == 0:
		return
	var parts := PackedStringArray()
	for k in _prof_sum:
		parts.append("%s=%.1f" % [k, _prof_sum[k] / _prof_frames])
	print("PROFILE|%d frames|ms/frame|%s" % [_prof_frames, "|".join(parts)])


# --- To implement in each scenario -------------------------------------------------------

## Builds the world, the actors, the cockpit (self.cockpit) and the conditions
## (self.conditions). Hazards are Hazard nodes anywhere below the scenario.
func _build() -> void:
	pass


## Places the actors at frame [param f] / time [param t].
func _pose(_f: int, _t: float) -> void:
	pass
