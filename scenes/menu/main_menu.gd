extends Control

@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var options: Panel = $Options

func _ready() -> void:
	v_box_container.visible = true
	options.visible = false

func _on_start_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level1.tscn")


func _on_options_pressed() -> void:
	v_box_container.visible = false
	options.visible = true


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	v_box_container.visible = true
	options.visible = false
	Settings.save()
