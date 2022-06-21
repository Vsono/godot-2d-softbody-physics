extends Node2D

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == 1:
			print("0")