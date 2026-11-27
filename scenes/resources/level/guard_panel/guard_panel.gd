extends Area2D

signal activated
@onready var prompt : Label = $Prompt
@onready var sprite : Sprite2D = $Sprite2D
var _player_inside := false
var _used := false


func _on_body_entered(_body):
	_player_inside = true
	if not _used:
		prompt.visible = true

func _on_body_exited(_body):
	_player_inside = false
	prompt.visible = false
	
func _unhandled_input(event: InputEvent) -> void:
	if _used or not _player_inside:
		return
	if not event.is_action_pressed("interact"):
		return
	var box = get_tree().get_first_node_in_group("textbox")
	if box != null and box.is_open():
		return
	if GameState.current_form != GameState.Form.GUARD:
		if box != null:
			box.show_text("The panel wants a guard's badge.")
		get_viewport().set_input_as_handled()
		return
	
	_used = true
	prompt.visible = false
	sprite.modulate = Color.GREEN
	activated.emit()


func _on_guard_panel_helper_body_ent() -> void:
	_used = false
	sprite.modulate = Color.WHITE
	# play click sfx maybe?
