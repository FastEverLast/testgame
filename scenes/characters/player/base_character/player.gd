extends CharacterBody2D

@export var speed := 200
@export var step_interval := 0.35
@export var step_starts_coarse: Array[float] = [0.64, 1.12, 1.59]
@export var step_starts: Array[float] = [ 0.48, 0.79]
@export var step_length := 0.20
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var statue_instance = preload("res://scenes/characters/player/statue_character/statue_character.tscn")
@onready var cat_sprite: AnimatedSprite2D = $CatForm
@onready var active_sprite = $AnimatedSprite2D
@onready var footsteps : AudioStreamPlayer = $Footsteps_base

var _statue: Node2D # re-added: holds the current statue
var last_direction: Vector2 = Vector2.DOWN
var _step_timer := 0.0
var _last_played : int = 0

func _ready() -> void:
	GameState.form_changed.connect(_on_form_changed)
	_on_form_changed(GameState.current_form)
	
func _change_animation(form) -> void:
	if form == GameState.Form.CAT:
		active_sprite = cat_sprite
	else:
		active_sprite = sprite
	
func _update_animation(direction : Vector2):
	var dir_name : String
	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x > 0:
			dir_name = "right"
		else:
			dir_name = "left"
	else:
		if last_direction.y > 0:
			dir_name = "down"
		else:
			dir_name = "up"
	
	if direction != Vector2.ZERO:
		active_sprite.play("walk_" + dir_name)
	else:
		active_sprite.play("idle_" + dir_name)

func _on_form_changed(form):	
	_change_animation(form)
	
	set_collision_mask_value(9, form != GameState.Form.CAT)
	
	sprite.visible = form != GameState.Form.CAT
	cat_sprite.visible = form == GameState.Form.CAT
	
	match form:
		GameState.Form.BASE:
			sprite.modulate = Color.WHITE
		GameState.Form.GUARD:
			sprite.modulate = Color.BLUE
		GameState.Form.CAT:
			pass
		GameState.Form.STATUE:
			sprite.modulate = Color.WHITE
			if is_instance_valid(_statue):
				_statue.queue_free()
				
			var new_statue = statue_instance.instantiate()
			new_statue.position = position
			_statue = new_statue # re-added: remember the new statue
			add_sibling(new_statue)

func _physics_process(_delta: float) -> void:
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if GameState.wheel_open == false:
		velocity = direction * speed
		_handle_footsteps(_delta)

		if direction != Vector2.ZERO:
			last_direction = direction.normalized()

		move_and_slide()
		_update_animation(direction)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("form_base"):
		GameState.shift_to(GameState.Form.BASE)
	if event.is_action_pressed("form_guard"):
		GameState.shift_to(GameState.Form.GUARD)
	if event.is_action_pressed("form_cat"):
		GameState.shift_to(GameState.Form.CAT)
	if event.is_action_pressed("form_statue"):
		GameState.shift_to(GameState.Form.STATUE)

	if event.is_action_pressed("debug_reset"):
		SceneManager.restart_level()

func _handle_footsteps(delta):
	if get_real_velocity().length() < 5.0:
		_step_timer = 0.0
		return
		
	_step_timer -= delta	# Counts down in seconds
	
	if _step_timer <= 0.0:
		_play_step()
		_step_timer = step_interval
		
func _play_step():
	footsteps.stream = load("res://assets/audio/sfx/game/footsteps_heavy.wav")
	footsteps.volume_db = randf_range(-10.0, -9.0)
	footsteps.pitch_scale = randf_range(0.9, 1.0)
	
	var start : float = step_starts.pick_random()
	footsteps.play(start)
	await get_tree().create_timer(step_length).timeout
	footsteps.stop()
	_last_played = 1
