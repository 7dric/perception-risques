class_name Conditions
extends Node3D
## Applies the time of day and the weather of a scenario (D5): sky (Poly Haven HDRI), sun,
## global illumination, fog, rain and wet road, street lights.

const HDRI := "res://assets/polyhaven/%s/%s_4k.hdr"

## Sky per (time of day, weather), with the sun strength and the exposure. "hdri" lists the
## variants: one is picked from the seed (D5: same condition, different skies).
const SKIES := {
	"day": {"hdri": ["kloofendal_48d_partly_cloudy_puresky", "kloppenheim_05_puresky"], "sun": 2.2, "exposure": 1.0},
	"day_overcast": {"hdri": ["kloofendal_overcast_puresky", "overcast_soil_puresky"], "sun": 0.0, "exposure": 1.25},
	"low_sun": {"hdri": ["syferfontein_6d_clear_puresky", "syferfontein_1d_clear_puresky"], "sun": 2.0, "exposure": 1.0},
	"dawn": {"hdri": ["qwantani_sunrise_puresky", "qwantani_dawn_puresky"], "sun": 1.2, "exposure": 1.4},
	"dusk": {"hdri": ["qwantani_dusk_2_puresky", "belfast_sunset_puresky"], "sun": 0.6, "exposure": 1.6},
	"night": {"hdri": ["qwantani_night_puresky", "kloppenheim_02_puresky"], "sun": 0.0, "exposure": 0.25},
}

var time_of_day := "day"
var weather := "clear"
## Poly Haven id of the sky in use.
var hdri := ""
var environment: Environment
var sun: DirectionalLight3D
var rain: GPUParticles3D


func apply(params: ScenarioParams, lamp_heads: Array[Vector3]) -> void:
	time_of_day = params.time_of_day
	weather = params.weather
	var key := _sky_key()
	var sky_def: Dictionary = SKIES[key]
	# Own generator: the sky choice does not shift the other random draws of the scenario.
	var sky_rng := RandomNumberGenerator.new()
	sky_rng.seed = hash("sky:%d" % params.rng_seed)
	var variants: Array = sky_def.hdri
	hdri = variants[sky_rng.randi() % variants.size()]
	print("SKY|%s" % hdri)
	var panorama: Texture2D = load(HDRI % [hdri, hdri])
	_build_environment(panorama, sky_def)
	_build_sun(panorama, sky_def)
	if weather in ["rain", "fog"]:
		_build_fog()
	if weather == "rain":
		_build_rain(params.rng_seed)
	Pbr.set_wetness(1.0 if weather == "rain" else 0.0)
	if time_of_day in ["night", "dusk", "dawn"]:
		_build_street_lights(lamp_heads)


func _sky_key() -> String:
	if time_of_day != "day":
		return time_of_day
	if weather == "low_sun":
		return "low_sun"
	if weather in ["overcast", "rain", "fog", "snow"]:
		return "day_overcast"
	return "day"


func _build_environment(panorama: Texture2D, sky_def: Dictionary) -> void:
	var sky_mat := PanoramaSkyMaterial.new()
	sky_mat.panorama = panorama
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_512
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = sky_def.exposure
	env.sdfgi_enabled = true
	env.sdfgi_use_occlusion = true
	env.sdfgi_cascades = 4
	env.sdfgi_min_cell_size = 0.2
	env.sdfgi_energy = 1.0
	env.ssao_enabled = true
	env.ssao_radius = 1.5
	env.ssao_intensity = 1.6
	env.ssil_enabled = true
	env.ssr_enabled = true
	env.ssr_max_steps = 128
	env.glow_enabled = true
	env.glow_intensity = 0.25
	env.glow_bloom = 0.02
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.05
	environment = env
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


## Points the sun (and its shadows) at the brightest spot of the HDRI.
func _build_sun(panorama: Texture2D, sky_def: Dictionary) -> void:
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = sky_def.sun
	sun.shadow_enabled = sky_def.sun > 0.0
	sun.light_angular_distance = 0.6
	sun.directional_shadow_max_distance = 160.0
	sun.directional_shadow_blend_splits = true
	sun.light_color = Color(1.0, 0.96, 0.9) if time_of_day == "day" else Color(1.0, 0.78, 0.55)
	var dir := _brightest_direction(panorama)
	sun.look_at_from_position(Vector3.ZERO, -dir, Vector3.UP if absf(dir.y) < 0.99 else Vector3.FORWARD)
	sun.visible = sky_def.sun > 0.0
	add_child(sun)


static func _brightest_direction(panorama: Texture2D) -> Vector3:
	var img := panorama.get_image()
	if img.is_compressed():
		img.decompress()
	img.resize(256, 128, Image.INTERPOLATE_BILINEAR)
	var best := -1.0
	var best_uv := Vector2(0.5, 0.25)
	for y in 64:  # upper half only: the sun is above the horizon
		for x in 256:
			var c := img.get_pixel(x, y)
			var l := c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
			if l > best:
				best = l
				best_uv = Vector2((x + 0.5) / 256.0, (y + 0.5) / 128.0)
	# Godot panorama mapping: u = 0.5 looks towards -Z, v = 0 is the zenith.
	var phi := (best_uv.x - 0.5) * TAU
	var theta := best_uv.y * PI
	return Vector3(sin(theta) * sin(phi), cos(theta), -sin(theta) * cos(phi)).normalized()


func _build_fog() -> void:
	environment.volumetric_fog_enabled = true
	environment.volumetric_fog_density = 0.035 if weather == "fog" else 0.008
	environment.volumetric_fog_albedo = Color(0.85, 0.87, 0.9)
	environment.volumetric_fog_length = 120.0
	environment.fog_enabled = weather == "fog"
	environment.fog_density = 0.01
	environment.fog_light_color = Color(0.7, 0.72, 0.75)


## Rain streaks around the camera. Particles use a fixed seed so renders are repeatable.
func _build_rain(scenario_seed: int) -> void:
	rain = GPUParticles3D.new()
	rain.name = "Rain"
	rain.amount = 12000
	rain.lifetime = 1.2
	rain.preprocess = 1.2
	rain.fixed_fps = 30
	rain.use_fixed_seed = true
	rain.seed = scenario_seed
	rain.visibility_aabb = AABB(Vector3(-25, -2, -40), Vector3(50, 25, 60))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(20, 0.5, 25)
	pm.direction = Vector3(0.05, -1, 0)
	pm.spread = 2.0
	pm.initial_velocity_min = 9.0
	pm.initial_velocity_max = 11.0
	pm.gravity = Vector3(0, -2, 0)
	rain.process_material = pm
	var streak := QuadMesh.new()
	streak.size = Vector2(0.008, 0.45)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.8, 0.85, 0.9, 0.25)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	streak.material = mat
	rain.draw_pass_1 = streak
	rain.position = Vector3(0, 12, -10)
	add_child(rain)


## Moves the rain volume with the learner's car.
func follow(camera_pos: Vector3) -> void:
	if rain:
		rain.global_position = camera_pos + Vector3(0, 12, -10)


func _build_street_lights(heads: Array[Vector3]) -> void:
	var energy := 14.0 if time_of_day == "night" else 1.2
	for p in heads:
		var light := OmniLight3D.new()
		light.position = p
		light.omni_range = 16.0
		light.light_energy = energy
		light.light_color = Color(1.0, 0.82, 0.6)
		light.shadow_enabled = false
		add_child(light)
