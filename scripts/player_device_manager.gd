extends Node
class_name PlayerDeviceManager

signal player_joined(player_id: int, device_id: int)
signal player_left(player_id: int)

@export var max_players: int = 2

var player_device_map: Dictionary = {}
var device_player_map: Dictionary = {}
var player_number: int = 1

func _ready() -> void:
    Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _unhandled_input(event: InputEvent) -> void:
    if player_device_map.size() < max_players:
        if event is InputEventJoypadButton:
            if event.button_index == JOY_BUTTON_START:
                if !device_player_map.has(event.device):
                    device_player_map[event.device] = player_number
                    player_device_map[player_number] = event.device
                    player_joined.emit(player_number, event.device)
                    player_number += 1
    else:
        return # MAX PLAYERS

func _on_joy_connection_changed(device: int, connected: bool) -> void:
    if !connected and device_player_map.has(device):
        var player_id: int = device_player_map[device]
        player_left.emit(player_id)
        player_device_map.erase(player_id)
        device_player_map.erase(device)
