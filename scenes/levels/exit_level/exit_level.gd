extends Area2D

@export_file("*.tscn") var next_level : String
@export var locked := false
@onready var sprite : Sprite2D = $Sprite2D

func _on_body_entered(_body):
	if next_level == "":
		return
	if locked:
		return
	GameState.prepare_next_level()
	SceneManager.change_level(next_level)

func _update_look():
	if locked:
		sprite.modulate = Color(0.4, 0.4, 0.4)
	else:
		sprite.modulate = Color.WHITE

func _ready() -> void:
	_update_look()

func unlock():
	locked = false
	_update_look()

func lock():
	locked = true
	_update_look()
