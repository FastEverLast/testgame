extends Node2D

@export var free_retries := false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$UI.visible = true
	$UI.visible = true
	GameState.start_level(free_retries)
