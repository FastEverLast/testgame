extends StaticBody2D

var _is_open := false
@onready var shape: CollisionShape2D = $CollisionShape2D
	

func _open() -> void:
	if _is_open:
		return
	_is_open = true
	shape.set_deferred("disabled", true)
	var _open_tween := create_tween()
	_open_tween.tween_property(self, "modulate:a", 0.0, 0.5) # Replace with opening animation
	# Play open sound

func _close() -> void:
	if _is_open == false:
		return
	_is_open = false
	shape.set_deferred("disabled", false)
	var _close_tween := create_tween()
	_close_tween.tween_property(self, "modulate:a", 1.0, 0.5) # Replace with closing animation
	# Play close sound

func _on_floor_button_activated() -> void:
	_open()	


func _on_floor_button_released() -> void:
	_close()	
