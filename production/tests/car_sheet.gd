# Contact sheet of the car models, to check their orientation and scale (needs rendering).
# godot --path production --script res://tests/car_sheet.gd -- --out=C:/.../cars.png [--paint=noir]
# Every car should face the camera (front bumper towards -Z, i.e. towards the viewer).
# --paint: repaints every car with that Car.PAINTS colour (checks car_paint.gdshader).
extends SceneTree


func _initialize() -> void:
	var out := ""
	var paint: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		if a.begins_with("--paint="):
			for p in Car.PAINTS:
				if p[0] == a.trim_prefix("--paint="):
					paint = p
	var world := Node3D.new()
	root.add_child(world)
	var env := Environment.new()
	var sky_mat := PanoramaSkyMaterial.new()
	sky_mat.panorama = load("res://assets/polyhaven/kloofendal_48d_partly_cloudy_puresky/kloofendal_48d_partly_cloudy_puresky_4k.hdr")
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = sky_mat
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.shadow_enabled = true
	world.add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	ground.mesh = plane
	ground.material_override = Pbr.material("asphalt_02", 3.0)
	world.add_child(ground)
	var models := CarLibrary.models()
	var x := 0.0
	for m in models:
		var car: Node3D = m.template.duplicate()
		car.position = Vector3(x, 0, 0)
		world.add_child(car)
		if not paint.is_empty():
			Car.apply_paint(car, m, paint)
		print("CAR|%s|l=%.2f w=%.2f h=%.2f" % [m.name, m.size.z, m.size.x, m.size.y])
		x += m.size.x + 1.6
	var cam := Camera3D.new()
	cam.fov = 62
	world.add_child(cam)
	cam.look_at_from_position(Vector3(x * 0.5, 4.5, -13), Vector3(x * 0.5, 0.6, 1.5), Vector3.UP)
	cam.current = true
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	print("SHEET|", img.save_png(out))
	world.free()
	CarLibrary.release()
	quit()
