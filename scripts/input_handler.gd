extends Node
class_name InputHandler


# Monkey Gameplay
func move_direction(player_id: int) -> Vector2:
    if _valid_input(player_id):
        return Vector2(sign(Input.get_axis("move_left%d" % player_id, "move_right%d" % player_id)), sign(Input.get_axis("move_up%d" % player_id, "move_down%d" % player_id)))
    return Vector2.ZERO


func aim_direction(player_id: int) -> Vector2:
    if _valid_input(player_id):
        return Vector2(Input.get_axis("aim_left%d" % player_id, "aim_right%d" % player_id), Input.get_axis("aim_up%d" % player_id, "aim_down%d" % player_id))
    return Vector2.ZERO


func jump(player_id: int) -> bool:
    if _valid_input(player_id):
        return Input.is_action_just_pressed("jump%d" % player_id)
    return false


func throw_rock(player_id: int) -> bool:
    if _valid_input(player_id):
        return Input.is_action_just_pressed("throw_rock%d" % player_id)
    return false


# Input Validation
func _valid_input(player_id: int) -> bool:
    var attempted_action: StringName

    for action in PM.action_list:
        if action.begins_with("ui_"):
            continue

        attempted_action = action + str(player_id)

        if InputMap.has_action(attempted_action):
            return true

    return false
