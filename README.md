# Snakie

A Snake game for the Commodore 64, written in 6502 assembly using the [c2 assembler](https://github.com/Hammarberg/c2).

## Build & Run

Requires [John Hammarberg's c2 assembler](https://github.com/Hammarberg/c2), and the [VICE emulator](https://vice-emu.sourceforge.io/).

With c2 installed and on your path, run c2 to build:

```bash
c2
```

This assembles the code, creates a D64 disk image, and launches the game in VICE.

## Controls

- **W** - Up
- **A** - Left
- **S** - Down
- **D** - Right
- **Space** - Start / Restart

## Gameplay

The snake speeds up over time. Collect treats to survive:

- **Heart** - Grows snake, slows you down (relief)
- **Star** - Bonus points, speeds you up (risk/reward)

Game ends on wall or self-collision.

## Project Structure

- `snakie.s` - Main entry point
- `include/` - Game modules (constants, screen, input, snake logic, drawing, UI, data)
- `GAMEPLAY.md` - Detailed game design documentation

## Author

Stacey Vetzal
