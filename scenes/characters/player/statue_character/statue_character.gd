extends CharacterBody2D
class_name Statue

var _player : Node2D = null
var _pushing := false

# Constants are better
const _push_speed := 60.0	# Higher number = lighter, Lower number = heavier 

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING 	# Fixes issues so godot doesn't treat up and down differently from left and right
														# i.e. the makes the statue have a constant speed in all directions
	_player = get_tree().get_first_node_in_group("player")
	velocity = Vector2(0,0)		# Start standing still
	
	if _player != null:
		_player.add_collision_exception_with(self)
		add_collision_exception_with(_player)


func _physics_process(_delta: float) -> void:
	var target_velocity : Vector2 = Vector2.ZERO
	var input_dir : Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")	# The keys the player holds, not his real velocity (that drops to zero when he is blocked)
	
	if _pushing and input_dir != Vector2.ZERO and GameState.reading == false and GameState.wheel_open == false: # No movement if changing form or reading
		var to_statue : Vector2 = _player.global_position.direction_to(global_position)	# Arrow of length 1 from player to statue
		var move_dir : Vector2 = input_dir.normalized()	# Direction the player wants to walk in, length 1
		
		if move_dir.dot(to_statue) > 0.7:	# The dot product is 1 if both arrows point the same way, 0 if sideways, -1 if opposite. Above 0.7 means the player is walking towards the statue
			target_velocity = move_dir * _push_speed	# Push in the way the player is walking
	
	velocity = target_velocity
	move_and_slide()


func _on_detection_body_entered(body: Node2D) -> void:
	if body == _player:
		_pushing = true
		_player.add_collision_exception_with(self)
		add_collision_exception_with(_player)


func _on_detection_body_exited(body: Node2D) -> void:
	if body == _player:
		_pushing = false
		_player.remove_collision_exception_with(self)
		remove_collision_exception_with(_player)
