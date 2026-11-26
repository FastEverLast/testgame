extends Node2D

@export var char_delay := 0.04
@export var hold_time := 1.6 # Seconds the finished text stays on screen
@export var height_above := 56.0

@onready var panel : PanelContainer = $Panel
@onready var label : Label = $Panel/Text
@onready var speaking : AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	panel.visible = false
	
func say(text : String) -> void:
	label.text = text
	label.visible_characters = 0
	panel.visible = true
	panel.reset_size()
	await get_tree().process_frame
	panel.position = Vector2(-panel.size.x / 2.0, -panel.size.y - height_above)
	
	for i in text.length():
		label.visible_characters = i + 1
		if i % 2 == 0:
			speaking.volume_db = 3.0
			speaking.stream = load("res://assets/audio/sfx/ui/guard_speaking.wav")
			speaking.play(0)
		await get_tree().create_timer(char_delay, false).timeout
		speaking.stop()
	
	await get_tree().create_timer(hold_time, false).timeout
	panel.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
