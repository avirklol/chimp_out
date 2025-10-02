class_name PlayerStats
extends NinePatchRect

var player_id: int

@onready var rocks: RichTextLabel = %PlayerRocks
@onready var points: RichTextLabel = %PlayerPoints
@onready var sprite_location: Control = %PlayerSprite


func _ready() -> void:
	GM.rock_thrown.connect(_on_rock_thrown)
	GM.points_changed.connect(_on_points_changed)
	GM.rock_picked_up.connect(_on_rock_picked_up)

func _on_rock_thrown(p_id: int, rock_count: int) -> void:
	if player_id == p_id:
		self.rocks.text = "rks: %d" % rock_count


func _on_rock_picked_up(p_id: int, rock_count: int) -> void:
	if player_id == p_id:
		self.rocks.text = "rks: %d" % rock_count


func _on_points_changed(p_id: int, point_count: int) -> void:
	if player_id == p_id:
		self.points.text = "pts: %d" % point_count
