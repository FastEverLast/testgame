extends StaticBody2D

signal body_ent

func body_entered(body: Node2D):
	body_ent.emit()	
