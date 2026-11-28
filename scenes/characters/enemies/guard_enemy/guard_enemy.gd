extends CharacterBody2D

enum State { PATROL, SUSPICIOUS, ALERT, TALKING }

@export var patrol_offsets : Array[Vector2] = [Vector2(96, 0)]		# The point the guard is going to, we can make it an array for more complex shapes
@export var patrol_speed : float = 40.0
@export var chase_speed : float = 85.0
@export var creep_speed : float = 12.0
@export var sus_time : float = 1.4				# How long until he starts chasing after he saw you
@export var lose_time : float = 3.0				# How long to keep searching after he cant se you anymore
@export var search_reach : float = 128.0			# How far the guard checks if there is a wall in the way before starting to patrol
@export var detects_disguise := false
@export var step_interval := 0.17
@export var distance_sus := false
@export var maximise_distance := false
@export var patrol_offsets_high : Array[Vector2] = [Vector2(96, 0)]
@export var comedic_timing := false

@onready var vision : Node2D = $Vision			# We rotate this to turn the guards view
@onready var los : RayCast2D = $LineOfSight		# Line of sight
@onready var alert_label : Label = $LineOfSight/Alert
@onready var cone_visual : Sprite2D = $Vision/ConeVisual
@onready var beam_material : ShaderMaterial = cone_visual.material
@onready var footsteps : AudioStreamPlayer = $Footsteps_guard
@onready var step_starts : Array[float] = [0.17]
@onready var step_length := 0.10
@onready var patrol_up : RayCast2D = $Patrol_Up
@onready var patrol_down : RayCast2D = $Patrol_Down
@onready var patrol_left : RayCast2D = $Patrol_Left
@onready var patrol_right : RayCast2D = $Patrol_Right
@onready var prev_pos : Vector2

var _state: int = State.PATROL
var _points : Array[Vector2]		# The different places the guard is going to stop at
var _index := 0						# The stop he is currently driving to - Fast here DRIVIG???
var _player : Node2D = null			# Gets filled after the player (you) first walks into the enemies vision cone
var _in_cone := false
var _suspicion := 0.0				# 0.0 is nothing and 1.0 is certain
var _lost_timer := 0.0				# How many seconds the guard has been chasing the player without seeing him
var _last_seen : Vector2 = Vector2.ZERO		# Last position the guard saw the player, he moves toward it every frame
var _caught := false
var _step_timer := 0.0
var _step_count := 0
var talking := false	# True while he is in conversation, which means that he cannot move
var look_target : Node2D = null
var _resetting := false
var _start_attack := false
var target_patrol: Vector2
var start_patrol := true

const PATROL_COLOR := Color(0.9, 0.95, 1.0, 0.16)
const SUS_COLOR := Color(1.0, 0.55, 0.0, 0.40)
const ALERT_COLOR := Color(1.0, 0.1, 0.1, 0.45)
const CONE_STEPS := 4

func _ready() -> void:
	_points = [global_position]	# The array is populated, with the current position as the first stop, and the current pos
								# plus the offset specified above as the second position 
	for offset in patrol_offsets:
		_points.append(global_position + offset)
	
	# print(self.name, ": ", _points)
	
	_player = get_tree().get_first_node_in_group("player")
	
	if detects_disguise:
		$Sprite2D.modulate = Color(1.0, 0.85, 0.3)
	
	if comedic_timing:
		start_patrol = false
	
	_set_state(State.PATROL)

func _on_cone_body_entered(body) -> void:	# Body can only be the player, since the mask is set to the player
	if not body.is_in_group("player"): 
		return
	_player = body		# Fills the variable that was previously null
	_in_cone = true

func _on_cone_body_exited(body) -> void:	# The _body just means that we are not using the body now
	if not body.is_in_group("player"): 
		return
	_in_cone = false

func _can_see_player() -> bool:
	if _in_cone == false:			
		return false
		
	if GameState.hidden_count > 0:
		return false
			
	if GameState.current_form == GameState.Form.GUARD and not detects_disguise:	# Guard does not detect the player when he is in the guard form
		return false
	
	los.target_position = los.to_local(_player.global_position + Vector2(0, -8))	# The raycast "lazer". The raycast is aimed at the player, and moved 8 pixels up, so
	los.force_raycast_update()														# that the raycast aims at his chest.
	
	return not los.is_colliding()	# The raycast only collides with walls. Since the raycast is aimed at the player, this checks if there is a wall between the plyer and enemy.
									# Returns false if it hits a wall, and true when he does not. 
	
func _move_toward(target: Vector2, speed: float) -> void:
	if (_player != null) and ((target == _player.global_position) and (_can_see_player() == false)): # So that the enemy doesn't chase you if you are behind a wall
		return		
	else:
		var dir: Vector2 = global_position.direction_to(target)		# Direction to gives an arrow of length 1 that points at the target	
		velocity = dir * speed			# Moves the enemy in a certain direction (dir) at a certain speed (speed)
		vision.rotation = dir.angle()	# Rotates the red vision cone towards the player, so that he can detect the player again
		move_and_slide()

func _guard_sfx(delta) -> void:	
	if _state == State.ALERT:
		if (footsteps.playing == false):
			if get_real_velocity().length() < 5.0:
				_step_timer = 0.0
				return
				
			_step_timer -= delta	# Counts down in seconds
			
			if global_position.distance_to(prev_pos) > 0.5:
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

			prev_pos = global_position


func _set_state(new_state):		# Changes the guards "mood"
	_state = new_state			# Store the new mood
	_lost_timer = 0.0			# Reset "lost you" timer
	if new_state == State.PATROL:	# If he is now on patrol, empty the suspicion meter
		_suspicion = 0.0
	
	match new_state:	# Case statement that displays something else in the label based on the mood
		State.PATROL : 
			alert_label.text = ""
			beam_material.set_shader_parameter("beam_color", PATROL_COLOR)
		State.SUSPICIOUS : 	
			alert_label.text = "?"
			beam_material.set_shader_parameter("beam_color", SUS_COLOR)
		State.ALERT : 
			alert_label.text = "!"
			beam_material.set_shader_parameter("beam_color", ALERT_COLOR)
	
func _patrol(sees) -> void:
	if _resetting == false:
		if start_patrol:
			if sees == true:	# The "sees" comes from the can_see_player variable
				_set_state(State.SUSPICIOUS)
				return
				
			target_patrol = _points[_index]
	
			if global_position.distance_to(target_patrol) < 2.0:	# If he is within 2 pixels of the stop, it counts as him arriving
				_index = (_index + 1) % _points.size()		# Increase the index by one to go to the next stop on the list. We mod with 2 right now since there are only 2 points
															# which means that the index will either be 0 or 1, so the guard just moves between index 0 and 1
			else:
				_move_toward(target_patrol, patrol_speed)	# If he is not close enough, walk towords the point at patrol_speed

func _suspicious(delta, sees):	# Delta is the number of seconds since the last frame, a very small number
	if _resetting == false:
		if sees:
			var time := sus_time
			if distance_sus:
				var distance := global_position.distance_to(_player.global_position)
				if distance > 65:
					time = sus_time * 0.67
				elif distance > 40:
					time = sus_time * 0.82
			_suspicion += delta / time	# Adds this very small number to the sus time, every second
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
			
		beam_material.set_shader_parameter("beam_color", SUS_COLOR.lerp(ALERT_COLOR, clampf(_suspicion, 0.0, 1.0)))
	
	
func _repatrol(_position_guard, reason) -> void:	# Starts patrolling in the new position
	if _resetting == false:
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
			var buffer_distance := 12	# Important, otherwise the distance the guard can walk is smaller than its hitbox, causing it to get stuck
			
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

func _alert(delta, sees):
	if _resetting == false:
		if sees:
			_last_seen = _player.global_position	# If he sees you, he sets the last_seen pos to your current positon
			_lost_timer = 0.0						# Reset lost timer, because he sees you...
			_move_toward(_last_seen, chase_speed)
			
			if global_position.distance_to(_player.global_position) < 14.0 and not _caught: # If you are within 14 pixels of him, and _caught is still false, make it true
				_caught = true
				SceneManager.caught() # Pretty obvious what this does...
		else:
			_lost_timer += delta
				
			if global_position.distance_to(_last_seen) > 4.0:	# If he is more than 4 pixels away from where he last saw you, keep running there!
				_move_toward(_last_seen, chase_speed)
				
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
	if SceneManager.busy or SceneManager.catching or (_resetting == true):
		return
	
	if talking:
		if look_target != null:
			vision.rotation = global_position.direction_to(look_target.global_position).angle()
			return
	
	if talking == false:
		if _player != null and not _caught:
			if global_position.distance_to(_player.global_position) < 14.0 and (GameState.current_form != GameState.Form.GUARD or detects_disguise) and GameState.hidden_count == 0:
				_caught = true
				SceneManager.caught()
				return
		
		var sees := _can_see_player()	# Asks the question and stores the "true" or "false" answer
	
		_guard_sfx(delta)				# Always run _guard_sfx
		if _start_attack:
			_set_state(State.ALERT)
			_alert(delta, true)
			target_patrol = _points[_index]
		else:
			match _state:					# Call the right function depending on his mood
				State.PATROL : _patrol(sees)
				State.SUSPICIOUS : _suspicious(delta, sees)
				State.ALERT : _alert(delta, sees)


func _on_conversation_helper_maximise_dist() -> void:
	if maximise_distance:
		_resetting = true
		_points = []
		for p in range(patrol_offsets_high.size()):
			_points.append(patrol_offsets_high[p])
		patrol_speed = patrol_speed * 1.4
		_resetting = false


func _on_floor_button_activated() -> void:
	if maximise_distance:
		_resetting = true
		_points = []
		for p in range(patrol_offsets_high.size()):
			_points.append(patrol_offsets_high[p])
		_resetting = false


func _on_comedic_timing_body_entered(body: Node2D) -> void:
	if body == _player:
		start_patrol = true


func _on_conversation_helper_get_him() -> void:
	await get_tree().create_timer(0.05).timeout # Enough time to realise oh no...
	_start_attack = true


func _on_conversation_helper_stop_attack() -> void:
	_start_attack = false
