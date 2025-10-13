# Chimp Out – Local Versus Arena

A fast-paced 1v1 local multiplayer arena game. Each player controls a monkey, aims with a crosshair, throws rocks to stun the opponent, and races to collect the most items thrown into the arena by the crowd.

## Game Concept

- 2-4 players battle in a compact arena
- Throw rocks to stun your opponent (short arc knockback when stunned)
- While they’re stunned, steal their rocks and/or collect more cookies
- Precise aim using gamepad right stick or mouse

## Features

- Local multiplayer (up to 4 players) with device-based input assignment
- Per-player crosshair aiming (gamepad right stick our mouse)
- Rock projectiles with CCD to prevent tunneling and owner-immunity grace window
- Minimal UI
- Stun system with configurable duration and arced knockback
- Join flow: “press start to join” on player select screen
- Simple, readable architecture using small managers and reusable player scene

## Controls

Default layout (can be adjusted in Project Settings):

- Keyboard/Mouse // UNDER CONSTRUCTION //
  - Move: WASD
  - Aim: Mouse
  - Throw: Left Mouse (action: `throw_rock`)
  - Back: Q
  - Select: E
  - Start: Enter
  - Jump/Dodge (once enabled): Space/Shift/Right Mouse

- Gamepad
  - Move: Left Stick
  - Aim: Right Stick
  - Throw: R2/RT
  - Back: B
  - Select: A
  - Start: Start
  - Jump/Dodge (once enabled): R1/RB

Notes:
- Mouse/keyboard input is wonky and will need to be fixed.
- Gamepads are auto-detected and assigned per device ID.
- Network multiplayer is a goal.
- Jumping not implemented yet.

## How It Works (Systems)

- PlayerManager (autoload):
  - Listens for the first input from each device and assigns it to a player
  - Tracks device → player mapping, handles connect/disconnect
  - Creates input mapping for each player

- GameManager (autoload):
  - Spawns players at arena spawn points
  - Applies per-player visuals (sprite sheet), forwards assigned device_id

- InputHandler (autoload):
  - Validates input to verify if it exists within InputMap
  - Returns gameplay-specific input data to `Monkey` class objects.

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
  game_manager.gd           # Spawning, per-player setup, high-level flow
  player_manager.gd         # Device → player mapping, join flow and per-player input mapping
  player_stats.gd           # Behaviour for the PlayerStats scene
  player_select.gd          # UI for player join, color section and readying up
  title_screen.gd           # Title screen UI
  round_title.gd            # Round title UI, loaded between rounds in a match
  user_interface.gd         # Provides access to constants within the UI, allowing for the game manager to adjust data
  input_handler.gd          # Player input (keyboard/mouse or gamepad) per player_id
  monkey.gd                 # Player logic (movement, aim, throw, stun)
  rock.gd                   # Projectile logic (launch, CCD, hit handling)
scenes/
  title_screen.tscn         # A title screen
  player_select.tscn        # Player selection screen; allows players to join by pressing start, selecting a monkey color and readying up
  round_title.tscn          # Titles that detail the round number and the most valuable monkey
  arena.tscn                # The arena that loads on round start
  rock.tscn                 # The rock monkeys yield to throw at one another
  monkey.tscn               # The monkeys players control
  input_handler.tscn        # Autoload scene to allow for export variables
  player_manager.tscn       # Autoload scene to allow for export variables
  game_manager.tscn         # Autoload scene to allow for export variables
  player_stats.tscn         # Player stat panels
  user_interface.tscn       # A collection of player stat panels
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

- Add spawn points: place/adjust nodes in `arena.tscn` (e.g., `Spawn1`, `Spawn2`) and align them with GameManager
- Player visuals: assign a minimum of 4 sprite sheets (green/red) for fast readability
- Tuning:
  - Rock speed/throw distance, stun duration, player speed, max rocks, jump strength, etc.
  - Owner immunity window and collision masks

## Roadmap Ideas

- Score HUD per player; match timer; round wins/best of players+1
- Items/power-ups (speed boost, multi-rock, shield)
- Camera that smoothly centers/zooms based on player distance
- Online play (future): keep input abstraction to ease migration

## License

This project is provided for learning and jam development. Modification and reuse for non-commercial purposes is permitted.
