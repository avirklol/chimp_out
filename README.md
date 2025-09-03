# Chimp Out – Local Versus Arena

A fast-paced 1v1 local multiplayer arena game. Each player controls a monkey, aims with a crosshair, throws rocks to stun the opponent, and races to collect the most items thrown into the arena by the crowd.

## Game Concept

- 2 players battle in a compact arena
- Throw rocks to stun your opponent (short arc knockback when stunned)
- While they’re stunned, steal their rocks and/or collect more cookies
- Precise aim using gamepad right stick or mouse

## Features

- Local multiplayer (up to 2 players) with device-based input assignment
- Per-player crosshair aiming (gamepad right stick our mouse)
- Rock projectiles with CCD to prevent tunneling and owner-immunity grace window
- Minimal UI
- Stun system with configurable duration and arced knockback
- Join flow: “press any key/button” to spawn and auto-assign device
- Simple, readable architecture using small managers and reusable player scene

## Controls

Default layout (can be adjusted in Project Settings):

- Player 1 (Keyboard/Mouse)
  - Move: WASD
  - Aim: Mouse
  - Throw: Left Mouse (action: `throw_rock`)
  - Jump/Dodge (if enabled): Space/Shift

- Player 2 (Gamepad)
  - Move: Left Stick
  - Aim: Right Stick
  - Throw: R2/RT
  - Jump/Dodge (if enabled): R1/RB

Notes:
- Mouse/keyboard input is wonky and will need to be fixed.
- Gamepads are auto-detected and assigned per device ID.
- Network multiplayer is a goal.
- Jumping not implemented yet.

## How It Works (Systems)

- PlayerDeviceManager (autoload):
  - Listens for the first input from each device and assigns it to a player
  - Tracks device → player mapping, handles connect/disconnect
  - Creates input mapping for each player

- GameStateManager (autoload):
  - Spawns players at arena spawn points
  - Applies per-player visuals (sprite sheet), forwards assigned device_id

- Monkey (player character):
  - Reads movement/aim input from its own `InputHandler` filtered by `device_id`
  - Drives crosshair, throws rocks, processes stun/knockback, jumps

- Rock (projectile):
  - Spawns at crosshair, launches immediately toward aim direction
  - Uses Continuous Collision Detection (CCD) for reliable hits
  - Owner immunity (brief) prevents self-stun right after throwing

## Project Structure (key files)

```
scripts/
  game_state_manager.gd      # Spawning, per-player setup, high-level flow
  player_device_manager.gd   # Device → player mapping, join flow and per-player input mapping
  input_handler.gd           # Player input (keyboard/mouse or gamepad) per player_id
  monkey.gd                  # Player logic (movement, aim, throw, stun)
  rock.gd                    # Projectile logic (launch, CCD, hit handling)
scenes/
  arena.tscn                 # Main scene (set as run/main_scene)
```

## Setup & Running

1. Open the project in Godot 4.4+
2. Ensure the main scene is set to `scenes/arena.tscn`
3. Press Play
4. Join as P1 by pressing gamepad start button; join as P2 by pressing gamepad start button

### Display/Scaling

- Uses a fixed internal resolution with content scaling (Canvas Items + Keep Aspect)
- The view area stays constant; the game scales to fill the window/screen

## Customization

- Add spawn points: place/adjust two nodes in `arena.tscn` (e.g., `Spawn1`, `Spawn2`) and align them with GameStateManager
- Player visuals: assign two sprite sheets (green/red) for fast readability
- Tuning:
  - Rock speed/throw distance, stun duration, player speed, max rocks, jump strength, etc.
  - Owner immunity window and collision masks

## Roadmap Ideas

- Score HUD per player; match timer; round wins/best-of-N
- Items/power-ups (speed boost, multi-rock, shield)
- Camera that smoothly centers/zooms based on player distance
- Online play (future): keep input abstraction to ease migration

## License

This project is provided for learning and jam development. Modification and reuse for non-commercial purposes is permitted.
