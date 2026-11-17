class_name Dashboard
extends Control
## Speedometer and turn signals, drawn with our own graphics (ADR-012).

## Normalized screen area of the dashboard (used to mask the windshield annotations).
const AREA := Rect2(0.42, 0.8, 0.16, 0.2)

var speed_kmh := 0.0
var left_signal := false
var right_signal := false
## Clip time (s): makes the turn signals blink deterministically.
var time := 0.0


func show_state(p_speed_kmh: float, p_time: float, p_left := false, p_right := false) -> void:
	speed_kmh = p_speed_kmh
	time = p_time
	left_signal = p_left
	right_signal = p_right
	queue_redraw()


func _draw() -> void:
	var s := size / Vector2(1920, 1080)
	var center := Vector2(960, 985) * s
	var radius := 82.0 * s.y
	var font := ThemeDB.fallback_font
	# Dial.
	draw_circle(center, radius + 10 * s.y, Color(0.02, 0.02, 0.025, 0.92))
	draw_arc(center, radius, 0, TAU, 64, Color(0.35, 0.37, 0.4), 2.0 * s.y, true)
	var start := deg_to_rad(135.0)
	var sweep := deg_to_rad(270.0)
	for kmh in range(0, 141, 10):
		if kmh in [0, 140]:
			continue  # keeps the bottom of the dial free for the digital speed
		var a := start + sweep * kmh / 140.0
		var dir := Vector2(cos(a), sin(a))
		var inner := radius * (0.78 if kmh % 20 == 0 else 0.86)
		draw_line(center + dir * inner, center + dir * radius * 0.95, Color(0.85, 0.87, 0.9), 2.0 * s.y, true)
		if kmh % 20 == 0:
			var txt := str(kmh)
			var fs := int(13 * s.y)
			var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(font, center + dir * radius * 0.6 - Vector2(w / 2.0, -fs / 3.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.75, 0.77, 0.8))
	# Needle.
	var a_needle := start + sweep * clampf(speed_kmh, 0, 140) / 140.0
	draw_line(center, center + Vector2(cos(a_needle), sin(a_needle)) * radius * 0.88, Color(0.95, 0.35, 0.15), 3.0 * s.y, true)
	draw_circle(center, 6 * s.y, Color(0.6, 0.6, 0.62))
	# Digital speed.
	var fs_big := int(17 * s.y)
	var label := "%d km/h" % roundi(speed_kmh)
	var lw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs_big).x
	draw_string(font, center + Vector2(-lw / 2.0, radius * 0.38), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs_big, Color(0.95, 0.95, 0.95))
	# Turn signals: blink at 1.5 Hz.
	var on := fmod(time * 1.5, 1.0) < 0.5
	_arrow(center + Vector2(-radius - 48 * s.y, -radius * 0.55), -1.0, left_signal and on, s.y)
	_arrow(center + Vector2(radius + 48 * s.y, -radius * 0.55), 1.0, right_signal and on, s.y)


func _arrow(at: Vector2, dir: float, lit: bool, k: float) -> void:
	var col := Color(0.2, 0.95, 0.35) if lit else Color(0.16, 0.2, 0.17)
	var pts := PackedVector2Array([
		at + Vector2(dir * 20, 0) * k, at + Vector2(dir * 2, -16) * k, at + Vector2(dir * 2, -7) * k,
		at + Vector2(-dir * 18, -7) * k, at + Vector2(-dir * 18, 7) * k, at + Vector2(dir * 2, 7) * k,
		at + Vector2(dir * 2, 16) * k,
	])
	draw_colored_polygon(pts, col)
