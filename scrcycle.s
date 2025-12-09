#include "c2/c64/c64.s"
#include "c2/mos/6502.s"

//----------------------------------------------
// Snake game for the Commodore 64
// Assemble with c2 and load via RUN
//----------------------------------------------

// Include all game modules
#include "include/constants.s"

basic_startup

start:
    jsr init_screen
    jsr draw_title_screen

title_loop:
    jsr get_key
    cmp #$20  // space bar to start
    bne title_loop

    // clear screen before starting game
    jsr clear_play_area
    jsr init_snake
    jsr place_food

main_loop:
    // check if game is over
    lda game_over
    bne game_over_loop

    jsr delay
    jsr get_key
    jsr update_direction
    jsr move_snake
    jsr update_body    // update body positions before collision check
    jsr check_collision
    jsr check_food     // check food before drawing so new food appears immediately
    jsr update_star    // handle star spawn/timeout
    jsr draw_snake     // draw last so everything is up-to-date
    jsr increment_score
    jsr draw_score
    jsr update_speed   // gradually increase speed over time
    jmp main_loop

game_over_loop:
    jsr draw_game_over
    jsr get_key
    cmp #$20  // space bar to restart
    beq start
    jmp game_over_loop

// Include all game modules
#include "include/screen.s"
#include "include/input.s"
#include "include/snake.s"
#include "include/drawing.s"
#include "include/ui.s"
#include "include/data.s"
