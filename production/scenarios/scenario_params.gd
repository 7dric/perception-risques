class_name ScenarioParams
extends RefCounted
## Parameters of one render, read from the user command-line arguments (after "--"):
##   --seed=42 --time=dusk --weather=rain --out=C:/.../content/raw/<id>
##   --still-frame=300 --still=C:/.../still.png
##   --frames=90 (shortened clip, for tests)
## Allowed values follow schema/clip.schema.json (conditions).

const TIMES := ["day", "dawn", "dusk", "night"]
const WEATHERS := ["clear", "overcast", "rain", "fog", "low_sun"]

var rng_seed := 42
var time_of_day := "day"
var weather := "clear"
## Output folder for the annotation JSON (absolute path). Empty: no JSON written.
var out_dir := ""
## Still mode: jump to this frame, let the lighting settle, save one PNG and quit.
var still_frame := -1
var still_path := ""
## Shortens the clip to this many frames (tests). 0: full duration.
var frames := 0
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
			"out":
				p.out_dir = value
			"still-frame":
				p.still_frame = int(value)
			"still":
				p.still_path = value
			"frames":
				p.frames = int(value)
			_:
				p.errors.append("argument inconnu : %s" % arg)
	return p


func _check(value: String, allowed: Array, key: String, fallback: String) -> String:
	if value in allowed:
		return value
	errors.append("--%s=%s invalide (valeurs : %s)" % [key, value, ", ".join(allowed)])
	return fallback


## Conditions block of the annotation JSON.
func conditions(environment: String) -> Dictionary:
	return {"timeOfDay": time_of_day, "weather": weather, "environment": environment}
