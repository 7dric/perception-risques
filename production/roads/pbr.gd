class_name Pbr
## Builds PBR materials from Poly Haven textures downloaded by tools/fetch-assets.mjs.
## Textures are projected in world space (triplanar), so meshes need no UVs and every
## surface keeps the real-world scale of the texture.

const ROOT := "res://assets/polyhaven/"

static var _cache: Dictionary = {}
static var _wetness := 0.0


## Returns an ORM material for texture [param id]; [param size_m] is the real-world size
## covered by one texture tile (Poly Haven textures are usually 1 to 3 m wide).
static func material(id: String, size_m: float = 2.0, tint: Color = Color.WHITE) -> ORMMaterial3D:
	var key := "%s|%s|%s" % [id, size_m, tint.to_html()]
	if _cache.has(key):
		return _cache[key]
	var m := ORMMaterial3D.new()
	m.albedo_texture = load(_file(id, "diff"))
	m.albedo_color = tint
	m.orm_texture = load(_file(id, "arm"))
	m.normal_enabled = true
	m.normal_texture = load(_file(id, "nor_gl"))
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 8.0
	m.uv1_scale = Vector3.ONE / size_m
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.set_meta("tint", tint)
	_wet(m)
	_cache[key] = m
	return m


## Rain: darker and glossier surfaces (0 = dry, 1 = soaked). Applies to existing and future
## textured materials.
static func set_wetness(w: float) -> void:
	_wetness = w
	for m in _cache.values():
		if m is ORMMaterial3D:
			_wet(m)


static func _wet(m: ORMMaterial3D) -> void:
	var tint: Color = m.get_meta("tint", Color.WHITE)
	m.albedo_color = tint.darkened(0.3 * _wetness)
	m.roughness = lerpf(1.0, 0.3, _wetness)


## Flat painted material (road markings, placeholder actors).
static func paint(color: Color, roughness: float = 0.6) -> StandardMaterial3D:
	var key := "paint|%s|%s" % [color.to_html(), roughness]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	_cache[key] = m
	return m


static func _file(id: String, map: String) -> String:
	return "%s%s/%s_%s_2k.jpg" % [ROOT, id, id, map]
