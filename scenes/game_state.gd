extends Node

const MAX_MEMORY = 10
var memory := 5

signal memory_changed(new_value)

func change_memory(amount):
	memory = clampi(memory + amount, 0, MAX_MEMORY)
	memory_changed.emit(memory)
