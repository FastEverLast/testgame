extends Area2D

signal activated
signal released
@onready var sprite: Sprite2D = $Sprite2D
var _bodies_on := 0


func _on_body_entered(_body: Node2D) -> void:
	_bodies_on += 1
	if _bodies_on == 1:
		sprite.frame = 2
		activated.emit()
		# Play audio?


func _on_body_exited(_body: Node2D) -> void:
	_bodies_on -= 1
	if _bodies_on == 0:
		sprite.frame = 1
		released.emit()
	# close gate again when the statue is removed
