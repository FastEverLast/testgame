extends Area2D

enum Dir{UP, DOWN, LEFT, RIGHT}

@export var direction : Dir = Dir.RIGHT
@export var distance := 80.0
@export var pan_time := 0.9
@export var zoom_out := 0.1
@export var hold_time := 2.2

static var _tween : Tween
static var _pan_id := 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
	_pan(_offset_for_direction(), -zoom_out)
	if hold_time <= 0.0:
		return
	var id := _pan_id
	await get_tree().create_timer(hold_time, false).timeout
	if id != _pan_id:
		return
	_pan(Vector2.ZERO, 0.0)

func _on_body_exited(body):
	if not body.is_in_group("player"):
		return
	_pan(Vector2.ZERO, 0.0)

func _offset_for_direction():
	match direction:
		Dir.UP: 
			return Vector2(0, -distance)
		Dir.DOWN:
			return Vector2(0, distance)
		Dir.LEFT:
			return Vector2(-distance, 0)
		Dir.RIGHT:
			return Vector2(distance, 0)

func _pan(target_offset, zoom_change):
	_pan_id += 1
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	if not cam.has_meta("base_zoom"): cam.set_meta("base_zoom", cam.zoom)
	
	var base : Vector2 = cam.get_meta("base_zoom")
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(cam, "offset", target_offset, pan_time)
	_tween.tween_property(cam, "zoom", base + Vector2.ONE * zoom_change, pan_time)
