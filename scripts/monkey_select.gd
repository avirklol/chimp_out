extends Control
class_name MonkeySelect

var player_join_labels: Array[Node]
var player_joined_sprite_location: Array[Node]
var player_ready_labels: Array[Node]


func _ready() -> void:
	player_join_labels = %PlayerJoin.get_children()
	player_joined_sprite_location = %MonkeySprite.get_children()
	player_ready_labels = %PlayerReady.get_children()

	GM.state = GM.States.PLAYER_SELECTION

	for label in player_join_labels:
		label.visible = true
	for label in player_ready_labels:
		label.visible = false


func _process(_delta: float) -> void:
	for index in PM.max_players:
		var player = PM.players[index]

		if player["joined"]:
			var monkey:= AnimatedSprite2D.new()
			var sprite_location: Control = player_joined_sprite_location[index]

			player_join_labels[index].visible = false
			player_ready_labels[index].visible = true

			get_tree().current_scene.add_child(monkey)
			monkey.global_position = sprite_location.global_position + Vector2(sprite_location.size.x / 2, 0)
			monkey.sprite_frames = GM.sprite_sheets[index]
			monkey.animation = "idle"
			monkey.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			monkey.scale = Vector2(3, 3)
		else:
			player_join_labels[index].visible = true
			player_ready_labels[index].visible = false
			player_joined_sprite_location[index].visible = false


# func _change_monkey_color(player_id: int) -> void:
