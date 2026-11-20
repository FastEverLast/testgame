extends CharacterBody2D

enum State { PATROL, SUSPICIOUS, ALERT }

@export var patrol_offset := Vector2(96, 0)
@export var patrol_speed : float = 40.0
@export var chase_speed : float = 85.0
@export var sus_time : float = 1.4
@export var lose_time : float = 3.0

@onready var vision: Node2D = $Vision
@onready var los: RayCast2D = $LineOfSight
@onready var alert_label: Label = $LineOfSight/Alert

var _state = State.PATROL
var _points : Array[Vector2]
var _index = 0
var _player : Node2D = null
var _in_cone := false
var _suspicion := 0.0
var _lost_timer := 0.0
var _last_seen : Vector2 = Vector2.ZERO
var _caught := false

func _ready() -> void:
	_points = [global_position, global_position + patrol_offset]

func _on_cone_body_entered(body):
	_player = body
	_in_cone = true

func _on_cone_body_exited(_body):
	_in_cone = false

func _can_see_player() -> bool:
	if _in_cone == false:
		return false
	if GameState.current_form == GameState.Form.GUARD:
		return false
	
	los.target_position = los.to_local(_player.global_position + Vector2(0, -8))	
	los.force_raycast_update()
	
	return los.is_colliding()
	
func _move_toward(target: Vector2, speed: float):
	var dir = global_position.direction_to(target)
	velocity = dir * speed
	vision.rotation = dir.angle()
	move_and_slide()
	
func _set_state(new_state):
	_state = new_state
	_lost_timer = 0.0
	if new_state == State.PATROL:
		_suspicion = 0.0
	
	match new_state:
		State.PATROL : alert_label.text = ""
		State.SUSPICIOUS : alert_label.text = "?"
		State.ALERT : alert_label.text = "!"
	
func _patrol(sees):
	if sees == true:
		_set_state(State.SUSPICIOUS)
		return
	
	var target = _points[_index]
	
	if global_position.distance_to(target) < 2.0:
		_index = (_index + 1) % _points.size()
	else:
		_move_toward(target, patrol_speed)

func _suspicious(delta, sees):
	if sees:
		_suspicion += delta / sus_time
		_last_seen = _player.global_position
		vision.rotation = global_position.direction_to(_player.global_position).angle()
	else:
		_suspicion -= delta
	
	
	if _suspicion >= 1.0:
		_set_state(State.ALERT)
	
	if _suspicion <= 0.0:
		_set_state(State.PATROL)

func _alert(delta, sees):
	if sees:
		_last_seen = _player.global_position
		_lost_timer = 0.0
		_move_toward(_last_seen, chase_speed)
		
		if global_position.distance_to(_player.global_position) < 14.0 and not _caught:
			_caught = true
			SceneManager.restart_level()
		else:
			_lost_timer += delta
			
			if global_position.distance_to(_last_seen) > 4.0:
				_move_toward(_last_seen, chase_speed)
			
			if _lost_timer >= lose_time:
				_set_state(State.PATROL)

func _physics_process(delta: float) -> void:
	var sees := _can_see_player()
	match _state:
		State.PATROL : _patrol(sees)
		State.SUSPICIOUS : _suspicious(delta, sees)
		State.ALERT : _alert(delta, sees)
