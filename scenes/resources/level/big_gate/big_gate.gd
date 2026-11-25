extends Node2D

@export_multiline var message : String = "..."
@export var depth_line := 13.5
@onready var player : Node2D = get_tree().get_first_node_in_group("player")
@onready var body_collision: CollisionShape2D = $StaticBody2D/DoorShape
@onready var sprite: AnimatedSprite2D = $StaticBody2D/AnimatedSprite2D

signal interacted

var _is_open := false
var _told := false
var _player_near := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.stop()
	sprite.frame = 0
	GameState.form_changed.connect(_on_form_changed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if player == null:
		return
	if player.global_position.y > global_position.y + depth_line:
		z_index = -1
	else:
		z_index = 1

func _on_trigger_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if GameState.current_form == GameState.Form.GUARD:
		_open()
	_player_near = true
	if _told or _is_open:
		return
	_told = true
	var box : Node = get_tree().get_first_node_in_group("textbox")
	if box != null:
		box.show_text(message)

func _on_form_changed(form) -> void:
	if form != GameState.Form.GUARD:
		return
	if _is_open or not _player_near:
		return
	_open()

func _on_trigger_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_near = false
		interacted.emit()

func _open() -> void:
	_is_open = true
	body_collision.set_deferred("disabled", true)
	sprite.frame = 1
