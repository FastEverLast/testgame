extends Node2D

@onready var ShiftButton := $Shift
@onready var screen_popup: Node2D = $"."
@onready var _player : Node2D

var _shifted := false

const wait_time := 0.45

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	screen_popup.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("wheel_open"):
		_shifted = true

func _on_big_gate_interacted():		# Used to make sure the button doesn't appear multiple times because that would be weird...
	if GameState.current_form != GameState.Form.GUARD:			#
		screen_popup.visible = true								#
																#
func _on_vent_double_wall_walked():#  <-------------------------#
	_shifted = false											#
	await get_tree().create_timer(wait_time, false).timeout		#
	if GameState.current_form != GameState.Form.CAT:			#
		screen_popup.visible = true								#
																#
func _on_floor_button_released():#  <---------------------------/
	_shifted = false
	await get_tree().create_timer(wait_time, false).timeout
	if _does_statue_exist() == false:
		screen_popup.visible = true
	
func _does_statue_exist() -> bool:
	for sibling in (get_parent().get_parent()).get_children():
		if sibling != self and (sibling is Statue): 	# Check if the statue is already an instance before showing the button again
			return true
		
	return false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if _shifted == false:
		screen_popup.global_position = _player.global_position
	elif _shifted == true:
		screen_popup.visible = false
