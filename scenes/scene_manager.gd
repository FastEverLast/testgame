extends Node

@onready var fade: ColorRect = $CanvasLayer/ColorRect
var busy := false


func change_level(path: String) -> void:
	if busy:
		return
	else:
		busy = true
		
	get_tree().paused = false
	
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.4)
	await tween.finished
	
	get_tree().change_scene_to_file(path)
	
	tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 0.4)
	await tween.finished
	
	busy = false
	
func restart_level():
	change_level(get_tree().current_scene.scene_file_path)
	
func go_to_main_menu():
	GameState.reset()
	change_level("res://scenes/menu/main_menu.tscn")
