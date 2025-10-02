class_name Monkey
extends CharacterBody2D

signal rock_thrown(player_id: int, rocks: int)

enum States { IDLE, MOVING, JUMPING, STUNNED, RECOVERING }

@export var rocks: int = 3
@export var speed: float = 155
@export var jump_strength: float = 1000
@export var aim_radius: float = 35

var state: States = States.IDLE
var disconnected: bool = false
var rock_ready: bool = true
var jump_ready: bool = true
var player_id: int
var device_id: int
var points: int = 0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animations: AnimatedSprite2D = $AnimatedSprite2D
@onready var crosshair: Sprite2D = $Crosshair
@onready var crosshair_wall_check: ShapeCast2D = %CrosshairWallCheck
@onready var jump_timer: Timer = $JumpTimer
@onready var rock_timer: Timer = $RockTimer
@onready var rock: PackedScene = preload("res://scenes/rock.tscn")


func _ready() -> void:
	PM.player_disconnected.connect(_on_player_disconnected)
	PM.player_reconnected.connect(_on_player_reconnected)
	animations.animation_finished.connect(_on_animation_finished)
	rock_timer.timeout.connect(_ready_rock)
	jump_timer.timeout.connect(_ready_jump)

	add_to_group("monkey")

	set_collision_layer_value(player_id, true)


func _ready_jump() -> void:
	jump_ready = true


func _ready_rock() -> void:
	rock_ready = true


func _on_animation_finished() -> void:
	if animations.animation == "stunned":
		animations.frame = 1

	if animations.animation == "recovering":
		state = States.IDLE


func _unhandled_input(_event: InputEvent) -> void:
	if GM.match_started:
		if state in [States.STUNNED, States.RECOVERING]:
			return

		if IH.move_direction(player_id) != Vector2.ZERO:
			if !Input.is_action_pressed("jump"):
				state = States.MOVING
			else:
				state = States.JUMPING
		else:
			state = States.IDLE

		if IH.throw_rock(player_id) and _can_throw_rock():
			_throw_rock()


func _physics_process(delta: float) -> void:
	match state:
		States.IDLE:
			pass
		States.MOVING:
			_move(delta)
		States.JUMPING:
			_jump(delta)
		States.STUNNED:
			_stun(delta)
		States.RECOVERING:
			pass


func _process(_delta: float) -> void:
	var direction = IH.move_direction(player_id)

	if !disconnected:
		match state:
			States.MOVING:
				if direction == Vector2(-1, 1):
					animations.play("down_left")
				elif direction == Vector2(1, 1):
					animations.play("down_right")
				elif direction == Vector2(1, -1):
					animations.play("up_right")
				elif direction == Vector2(-1, -1):
					animations.play("up_left")
				elif direction == Vector2(0, 1):
					animations.play("down")
				elif direction == Vector2(0, -1):
					animations.play("up")
				elif direction == Vector2(1, 0):
					animations.play("right")
				elif direction == Vector2(-1, 0):
					animations.play("left")
			States.JUMPING:
				animations.play("idle")
			States.IDLE:
				animations.play("idle")
			States.STUNNED:
				animations.play("stunned")
			States.RECOVERING:
				animations.play("recovering")

		var aim_dir: Vector2 = IH.aim_direction(player_id)

		if aim_dir != Vector2.ZERO:
			crosshair.visible = true
			crosshair.global_position = global_position + aim_dir.normalized() * aim_radius
		else:
			crosshair.visible = false
			if direction != Vector2.ZERO:
				crosshair.global_position = global_position + direction * aim_radius
			else:
				crosshair.global_position = Vector2(global_position.x, global_position.y + aim_radius)
	else:
		crosshair.visible = false
		animations.play("idle")

# TODO: Fix mouse input!
		# var mouse_pos: Vector2 = IH.mouse_position()
		# var to_mouse: Vector2 = (mouse_pos - global_position)
		# crosshair.global_position = global_position + to_mouse.limit_length(radius)


func _move(_delta: float) -> void:
	velocity = IH.move_direction(player_id) * speed
	move_and_slide()

# TODO: Add jump animation and movement
func _jump(_delta: float) -> void:
	pass


func _stun(_delta: float) -> void:
	# TODO: Add additional stun animations and movement
	velocity = Vector2.ZERO
	move_and_slide()

	var stun_timer := Timer.new()
	stun_timer.wait_time = 1.5
	stun_timer.one_shot = true
	stun_timer.timeout.connect(func():
		state = States.RECOVERING
	)
	add_child(stun_timer)
	stun_timer.start()


func _throw_rock() -> void:
	if rocks > 0:
		rocks -= 1
		var rock_instance = rock.instantiate()
		rock_instance.global_position = crosshair.global_position
		get_tree().current_scene.add_child(rock_instance)
		rock_instance.throw(self)
		rock_ready = false
		rock_timer.start()

		GM.rock_thrown.emit(player_id, rocks)


func _can_throw_rock() -> bool:
	return rock_ready and !crosshair_wall_check.is_colliding() and state != States.JUMPING


func _on_player_disconnected(p_id: int, _player_index: int) -> void:
	if p_id == self.player_id:
		_disable_player(true)

		var timer = Timer.new()
		timer.name = "DisconnectedTimer"
		timer.wait_time = 0.7
		timer.one_shot = false
		timer.timeout.connect(func():
			self.visible = !self.visible
		)
		add_child(timer)
		timer.start()


func _on_player_reconnected(p_id: int, _player_index: int) -> void:
	if p_id == self.player_id:
		var disconnected_timer = get_node_or_null("DisconnectedTimer")

		if disconnected_timer:
			disconnected_timer.stop()
			disconnected_timer.queue_free()

		_disable_player(false)


func _disable_player(disabled: bool) -> void:
	disconnected = disabled
	collision_shape.disabled = disabled
	self.visible = !disabled
	self.z_index = 1 if disabled else 2
