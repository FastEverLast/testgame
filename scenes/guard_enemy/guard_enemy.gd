extends CharacterBody2D

enum State { PATROL, SUSPICIOUS, ALERT }

@export var patrol_offset := Vector2(96, 0)		# The point the guard is going to, we can make it an array for more complex shapes
@export var patrol_speed : float = 40.0
@export var chase_speed : float = 85.0
@export var sus_time : float = 1.4				# How long until he starts chasing after he saw you
@export var lose_time : float = 3.0				# How long to keep searching after he cant se you anymore

@onready var vision: Node2D = $Vision			# We rotate this to turn the guards view
@onready var los: RayCast2D = $LineOfSight		# Line of sight
@onready var alert_label: Label = $LineOfSight/Alert

var _state: int = State.PATROL
var _points : Array[Vector2]		# The different places the guard is going to stop at
var _index := 0						# The stop he is currently driving to
var _player : Node2D = null			# Gets filled after the player (you) first walks into the enemies vision cone
var _in_cone := false
var _suspicion := 0.0				# 0.0 is nothing and 1.0 is certain
var _lost_timer := 0.0				# How many seconds the guard has been chasing the player without seeing him
var _last_seen : Vector2 = Vector2.ZERO		#Last position the guard saw the player, he moves toward it every frame
var _caught := false

func _ready() -> void:
	_points = [global_position, global_position + patrol_offset]	# The array is populated, with the current position as the first stop, and the current pos
																	# plus the offset specified above as the second position 	
func _on_cone_body_entered(body):	# Body can only be the player, since the mask is set to the player
	_player = body					# Fills the variable that was previously null
	_in_cone = true

func _on_cone_body_exited(_body):	# The _body just means that we are not using the body now
	_in_cone = false

func _can_see_player() -> bool:
	if _in_cone == false:			
		return false
	if GameState.current_form == GameState.Form.GUARD:	# Guard does not detect the player when he is in the guard form
		return false
	
	los.target_position = los.to_local(_player.global_position + Vector2(0, -8))	# The raycast "lazer". The raycast is aimed at the player, and moved 8 pixels up, so
	los.force_raycast_update()														# that the raycast aims at his chest.
	
	return not los.is_colliding()	# The raycast only collides with walls. Since the raycast is aimed at the player, this checks if there is a wall between the plyer and enemy.
									# Returns false if it hits a wall, and true when he does not. 
	
func _move_toward(target: Vector2, speed: float):
	var dir: Vector2 = global_position.direction_to(target)		# Direction to gives an arrow of length 1 that points at the target
	velocity = dir * speed		# Moves the enemy in a certain direction (dir) at a certain speed (speed)
	vision.rotation = dir.angle()	# Rotates the red vision cone towards the player, so that he can detect the player again
	move_and_slide()
	
func _set_state(new_state):		# Changes the guards "mood"
	_state = new_state			# Store the new mood
	_lost_timer = 0.0			# Reset "lost you" timer
	if new_state == State.PATROL:	# If he is now on patrol, empty the suspicion meter
		_suspicion = 0.0
	
	match new_state:	# Case statement that displays something else in the label based on the mood
		State.PATROL : alert_label.text = ""
		State.SUSPICIOUS : alert_label.text = "?"
		State.ALERT : alert_label.text = "!"
	
func _patrol(sees) -> void:
	if sees == true:	# The "sees" comes from the can see player variable
		_set_state(State.SUSPICIOUS)
		return
	
	var target: Vector2 = _points[_index]	# Sets the target where he wants to patrol to. The index specifies which set of coords to walk too.
	
	if global_position.distance_to(target) < 2.0:	# If he is within 2 pixels of the stop, it counts as him arriving
		_index = (_index + 1) % _points.size()		# Increase the index by one to go to the next stop on the list. We mod with 2 right now since there are only 2 points
													# which means that the index will either be 0 or 1, so the guard just moves between index 0 and 1
	else:
		_move_toward(target, patrol_speed)	# If he is not close enough, walk towords the point at patrol_speed

func _suspicious(delta, sees):	# Delta is the number of seconds since the last frame, a very small number
	if sees:
		_suspicion += delta / sus_time	# Adds this very small number to the sus time, every second
		_last_seen = _player.global_position	# REMEMBERS the last place he saw you at
		vision.rotation = global_position.direction_to(_player.global_position).angle()	# Rotate the red vision area to face that last seen position.
	else:
		_suspicion -= delta	# The meter drains in seconds
	
	
	if _suspicion >= 1.0:	# If the meter is full
		_set_state(State.ALERT)
	
	if _suspicion <= 0.0: # If the meter is empty
		_set_state(State.PATROL)

func _alert(delta, sees):
	if sees:
		_last_seen = _player.global_position	# If he sees you, he sets the last_seen pos to your current positon
		_lost_timer = 0.0						# Reset lost timer, because he sees you...
		_move_toward(_last_seen, chase_speed)
		
		if global_position.distance_to(_player.global_position) < 14.0 and not _caught: # If you are within 14 pixels of him, and caught is still false, make it true
			_caught = true
			SceneManager.restart_level() # Pretty obvious what this does...
	else:
		_lost_timer += delta
			
		if global_position.distance_to(_last_seen) > 4.0:	# If he is more than 4 pixels away from where he last saw you, keep running there!
			_move_toward(_last_seen, chase_speed)
			
		if _lost_timer >= lose_time:	# Give up, you lost the player ;)
			_set_state(State.PATROL)

func _physics_process(delta: float) -> void: # Runns 60 times a second
	var sees := _can_see_player()	# Asks the question and stores the "true" or "false" answer
	match _state:	# Call the right function depending on his mood
		State.PATROL : _patrol(sees)
		State.SUSPICIOUS : _suspicious(delta, sees)
		State.ALERT : _alert(delta, sees)
