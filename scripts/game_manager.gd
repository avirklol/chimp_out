extends Node
class_name GameManager

signal game_start
signal game_end

@export var sprite_sheets: Array[Dictionary] = []

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


func _on_player_joined(player_id: int, device_id: int, _player_index: int) -> void:
	print("Player %d joined with device %d" % [player_id, device_id])


func _on_player_left(player_id: int, _player_index: int) -> void:
	print("Player %d left" % player_id)


func get_next_available_sprite(player_id: int, reverse: bool = false) -> Resource:
	var new_sprite: Resource
	var sprite_array_length: int = sprite_sheets.size()
	var current_index: int = -1

	for i in range(sprite_array_length):
		if sprite_sheets[i]["player_id"] == player_id:
			current_index = i
			break

	print(current_index)

	var indices: Array[int] = []
	for i in range(sprite_array_length):
		indices.append(i)
	if reverse:
		indices.reverse()

	print(indices)

	var start: int = 0
	if current_index != -1:
		start = (indices.find(current_index) + (-1 if reverse else 1)) % sprite_array_length
		sprite_sheets[current_index]["player_id"] = 0
	else:
		start = 0

# TODO: You need to fix how we look through the sprite sheets in reverse.
	var found_index: int = -1
	for offset in range(sprite_array_length):
		var idx = indices[(start + offset) % sprite_array_length]
		if sprite_sheets[idx]["player_id"] == 0:
			found_index = idx
			break

	if found_index != -1:
		sprite_sheets[found_index]["player_id"] = player_id
		new_sprite = sprite_sheets[found_index]["frames"]

	print(sprite_sheets)
	return new_sprite
