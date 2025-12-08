# Snake Gameplay Design

## Core Concept

A snake game with dynamic difficulty that increases over time, where eating treats provides temporary relief from the accelerating pace.

## Difficulty Progression

### Speed System
- **Base speed**: Snake starts at a comfortable pace
- **Automatic acceleration**: Speed gradually increases over time (every N ticks or score milestones)
- **Treat effect**: Eating a treat temporarily slows the snake down, giving the player a brief respite
- **Speed cap**: Maximum speed limit to keep the game playable

### Difficulty Curve
```
Speed
  ^
  |        _______________  (speed cap)
  |       /
  |      /  <- gradual increase
  |     /
  |____/    <- starting speed
  +-------------------------> Time/Score
       ^
       Treat eaten (temporary dip)
```

## Mechanics

### Current
- WASD movement
- Collect hearts to grow
- Wall and self-collision ends game
- Score increments each tick

### Proposed Changes

1. **Dynamic Delay**
   - Replace fixed delay loop with variable delay
   - Delay decreases over time (faster movement)
   - Eating heart treat increases delay temporarily (slower movement)

2. **Score System**
   - Bonus points for surviving at higher speeds?
   - Multiplier based on current speed?

## Treat Types

### Heart (♥) - Primary Treat
- **Character**: $53 (heart symbol)
- **Always present**: One heart is always on the playfield
- **Effects**:
  - Grows snake by 1 segment
  - Slows snake down (increases delay)
  - Standard points
- **Strategy**: Use hearts to manage your speed while growing

### Star (★) - Bonus Treat
- **Character**: $2A or similar star symbol
- **Temporary**: Appears randomly, disappears after N ticks if not collected
- **Timeout**: Starts at ~76 ticks (2× screen width of 38), decreases over time
- **Effects**:
  - Does NOT grow snake
  - Speeds snake UP (decreases delay) - risk!
  - Large point bonus
- **Strategy**: High risk/reward - grab for points but makes game harder

### Treat Spawn Rules
- Heart: Always spawns immediately when previous heart is eaten
- Star: Random chance to spawn each N ticks (if no star present)
- Star timeout:
  - Initial: 76 ticks (enough time to cross screen twice at starting speed)
  - Decreases over time (as game speeds up, stars vanish faster)
  - Minimum timeout to keep it possible to reach
- Only one star on screen at a time

## Implementation Ideas

### Speed Variables (Zero Page)
- `delay_current` - Current delay value (higher = slower)
- `delay_min` - Minimum delay (speed cap)
- `speed_timer` - Counter for when to increase speed

### Treat Variables (Zero Page)
- `star_x`, `star_y` - Star position (0 = no star present)
- `star_timer` - Countdown until star disappears
- `star_timeout` - Current timeout duration (decreases over time)
- `star_spawn_timer` - Countdown until next star spawn chance

### Speed Increase Triggers
- Every N game ticks, decrease `delay_current` by 1
- Stop decreasing when `delay_current` reaches `delay_min` (speed cap)

### Treat Slow-Down
- When heart eaten: `delay_current += HEART_SLOWDOWN`
- Cap at maximum delay (starting speed)

### Star Mechanics
- When star eaten: `delay_current -= STAR_SPEEDUP` (makes game harder!)
- Add large bonus to score (e.g., 100 points)
- Star spawns with random chance every N ticks
- Star timeout mechanics:
  - Initial timeout: 76 ticks (2 × 38 playable columns)
  - Timeout decreases over time alongside speed increase
  - Minimum timeout (e.g., 20 ticks) to keep stars reachable
- Visual: Could flash/blink to indicate it's temporary

## Questions to Decide

All timing and balance values should be parameterized as constants for easy tuning during playtesting:

- `DELAY_START` - Initial delay (starting speed)
- `DELAY_MIN` - Minimum delay (speed cap)
- `SPEED_INCREASE_INTERVAL` - Ticks between speed increases
- `HEART_SLOWDOWN` - How much hearts slow you down
- `STAR_SPEEDUP` - How much stars speed you up
- `STAR_POINTS` - Point bonus for collecting a star
- `STAR_TIMEOUT_START` - Initial star timeout (76 ticks)
- `STAR_TIMEOUT_MIN` - Minimum star timeout
- `STAR_SPAWN_INTERVAL` - Ticks between star spawn chances

Everything resets on game over.

## Future Ideas

- More temporary treat types:
  - Shield: Pass through walls once
  - Ghost: Pass through self once
  - Shrink: Reduce snake length
  - Freeze: Pause speed acceleration temporarily
- Obstacles that appear over time
- Multiple food items on screen
- Sound effects for speed changes
- Visual speed indicator on screen
