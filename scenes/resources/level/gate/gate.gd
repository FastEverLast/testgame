extends StaticBody2D

var _tween: Tween
var _is_open := false
var _pressed := 0
@export var required := 1
@export var stay_open := false
@onready var shape: CollisionShape2D = $CollisionShape2D


func _open() -> void:
	if _is_open:
		return
	_is_open = true
	shape.set_deferred("disabled", true)
	if _tween: _tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.5) # Replace with opening animation
	# Play open sound

func _close() -> void:
	if _is_open == false:
		return
	_is_open = false
	shape.set_deferred("disabled", false)
	if _tween: _tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.5) # Replace with closing animation
	# Play close sound

func _on_floor_button_activated() -> void:
	_pressed += 1
	if _pressed >= required:
		_open()

func _on_floor_button_released() -> void:
	_pressed -= 1
	if _pressed < required and not stay_open:
		_close()


func _on_guard_panel_helper_body_entered(_body: Node2D) -> void:
	_close()
