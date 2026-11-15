extends Area2D

signal activated
signal released
@onready var sprite: Sprite2D = $Sprite2D
var _pressed := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if _pressed:
		return
	_pressed = true
	sprite.frame = 2
	activated.emit()
	# Play audio?


func _on_body_exited(body: Node2D) -> void:
	_pressed = false
	sprite.frame = 1
	released.emit()
	# close gate again when the statue is removed
