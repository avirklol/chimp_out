extends RigidBody2D
class_name Rock

@export var throw_strength: float = 900
@export var max_distance: float = 300

@onready var hit_area: Area2D = $HitArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var column_check: ShapeCast2D = $ColumnCheck


var parent: Monkey
var states:= Monkey.States
var direction: Vector2
var start_position: Vector2
var final_velocity: Vector2
var thrown: bool


func _ready() -> void:
	global_rotation_degrees = randf_range(0, 360)
	hit_area.body_entered.connect(_on_hit_area_body_entered)
	custom_integrator = true
	contact_monitor = true
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	max_contacts_reported = 1


func _on_hit_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("monkey"):
		if thrown:
			print(str(body.name) + ' is stunned!')
			print(sign((body.global_position - global_position).normalized()))
			body.state = states.STUNNED
		else:
			if body.state not in [states.STUNNED, states.RECOVERING, states.JUMPING]:
				print(str(body.name) + ' picked up a rock!')
				body.rocks += 1
				queue_free()


func _physics_process(_delta: float) -> void:
	if thrown:
		var distance_traveled = global_position.distance_to(start_position)

		if distance_traveled > max_distance:
			_stop_rock(0.1)

		if linear_velocity.length() > 0:
			global_rotation_degrees = linear_velocity.angle() * 180 / PI

		if get_contact_count():
			print('Rock hit an object!')
			_stop_rock(0.5)

	else:
		if column_check.is_colliding():
			freeze = false
			apply_central_impulse(Vector2(sign(randf_range(-1, 1)), sign(randf_range(-1, 1))) * 100)
		else:
			freeze = true


func throw(monkey: Monkey) -> void:
	parent = monkey
	_parent_collision_enabled(false)
	start_position = global_position
	direction = (parent.crosshair.global_position - parent.global_position).normalized()
	linear_velocity = direction * throw_strength
	thrown = true


func _stop_rock(timer_wait_time: float = 0.3) -> void:
	_parent_collision_enabled(true)
	var stop_timer := Timer.new()
	stop_timer.wait_time = timer_wait_time
	stop_timer.one_shot = true
	stop_timer.timeout.connect(func():
		final_velocity = linear_velocity
		linear_velocity = Vector2.ZERO
		thrown = false
		freeze = true
	)
	add_child(stop_timer)
	stop_timer.start()


func _parent_collision_enabled(enabled: bool) -> void:
	set_collision_mask_value(parent.player_id, enabled)
	hit_area.set_collision_mask_value(parent.player_id, enabled)
