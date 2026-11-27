extends Area2D

@export_file("*.tscn") var next_level : String
@export var direction_in := Vector2.LEFT
@export var locked := false
@onready var sprite : Sprite2D = $Sprite2D

var _player : Node2D = null
var walk_direction : Vector2
var walk_time := 0.9

func _on_body_entered(body):
	if next_level == "":
		if body.is_in_group("player"):
			GameState.reading = true
			_player.talk_direction = walk_direction
			await get_tree().create_timer(walk_time, false).timeout
			_player.talk_direction = Vector2.ZERO
			GameState.reading = false
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
	walk_direction = direction_in
	_player = get_tree().get_first_node_in_group("player")
	_update_look()

func unlock():
	locked = false
	_update_look()

func lock():
	locked = true
	_update_look()
