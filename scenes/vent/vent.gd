extends StaticBody2D


func _on_zone_body_entered(_body):
	GameState.shift_lock += 1

func _on_zone_body_exited(_body):
	GameState.shift_lock -= 1
