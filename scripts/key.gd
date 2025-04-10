extends Node2D

@export var key_inventory : PackedScene 


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("hitbox"):
		var inventory :Inventory = area.get_parent().inventory
		if inventory.full == true:
			return
		inventory.add_stuff(key_inventory.instantiate())
		queue_free()
