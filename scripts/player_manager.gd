extends Node
class_name PlayerManager

signal player_joined(player_id: int, device_id: int, player_index: int)
signal player_left(player_id: int, player_index: int)

@export var max_players: int = 4
@export var sprite_sheets: Array[Dictionary] = []

@onready var monkey_scene: PackedScene = preload("res://scenes/monkey.tscn")

var players: Array[Dictionary] = []
var device_player_map: Dictionary = {}
var action_list: Array[StringName] = []
var player_number: int = 1


func _ready() -> void:
	action_list = InputMap.get_actions()

	for player in range(max_players):
		players.append({ "player_id": player_number, "device_id": null, "joined": false, "ready": false, "monkey": null , "sprite": null, "points": 0})
		player_number += 1

	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _unhandled_input(event: InputEvent) -> void:
	var device_id: int = event.device
	var player_id: int = get_player_id(device_id)

	if GM.state == GM.States.PLAYER_SELECTION:
		if event is InputEventJoypadButton:
			if event.button_index == JOY_BUTTON_START or event.button_index == JOY_BUTTON_A:
				if !device_player_map.has(device_id):
					for player in players:
						if !player["joined"]:
							var player_index: int = players.find(player)

							player_id = player["player_id"]
							device_player_map[device_id] = player_id

							player["joined"] = true
							player["device_id"] = device_id
							player["monkey"] = monkey_scene.instantiate()
							player["monkey"].player_id = player_id
							player["monkey"].device_id = device_id
							player["monkey"].name = "Player %d" % player_id

							_build_input_map(player_id, device_id)

							player_joined.emit(player_id, device_id, player_index)
							break

		if player_id != 0:

			if event.is_action_pressed("select%d" % player_id):
				for player in players:
					if player["player_id"] == player_id:
						if !player["ready"]:
							player["ready"] = true

							break

			if event.is_action_pressed("back%d" % player_id):
				for player in players:
					if player["player_id"] == player_id:
						if player["ready"]:
							player["ready"] = false

							break
						else:
							_remove_player(player_id, device_id)
							break

	else:
		return # MAX PLAYERS


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if !connected and device_player_map.has(device_id):
		var player_id: int = device_player_map[device_id]

		_remove_player(player_id, device_id)


func _remove_player(player_id: int, device_id: int) -> void:
	var player_index: int

	for player in players:
		if player["player_id"] == player_id:
			player["joined"] = false
			player["device_id"] = null
			player["monkey"] = null
			player_index = players.find(player)
			break

	device_player_map.erase(device_id)

	for action in action_list:
		if (action.begins_with("ui_")):
			continue

		var player_action = action + str(player_id)

		if InputMap.has_action(player_action):
			InputMap.erase_action(player_action)

	for sprite in sprite_sheets:
		if sprite["player_id"] == player_id:
			sprite["player_id"] = 0
			break

	player_left.emit(player_id, player_index)


func _build_input_map(player_id: int, device_id: int) -> void:
	var action_event_list:Array[InputEvent]
	var current_action:StringName
	var current_event:InputEvent

	for action in action_list:
		if (action.begins_with("ui_")):
			continue

		current_action = action + str(player_id)
		InputMap.add_action(current_action)

		action_event_list = InputMap.action_get_events(action)

		for event in action_event_list:
			current_event = event.duplicate(true)
			current_event.set_device(device_id)
			print(current_event.device)
			InputMap.action_add_event(current_action,current_event)


func get_player_id(device_id: int) -> int:
	if device_player_map.has(device_id):
		return device_player_map[device_id]
	else:
		return 0

func get_player_index(player_id: int) -> int:
	for i in range(players.size()):
		if players[i]["player_id"] == player_id:
			return i
	return -1


func get_next_available_sprite(player_id: int, reverse: bool = false) -> Resource:
	var player_index: int = get_player_index(player_id)
	var new_sprite: Resource
	var sprite_array_length: int = sprite_sheets.size()
	var current_index: int = -1

	for i in range(sprite_array_length):
		if sprite_sheets[i]["player_id"] == player_id:
			current_index = i
			break

	if current_index != -1:
		sprite_sheets[current_index]["player_id"] = 0

	var found_index: int = -1
	var offset: int = -1 if reverse else 1

	for i in range(1, sprite_array_length):
		var idx = posmod(current_index + (offset * i), sprite_array_length)
		print(idx)
		if sprite_sheets[idx]["player_id"] == 0:
			found_index = idx
			break

	if found_index != -1:
		sprite_sheets[found_index]["player_id"] = player_id
		new_sprite = sprite_sheets[found_index]["frames"]
		players[player_index]["sprite"] = new_sprite

	return new_sprite
