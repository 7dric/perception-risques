class_name FfmpegPipe
extends RefCounted
## Sends rendered frames, raw, to an FFmpeg process that encodes them while Godot renders the
## next one (ADR-020). Replaces Movie Maker's PNG output, which took 80 % of the render time.
## (Movie Maker cannot use a script writer: it picks its writer before any script runs.)
##
## FFmpeg writes, in one pass:
##  - <path>.mkv: lossless master (FFV1, RGB), source of the checks and of the final encoding;
##  - <path without .mkv>.preview.mp4 (optional): H.264 to watch the clip quickly, encoded by
##    the NVIDIA GPU (h264_nvenc) when the driver allows it, else by the CPU (libx264).
## Environment: PR_FFMPEG (path of ffmpeg.exe, required), PR_MOVIE_PREVIEW (h264_nvenc,
## libx264 or 0 for no preview; chosen by tools/lib/render.mjs).

var path := ""
var frames := 0
var _pipe: FileAccess
var _err: FileAccess
var _pid := -1
var _size := Vector2i.ZERO
var _fps := 30
var _format := -1


func _init(movie_path: String, fps: int) -> void:
	path = movie_path
	_fps = fps


## Writes one frame. FFmpeg starts on the first one, once the image size and format are known.
func write(img: Image) -> Error:
	if _pid < 0:
		var e := _start(img)
		if e != OK:
			return e
	if img.get_format() != _format:
		img.convert(_format)
	_pipe.store_buffer(img.get_data())
	frames += 1
	if _pipe.get_error() != OK:
		printerr("FfmpegPipe : écriture interrompue (image %d) : %s" % [frames, _err.get_as_text()])
		return ERR_FILE_CANT_WRITE
	return OK


## Closes the pipe and waits until FFmpeg has finished writing the files.
func finish() -> Error:
	if _pid < 0:
		return ERR_UNCONFIGURED
	_pipe.close()
	while OS.is_process_running(_pid):
		OS.delay_msec(20)
	var code := OS.get_process_exit_code(_pid)
	_pid = -1
	if code != 0:
		# Only read stderr on failure: reading a closed pipe logs an engine error on Windows.
		printerr("FfmpegPipe : FFmpeg a échoué (code %d) : %s" % [code, _err.get_as_text().strip_edges()])
		return FAILED
	print("MOVIE|%s|%d frames" % [path, frames])
	return OK


func _start(img: Image) -> Error:
	var ffmpeg := OS.get_environment("PR_FFMPEG")
	if ffmpeg == "":
		printerr("FfmpegPipe : variable PR_FFMPEG absente (chemin de ffmpeg.exe)")
		return ERR_UNCONFIGURED
	_format = img.get_format()
	_size = img.get_size()
	var pix: String = {Image.FORMAT_RGBA8: "rgba", Image.FORMAT_RGB8: "rgb24"}.get(_format, "")
	if pix == "":
		_format = Image.FORMAT_RGBA8
		pix = "rgba"
	var args := PackedStringArray([
		"-hide_banner", "-loglevel", "error", "-nostats", "-y",
		"-f", "rawvideo", "-pix_fmt", pix, "-s", "%dx%d" % [_size.x, _size.y], "-r", str(_fps),
		"-i", "-",
		"-map", "0:v", "-c:v", "ffv1", "-level", "3", "-threads", "16", "-slices", "24",
		"-slicecrc", "1", "-g", "1", "-pix_fmt", "bgr0", path,
	])
	var preview := OS.get_environment("PR_MOVIE_PREVIEW")
	if preview == "h264_nvenc":
		args.append_array(["-map", "0:v", "-c:v", "h264_nvenc", "-preset", "p5", "-rc", "vbr",
			"-cq", "24", "-b:v", "0"])
	elif preview == "libx264":
		args.append_array(["-map", "0:v", "-c:v", "libx264", "-preset", "veryfast", "-crf", "23"])
	if preview in ["h264_nvenc", "libx264"]:
		args.append_array(["-pix_fmt", "yuv420p", "-movflags", "+faststart",
			path.get_basename() + ".preview.mp4"])
	var proc := OS.execute_with_pipe(ffmpeg, args, true)
	if proc.is_empty():
		printerr("FfmpegPipe : impossible de lancer FFmpeg (%s)" % ffmpeg)
		return ERR_CANT_CREATE
	_pipe = proc.stdio
	_err = proc.stderr
	_pid = proc.pid
	return OK
