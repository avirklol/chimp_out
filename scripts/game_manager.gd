extends Node
class_name GameManager

signal game_start
signal game_end

@export var sprite_sheets: Array[Resource] = []

enum States { TITLE, PLAYER_SELECTION, GAME, END }

var state: States = States.TITLE
var game_started: bool = false
var game_ended: bool = false
var round_number: int = 1
var players: Dictionary = {}
var spawn_points: Array[Node] = []



func _ready() -> void:
    PM.player_joined.connect(_on_player_joined)
    PM.player_left.connect(_on_player_left)
    spawn_points = get_tree().current_scene.get_children().filter(func(child: Node): return child is Node2D and child.name.contains("Spawn"))


func _on_player_joined(player_id: int, device_id: int) -> void:
    print("Player %d joined with device %d" % [player_id, device_id])


func _on_player_left(player_id: int) -> void:
    print("Player %d left" % player_id)
