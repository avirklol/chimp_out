extends Node
class_name GameManager

signal game_start
signal game_end

enum States { TITLE, PLAYER_SELECTION, GAME, END }

@export var round_time_limit: float = 120.0
@export var round_time_limit_warning: float = 10.0

var state: States = States.TITLE
var ready_players: int = 0
var round_number: int = 1
var max_rounds: int = 3
var game_started: bool = false
var game_ended: bool = false
var spawn_points: Array[Node] = []


func _ready() -> void:
	PM.player_joined.connect(_on_player_joined)
	PM.player_left.connect(_on_player_left)
	PM.player_ready.connect(_on_player_ready)
	spawn_points = get_tree().current_scene.get_children().filter(func(child: Node): return child is Node2D and child.name.contains("Spawn"))


func _process(_delta: float) -> void:
	match state:
		States.TITLE:
			if !get_tree().current_scene.name.contains("TitleScreen"):
				get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
		States.PLAYER_SELECTION:
			if !get_tree().current_scene.name.contains("PlayerSelect"):
				get_tree().change_scene_to_file("res://scenes/player_select.tscn")
		States.GAME:
			pass


func _on_player_joined(player_id: int, device_id: int, _player_index: int) -> void:
	print("Player %d joined with device %d!" % [player_id, device_id])


func _on_player_left(player_id: int, _player_index: int) -> void:
	print("Player %d left!" % player_id)


func _on_player_ready(player_id: int, _player_index: int, is_ready: bool) -> void:
	if is_ready:
		ready_players += 1
		print("Player %d is ready!" % player_id)
	else:
		ready_players -= 1
		print("Player %d is no longer ready!" % player_id)
