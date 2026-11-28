extends CharacterBody2D

enum State { PATROL, SUSPICIOUS, ALERT }

@export var patrol_offsets : Array[Vector2] = [Vector2(96, 0)]		# The point the hound is going to, we can make it an array for more complex shapes
@export var patrol_speed : float = 40.0
@export var chase_speed : float = 85.0
@export var creep_speed : float = 12.0
@export var sus_time : float = 1.4				# How long until he starts chasing after he saw you
@export var lose_time : float = 3.0				# How long to keep searching after he cant se you anymore
@export var search_reach : float = 128.0			# How far the hound checks if there is a wall in the way before starting to patrol
@export var step_interval := 0.17
@export var vent_side_1: Array[Node2D] = []
@export var vent_side_2: Array[Node2D] = []
@export var comedic_timing := false

@onready var vision : Node2D = $Vision			# We rotate this to turn the hounds view
@onready var los : RayCast2D = $LineOfSight		# Line of sight
@onready var alert_label : Label = $LineOfSight/Alert
@onready var footsteps : AudioStreamPlayer = $Footsteps_hound
@onready var step_starts : Array[float] = [0.17]
@onready var step_length := 0.10
@onready var patrol_up : RayCast2D = $Patrol_Up
@onready var patrol_down : RayCast2D = $Patrol_Down
@onready var patrol_left : RayCast2D = $Patrol_Left
@onready var patrol_right : RayCast2D = $Patrol_Right

var _state: int = State.PATROL
var _points : Array[Vector2]		# The different places the hound is going to stop at
var _index := 0						# The stop he is currently driving to - Fast here DRIVIG???
var _player : Node2D = null			# Gets filled after the player (you) first walks into the enemies vision cone
var _in_cone := false
var _suspicion := 0.0				# 0.0 is nothing and 1.0 is certain
var _lost_timer := 0.0				# How many seconds the hound has been chasing the player without seeing him
var _last_seen : Vector2 = Vector2.ZERO		# Last position the hound saw the player, he moves toward it every frame
var _caught := false
var _step_timer := 0.0
var _step_count := 0
var start_patrol := true
var talking := false	# True while he is in conversation, which means that he cannot move
var look_target : Node2D = null
var _chosen := -1	# Index of the vent pair the hound has committed to, -1 means none yet
var _trail : Array[Vector2] = []	# Breadcrumbs of where the player walked, the hound follows these when he cannot see you

func _ready() -> void:
	set_collision_mask_value(9, false)
	_points = [global_position]	# The array is populated, with the current position as the first stop, and the current pos
								# plus the offset specified above as the second position 
	for offset in patrol_offsets:
		_points.append(global_position + offset)
	
	_player = get_tree().get_first_node_in_group("player")
	
	if comedic_timing:
		start_patrol = false

func _on_cone_body_entered(body):	# Body can only be the player, since the mask is set to the player
	if not body.is_in_group("player"): 
		return
	_player = body					# Fills the variable that was previously null
	_in_cone = true

func _on_cone_body_exited(body):	# The _body just means that we are not using the body now
	if not body.is_in_group("player"): 
		return
	_in_cone = false

func _is_target_form() -> bool:
	return GameState.current_form == GameState.Form.CAT or GameState.current_form == GameState.Form.BASE

func _can_see_player() -> bool:
	if _is_target_form():	# hound only detects the player when he is in the cat form
		if _in_cone == false:			
			return false
			
		if GameState.hidden_count > 0:
			return false
		
		los.target_position = los.to_local(_player.global_position + Vector2(0, -8))	# The raycast "lazer". The raycast is aimed at the player, and moved 8 pixels up, so
		los.force_raycast_update()														# that the raycast aims at his chest.
		
		return not los.is_colliding()	# The raycast only collides with walls. Since the raycast is aimed at the player, this checks if there is a wall between the plyer and enemy.
	return false						# Returns false if it hits a wall, and true when he does not. 
	
func _move_toward(target: Vector2, speed: float) -> void:
	if (_player != null) and ((target == _player.global_position) and (_can_see_player() == false)): # So that the enemy doesn't chase you if you are behind a wall
		return		
	else:
		var dir: Vector2 = global_position.direction_to(target)		# Direction to gives an arrow of length 1 that points at the target	
		velocity = dir * speed				# Moves the enemy in a certain direction (dir) at a certain speed (speed)
		vision.rotation = dir.angle()		# Rotates the red vision cone towards the player, so that he can detect the player again
		move_and_slide()

				
func _hound_sfx(delta) -> void:	
	if _state == State.ALERT:
		if (footsteps.playing == false):
			if get_real_velocity().length() < 5.0:
				_step_timer = 0.0
				return
				
			_step_timer -= delta	# Counts down in seconds
			
			if _step_timer <= 0.0:
				if _step_count == 0:
					_step_count = 1
					footsteps.pitch_scale = 1.1
					step_length = 0.06
				elif _step_count == 1:
					_step_count = 0	
					footsteps.pitch_scale = 1.0
					step_length = 0.1
				_step_timer = step_interval
				footsteps.stream = load("res://assets/audio/sfx/game/footstep.wav")	
				footsteps.volume_db = 8.0
				var start : float = step_starts.pick_random() 
				footsteps.play(start)	
				await get_tree().create_timer(step_length).timeout
				footsteps.stop()
		
func _set_state(new_state):		# Changes the hounds "mood"
	_trail.clear()				# A new mood starts with no trail
	_chosen = -1				# Every new mood starts with a fresh vent choice
	_state = new_state			# Store the new mood
	_lost_timer = 0.0			# Reset "lost you" timer
	if new_state == State.PATROL:	# If he is now on patrol, empty the suspicion meter
		_suspicion = 0.0
	
	match new_state:	# Case statement that displays something else in the label based on the mood
		State.PATROL : alert_label.text = ""
		State.SUSPICIOUS : alert_label.text = "?"
		State.ALERT : alert_label.text = "!"
	
func _patrol(sees) -> void:
	if start_patrol:
		if sees == true:	# The "sees" comes from the can_see_player variable
			_set_state(State.SUSPICIOUS)
			return
		
		var target: Vector2 = _points[_index]	# Sets the target where he wants to patrol to. The index specifies which set of coords to walk too.
		
		if global_position.distance_to(target) < 2.0:	# If he is within 2 pixels of the stop, it counts as him arriving
			_index = (_index + 1) % _points.size()		# Increase the index by one to go to the next stop on the list. We mod with 2 right now since there are only 2 points
														# which means that the index will either be 0 or 1, so the hound just moves between index 0 and 1
		else:
			_move_toward(target, patrol_speed)	# If he is not close enough, walk towords the point at patrol_speed

func _suspicious(delta, sees):	# Delta is the number of seconds since the last frame, a very small number
	if sees:
		_suspicion += delta / sus_time	# Adds this very small number to the sus time, every second
		_last_seen = _player.global_position	# REMEMBERS the last place he saw you at
		vision.rotation = (global_position.direction_to(_player.global_position)).angle()	# Rotate the red vision area to face that last seen position.
		
		if global_position.distance_to(_player.global_position) > 20:
			_move_toward(_player.global_position, creep_speed)
	else:
		_suspicion -= delta		# The meter drains in seconds
		if global_position.distance_to(_last_seen) > 4.0:
			_move_toward(_last_seen, creep_speed)
	
	if _suspicion >= 1.0:	# If the meter is full
		_set_state(State.ALERT)
	
	if _suspicion <= 0.0: # If the meter is empty
		_repatrol(global_position, "lost_sucpicion")
		
				
func _repatrol(_position_hound, reason) -> void:	# Starts patrolling in the new position
	if reason == "lost_player":
		var distance_down : float = patrol_down.target_position.length()	# Get the lenght of the vector (128 px)
		if patrol_down.is_colliding():
			distance_down = global_position.distance_to(patrol_down.get_collision_point()) 		# If the raycast collides with anything, make the new distance that point
																								#										|
		var distance_up : float = patrol_up.target_position.length()							#										|
		if patrol_up.is_colliding():															#										|
			distance_up = global_position.distance_to(patrol_up.get_collision_point())			# <-------------------------------------|
																								#										|									 	
		var distance_right : float = patrol_right.target_position.length()						#										|
		if patrol_right.is_colliding():															#										|
			distance_right = global_position.distance_to(patrol_right.get_collision_point())	# <-------------------------------------|
																								#										|
		var distance_left : float = patrol_left.target_position.length()						#										|
		if patrol_left.is_colliding():															#										|
			distance_left = global_position.distance_to(patrol_left.get_collision_point())		# <-------------------------------------|
		
		var horizontal : float = distance_left + distance_right
		var vertical : float = distance_up + distance_down
		var buffer_distance := 12	# Important, otherwise the distance the hound can walk is smaller than its hitbox, causing it to get stuck
		
		if vertical > horizontal:
			if distance_up > 96:
				_points = [global_position, global_position - Vector2(0, 96)] 
			elif distance_down > 96:
				_points = [global_position, global_position + Vector2(0, 96)] 
			else: 	
				_points = [Vector2(global_position.x, global_position.y - distance_up + buffer_distance), Vector2(global_position.x, global_position.y + distance_down - buffer_distance)] 
			
		else:
			if distance_right > 96:
				_points = [global_position, global_position + Vector2(96, 0)] 
			elif distance_left > 96:
				_points = [global_position, global_position - Vector2(96, 0)] 
			else: 	
				_points = [Vector2(global_position.x - distance_left + buffer_distance, global_position.y), Vector2(global_position.x + distance_right - buffer_distance, global_position.y)] 
	
		_index = 0	# Walk to the second point first		
			
	_set_state(State.PATROL)
				
	# elif reason == "lost_sucpicion":

# Works out where the hound should walk: the target itself, or a vent entrance if a wall is in the way
func _funnel_target(target: Vector2) -> Vector2:
	var count := mini(vent_side_1.size(), vent_side_2.size())	# Only as many pairs as both lists have

	# Rule 1: the target is inside a vent shaft, so the player went through that vent
	for i in count:
		if vent_side_1[i] == null or vent_side_2[i] == null:
			continue
		var vent_x : float = vent_side_1[i].global_position.x
		var north_y : float = vent_side_1[i].global_position.y
		var south_y : float = vent_side_2[i].global_position.y
		if abs(target.x - vent_x) < 16.0 and target.y >= north_y and target.y <= south_y:
			_chosen = i
			return _funnel_for_pair(vent_side_1[i], vent_side_2[i], target)

	# Rule 2: keep the vent we already picked, until its wall is no longer in the way
	if _chosen >= 0 and _chosen < count and vent_side_1[_chosen] != null and vent_side_2[_chosen] != null:
		var kept := _funnel_for_pair(vent_side_1[_chosen], vent_side_2[_chosen], target)
		if kept != target:
			return kept
		_chosen = -1	# We are through it, free to pick the next one

	# Rule 3: no vent chosen yet, take the one with the shortest trip (hound to vent plus vent to target)
	var best := target
	var best_cost := INF
	var best_index := -1
	for i in count:
		if vent_side_1[i] == null or vent_side_2[i] == null:
			continue
		var result := _funnel_for_pair(vent_side_1[i], vent_side_2[i], target)
		if result == target:
			continue	# This vent is not in the way
		var middle := (vent_side_1[i].global_position + vent_side_2[i].global_position) / 2.0	# The middle of this vent
		var cost := global_position.distance_to(middle) + middle.distance_to(target)
		if cost < best_cost:
			best = result
			best_cost = cost
			best_index = i

	_chosen = best_index	# Remember the pick so it cannot change next frame
	return best

# Returns where the hound should walk right now. Usually the target itself, but if a wall is in the way, it returns the vent entrance instead.
func _funnel_for_pair(side_1: Node2D, side_2: Node2D, target: Vector2) -> Vector2:
	var vent_x : float = side_1.global_position.x # The x pos of the vent opening, both sides share it
	var north_y : float = side_1.global_position.y # Vent side 1's north edge
	var south_y : float = side_2.global_position.y # Vent side 2's south edge
	var misaligned : bool = abs(global_position.x - vent_x) > 10.0 # Mesures how far the hound is from the real entrance, if that distance is more than 10px
	var entrance_north := Vector2(vent_x, north_y - 25.0) # A spot 25 px north of the vents north side
	var entrance_south := Vector2(vent_x, south_y + 25.0)
	
	if global_position.y < north_y and target.y >= north_y: # If the hound is north of the wall and the target is at or past the wall
		if misaligned:		# Not lined up with vent, so move to entrance
			return entrance_north
		if target.y > south_y:
			return entrance_south	# Properly lined up, walk through
		return target
	
	if global_position.y > south_y and target.y <= south_y: # Same as above, but the hound is on the south side
		if misaligned:
			return entrance_south
		if target.y < north_y:
			return entrance_north
		return target
		
	if global_position.y >= north_y and global_position.y <= south_y: # Hound is inside the vent, leave through side the target is on
		if target.y > south_y:
			return entrance_south
		if target.y < north_y:
			return entrance_north
	return target 	# Nothing in the way, go to the target!

# Drops a breadcrumb at the player's position if he has moved far enough from the last one
func _record_trail() -> void:
	if _player == null:
		return
	if GameState.hidden_count > 0:	# Hidden players leave no scent
		return
	if not _is_target_form():	# Guards leave no scent for hounds
		return
	if _trail.is_empty() or _player.global_position.distance_to(_trail.back()) > 6.0:
		_trail.append(_player.global_position)
		if _trail.size() > 600:	# Safety: never let the trail grow forever
			_trail.remove_at(0)

func _alert(delta, sees):
	if sees:
		_last_seen = _player.global_position	# If he sees you, he sets the last_seen pos to your current positon
		_lost_timer = 0.0						# Reset lost timer, because he sees you...
		_trail.clear()							# He can see you, so the old trail is not needed...
		_record_trail()							# ...except for one crumb: where you are right now
		
		_move_toward(_player.global_position, chase_speed)	# Run straight at you
		
		if global_position.distance_to(_player.global_position) < 14.0 and not _caught: # If you are within 14 pixels of him, and _caught is still false, make it true
			_caught = true
			SceneManager.caught() # Pretty obvious what this does...
	else:
		if not _is_target_form():
			_trail.clear()
		_record_trail()
		
		if _trail.size() > 0:	# Follow the scent, one crumb at a time
			_lost_timer += delta * 0.3	# Counts slowly while tracking, so he cannot get stuck on a wall forever
			var next : Vector2 = _trail[0]
			if global_position.distance_to(next) < 6.0:
				_trail.remove_at(0)	# Reached this crumb, on to the next
			else:
				_move_toward(next, chase_speed)
		else:
			_lost_timer += delta	# The trail is over, now he searches normally
		
		if _lost_timer >= lose_time:	# Give up, you lost the player ;)
			_repatrol(global_position, "lost_player")
			
func start_talking() -> void:
	talking = true
	_set_state(State.PATROL) # Removes beam color and questionmark
	
func stop_talking() -> void:
	talking = false
	look_target = null
	
func face(target : Node2D) -> void:
	look_target = target

func _physics_process(delta: float) -> void: 	# Runs 60 times a second
	if SceneManager.busy or SceneManager.catching:
		return
			
	if talking:
		if look_target != null:
			vision.rotation = global_position.direction_to(look_target.global_position).angle()
			return
	
	if talking == false:
		if _player != null and not _caught:
			if global_position.distance_to(_player.global_position) < 14.0 and _is_target_form() and GameState.hidden_count == 0:
				_caught = true
				SceneManager.caught()
				return
	
		var sees := _can_see_player()	# Asks the question and stores the "true" or "false" answer
		_hound_sfx(delta)				# Always run _hound_sfx
		match _state:					# Call the right function depending on his mood
			State.PATROL : _patrol(sees)
			State.SUSPICIOUS : _suspicious(delta, sees)
			State.ALERT : _alert(delta, sees)


func _on_comedic_timing_body_entered(body: Node2D) -> void:
	if body == _player:
		start_patrol = true
