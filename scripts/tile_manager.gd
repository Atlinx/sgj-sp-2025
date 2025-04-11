@tool
class_name TileManager
extends Node2D


static var global: TileManager


enum TerrainID {
	WALL = 0,
	FLOOR = 1
}


@export var fade_speed: float = 4.0
@export var bg_color: Color

@export_category("Dependencies")
@export var _wall_layer: TileMapLayer
@export var _floor_layer: TileMapLayer
@export var _visible_wall_layer: ModulateTileLayer
@export var _visible_floor_layer: ModulateTileLayer

var tile_entity_to_pos: Dictionary[TileEntity, Vector2i] = {}
# Maps positions to an array of tile entities
# Maps [Vector2i] -> Array[TileEntity]
var pos_to_tile_entities: Dictionary = {}
# Current set of visible tiles
var visible_tiles: Dictionary[Vector2i, bool] = {}
# Current set of TileEntities that we are fading out
var tile_entity_alphas: Dictionary[TileEntity, bool] = {}

@onready var VISIBLE_LAYERS: Array[ModulateTileLayer] = [_visible_wall_layer, _visible_floor_layer]
@onready var LAYERS: Array[TileMapLayer] = [_wall_layer, _floor_layer]


func _enter_tree() -> void:
	if global != null:
		queue_free()
		return
	print("init")
	global = self


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if global == self:
			global = null


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_floor_layer.visible = false
	_wall_layer.visible = false
	_visible_wall_layer.visible = true
	_visible_floor_layer.visible = true
	_init_walls()
	RenderingServer.set_default_clear_color(bg_color)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	# Fade entities
	for entity in tile_entity_alphas.keys():
		if tile_entity_to_pos[entity] not in visible_tiles:
			# Fade out entities that are no longer visible
			entity.modulate.a -= delta * fade_speed
			if entity.modulate.a <= 0:
				tile_entity_alphas.erase(entity)
				entity.visible = false
		
	# Fade tiles
	for visible_layer in VISIBLE_LAYERS:
		visible_layer.visible_tiles = visible_tiles


func local_to_map(local_pos: Vector2) -> Vector2i:
	return _wall_layer.local_to_map(local_pos)


func map_to_local(map_pos: Vector2i) -> Vector2:
	return _wall_layer.map_to_local(map_pos)


func _get_or_make_tile_entities_at(pos: Vector2i) -> Array[TileEntity]:
	var entities = pos_to_tile_entities.get(pos)
	if entities == null:
		entities = Array([], TYPE_OBJECT, "Node2D", TileEntity)
	pos_to_tile_entities[pos] = entities
	return entities


func add_tile_entity(entity: TileEntity, pos: Vector2i):
	assert(entity not in tile_entity_to_pos)
	tile_entity_to_pos[entity] = pos
	var entities: Array[TileEntity] = _get_or_make_tile_entities_at(pos)
	assert(entity not in entities)
	entities.append(entity)
	move_tile_entity(entity, pos)


# Returns the TileEntities at a given position.
# May return multiple TileEntities if there are multiple overlapping
# entities on the same tile.
func get_tile_entities_at(pos: Vector2i) -> Array[TileEntity]:
	var entities = pos_to_tile_entities.get(pos)
	if entities == null:
		return Array([], TYPE_OBJECT, "Node2D", TileEntity)
	return entities


# Returns TileEntitites at multiple positions
func get_tile_entities_at_array(pos_array: Array[Vector2i]) -> Array[TileEntity]:
	var entities: Array[TileEntity] = []
	for pos in pos_array:
		entities.append_array(get_tile_entities_at(pos))
	return entities


func get_visible_tile_entities() -> Array[TileEntity]:
	return get_tile_entities_at_array(visible_tiles.keys())


# Tries to move a TileEntity to a new position
# Returns true if it could be moved
func move_tile_entity(entity: TileEntity, new_pos: Vector2i):
	assert(entity in tile_entity_to_pos)
	var old_pos = tile_entity_to_pos[entity]
	var old_tile_entities = get_tile_entities_at(old_pos)
	assert(get_tile_entities_at(old_pos).has(entity))
	pos_to_tile_entities[old_pos].erase(entity)
	_get_or_make_tile_entities_at(new_pos).append(entity)
	tile_entity_to_pos[entity] = new_pos
	if new_pos in visible_tiles:
		# Make entity visible
		entity.visible = true
		tile_entity_alphas[entity] = true


# Removes a TileEntity from being tracked
func remove_tile_entity(entity: TileEntity):
	assert(entity in tile_entity_to_pos)
	var pos = tile_entity_to_pos[entity]
	_get_or_make_tile_entities_at(pos).erase(entity)
	if pos_to_tile_entities[pos].size() == 0:
		pos_to_tile_entities.erase(pos)
	tile_entity_to_pos.erase(entity)
	tile_entity_alphas.erase(entity)


func set_visible_tiles(cells: Array[Vector2i]):
	# Update newly visible tiles
	visible_tiles.clear()
	for cell in cells:
		visible_tiles[cell] = true
		for entity in get_tile_entities_at(cell):
			# Make entity visible
			entity.visible = true
			entity.modulate.a = 1.0
			tile_entity_alphas[entity] = true
		for i in len(VISIBLE_LAYERS):
			VISIBLE_LAYERS[i].set_cell(cell, LAYERS[i].get_cell_source_id(cell), LAYERS[i].get_cell_atlas_coords(cell), LAYERS[i].get_cell_alternative_tile(cell))
			var tiledata = VISIBLE_LAYERS[i].get_cell_tile_data(cell)
			if tiledata:
				tiledata.modulate.a = 1


# Returns whether any tile (wall, floor, etc.) is at a given cell location
func has_any_tile_at(cell: Vector2i) -> bool:
	for layer in LAYERS:
		if layer.get_cell_source_id(cell):
			return true
	return false


var DEBUG = []

func raycast_tiles_arc(pos: Vector2, angle_start: float, angle_end: float) -> Array[Vector2i]:
	#print("raycast_tiles_arc: pos: %s start: %s end: %s" % [pos, angle_start, angle_end])
	var res_tiles: Dictionary[Vector2i, bool] = {}
	var space = get_world_2d().direct_space_state
	var angle_divisions = ceil((angle_end - angle_start) * 50)
	# TODO: Refactor this with more efficient + less flickery visibility algorithm: https://www.redblobgames.com/articles/visibility/
	DEBUG.clear()
	for i in range(angle_divisions + 1):
		var angle = lerp(angle_start, angle_end, float(i) / angle_divisions)
		var params = PhysicsRayQueryParameters2D.create(pos, pos + Vector2.from_angle(angle) * 1000)
		var res = space.intersect_ray(params)
		if not res.is_empty():
			var raycast_pos: Vector2 = res["position"]
			DEBUG.append([pos, raycast_pos])
			raycast_pos += (raycast_pos - pos).normalized() * 8
			var divisions = pos.distance_to(raycast_pos) / 5
			for j in range(divisions + 1):
				var lerp_pos = lerp(pos, raycast_pos, float(j) / divisions)
				var test_pos = _wall_layer.local_to_map(lerp_pos)
				if has_any_tile_at(test_pos):
					res_tiles[test_pos] = true
	return res_tiles.keys()


# Move from a cell by a certain amount, and returns the net movement
func move_and_slide(cell: Vector2i, amount: Vector2i) -> Vector2i:
	var net_move = amount 
	for x in range(1, abs(amount.x) + 1):
		if get_collision_at(cell + Vector2i(sign(amount.x) * x, 0)):
			net_move.x = sign(amount.x) * (x - 1)
			break
	cell.x += net_move.x
	for y in range(1, abs(amount.y) + 1):
		if get_collision_at(cell + Vector2i(0, sign(amount.y) * y)):
			net_move.y = sign(amount.y) * (y - 1)
			break
	return net_move


func get_collision_at(cell: Vector2i) -> bool:
	for entity in get_tile_entities_at(cell):
		if entity.collidable:
			return true
	return _wall_layer.get_cell_source_id(cell) != -1


func set_invisible_wall_at(cell: Vector2i):
	_wall_layer.set_cell(cell, 2, Vector2i(0, 0))


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
