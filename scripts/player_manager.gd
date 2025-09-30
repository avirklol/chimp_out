class_name PlayerManager
extends Node

signal player_joined(player_id: int, device_id: int, player_index: int)
signal player_left(player_id: int, player_index: int)
signal player_ready(player_id: int, player_index: int, is_ready: bool)
signal player_disconnected(player_id: int, player_index: int)
signal player_reconnected(player_id: int, player_index: int)
signal new_player_sprite(player_id: int, player_index: int, sprite: Resource)

@export var sprite_sheets: Array[Dictionary] = []

var max_players: int = 4
var players: Array[Dictionary] = []
var device_player_map: Dictionary = {}
var action_list: Array[StringName] = []

@onready var monkey_scene: PackedScene = preload("res://scenes/monkey.tscn")

func _ready() -> void:
	action_list = InputMap.get_actions()
	var player_number: int = 1

	for player in range(max_players):
		players.append({
			"player_id": player_number, "device_id": null, "joined": false, "ready": false,
			"monkey": null, "sprite": null, "points": 0, "timer": null})
		player_number += 1

	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _process(_delta: float) -> void:
	for player in players:
		if player["timer"]:
			var timer = player["timer"]
			print("Player %d Rejoin Timer: %d" % [player["player_id"], timer.time_left])


func _unhandled_input(event: InputEvent) -> void:
	var device_id: int = event.device
	var player_id: int = _get_player_id(device_id)
	var player_index: int = _get_player_index(player_id)

	if GM.state == GM.States.PLAYER_SELECTION:
		if event.is_echo():
			return

		if event is InputEventJoypadButton:
			if event.button_index == JOY_BUTTON_START:
				if !device_player_map.has(device_id):
					for player in players:
						if !player["joined"]:
							player_index = players.find(player)

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

		if player_id:
			var is_ready = players[player_index]["ready"]

			if event.is_action_pressed("select%d" % player_id):
				if !is_ready:
					players[player_index]["ready"] = true

					player_ready.emit(player_id, player_index, true)

			if event.is_action_pressed("back%d" % player_id):
				if is_ready:
					players[player_index]["ready"] = false

					player_ready.emit(player_id, player_index, false)
				else:
					_remove_player(player_id, device_id)
					return

			if !is_ready:
				if event.is_action_pressed("move_up%d" % player_id):
					new_player_sprite.emit(player_id, player_index, get_next_available_sprite(player_id, true))
				elif event.is_action_pressed("move_down%d" % player_id):
					new_player_sprite.emit(player_id, player_index, get_next_available_sprite(player_id))

		if event.is_action_pressed("back"):
			if !_players_joined():
				GM.state = GM.States.TITLE


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	var player_id: int = _get_player_id(device_id)
	var player_index: int = _get_player_index(player_id)

	if !connected and device_player_map.has(device_id):
		var timer = Timer.new()
		timer.name = "RemovePlayer%d" % player_id
		timer.one_shot = true
		timer.timeout.connect(func(): _remove_player(player_id, device_id))
		timer.wait_time = 30.0
		add_child(timer)
		timer.start()

		players[player_index]["timer"] = get_node_or_null(NodePath(timer.name))

		player_disconnected.emit(player_id, player_index)
	else:
		if players[player_index]["timer"]:
			var timer = players[player_index]["timer"]
			timer.stop()
			timer.queue_free()

			players[player_index]["timer"] = null

			player_reconnected.emit(player_id, player_index)


func _remove_player(player_id: int, device_id: int) -> void:
	var player_index: int = _get_player_index(player_id)

	players[player_index]["joined"] = false
	players[player_index]["device_id"] = null
	players[player_index]["monkey"] = null
	players[player_index]["sprite"] = null
	players[player_index]["points"] = 0
	players[player_index]["timer"] = null
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


func _players_joined() -> bool:
	for player in players:
		if player["joined"]:
			return true
	return false


func _get_player_id(device_id: int) -> int:
	if device_player_map.has(device_id):
		return device_player_map[device_id]
	return -1


func _get_player_index(player_id: int) -> int:
	for i in range(players.size()):
		if players[i]["player_id"] == player_id:
			return i
	return -1


func get_next_available_sprite(player_id: int, reverse: bool = false) -> Resource:
	var player_index: int = _get_player_index(player_id)
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
