class_name ScenarioParams
extends RefCounted
## Parameters of one render, read from the user command-line arguments (after "--"):
##   --seed=42 --time=dusk --weather=rain --environment=residential --quality=fast
##   --out=C:/.../content/raw/<id>
##   --movie=C:/.../<id>.mkv (frames piped to FFmpeg, see FfmpegPipe)
##   --still-frame=300 --still=C:/.../still.png
##   --frames=90 (shortened clip, for tests)
##   --profile (prints the render time per frame, CPU and GPU, at the end)
## Allowed values follow schema/clip.schema.json (conditions).

const TIMES := ["day", "dawn", "dusk", "night"]
const WEATHERS := ["clear", "overcast", "rain", "fog", "low_sun"]
const ENVIRONMENTS := ["urban", "residential"]
const QUALITIES := ["reference", "fast"]

var rng_seed := 42
var time_of_day := "day"
var weather := "clear"
## Scenery: urban crossroads or residential street (schema: conditions.environment).
var environment := "urban"
## Render settings preset (see Scenario._apply_quality).
var quality := "reference"
## Output folder for the annotation JSON (absolute path). Empty: no JSON written.
var out_dir := ""
## Video output (FfmpegPipe), rendered with --fixed-fps 30. Empty: no video.
var movie_path := ""
## Still mode: jump to this frame, let the lighting settle, save one PNG and quit.
var still_frame := -1
var still_path := ""
## Shortens the clip to this many frames (tests). 0: full duration.
var frames := 0
## Measures the render time of every viewport and prints a PROFILE| summary at the end.
var profile := false
## Invalid arguments; the scenario refuses to run if this is not empty.
var errors: PackedStringArray = []


static func from_command_line(args: PackedStringArray = OS.get_cmdline_user_args()) -> ScenarioParams:
	var p := ScenarioParams.new()
	for arg in args:
		var kv := arg.trim_prefix("--").split("=", true, 1)
		var key := kv[0]
		var value := kv[1] if kv.size() > 1 else ""
		match key:
			"seed":
				if value.is_valid_int() and int(value) >= 0:
					p.rng_seed = int(value)
				else:
					p.errors.append("--seed doit être un entier positif ou nul")
			"time":
				p.time_of_day = p._check(value, TIMES, key, p.time_of_day)
			"weather":
				p.weather = p._check(value, WEATHERS, key, p.weather)
			"environment":
				p.environment = p._check(value, ENVIRONMENTS, key, p.environment)
			"quality":
				p.quality = p._check(value, QUALITIES, key, p.quality)
			"out":
				p.out_dir = value
			"movie":
				p.movie_path = value
			"still-frame":
				p.still_frame = int(value)
			"still":
				p.still_path = value
			"frames":
				p.frames = int(value)
			"profile":
				p.profile = true
			_:
				p.errors.append("argument inconnu : %s" % arg)
	return p


func _check(value: String, allowed: Array, key: String, fallback: String) -> String:
	if value in allowed:
		return value
	errors.append("--%s=%s invalide (valeurs : %s)" % [key, value, ", ".join(allowed)])
	return fallback


## Conditions block of the annotation JSON.
func conditions() -> Dictionary:
	return {"timeOfDay": time_of_day, "weather": weather, "environment": environment}
