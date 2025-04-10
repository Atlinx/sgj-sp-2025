extends Node2D

@export var key_inventory : PackedScene 
var player_overlap : bool = false
var inventory :Inventory

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("hitbox"):
		inventory = area.get_parent().inventory
		player_overlap = true
		
func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.is_in_group("hitbox"):
		player_overlap = false


func _process(delta: float) -> void:
	if player_overlap :
		if Input.is_action_just_pressed("p1_interact"):
			if inventory.full == false:
				inventory.add_stuff(key_inventory.instantiate())
				queue_free()
