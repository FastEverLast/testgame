extends Node

const MAX_MEMORY = 10
var memory := 5
var current_form:Form = Form.BASE

enum Form { BASE, GUARD, CAT, STATUE }

signal memory_changed(new_value)
signal form_changed(new_form)

func change_memory(amount):
	memory = clampi(memory + amount, 0, MAX_MEMORY)
	memory_changed.emit(memory)

func shift_to(form):
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
	current_form = Form.BASE
