extends CheckButton


func _ready() -> void:
	set_pressed_no_signal(Settings.get_setting("controls", "auto_select", false)) # Sets tick without triggering a save


func _on_toggled(toggled_on: bool) -> void:
	Settings.set_setting("controls", "auto_select", toggled_on)
	Settings.save()
