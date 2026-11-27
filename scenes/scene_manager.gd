extends Node

@onready var fade: ColorRect = $CanvasLayer/ColorRect
@onready var fade_color_normal := fade.color	# Remembers the normal fade color

var busy := false
var catching := false

var just_died := false


func _on_memory_empty():
	if busy:
		return
	change_level("res://scenes/levels/tutorial_level.tscn")

func change_level(path: String) -> void:
	if busy:
		return
	else:
		busy = true

	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.4)
	await tween.finished

	get_tree().change_scene_to_file(path)
	get_tree().paused = false

	tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 0.4)
	await tween.finished
	fade.color = fade_color_normal
	busy = false

func restart_level():
	GameState.reset() # agreed fix: reset memory and form on restart
	change_level(get_tree().current_scene.scene_file_path)

func caught():
	if busy or catching:
		return
	catching = true
	GameState.reading = true # Makes it so that the player cannot move (ik hes not actually reading)
	fade.color = Color(0.5, 0.0, 0.0)
	var camera = get_viewport().get_camera_2d()
	var red_tween := create_tween()
	red_tween.tween_property(fade, "modulate:a", 0.7, 0.32)
	
	if camera != null:
		for i in 8:
			camera.offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))	# Camera shake
			await get_tree().create_timer(0.04, true).timeout
		camera.offset = Vector2.ZERO	# Reset camera shake
	
	if GameState.free_retries:		# Tutorial: dying costs nothing
		GameState.change_memory(GameState.memory_at_level_start - GameState.memory)
		GameState.reset_level_state()
		change_level(get_tree().current_scene.scene_file_path)
	else:
		GameState.reset_level_state()
		change_level(get_tree().current_scene.scene_file_path)
		just_died = true
	catching = false

func go_to_main_menu():
	GameState.reset()
	change_level("res://scenes/ui/menu/main_menu.tscn")
