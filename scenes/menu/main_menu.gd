extends Control

@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var options: Panel = $Options

var _tween:Tween = null

func _ready() -> void:
	v_box_container.visible = true
	options.visible = false
	options.modulate.a = 0.0

func _on_start_game_pressed() -> void:
	GameState.reset()
	SceneManager.change_level("res://scenes/levels/level1.tscn")


func _on_options_pressed() -> void:
	_show_options(true)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	_show_options(false)
	Settings.save()
	

func _show_options(show_options: bool) -> void:
	if _tween and _tween.is_running():
		return
		
	var hide_node: Control
	var show_node: Control
	
	if show_options:
		hide_node = v_box_container
		show_node = options
	else:
		hide_node = options
		show_node = v_box_container
	
	_tween = create_tween()
	_tween.tween_property(hide_node, "modulate:a", 0.0, 0.2)
	_tween.tween_callback(hide_node.hide)
	_tween.tween_callback(show_node.show)
	_tween.tween_property(show_node, "modulate:a", 1.0, 0.2)
