extends Node2D


@export var _tile_manager: TileManager


#func _process(delta: float) -> void:
	#queue_redraw()
#
#
#func _draw() -> void:
	#for line in _tile_manager.DEBUG:
		#draw_line(line[0], line[1], Color(Color.RED, 0.05))
	#for pos in _tile_manager.visible_tiles:
		#draw_circle(_tile_manager._visible_wall_layer.map_to_local(pos), 8, Color(Color.RED, 0.5), false)
	#for pos in _tile_manager._visible_wall_layer.get_used_cells():
		#draw_circle(_tile_manager._visible_wall_layer.map_to_local(pos), 4, Color(Color.GREEN, 0.5), false)
	#for pos in _tile_manager._visible_floor_layer.get_used_cells():
		#draw_circle(_tile_manager._visible_floor_layer.map_to_local(pos), 4, Color(Color.CYAN, 0.5), false)
	#draw_circle(_tile_manager._visible_floor_layer.map_to_local(Vector2i(-2, -2)), 6, Color(Color.PURPLE, 0.5), false)
