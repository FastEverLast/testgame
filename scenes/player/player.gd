extends CharacterBody2D

@export var speed := 300
@onready var sprite: Sprite2D = $Sprite2D
var last_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	GameState.form_changed.connect(_on_form_changed)
	_on_form_changed(GameState.current_form)

func _on_form_changed(form):
	match form:
		GameState.Form.BASE:
			sprite.modulate = Color.WHITE
		GameState.Form.GUARD:
			sprite.modulate = Color.BLUE
		GameState.Form.CAT:
			sprite.modulate = Color.ORANGE
		GameState.Form.STATUE:
			sprite.modulate = Color.GRAY

func _physics_process(_delta: float) -> void:
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.is_action_pressed("wheel_open") == false:
		velocity = direction * speed
	
		if direction != Vector2.ZERO:
			last_direction = direction.normalized()
	
		move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("form_base"):
		GameState.shift_to(GameState.Form.BASE)
	if event.is_action_pressed("form_guard"):
		GameState.shift_to(GameState.Form.GUARD)
	if event.is_action_pressed("form_cat"):
		GameState.shift_to(GameState.Form.CAT)
	if event.is_action_pressed("form_statue"):
		GameState.shift_to(GameState.Form.STATUE )
	
	if event.is_action_pressed("debug_reset"):
		SceneManager.restart_level()
