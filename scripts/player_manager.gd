extends Node
class_name PlayerManager

signal player_joined(player_id: int, device_id: int)
signal player_left(player_id: int)

@export var max_players: int = 4

@onready var monkey_scene: PackedScene = preload("res://scenes/monkey.tscn")

var players: Array[Dictionary] = []
var device_player_map: Dictionary = {}
var action_list: Array[StringName] = []
var player_number: int = 1


func _ready() -> void:
    action_list = InputMap.get_actions()

    for player in range(max_players):
        players.append({ "player_id": player_number, "device_id": null, "joined": false, "monkey": null })
        player_number += 1

    Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _unhandled_input(event: InputEvent) -> void:
    if GM.state == GM.States.PLAYER_SELECTION:
        if event is InputEventJoypadButton:
            if event.button_index == JOY_BUTTON_START:
                if !device_player_map.has(event.device):
                    for player in players:
                        if !player["joined"]:
                            var player_id: int = player["player_id"]

                            device_player_map[event.device] = player_id

                            player["joined"] = true
                            player["device_id"] = event.device
                            player["monkey"] = monkey_scene.instantiate()
                            player["monkey"].player_id = player_id
                            player["monkey"].device_id = event.device
                            player["monkey"].name = "Player %d" % player_id

                            _build_input_map(player_id, event.device)

                            player_joined.emit(player_id, event.device)

                            break
    else:
        return # MAX PLAYERS


func _on_joy_connection_changed(device: int, connected: bool) -> void:
    if !connected and device_player_map.has(device):
        var player_id: int = device_player_map[device]

        for player in players:
            if player["player_id"] == player_id:
                player["joined"] = false
                player["device_id"] = null
                player["monkey"] = null

                break

        device_player_map.erase(device)

        player_left.emit(player_id)


func _build_input_map(player_id: int, device_id: int) -> void:
    var action_event_list:Array[InputEvent]
    var current_action:StringName
    var current_event:InputEvent

    for action in range(action_list.size()):
        if (action_list[action].begins_with("ui_")):
            continue

        current_action = action_list[action]+str(player_id)
        InputMap.add_action(current_action)

        action_event_list = InputMap.action_get_events(action_list[action])

        for event in range(action_event_list.size()):
            current_event = action_event_list[event].duplicate(true)
            current_event.set_device(device_id)
            print(current_event.device)
            InputMap.action_add_event(current_action,current_event)
