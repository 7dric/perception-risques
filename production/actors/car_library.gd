class_name CarLibrary
## Realistic car models from the "Generic passenger car pack" (Comrade1280, CC-BY 4.0,
## docs/ASSETS.md). The pack lays its 10 cars out in a showroom, each with its own yaw, and
## its wheels are separate nodes. This library regroups each body with its four nearest
## wheels, finds the car axis from the wheels, and rebuilds every car in our convention:
## origin in the middle of the front bumper on the ground, facing -Z, body along +Z.

const PACK := "res://assets/sketchfab/generic_passenger_car_pack/scene.gltf"

## Body node name -> [weight in Belgian city traffic, flip the axis found from the wheels].
## The flip is set by checking the contact sheet (tests/car_sheet.gd).
const MODELS := {
	"Compact Body": [3.0, true],
	"Hatchback Body": [3.0, false],
	"Sedan Body": [2.0, true],
	"Wagon Body": [2.0, true],
	"minivan body": [1.5, false],
	"SUV Body": [2.0, false],
	"Offroad Body": [0.5, true],
	"Coupe Body": [0.4, true],
	"Sport body": [0.2, false],
	"Pickup Body": [0.2, false],
}

## One entry per model: {"name", "weight", "template": Node3D, "size": Vector3 (w, h, length),
## "body_materials": Array[Material]}
static var _models: Array = []


## Frees the cached templates (call before quitting, or Godot reports leaks at exit).
static func release() -> void:
	for m in _models:
		(m.template as Node).free()
	_models.clear()


static func available() -> bool:
	return ResourceLoader.exists(PACK)


static func models() -> Array:
	if _models.is_empty() and available():
		_build()
	return _models


## Picks a model at random (weighted). Returns an instance of its template.
static func pick(rng: RandomNumberGenerator) -> Dictionary:
	var list := models()
	var total := 0.0
	for m in list:
		total += m.weight
	var r := rng.randf() * total
	for m in list:
		r -= m.weight
		if r <= 0.0:
			return m
	return list[-1]


static func _build() -> void:
	var scene: Node = (load(PACK) as PackedScene).instantiate()
	var bodies := {}   # body node -> Array[MeshInstance3D]
	var wheels := {}   # wheel node -> Array[MeshInstance3D]
	for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
		var group := mi.get_parent()
		var gname := String(group.name)
		if MODELS.has(gname):
			bodies.get_or_add(group, []).append(mi)
		elif gname.begins_with("Wheel"):
			wheels.get_or_add(group, []).append(mi)
	for b in bodies:
		var footprint := _footprint(bodies[b])
		var own := []
		for w in wheels:
			var c := _center(wheels[w])
			if not _inside(footprint, c):
				continue
			# Some wheels come as two nodes (tyre and hub cap) at the same place: merge them.
			var merged := false
			for g in own:
				if _center(g).distance_to(c) < 0.5:
					g.append_array(wheels[w])
					merged = true
					break
			if not merged:
				own.append((wheels[w] as Array).duplicate())
		if own.size() != 4:
			push_warning("CarLibrary: %s a %d roues, ignoré (%s)" % [b.name, own.size(), own.map(func(g): return "%s@%s" % [g[0].get_parent().name, _center(g).snapped(Vector3.ONE * 0.1)])])
			continue
		_models.append(_make_model(String(b.name), bodies[b], own, footprint))
	scene.free()


## Minimum-area rectangle around the body seen from above (search by 0.5° steps).
## Returns {"center": Vector2, "axis": Vector2 (long side), "half": Vector2 (long, short)}.
static func _footprint(meshes: Array) -> Dictionary:
	var pts := PackedVector2Array()
	for mi: MeshInstance3D in meshes:
		var xf := _world(mi)
		for v in mi.mesh.get_faces():
			var p := xf * v
			pts.append(Vector2(p.x, p.z))
	var best := {}
	var best_area := INF
	for step in 360:
		var a := deg_to_rad(step * 0.5)
		var u := Vector2(cos(a), sin(a))
		var n := Vector2(-u.y, u.x)
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for p in pts:
			var q := Vector2(p.dot(u), p.dot(n))
			lo = lo.min(q)
			hi = hi.max(q)
		var size := hi - lo
		if size.x * size.y < best_area:
			best_area = size.x * size.y
			var c := (lo + hi) / 2.0
			var center := u * c.x + n * c.y
			best = {"center": center, "axis": u, "half": size / 2.0} if size.x >= size.y \
				else {"center": center, "axis": n, "half": Vector2(size.y, size.x) / 2.0}
	return best


static func _inside(fp: Dictionary, p: Vector3) -> bool:
	var d := Vector2(p.x, p.z) - (fp.center as Vector2)
	var u: Vector2 = fp.axis
	var n := Vector2(-u.y, u.x)
	return absf(d.dot(u)) <= fp.half.x + 0.2 and absf(d.dot(n)) <= fp.half.y + 0.2


static func _make_model(name: String, body_meshes: Array, wheel_groups: Array, fp: Dictionary) -> Dictionary:
	var axis2: Vector2 = fp.axis
	var forward := Vector3(axis2.x, 0.0, axis2.y) * (-1.0 if MODELS[name][1] else 1.0)
	var z := -forward
	var basis := Basis(Vector3.UP.cross(z).normalized(), Vector3.UP, z)
	var c2: Vector2 = fp.center
	var frame := Transform3D(basis, Vector3(c2.x, 0.0, c2.y))
	var inv := frame.affine_inverse()
	# Exact extents of the body in the car frame.
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	for mi: MeshInstance3D in body_meshes:
		var xf := inv * _world(mi)
		for v in mi.mesh.get_faces():
			var p := xf * v
			lo = lo.min(p)
			hi = hi.max(p)
	var shift := Transform3D(Basis.IDENTITY, Vector3(-(lo.x + hi.x) / 2.0, 0.0, -lo.z))
	var template := Node3D.new()
	template.name = name.replace(" ", "")
	var body_mats: Array[Material] = []
	for mi: MeshInstance3D in body_meshes:
		var copy := _copy(mi, shift * inv * _world(mi))
		template.add_child(copy)
		if String(mi.name).contains("_Body_"):
			body_mats.append(copy.mesh.surface_get_material(0))
	for g in wheel_groups:
		for mi: MeshInstance3D in g:
			template.add_child(_copy(mi, shift * inv * _world(mi)))
	return {
		"name": name,
		"weight": MODELS[name][0],
		"template": template,
		"size": Vector3(hi.x - lo.x, hi.y, hi.z - lo.z),
		"body_materials": body_mats,
	}


static func _copy(mi: MeshInstance3D, xf: Transform3D) -> MeshInstance3D:
	var c := MeshInstance3D.new()
	c.name = mi.name
	c.mesh = mi.mesh
	c.transform = xf
	return c


## Global transform of a node that is not in the scene tree.
static func _world(n: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur := n
	while cur != null:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf


static func _center(meshes: Array) -> Vector3:
	var box := AABB()
	var first := true
	for mi: MeshInstance3D in meshes:
		var b := _world(mi) * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box.get_center()


static func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)
