extends Control

var option_index: int = 0

@onready var title: RichTextLabel = %Title
@onready var start: RichTextLabel = %Start
@onready var quit: RichTextLabel = %Quit
@onready var pointer: TextureRect = %Pointer


func _ready() -> void:
	pointer.position = Vector2(457, 528)
	pointer.scale = Vector2(0.75, 0.75)
	pointer.texture = load("res://assets/ui/HandRight.png")
	title.text = "[b]CHIMP OUT[/b]"
	start.text = "START"
	quit.text = "QUIT"


func _process(_delta: float) -> void:
	_move_pointer()
	_process_selection()


func _move_pointer() -> void:
	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_down"):
		option_index = 1 if option_index == 0 else 0

	match option_index:
		0:
			pointer.position = Vector2(457, 528)
		1:
			pointer.position = Vector2(457, 569)


func _process_selection() -> void:
	if Input.is_action_just_pressed("select"):
		match option_index:
			0:
				GM.state = GM.States.PLAYER_SELECTION
			1:
				get_tree().quit()
