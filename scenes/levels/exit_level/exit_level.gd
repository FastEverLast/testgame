extends Area2D

@export_file("*.tscn") var next_level : String

func _on_body_entered(_body):
	if next_level == "":
		return
	GameState.prepare_next_level()
	SceneManager.change_level(next_level)
