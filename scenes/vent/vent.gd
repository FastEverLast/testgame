extends StaticBody2D

@onready var top_half: Sprite2D = $TopHalf
@onready var bottom_half: Sprite2D = $BottomHalf


func _on_zone_body_entered(_body):
	GameState.shift_lock += 1


func _on_zone_body_exited(_body):
	GameState.shift_lock -= 1


func _on_z_detection_body_entered(body) -> void:
	if GameState.current_form == GameState.Form.CAT:
		top_half.z_index = 1
		#body.get_node("CatForm").z_index = -1
		
		
	if GameState.current_form == GameState.Form.BASE:
		top_half.z_index = 0


func _on_z_detection_body_exited(body: Node2D) -> void:
	if GameState.current_form == GameState.Form.CAT:
		#body.get_node("CatForm").z_index = 0
