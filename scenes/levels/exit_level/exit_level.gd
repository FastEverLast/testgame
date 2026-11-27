extends Area2D

@export_file("*.tscn") var next_level : String
@export var direction_in := Vector2.LEFT
@export var locked := false
@onready var sprite : Sprite2D = $Sprite2D

var _player : Node2D = null
var walk_direction : Vector2
var walk_time := 0.9
var _fragment := preload("res://scenes/resources/interactables/fragment/fragment.tscn")
var _used := false

const extra := 20.0

func _on_body_entered(body):
	if next_level == "":
		if body.is_in_group("player"):
			GameState.reading = true
			_player.talk_direction = walk_direction
			await get_tree().create_timer(walk_time, false).timeout
			_player.talk_direction = Vector2.ZERO
			GameState.reading = false
			
			if not GameState.entrances_used.has(get_tree().current_scene.scene_file_path):
				GameState.entrances_used.append(get_tree().current_scene.scene_file_path)
				if GameState.memory <= 2:
					GameState.memory_at_level_start += 4
					for i in range(1, 5):
						var new_fragment = _fragment.instantiate()
						if direction_in == Vector2.LEFT:
							new_fragment.position = global_position - Vector2((i*23), 0) - Vector2(extra, 0)
						elif direction_in == Vector2.RIGHT:
							new_fragment.position = global_position + Vector2((i*23), 0) + Vector2(extra, 0)
						add_sibling(new_fragment)
				else:
					GameState.memory_at_level_start += 2
					for i in range(1, 3):
						var new_fragment = _fragment.instantiate()
						if direction_in == Vector2.LEFT:
							new_fragment.position = global_position - Vector2((i*23), 0) - Vector2(extra, 0)
						elif direction_in == Vector2.RIGHT:
							new_fragment.position = global_position + Vector2((i*23), 0) + Vector2(extra, 0)
						add_sibling(new_fragment)
			_used = true
		return
		
	if locked:
		return
	GameState.prepare_next_level()
	SceneManager.change_level(next_level)
	_used = false


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
