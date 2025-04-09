class_name TileManager
extends Node2D


enum TerrainID {
	WALL = 0,
	FLOOR = 1
}


@export var _bg_color: Color
@export var _wall_layer: TileMapLayer
@export var _floor_layer: TileMapLayer


func _ready() -> void:
	_init_walls()
	RenderingServer.set_default_clear_color(_bg_color)


# Move from a cell by a certain amount, and returns the net movement
func move_and_slide(cell: Vector2i, amount: Vector2i) -> Vector2i:
	var net_move = amount 
	for x in range(1, abs(amount.x) + 1):
		if get_wall_at(cell + Vector2i(sign(amount.x) * x, 0)):
			net_move.x = sign(amount.x) * (x - 1)
			break
	cell.x += net_move.x
	for y in range(1, abs(amount.y) + 1):
		if get_wall_at(cell + Vector2i(0, sign(amount.y) * y)):
			net_move.y = sign(amount.y) * (y - 1)
			break
	return net_move


func get_wall_at(cell: Vector2i) -> bool:
	return _wall_layer.get_cell_source_id(cell) != -1


func set_wall_void_at(cell: Vector2i):
	_wall_layer.set_cell(cell, 1, Vector2i(9, 2))


const EDGE_OFFSETS = [	Vector2i(-1, -1), 	Vector2i(0, -1), 	Vector2i(1, -1), \
						Vector2i(-1, 0), 						Vector2i(1, 0), \
						Vector2i(-1, 1),		Vector2i(0, 1),		Vector2i(1, 1)]

func is_wall_edge(cell: Vector2i, fill_visited: Dictionary[Vector2i, bool]):
	for offset in EDGE_OFFSETS:
		if (cell + offset) not in fill_visited:
			return true
	return false


const FILL_OFFSETS = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]

# Flood fills at a given cell, an inputs all flood filled
# tiles into visited. Returns true if this flood fill does
# not touch the outside of the tiles.
func _init_walls_fill(cell: Vector2i, visited: Dictionary[Vector2i, bool], rect: Rect2i) -> bool:
	if cell in visited or _wall_layer.get_cell_source_id(cell) != -1:
		return true
	# Return false if we hit the edge of the tile bounding rect.
	if cell.x == rect.position.x or cell.x == rect.end.x - 1 or \
		cell.y == rect.position.y or cell.y == rect.end.y - 1:
		return false
	visited[cell] = true
	for offset in FILL_OFFSETS:
		if not _init_walls_fill(cell + offset, visited, rect):
			return false
	return true


func _init_walls():
	var rect = _wall_layer.get_used_rect()
	var visited: Dictionary[Vector2i, bool] = {}
	# Tiles that are enclosed
	var fill_visited: Dictionary[Vector2i, bool] = {}
	# Tiles that are touching the edge
	var edge_visited: Dictionary[Vector2i, bool] = {}
	# Initialize fill_visited with wall cells
	for cell in _wall_layer.get_used_cells():
		fill_visited[cell] = true
	# Iterate over each position within the bounding rect and try flood filling
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var cell = Vector2i(x, y)
			if cell in fill_visited or cell in edge_visited:
				continue
			visited.clear()
			if _init_walls_fill(cell, visited, rect):
				# This is an enclose fill
				for vcell in visited:
					fill_visited[vcell] = true
			else:
				# This is an unenclosed fill
				for vcell in visited:
					edge_visited[vcell] = true
	
	var edge_cells: Dictionary[Vector2i, bool] = {}
	for cell in fill_visited:
		for offset in EDGE_OFFSETS:
			var edge_cell = cell + offset
			if edge_cell not in fill_visited:
				edge_cells[edge_cell] = true
	_wall_layer.set_cells_terrain_connect(edge_cells.keys(), 0, TerrainID.WALL)
	for cell in edge_cells:
		set_wall_void_at(cell)
	
	var update_floors = []
	for cell in fill_visited:
		if _floor_layer.get_cell_source_id(cell) == -1:
			# If floor is empty, then use default floor
			update_floors.append(cell)
	_floor_layer.set_cells_terrain_connect(update_floors, 0, TerrainID.FLOOR)
