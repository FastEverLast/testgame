extends Area2D

@export_multiline var text : String = "..."
@export var memory_reward := 0
@onready var prompt : Label = $Prompt

var _player_inside = false
var _rewarded = false

func _on_body_entered(_body):
	_player_inside = true
	prompt.visible = true

func _on_body_exited(_body):
	_player_inside = false
	prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside:
		return
	if not event.is_action_pressed("interact"):
		return
	var box = get_tree().get_first_node_in_group("textbox")
	if box == null or box.is_open():
		return
	box.show_text(text)
	get_viewport().set_input_as_handled()
	
	if memory_reward != 0 and not _rewarded:
		GameState.change_memory(memory_reward) 
		_rewarded = true
