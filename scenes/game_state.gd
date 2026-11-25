extends Node

const MAX_MEMORY = 10
var memory := 5
var current_form:Form = Form.BASE
var wheel_open : bool = false
var shift_lock := 0
var hidden_count := 0
var reading := false

enum Form { BASE, GUARD, CAT, STATUE }

signal memory_changed(new_value)
signal form_changed(new_form)

func change_memory(amount):
	memory = clampi(memory + amount, 0, MAX_MEMORY)
	memory_changed.emit(memory)

func shift_to(form):
	if shift_lock > 0:
		if reading:
			return
	if form == current_form:
		return
	elif form != Form.BASE:
		if memory < 1:
			return
		else:
			change_memory(-1)
	current_form = form
	form_changed.emit(form)
	
func reset():
	memory = 5
	reset_level_state()
	
func reset_level_state():
	current_form = Form.BASE
	wheel_open = false
	shift_lock = 0
	hidden_count = 0
	reading = false

func prepare_next_level():
	current_form = Form.BASE
	wheel_open = false
	shift_lock = 0
	hidden_count = 0
	memory = maxi(memory, 3)
	memory_changed.emit(memory)
	reading = false
