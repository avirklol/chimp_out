class_name GameManager
extends Node

signal game_start
signal game_end
signal rock_thrown(player_id: int, rocks: int)
signal rock_picked_up(player_id: int, rocks: int)
signal points_changed(player_id: int, points: int)

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
var round_timer: Timer
var round_timer_label: RichTextLabel
var round_number: int = 1
var max_rounds: int = 3
var match_started: bool = false
var match_ended: bool = false
var players_spawned: bool = false
var spawn_points: Array[Node] = []
var player_stats: Array[Node] = []

@onready var ui_scene: PackedScene = preload("res://scenes/user_interface.tscn")


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
	ready_timer = get_node_or_null(NodePath(timer.name))


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
		States.GAME:
			if !get_tree().current_scene.name.contains("Arena"):
				get_tree().change_scene_to_packed(arena)
			else:

				if !players_spawned:
					var ui = ui_scene.instantiate()
					add_child(ui)
					ui.z_index = 100

					player_stats = ui.stats.get_children()
					round_timer_label = ui.round_timer
					spawn_points = get_tree().current_scene.get_children().filter(func(child: Node): return child is Node2D and child.name.contains("Spawn"))

					for player_index in range(PM.players.size()):
						if PM.players[player_index]["joined"]:
							var player = PM.players[player_index]
							var stats = player_stats[player_index]
							var stat_sprite = AnimatedSprite2D.new()
							var monkey = player["monkey"]
							var monkey_sprite = player["sprite"]

							add_child(monkey)
							monkey.global_position = spawn_points[player_index].global_position
							monkey.visible = true
							monkey.animations.sprite_frames = monkey_sprite

							stats.visible = true
							stats.player_id = player["player_id"]
							stats.rocks.text = "rks: %d" % monkey.rocks
							stats.points.text = "pts: %d" % monkey.points

							stats.sprite_location.add_child(stat_sprite)
							stat_sprite.sprite_frames = monkey_sprite
							stat_sprite.animation = "idle"
							stat_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
							stat_sprite.scale = Vector2(2, 2)

							print("Player %d is spawning!" % player["player_id"])

					round_timer = Timer.new()
					round_timer.name = "MatchStartTimer"
					round_timer.one_shot = true
					round_timer.timeout.connect(func(): _on_match_start_timer_timeout())
					round_timer.wait_time = 5.0
					add_child(round_timer)
					round_timer.start()

					players_spawned = true


				round_timer_label.text = "%d" % int(round_timer.time_left)


func _on_player_joined(player_id: int, device_id: int, _player_index: int) -> void:
	print("Player %d joined with device %d!" % [player_id, device_id])

	if not ready_timer.is_stopped():
		ready_timer.wait_time += max_ready_time - ready_timer.time_left if 5.0 < max_ready_time - ready_timer.time_left else 5.0
		if ready_timer.time_left < ready_timer.wait_time:
			ready_timer.start(ready_timer.time_left + 5.0)


func _on_player_left(player_id: int, _player_index: int) -> void:
	print("Player %d left!" % player_id)

	if state == States.GAME:
		var monkey = get_node_or_null("Player %d" % player_id)

		if monkey:
			monkey.queue_free()


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


func _on_match_start_timer_timeout() -> void:
	match_started = true
	round_timer.queue_free()
	round_timer = Timer.new()
	round_timer.name = "RoundTimer"
	round_timer.one_shot = true
	round_timer.timeout.connect(func(): _on_round_timer_timeout())
	round_timer.wait_time = round_time_limit
	add_child(round_timer)
	round_timer.start()

# TODO: Add round end logic
func _on_round_timer_timeout() -> void:
	round_number += 1
	round_timer.queue_free()
	round_timer = Timer.new()
	round_timer.name = "RoundTimer"
	round_timer.one_shot = true
	round_timer.timeout.connect(func(): _on_round_timer_timeout())
	round_timer.wait_time = round_time_limit
	add_child(round_timer)
	round_timer.start()
