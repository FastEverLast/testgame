extends CharacterBody2D

@export var speed := 300
var last_direction: Vector2 = Vector2.DOWN

func _physics_process(_delta: float) -> void:
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	
	if direction != Vector2.ZERO:
		last_direction = direction.normalized()
	
	move_and_slide()
	
