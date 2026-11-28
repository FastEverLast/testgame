extends StaticBody2D

var _tween: Tween
var _is_open := false
var _pressed := 0
@onready var sfx := $AudioStreamPlayer
@export var required := 1
@export var stay_open := false
@onready var shape: CollisionShape2D = $CollisionShape2D


func _open() -> void:
	if _is_open:
		return
	_is_open = true
	await get_tree().create_timer(0.4, false).timeout
	shape.set_deferred("disabled", true)
	if _tween: _tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.5) # Replace with opening animation
	sfx.play()
	await get_tree().create_timer(0.47, false).timeout
	sfx.stop()

func _close() -> void:
	if _is_open == false:
		return
	_is_open = false
	await get_tree().create_timer(0.4, false).timeout
	shape.set_deferred("disabled", false)
	if _tween: _tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.5) # Replace with closing animation
	sfx.play()
	await get_tree().create_timer(0.47, false).timeout
	sfx.stop()

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
