extends Node
class_name GameStateManager

signal game_start
signal game_end

@export var sprite_sheets: Array[Resource] = []
@onready var monkey_scene: PackedScene = preload("res://scenes/monkey.tscn")

var game_started: bool = false
var game_ended: bool = false
var players: Dictionary = {}
var spawn_points: Array[Node] = []


func _ready() -> void:
    PDM.player_joined.connect(_on_player_joined)
    PDM.player_left.connect(_on_player_left)
    spawn_points = get_tree().current_scene.get_children().filter(func(child: Node): return child is Node2D and child.name.contains("Spawn"))


func _on_player_joined(player_id: int, device_id: int) -> void:
    if !players.has(player_id):
        var monkey: Monkey = monkey_scene.instantiate()
        monkey.player_id = player_id
        monkey.device_id = device_id
        get_tree().current_scene.add_child(monkey)
        monkey.animations.sprite_frames = sprite_sheets[player_id - 1]
        monkey.name = "Player %d" % player_id
        monkey.global_position = spawn_points[player_id - 1].global_position
        players[player_id] = monkey
        PDM.build_input_map(player_id, device_id)

        print("Player %d joined with device %d" % [player_id, device_id])
    else:
        return # PLAYER EXISTS


func _on_player_left(player_id: int) -> void:
    print("Player %d left" % player_id)
