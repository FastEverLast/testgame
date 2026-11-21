extends Area2D

signal activated
signal released
@onready var sprite: Sprite2D = $Sprite2D
@onready var press_sound : AudioStreamPlayer = $PressSound
@onready var release_sound : AudioStreamPlayer = $ReleaseSound

var _bodies_on := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_body_entered(_body: Node2D) -> void:
	_bodies_on += 1
	if _bodies_on == 1:
		sprite.frame = 2
		activated.emit()
		press_sound.play()


func _on_body_exited(_body: Node2D) -> void:
	_bodies_on -= 1
	if _bodies_on == 0:
		sprite.frame = 1
		released.emit()
		release_sound.play()
