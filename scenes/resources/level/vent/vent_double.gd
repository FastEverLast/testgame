extends StaticBody2D

@onready var top_half: Sprite2D = $TopHalf
@onready var bottom_half: Sprite2D = $BottomHalf

signal wall_walked


func _on_zone_body_entered(body):
	if body.is_in_group("player"):
		GameState.shift_lock += 1
		if GameState.current_form == GameState.Form.CAT:
			top_half.z_index = 1
			if body.has_node("CatForm"):
				body.get_node("CatForm").z_index = -1
	elif body.is_in_group("hound"):
		body.modulate.a = 0.35
		top_half.z_index = 1
		if body.has_node("Sprite2D"):
			body.get_node("Sprite2D").z_index = -1


func _on_zone_body_exited(body):
	if body.is_in_group("player"):
		GameState.shift_lock -= 1
		top_half.z_index = 0
		if body.has_node("CatForm"):
			body.get_node("CatForm").z_index = 0
	elif body.is_in_group("hound"):
		body.modulate.a = 1.0
		top_half.z_index = 0
		if body.has_node("Sprite2D"):
			body.get_node("Sprite2D").z_index = 0


func _on_z_detection_body_entered(body) -> void:
	if body.is_in_group("player"):
		if GameState.current_form == GameState.Form.CAT:
			top_half.z_index = 1
				
			if body.has_node("CatForm"):
				body.get_node("CatForm").z_index = -1	
			
		if GameState.current_form == GameState.Form.BASE:
			top_half.z_index = 0
			
	elif body.is_in_group("hound"):
		top_half.z_index = 1
		if body.has_node("Sprite2D"):
			body.get_node("Sprite2D").z_index = -1
		


func _on_z_detection_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		
		if body.has_node("CatForm"):
			body.get_node("CatForm").z_index = 0
			
		if body.global_position.y > global_position.y + 8:
			top_half.z_index = 0
		
	elif body.is_in_group("hound"):
		if body.has_node("Sprite2D"):
			body.get_node("Sprite2D").z_index = 0
		if body.global_position.y > global_position.y + 8:
			top_half.z_index = 0


func _on_player_detector_body_entered(body: Node2D) -> void:
	if GameState.current_form != GameState.Form.CAT:
		wall_walked.emit()
