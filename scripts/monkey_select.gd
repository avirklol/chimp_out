extends Control
class_name MonkeySelect

var player_join_labels: Array[Node]
var player_joined_sprite_location: Array[Node]
var player_ready_labels: Array[Node]


func _ready() -> void:
	GM.state = GM.States.PLAYER_SELECTION

	PM.player_joined.connect(_on_player_joined)
	PM.player_left.connect(_on_player_left)

	player_join_labels = %PlayerJoin.get_children()
	player_joined_sprite_location = %MonkeySprite.get_children()
	player_ready_labels = %PlayerReady.get_children()

	for label in player_join_labels:
		label.visible = true
	for label in player_ready_labels:
		label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	var player_id = PM.get_player_id(event.device)

	if player_id != 0:
		if event.is_echo():
			return

		if event.is_action_pressed("move_up%d" % player_id):
			_change_monkey_color(player_id, true)
		elif event.is_action_pressed("move_down%d" % player_id):
			_change_monkey_color(player_id)


func _on_player_joined(player_id: int, _device_id: int, player_index: int) -> void:
	player_join_labels[player_index].visible = false
	player_ready_labels[player_index].visible = true

	var monkey:= AnimatedSprite2D.new()
	var sprite_location: Control = player_joined_sprite_location[player_index]

	get_tree().current_scene.add_child(monkey)
	monkey.name = "Player %d" % player_id
	monkey.global_position = sprite_location.global_position + Vector2(sprite_location.size.x / 2, 0)
	monkey.sprite_frames = GM.get_next_available_sprite(player_id)
	monkey.animation = "idle"
	monkey.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	monkey.scale = Vector2(3, 3)


func _on_player_left(player_id: int, player_index: int) -> void:
	player_join_labels[player_index].visible = true
	player_ready_labels[player_index].visible = false

	var monkey = get_tree().current_scene.get_node_or_null("Player %d" % player_id)
	if monkey:
		monkey.queue_free()

func _change_monkey_color(player_id: int, reverse: bool = false) -> void:
	var monkey = get_tree().current_scene.get_node_or_null("Player %d" % player_id)

	if monkey:
		monkey.sprite_frames = GM.get_next_available_sprite(player_id, reverse)
		monkey.animation = "idle"
