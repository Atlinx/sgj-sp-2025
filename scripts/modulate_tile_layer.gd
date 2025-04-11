class_name ModulateTileLayer
extends TileMapLayer


var cell_alphas: Dictionary[Vector2i, float] = {}


func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	return true


func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	tile_data.modulate.a = cell_alphas.get(coords, 1.0)
