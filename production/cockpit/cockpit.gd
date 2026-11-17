class_name Cockpit
extends Node3D
## The learner's point of view, attached to the car (origin: middle of the front bumper on
## the ground, facing -Z). Windshield camera, three mirrors rendered in SubViewports and shown
## flipped, a hood, and a dashboard drawn with our own graphics (no official artwork, ADR-012).

const VIDEO := Vector2(1920, 1080)
## Screen rectangles (normalized) of the mirror images, written to the JSON "views".
const MIRROR_RECTS := {
	"mirrorCenter": Rect2(0.335, 0.02, 0.33, 0.16),
	"mirrorLeft": Rect2(0.015, 0.72, 0.19, 0.2),
	"mirrorRight": Rect2(0.795, 0.72, 0.19, 0.2),
}
## Camera of each mirror: position (car space), yaw (rad, 0 = looking back), vertical fov.
const MIRROR_CAMERAS := {
	"mirrorCenter": [Vector3(0.0, 1.32, 1.55), 0.0, 22.0],
	"mirrorLeft": [Vector3(-0.98, 1.05, 1.35), -0.12, 26.0],
	"mirrorRight": [Vector3(0.98, 1.05, 1.35), 0.16, 26.0],
}
const DRIVER_EYE := Vector3(-0.37, 1.22, 2.05)

var windshield: Camera3D
var mirror_cameras: Dictionary = {}
var dashboard: Dashboard


func _ready() -> void:
	windshield = Camera3D.new()
	windshield.name = "Windshield"
	windshield.position = DRIVER_EYE
	windshield.rotation.x = deg_to_rad(-3.0)
	windshield.fov = 55.0
	windshield.near = 0.05
	windshield.far = 600.0
	windshield.current = true
	add_child(windshield)
	_build_hood()
	var ui := CanvasLayer.new()
	ui.name = "Ui"
	add_child(ui)
	for view in MIRROR_RECTS:
		_build_mirror(ui, view)
	dashboard = Dashboard.new()
	dashboard.set_anchors_preset(Control.PRESET_FULL_RECT)
	dashboard.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(dashboard)


func _build_hood() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.02, 0.022, 0.026)
	mat.roughness = 1.0
	mat.metallic_specular = 0.1
	var hood := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.75, 0.08, 2.0)
	hood.mesh = box
	hood.position = Vector3(0, 0.72, 1.0)
	hood.rotation.x = deg_to_rad(-4.0)
	hood.material_override = mat
	add_child(hood)


func _build_mirror(ui: CanvasLayer, view: String) -> void:
	var rect: Rect2 = MIRROR_RECTS[view]
	var px := Rect2(rect.position * VIDEO, rect.size * VIDEO)
	var frame := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.025)
	style.set_corner_radius_all(14)
	frame.add_theme_stylebox_override("panel", style)
	frame.position = px.position - Vector2(7, 7)
	frame.size = px.size + Vector2(14, 14)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(frame)
	var vp := SubViewport.new()
	vp.name = view
	vp.size = Vector2i(px.size)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.scaling_3d_scale = 2.0
	vp.msaa_3d = Viewport.MSAA_2X
	add_child(vp)
	var cam := Camera3D.new()
	var def: Array = MIRROR_CAMERAS[view]
	vp.add_child(cam)
	cam.current = true
	cam.fov = def[2]
	cam.near = 0.1
	cam.far = 400.0
	mirror_cameras[view] = {"camera": cam, "offset": def[0], "yaw": def[1]}
	var tex := TextureRect.new()
	tex.texture = vp.get_texture()
	tex.flip_h = true
	tex.position = px.position
	tex.size = px.size
	tex.stretch_mode = TextureRect.STRETCH_SCALE
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(tex)


## Mirror cameras live in SubViewports (outside this node's transform): move them with the car.
func update_mirrors() -> void:
	for view in mirror_cameras:
		var m: Dictionary = mirror_cameras[view]
		var cam: Camera3D = m.camera
		var basis := global_basis * Basis(Vector3.UP, PI + m.yaw)
		cam.global_transform = Transform3D(basis, global_transform * m.offset)


## Views for the AnnotationRecorder.
func recorder_views() -> Dictionary:
	var out := {"windshield": {"camera": windshield, "rect": Rect2(0, 0, 1, 1), "mirrored": false}}
	for view in MIRROR_RECTS:
		out[view] = {"camera": mirror_cameras[view].camera, "rect": MIRROR_RECTS[view], "mirrored": true}
	return out


## Screen areas covering the windshield view (mirrors with their frame, dashboard).
func overlays() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for view in MIRROR_RECTS:
		out.append((MIRROR_RECTS[view] as Rect2).grow(0.004))
	out.append(Dashboard.AREA)
	return out
