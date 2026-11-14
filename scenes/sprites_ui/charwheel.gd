extends Node2D

@onready var wheel : AnimatedSprite2D = $Wheel
const INNER_RADIUS = 10.0
const OUTER_RADIUS = 48.0
var _hovered : int = -1

func _ready() -> void:
	visible = false
	wheel.frame = 0
	GameState.wheel_open = false
	
func _open():
	visible = true
	GameState.wheel_open = true
	_set_hovered(-1)

func _close():
	visible = false
	GameState.wheel_open = false
	
func _confirm():
	if _hovered != -1:
		GameState.shift_to(_hovered) # Shift to the selected form
		_close()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("wheel_open"):
		if visible:
			_close() # If the wheel is already open, close it
		else:
			_open()
		return
	
	if not visible:
		return
	elif event.is_action_pressed("move_up"):
		_set_hovered(GameState.Form.BASE)
	elif event.is_action_pressed("move_right"):
		_set_hovered(GameState.Form.GUARD)
	elif event.is_action_pressed("move_down"):
		_set_hovered(GameState.Form.CAT)
	elif event.is_action_pressed("move_left"):
		_set_hovered(GameState.Form.STATUE)
	
	if event.is_action_pressed("wheel_confirm") or event.is_action_pressed("wheel_select"):
		_confirm()
	
	if event is InputEventMouseMotion:
		_hover_from_mouse()


func _hover_from_mouse():
	var offset: Vector2 = wheel.get_local_mouse_position()
	var dist := offset.length()
	
	if dist < INNER_RADIUS or dist > OUTER_RADIUS:
		_set_hovered(-1)
		return
	
	if abs(offset.y) > abs(offset.x):
		if offset.y < 0:
			_set_hovered(GameState.Form.BASE)
		else:
			_set_hovered(GameState.Form.CAT)
	else:
		if offset.x > 0:
			_set_hovered(GameState.Form.GUARD)
		else:
			_set_hovered(GameState.Form.STATUE)

func _set_hovered(form: int):
	if form == _hovered:
		return
	_hovered = form
	wheel.frame = 0 if form == -1 else form + 1
	if form != -1:
		UiAudio.play_hover()
