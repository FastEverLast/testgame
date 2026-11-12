extends Node

@onready var hover: AudioStreamPlayer = $Hover
@onready var click: AudioStreamPlayer = $Click

func play_hover():
	hover.play()

func play_click():
	click.play()
