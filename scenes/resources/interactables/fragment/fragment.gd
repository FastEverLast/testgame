extends Area2D

@export var amount : int = 1
var _taken = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_body_entered(_body: Node2D) -> void:
	if _taken:
		return
	_taken = true
	GameState.change_memory(amount)
	UiAudio.play_hover() # Placeholder sound
	var tween := create_tween().set_parallel() # Lets the tweens run simultaniously
	tween.tween_property(self, "scale", scale * 1.8, 0.25)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished
	queue_free() 
