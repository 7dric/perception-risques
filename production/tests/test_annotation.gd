# Unit tests of the annotation logic (no rendering).
# godot --headless --path production --script res://tests/test_annotation.gd
extends SceneTree

var _failures := 0


func _initialize() -> void:
	_test_linear_motion_keeps_two_keyframes()
	_test_hidden_span()
	_test_turn_adds_keyframe()
	_test_timeline()
	_test_speed_profile_stops()
	print("TESTS|%s|%d échec(s)" % ["OK" if _failures == 0 else "KO", _failures])
	quit(0 if _failures == 0 else 1)


func _rect(x: float, y: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x, y), Vector2(x + 0.1, y), Vector2(x + 0.1, y + 0.2), Vector2(x, y + 0.2)])


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failures += 1
		printerr("ÉCHEC : ", msg)


func _test_linear_motion_keeps_two_keyframes() -> void:
	var seq := []
	for f in 30:
		seq.append(_rect(0.1 + f * 0.01, 0.5))
	var keys := AnnotationRecorder.compress(seq)
	_check(keys.size() == 2, "mouvement linéaire : 2 images clés attendues, %d obtenues" % keys.size())
	_check(keys[0].frame == 0 and keys[-1].frame == 29, "mouvement linéaire : début et fin gardés")


func _test_hidden_span() -> void:
	var seq := []
	for f in 10:
		seq.append(PackedVector2Array())
	for f in 10:
		seq.append(_rect(0.3, 0.3))
	for f in 5:
		seq.append(PackedVector2Array())
	var keys := AnnotationRecorder.compress(seq)
	_check(keys[0].frame == 10, "plage cachée : la piste commence à la première image visible")
	_check(keys[-1].frame == 20 and keys[-1].visible == false, "plage cachée : visible=false quand le danger disparaît")


func _test_turn_adds_keyframe() -> void:
	var seq := []
	for f in 20:
		seq.append(_rect(0.1 + f * 0.01, 0.5))
	for f in 20:
		seq.append(_rect(0.29, 0.5 - f * 0.01))
	var keys := AnnotationRecorder.compress(seq)
	_check(keys.size() >= 3, "changement de direction : au moins 3 images clés")
	for k in keys:
		if k.has("polygon"):
			var orig: PackedVector2Array = seq[k.frame]
			_check(absf(k.polygon[0][0] - orig[0].x) < 0.0002, "image clé %d fidèle à la mesure" % k.frame)


func _test_timeline() -> void:
	var tl := Timeline.new().add(0.0, Vector3.ZERO).walk_to(Vector3(0, 0, -10), 2.0).wait(1.0)
	_check(is_equal_approx(tl.end_time(), 6.0), "timeline : durée de marche")
	_check(tl.position_at(2.5).is_equal_approx(Vector3(0, 0, -5)), "timeline : interpolation")
	_check(tl.heading_at(5.5) == Vector3.ZERO, "timeline : immobile pendant l'attente")


func _test_speed_profile_stops() -> void:
	var p := SpeedProfile.new(10.0).phase(1.0, 0.0).phase(10.0, -2.5).bake(300)
	# 10 m in the first second, then 10² / (2 × 2.5) = 20 m of braking.
	_check(absf(p.distance(299) - 30.0) < 0.2, "profil de vitesse : arrêt à 30 m (%.2f)" % p.distance(299))
	_check(p.speed(299) == 0.0, "profil de vitesse : vitesse nulle à l'arrêt")
	_check(is_equal_approx(p.distance(-30), -10.0), "profil de vitesse : extrapolation avant le début")
