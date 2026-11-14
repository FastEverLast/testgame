extends Control

const CLOSED_OFFSET := Vector2(-500, 0) # offscreen left
const SLIDE_TIME := 0.4
const STAGGER := 0.06

@onready var panel_container: PanelContainer = $PanelContainer
@onready var v_box_container: VBoxContainer = $PanelContainer/VBoxContainer
@onready var memory_label: Label = $"../MemoryLabel"
@onready var options: Control = $OptionsPanel

var _buttons: Array[AnimatedButton] = []
var _tween: Tween = null
var _open := false

func _ready() -> void:
	for child in v_box_container.get_children():
		if child is AnimatedButton:
			_buttons.append(child)
	_reset()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		_toggle(not _open)


func _toggle(should_open: bool) -> void:
	options.hide()
	options.modulate.a = 0.0
	v_box_container.show()
	v_box_container.modulate.a = 1.0
	_open = should_open
	get_tree().paused = should_open
	if should_open:
		panel_container.visible = true # must be visible before anim starts

	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel()

	var count := _buttons.size()
	for i in count:
		var step := i if should_open else count - 1 - i # reversed stagger when closing
		var target := Vector2.ZERO if should_open else CLOSED_OFFSET
		var ease_type := Tween.EASE_OUT if should_open else Tween.EASE_IN
		_tween.tween_property(_buttons[i], ^"offset_transform_position", target, SLIDE_TIME) \
		.set_delay(step * STAGGER).set_trans(Tween.TRANS_BACK).set_ease(ease_type) # offset transform so vbox layout stays intact
		
	_tween.tween_property(panel_container, ^"modulate", Color.WHITE if should_open else Color.TRANSPARENT, SLIDE_TIME)
	
	if !should_open:
		_tween.chain().tween_callback(func() -> void: panel_container.visible = false) # hide only after every slide finishes
	
	memory_label.visible = not should_open

func _reset() -> void:
	panel_container.visible = false
	panel_container.modulate = Color.TRANSPARENT
	_open = false
	for button in _buttons:
		button.offset_transform_position = CLOSED_OFFSET
		
func _on_resume_pressed():
	_toggle(false)
	
func _on_main_menu_pressed():
	SceneManager.go_to_main_menu()
	
func _on_quit_pressed():
	get_tree().quit()

func _on_options_pressed() -> void:
	_show_options(true)

func _show_options(show_options: bool) -> void:
	if _tween and _tween.is_running():
		return
		
	var hide_node: Control
	var show_node: Control
	
	if show_options:
		hide_node = v_box_container
		show_node = options
	else:
		hide_node = options
		show_node = v_box_container
	
	_tween = create_tween()
	_tween.tween_property(hide_node, "modulate:a", 0.0, 0.2)
	_tween.tween_callback(hide_node.hide)
	_tween.tween_callback(show_node.show)
	_tween.tween_property(show_node, "modulate:a", 1.0, 0.2)


func _on_back_pressed() -> void:
	_show_options(false)
	Settings.save()
