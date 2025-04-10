extends Control
class_name Inventory

var full : bool = false

func add_stuff(stuff):
	for i in $HBoxContainer.get_children():
		if i.get_children() == [] :
			i.add_child(stuff)
			print(stuff)
			break
	var empty_slot : int = 0
	for i in $HBoxContainer.get_children():
		if i.get_children() == [] :
			empty_slot += 1
	print(empty_slot)
	if empty_slot == 0:
		full = true
	else:
		full = false
