extends Control

@onready var panel : PanelContainer = $PanelContainer
@onready var label : Label = $PanelContainer/Label
@onready var textbox : AudioStreamPlayer = $TypeSound
@export var char_delay := 0.03
var _open := false
var _typing := false
var _skip := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	panel.visible = false

func show_text(text : String):
	if _open:
		return
	_open = true
	_typing = true
	_skip = false
	GameState.reading = true
	label.text = text
	label.visible_characters = 0
	panel.visible = true
	
	for i in text.length():
		if _skip or not _open: 
			break
		label.visible_characters = i + 1	
		if i % 2 == 0:
			textbox.stream = load("res://assets/audio/sfx/ui/chatter.wav")
			textbox.play(0.5)
		await get_tree().create_timer(char_delay).timeout
		textbox.stop()
	if not _open:
		return
	label.visible_characters = -1
	_typing = false

func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("interact"):
		if _typing:
			_skip = true
		else:
			_close()
		get_viewport().set_input_as_handled()
	
	if event.is_action_pressed("pause"):
		_close()
		get_viewport().set_input_as_handled()
		return

func _close():
	_open = false
	panel.visible = false
	GameState.reading = false
	_typing = false

func is_open() -> bool:
	return _open 
