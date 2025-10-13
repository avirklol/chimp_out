class_name GameManager
extends Node

signal game_start
signal game_end
signal rock_thrown(player_id: int, rocks: int)
signal rock_picked_up(player_id: int, rocks: int)
signal points_changed(player_id: int, points: int)

enum States { TITLE, PLAYER_SELECTION, GAME, END }

@export var title_screen: PackedScene
@export var player_select_screen: PackedScene
@export var round_title_screen: PackedScene
@export var user_interface: PackedScene
@export var arena: PackedScene
@export var round_time_limit: float = 120.0
@export var round_time_limit_warning: float = 10.0
@export var max_ready_time: float = 10.0

var state: States = States.TITLE
var ui: UserInterface
var ready_players: int = 0
var ready_timer: Timer
var round_title_timer: Timer
var round_start_timer: Timer
var round_timer: Timer
var round_timer_label: RichTextLabel
var round_number: int = 0
var max_rounds: int = 3
var round_title: bool = true
var round_started: bool = false
var players_spawned: bool = false
var mvm: Dictionary
var spawn_points: Array[Node] = []
var player_stats: Array[Node] = []


func _ready() -> void:
	PM.player_joined.connect(_on_player_joined)
	PM.player_ready.connect(_on_player_ready)
	PM.player_left.connect(_on_player_left)

	ready_timer = _create_timer("ReadyTimer", max_ready_time, true, _on_ready_timer_timeout)


func _process(_delta: float) -> void:
	if not ready_timer.is_stopped():
		print("Ready Timer: %d" % int(ready_timer.time_left))

	match state:
		States.TITLE:
			if !get_tree().current_scene.name.contains("TitleScreen"):
				get_tree().change_scene_to_packed(title_screen)
		States.PLAYER_SELECTION:
			if !get_tree().current_scene.name.contains("PlayerSelect"):
				get_tree().change_scene_to_packed(player_select_screen)
		States.GAME:
			if !round_title:
				if !get_tree().current_scene.name.contains("Arena"):
					get_tree().change_scene_to_packed(arena)
				else:
					if !players_spawned:
						if !ui:
							ui = user_interface.instantiate()
							add_child(ui)
							ui.z_index = 100

						ui.visible = true
						player_stats = ui.stats.get_children()
						round_timer_label = ui.round_timer
						spawn_points = get_tree().current_scene.get_children().filter(func(child: Node): return child is Node2D and child.name.contains("Spawn"))

						for player_index in range(PM.players.size()):
							if PM.players[player_index]["joined"]:
								var player: Dictionary = PM.players[player_index]
								var stats: PlayerStats = player_stats[player_index]
								var monkey: Monkey = player["monkey"]
								var monkey_sprite: Resource = player["sprite"]

								add_child(monkey)
								monkey.global_position = spawn_points[player_index].global_position
								monkey.visible = true
								monkey.animations.sprite_frames = monkey_sprite

								stats.visible = true
								stats.player_id = player["player_id"]
								stats.rocks.text = "rks: %d" % monkey.rocks
								stats.points.text = "pts: %d" % monkey.points

								_add_idle_sprite_to_location(stats.sprite_location, monkey_sprite)

								print("Player %d is spawning!" % player["player_id"])

						round_start_timer = _create_timer("RoundStartTimer", 5.0, true, _on_round_start_timer_timeout)
						round_start_timer.start()

						players_spawned = true

					if round_timer:
						round_timer_label.text = "%d" % int(round_timer.time_left)
			else:
				if !get_tree().current_scene.name.contains("RoundTitle"):
					round_number += 1
					mvm.clear()
					get_tree().change_scene_to_packed(round_title_screen)
				else:
					var round_label = get_tree().current_scene.round_label
					var mvm_label = get_tree().current_scene.mvm_label
					var mvm_location = get_tree().current_scene.mvm_location

					round_label.text = "ROUND %d" % round_number
					mvm_label.visible = false
					mvm_location.visible = false

					if round_number > 1 and !mvm:
						var player_points: Array[int] = []
						var mvm_list: Array[Dictionary] = []

						for player in PM.players:
							player_points.append(player["points"])

						var highest_points = player_points.max()

						for player in PM.players:
							if player["points"] == highest_points:
								mvm_list.append(player)

						if mvm_list.size() > 1:
							var true_mvm = _tie_breaker(mvm_list)

							if true_mvm:
								mvm = true_mvm
							else:
								mvm = mvm_list[randi() % mvm_list.size()]
						else:
							mvm = mvm_list[0]

					if mvm:
						mvm_label.text = "MVM"
						mvm_label.visible = true
						mvm_location.visible = true

						_add_idle_sprite_to_location(mvm_location, mvm["sprite"])

					round_title_timer = _create_timer("RoundTitleTimer", 5.0, true, _on_round_title_timer_timeout)
					round_title_timer.start()


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


func _on_round_title_timer_timeout() -> void:
	round_title = false


func _on_round_start_timer_timeout() -> void:
	round_started = true
	round_start_timer.queue_free()
	round_timer = _create_timer("RoundTimer", round_time_limit, true, _on_round_timer_timeout)
	round_timer.start()


func _on_round_timer_timeout() -> void:
	var monkeys: Array[Node] = get_tree().get_nodes_in_group("monkey")

	ui.visible = false

	for monkey in monkeys:
		monkey.visible = false

	round_timer.queue_free()

	round_title = true
	players_spawned = false
	round_started = false


func _tie_breaker(mvm_list: Array[Dictionary]) -> Variant:
	var comparison_keys: Array[String] = ["hits_landed", "hits_taken"]
	var player_points: Array[int] = []
	var new_mvm_list: Array[Dictionary] = []

	for key in comparison_keys:
		for player in mvm_list:
			player_points.append(player[key])

		var highest_points = player_points.max()

		for player in mvm_list:
			if player[key] == highest_points:
				new_mvm_list.append(player)

		if new_mvm_list.size() > 1:
			player_points.clear()
			new_mvm_list.clear()
		else:
			return new_mvm_list[0]

	return null


func _add_idle_sprite_to_location(location: Control, sprite_frames: Resource) -> void:
	var sprite = AnimatedSprite2D.new()
	location.add_child(sprite)
	sprite.sprite_frames = sprite_frames
	sprite.animation = "idle"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(2, 2)


func _create_timer(timer_name: String, wait_time: float, one_shot: bool = true, timeout_callback: Callable = func(): pass) -> Timer:
	var timer = Timer.new()
	timer.name = timer_name
	timer.one_shot = one_shot
	timer.wait_time = wait_time
	timer.timeout.connect(timeout_callback)
	add_child(timer)
	return timer
