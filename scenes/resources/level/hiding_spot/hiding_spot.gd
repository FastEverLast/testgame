extends Area2D


func _on_enter(body):
	GameState.hidden_count += 1
	body.modulate.a = 0.5

func _on_exit(body):
	GameState.hidden_count -= 1
	
	if GameState.hidden_count == 0:
		body.modulate.a = 1.0
