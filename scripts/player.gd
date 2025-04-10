class_name Player
extends Node2D


@export var tile_position: Vector2i
@export var move_cooldown: float = 1.0
@export var interact_angle: float :
	get:
		return interact_angle
	set(value):
		if is_equal_approx(_real_interact_angle, value):
			return
		if _interact_angle_tween:
			_interact_angle_tween.kill()
		_interact_angle_tween = create_tween()
		_interact_angle_from = _real_interact_angle
		_interact_angle_tween.tween_method(_tween_interact_angle, 0.0, 1.0, interact_angle_lerp_duration) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		_interact_angle_tween.play()
		interact_angle = value
var _real_interact_angle: float

@export var interact_angle_width: float = 30
@export var interact_angle_lerp_duration: float = 0.2

@export var _tile_manager: TileManager
@export var _animation_player: AnimationPlayer
@export var _flashlight_area: Area2D
@export var _flashlight: Node2D

var _interact_angle_from: float

@export var inventory : Control

func _ready() -> void:
	_update_position()
	_flashlight_area.body_entered.connect(_on_body_entered)
	_flashlight_area.body_exited.connect(_on_body_exited)


func _tween_interact_angle(weight: float):
	_real_interact_angle = fmod(lerp_angle(_interact_angle_from, interact_angle, weight) + 2 * PI, 2 * PI)


func _on_body_entered(body: Node2D):
	print("body entered: ", body)


func _on_body_exited(body: Node2D):
	print("body exited: ", body)


const ACTIONS = {
	"p1_down": Vector2i.DOWN,
	"p1_up": Vector2i.UP,
	"p1_left": Vector2i.LEFT,
	"p1_right": Vector2i.RIGHT,
}

var _move_cooldown_timer: float = 0
var _position_tween: Tween
var _interact_angle_tween: Tween

func _process(delta: float) -> void:
	var move_vector = Vector2i.ZERO
	interact_angle = get_local_mouse_position().normalized().angle()
	
	_flashlight.rotation = round(_real_interact_angle / (PI)) * PI
	#_flashlight.z_index = 0 #if _real_interact_angle > 0 and _real_interact_angle < PI else -1 
	var visible_tiles = _tile_manager.raycast_tiles_arc(global_position, _real_interact_angle - deg_to_rad(interact_angle_width) / 2.0, _real_interact_angle + deg_to_rad(interact_angle_width) / 2.0)
	_tile_manager.set_visible_tiles(visible_tiles)
	
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
	if _position_tween:
		_position_tween.kill()
	_position_tween = create_tween()
	_position_tween.tween_property(self, "global_position", _tile_manager._wall_layer.map_to_local(tile_position), move_cooldown) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_position_tween.play()
