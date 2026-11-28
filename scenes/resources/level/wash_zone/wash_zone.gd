extends Area2D

var _inside := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameState.form_changed.connect(_on_form_changed)
	
func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
	_inside = true
	_strip.call_deferred()

func _on_body_exited(body):
	if not body.is_in_group("player"):
		return
	_inside = false

func _on_form_changed(_form):
	if _inside:
		_strip.call_deferred()

func _strip():
	if GameState.current_form != GameState.Form.BASE:
		GameState.shift_to(GameState.Form.BASE)
