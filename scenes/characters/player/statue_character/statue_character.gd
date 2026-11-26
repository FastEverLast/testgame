extends CharacterBody2D

var _player : Node2D = null
var _pushing := false

# Constants are better
const _push_speed := 30.0	# Higher number = lighter, Lower number = heavier 

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING 	# Fixes issues so godot doesn't treat up and down differently from left and right
														# i.e. the makes the statue have a constant speed in all directions
	_player = get_tree().get_first_node_in_group("player")
	velocity = Vector2(0,0)
		
func _physics_process(delta: float) -> void:
	var target_velocity = Vector2.ZERO 	# If it is velocity, everything is very jittery

	if _pushing and (_player.velocity != Vector2.ZERO):
		var to_statue : Vector2 = _player.global_position.direction_to(global_position)
		var move_dir : Vector2 = _player.velocity.normalized()

		if move_dir.dot(to_statue) > 0.7:
			target_velocity = move_dir * _push_speed

	velocity = target_velocity	
	move_and_slide()


func _on_detection_body_entered(body: Node2D) -> void:
	if body == _player:
		_pushing = true


func _on_detection_body_exited(body: Node2D) -> void:
	if body == _player:
		_pushing = false
