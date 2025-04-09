class_name ModulateTileLayer
extends TileMapLayer


@export var visible_tiles: Dictionary[Vector2i, bool]
@export var fade_speed: float = 4.0

var cell_alphas: Dictionary[Vector2i, float] = {}


func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	return true


func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	if coords in visible_tiles:
		cell_alphas[coords] = 1.0
	else:
		var delta = get_process_delta_time()
		cell_alphas[coords] -= delta * fade_speed
	tile_data.modulate.a = cell_alphas[coords]
