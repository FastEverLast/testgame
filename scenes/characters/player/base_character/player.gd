extends CharacterBody2D

@export var speed  := 200
@export var step_interval := 0.35
@export var step_starts_coarse: Array[float] = [0.64, 1.12, 1.58]
@export var step_starts: Array[float] = [0.48, 0.79]
@export var step_starts_varient: Array[float] = [0.17]
@export var step_length := 0.11
@onready var puff : CPUParticles2D = $Puff
@onready var shift_sound : AudioStreamPlayer = $ShiftSound
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var statue_instance = preload("res://scenes/characters/player/statue_character/statue_character.tscn")
@onready var cat_sprite: AnimatedSprite2D = $CatForm
@onready var active_sprite = $AnimatedSprite2D
@onready var footsteps : AudioStreamPlayer = $Footsteps_base
@onready var _sprite_scale := sprite.scale
@onready var _cat_scale := cat_sprite.scale

var _statue: Node2D # re-added: holds the current statue
var last_direction: Vector2 = Vector2.DOWN
var _step_timer := 0.0
var _flash_tween : Tween
var _squash_tween : Tween

func _ready() -> void:
	GameState.form_changed.connect(_on_form_changed)
	GameState.form_changed.connect(_play_shift_effect)
	_on_form_changed(GameState.current_form)
	
func _play_shift_effect(_form):
	if _flash_tween:
		_flash_tween.kill()
	sprite.self_modulate = Color(3, 3, 3)
	cat_sprite.self_modulate = Color(3, 3, 3)
	_flash_tween = create_tween().set_parallel()
	_flash_tween.tween_property(sprite, "self_modulate", Color.WHITE, 0.3)
	_flash_tween.tween_property(cat_sprite, "self_modulate", Color.WHITE, 0.3)
	shift_sound.pitch_scale = randf_range(0.9, 1.1)
	shift_sound.volume_db = -7.0
	shift_sound.play()
	_squash()
	puff.restart()

func _squash():
	if _squash_tween:
		_squash_tween.kill()
	sprite.scale = _sprite_scale * Vector2(1.4, 0.6)
	cat_sprite.scale = _cat_scale * Vector2(1.4, 0.6)
	
	_squash_tween = create_tween()
	_squash_tween.set_parallel(true)
	_squash_tween.set_trans(Tween.TRANS_BACK)
	_squash_tween.set_ease(Tween.EASE_OUT)
	_squash_tween.tween_property(sprite, "scale", _sprite_scale, 0.25)
	_squash_tween.tween_property(cat_sprite, "scale", _cat_scale, 0.25)

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
	
	if GameState.wheel_open == false and GameState.reading == false:
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

func _handle_footsteps(delta) -> void:
	if get_real_velocity().length() < 5.0:
		_step_timer = 0.0
		return
		
	_step_timer -= delta	# Counts down in seconds
	
	if _step_timer <= 0.0:
		_play_step()
		_step_timer = step_interval
		
func _play_step():
	var _choose_footstep := randi_range(0, 10)
	footsteps.volume_db = randf_range(-10.0, -9.0)
	if range(0,4).has(_choose_footstep):
		footsteps.pitch_scale = randf_range(0.7, 0.8)
		footsteps.stream = load("res://assets/audio/sfx/game/footstep.wav")
		var start : float = step_starts_varient.pick_random() # step_starts for footsteps and footsteps_heavy; step_starts_coarse for footsteps_coarse and step_starts_varient for footstep
		footsteps.play(start)
		
	elif range(4,11).has(_choose_footstep):
		footsteps.pitch_scale = randf_range(0.8, 1.1)
		footsteps.stream = load("res://assets/audio/sfx/game/footsteps.wav")	
		var start : float = step_starts.pick_random() # step_starts for footsteps and footsteps_heavy; step_starts_coarse for footsteps_coarse and step_starts_varient for footstep
		footsteps.play(start)
	
	await get_tree().create_timer(step_length).timeout
	footsteps.stop()
