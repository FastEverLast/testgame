extends Node2D

@onready var ShiftButton := $Shift
@onready var screen_popup: Node2D = $"."
@onready var _player : Node2D

var _interacted := false
var _shifted := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	screen_popup.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("wheel_open"):
		_shifted = true

func _on_big_gate_interacted():
	if _interacted == false:
		screen_popup.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if _shifted == false:
		screen_popup.global_position = _player.global_position
	elif _shifted == true:
		screen_popup.visible = false
