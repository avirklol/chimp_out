class_name GameManager
extends Node

signal game_start
signal game_end

enum States { TITLE, PLAYER_SELECTION, GAME, END }

@export var title_screen: PackedScene
@export var player_select: PackedScene
@export var arena: PackedScene
@export var round_time_limit: float = 120.0
@export var round_time_limit_warning: float = 10.0
@export var max_ready_time: float = 10.0

var state: States = States.TITLE
var ready_players: int = 0
var ready_timer: Timer
var round_number: int = 1
var max_rounds: int = 3
var game_started: bool = false
var game_ended: bool = false
var spawn_points: Array[Node] = []


func _ready() -> void:
	PM.player_joined.connect(_on_player_joined)
	PM.player_ready.connect(_on_player_ready)
	PM.player_left.connect(_on_player_left)

	var timer = Timer.new()
	timer.name = "ReadyTimer"
	timer.one_shot = true
	timer.timeout.connect(_on_ready_timer_timeout)
	timer.wait_time = max_ready_time
	add_child(timer)
	ready_timer = get_node("ReadyTimer")


func _process(_delta: float) -> void:
	if not ready_timer.is_stopped():
		print("Ready Timer: %d" % int(ready_timer.time_left))

	match state:
		States.TITLE:
			if !get_tree().current_scene.name.contains("TitleScreen"):
				get_tree().change_scene_to_packed(title_screen)
		States.PLAYER_SELECTION:
			if !get_tree().current_scene.name.contains("PlayerSelect"):
				get_tree().change_scene_to_packed(player_select)
		States.GAME: #TODO: Fix spawning.
			if !get_tree().current_scene.name.contains("Arena"):
				get_tree().change_scene_to_packed(arena)
				spawn_points = get_tree().current_scene.get_children().filter(func(child: Node): return child is Node2D and child.name.contains("Spawn"))

				for player_index in range(PM.players.size()):
					if PM.players[player_index]["joined"]:
						print("Player %d is spawning" % PM.players[player_index]["player_id"])
						var monkey = PM.players[player_index]["monkey"]
						var monkey_sprite = PM.players[player_index]["sprite"]
						add_child(monkey)
						monkey.global_position = spawn_points[player_index].global_position
						monkey.visible = true
						monkey.sprite_frames = monkey_sprite


func _on_player_joined(player_id: int, device_id: int, _player_index: int) -> void:
	print("Player %d joined with device %d!" % [player_id, device_id])

	if not ready_timer.is_stopped():
		ready_timer.wait_time += max_ready_time - ready_timer.time_left if 5.0 < max_ready_time - ready_timer.time_left else 5.0
		if ready_timer.time_left < ready_timer.wait_time:
			ready_timer.start(ready_timer.time_left + 5.0)

func _on_player_left(player_id: int, _player_index: int) -> void:
	print("Player %d left!" % player_id)


func _on_player_ready(player_id: int, _player_index: int, is_ready: bool) -> void:
	if is_ready:
		ready_players += 1
		print("Player %d is ready!" % player_id)
	else:
		ready_players -= 1
		print("Player %d is no longer ready!" % player_id)

	if ready_players >= 2:
		if not ready_timer.is_stopped():
			pass
		else:
			ready_timer.start()
	else:
		if not ready_timer.is_stopped():
			ready_timer.stop()


func _on_ready_timer_timeout() -> void:
	state = States.GAME
