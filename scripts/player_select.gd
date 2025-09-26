class_name PlayerSelect
extends Control

@export var checkbox_textures: Array[Resource]

var player_join_labels: Array[Node]
var player_joined_sprite_location: Array[Node]
var player_ready_labels: Array[Node]
var player_ready_checkboxes: Array[Node] = []


func _ready() -> void:
	PM.player_joined.connect(_on_player_joined)
	PM.player_left.connect(_on_player_left)
	PM.player_ready.connect(_on_player_ready)
	PM.new_player_sprite.connect(_change_monkey_color)

	player_join_labels = %PlayerJoin.get_children()
	player_joined_sprite_location = %MonkeySprite.get_children()
	player_ready_labels = %PlayerReady.get_children().filter(func(child: Node): return child is RichTextLabel)
	player_ready_checkboxes = %PlayerReady.get_children().filter(func(child: Node): return child is TextureRect)


	for label in player_join_labels:
		label.visible = true

	for label in player_ready_labels:
		label.visible = false
		player_ready_checkboxes.append(label.get_child(0))

	for checkbox in player_ready_checkboxes:
		checkbox.texture = checkbox_textures[0]

		var checked = checkbox.get_child(0)

		checked.texture = checkbox_textures[1]
		checked.visible = false


func _on_player_ready(_player_id: int, player_index: int, is_ready: bool) -> void:
	var checkmark_sprite = player_ready_checkboxes[player_index].get_child(0)

	if is_ready:
		checkmark_sprite.visible = true
	else:
		checkmark_sprite.visible = false


func _on_player_joined(player_id: int, _device_id: int, player_index: int) -> void:
	player_join_labels[player_index].visible = false
	player_ready_labels[player_index].visible = true

	var monkey:= AnimatedSprite2D.new()
	var sprite_location: Control = player_joined_sprite_location[player_index]

	get_tree().current_scene.add_child(monkey)
	monkey.name = "Player %d" % player_id
	monkey.global_position = sprite_location.global_position + Vector2(sprite_location.size.x / 2, 0)
	monkey.sprite_frames = PM.get_next_available_sprite(player_id)
	monkey.animation = "idle"
	monkey.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	monkey.scale = Vector2(3, 3)


func _on_player_left(player_id: int, player_index: int) -> void:
	player_join_labels[player_index].visible = true
	player_ready_labels[player_index].visible = false

	var monkey = get_tree().current_scene.get_node_or_null("Player %d" % player_id)
	if monkey:
		monkey.queue_free()


func _change_monkey_color(player_id: int, _player_index: int, sprite: Resource) -> void:
	var monkey = get_tree().current_scene.get_node_or_null("Player %d" % player_id)

	if monkey:
		monkey.sprite_frames = sprite
		monkey.animation = "idle"
