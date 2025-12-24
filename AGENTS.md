# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Commodore 64 Snake game written in 6502 assembly using the c2 assembler. Features dynamic difficulty with speed acceleration and treat mechanics.

## Build & Run

```bash
c2                    # Build and launch in VICE emulator
c2 -r                 # Force rebuild
c2 -X                 # Build without executing
c2 --clean            # Remove intermediate files
```

The c2 assembler is located at `~/bin/c2`. Build configuration is in `snakie.c2.json`.

## Architecture

### Module Organization

- `snakie.s` - Main entry point and game loop
- `include/constants.s` - Game tuning constants and zero-page variable definitions
- `include/screen.s` - Screen initialization and utilities
- `include/input.s` - Keyboard input (WASD controls)
- `include/snake.s` - Core game logic (movement, collision, food mechanics)
- `include/drawing.s` - Rendering (snake, food, score, star)
- `include/ui.s` - Title and game over screens
- `include/data.s` - Game data, delay loop, speed updates

### Memory Layout

**Zero Page ($50-$6F):** Game state variables
- $50-$51: Snake head position (X, Y)
- $52-$53: Food position
- $54: Direction (0=right, 1=down, 2=left, 3=up)
- $56: Snake length
- $57: Game over flag
- $5C-$5D: 16-bit score
- $5E: Current delay (speed control)
- $63-$68: Star mechanics (position, timeout, timers)

**Snake Body Storage:** $C000-$C0FF (avoids system vectors at $0300-$033A)

### Game State Machine

```
TITLE_LOOP → INIT → MAIN_LOOP → COLLISION_CHECK → GAME_OVER_LOOP → RESTART
```

## c2 Assembler Syntax

Key differences from traditional 6502 assemblers:
- Comments: `//` or `/* */` (NOT `;`)
- ORG pointer: `@` (NOT `*`)
- Variables: `var name = $address`
- Labels: `name:` (global), `.name:` (local)
- Strings: `petscii "text"` or `screencode "text"`

## Game Balance Tuning

All tunable constants are in `include/constants.s`:

```asm
DELAY_START = $80           // Starting speed (higher = slower)
DELAY_MIN = $20             // Speed cap (lower = faster)
SPEED_INCREASE_INTERVAL = 30 // Ticks between acceleration
HEART_SLOWDOWN = $10        // Slowdown when eating heart
STAR_SPEEDUP = $08          // Speedup when eating star
STAR_POINTS_LO = 100        // Star bonus points
STAR_TIMEOUT_START = 76     // Star visibility duration
```

## Detailed Reference

See `.github/copilot-instructions.md` for:
- Full 6502 instruction reference
- C64 memory map
- KERNAL routines
- c2 macro syntax
- Code examples

See `GAMEPLAY.md` for game design documentation.
