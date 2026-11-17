# Prints the rendering driver and GPU, then quits. Used by tools/check-env.mjs.
# godot --path production --script res://tools/gpu_info.gd
extends SceneTree


func _initialize() -> void:
	print("GPU_INFO|%s|%s|%s" % [
		RenderingServer.get_current_rendering_driver_name(),
		RenderingServer.get_video_adapter_name(),
		RenderingServer.get_current_rendering_method(),
	])
	quit()
