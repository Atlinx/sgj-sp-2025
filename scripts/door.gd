@tool
class_name Door
extends TileEntity


@export var key: KeyItem
@export_category("Dependencies")
@export var _door_open: Sprite2D
@export var _door_closed: Sprite2D
@export var _door_key: Sprite2D
@export var is_locked: bool = false :
	set(value):
		_update_visuals()
		is_locked = value
@export var is_open: bool = false :
	set(value):
		_update_visuals()
		is_open = value


func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		TileManager.global.set_invisible_wall_at(tile_position)
		_update_visuals()


func _process(delta: float) -> void:
	super._process(delta)
	if Engine.is_editor_hint():
		_update_visuals()


func _update_visuals():
	_door_key.visible = key != null and is_locked
	if _door_key and key:
		_door_key.self_modulate = key.key_color
	_door_open.visible = is_open
	_door_closed.visible = not is_open
