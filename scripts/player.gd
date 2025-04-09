class_name Player
extends Node2D

@export var tile_position: Vector2i
@export var move_cooldown: float = 1.0

@export var _tile_manager: TileManager
@export var _animation_player: AnimationPlayer


func _ready() -> void:
	_update_position()

const ACTIONS = {
	"p1_down": Vector2i.DOWN,
	"p1_up": Vector2i.UP,
	"p1_left": Vector2i.LEFT,
	"p1_right": Vector2i.RIGHT,
}

var _move_cooldown_timer: float = 0
var _tween: Tween

func _process(delta: float) -> void:
	var move_vector = Vector2i.ZERO
	for action in ACTIONS:
		if Input.is_action_just_pressed(action):
			_move_cooldown_timer = 0
		if Input.is_action_pressed(action):
			move_vector += ACTIONS[action]
	if _move_cooldown_timer <= 0:
		if move_vector != Vector2i.ZERO:
			var net_move = _tile_manager.move_and_slide(tile_position, move_vector)
			tile_position += net_move
			_update_position()
			_move_cooldown_timer = move_cooldown
			if (net_move.x != 0 and net_move.y != 0):
				_move_cooldown_timer *= 1.5
	else:
		_move_cooldown_timer -= delta


func _update_position():
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "global_position", _tile_manager._wall_layer.map_to_local(tile_position), move_cooldown) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.play()
