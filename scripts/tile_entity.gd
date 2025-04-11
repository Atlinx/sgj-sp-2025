@tool
class_name TileEntity
extends Node2D


@export var collidable: bool
@export var tile_position: Vector2i


func _ready() -> void:
	tile_position = TileManager.global.local_to_map(position)
	print("add self")
	TileManager.global.add_tile_entity(self, tile_position)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		tile_position = TileManager.global.local_to_map(position)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		TileManager.global.remove_tile_entity(self)
