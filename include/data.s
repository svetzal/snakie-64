//----------------------------------------------
// Game data and message strings
//----------------------------------------------

//----------------------------------------------
// UI Messages (in screen codes)
//----------------------------------------------
game_over_msg:
    // "GAME OVER" in screen codes: G=7, A=1, M=13, E=5, space=32, O=15, V=22, E=5, R=18
    byte 7,1,13,5,32,15,22,5,18,0

press_space_msg:
    // "PRESS SPACE" in screen codes: P=16, R=18, E=5, S=19, S=19, space=32, S=19, P=16, A=1, C=3, E=5
    byte 16,18,5,19,19,32,19,16,1,3,5,0

title_msg:
    // "SNAKE" in screen codes: S=19, N=14, A=1, K=11, E=5
    byte 19,14,1,11,5,0

by_msg:
    // "A GAME BY" in screen codes
    byte 1,32,7,1,13,5,32,2,25,0

author_msg:
    // "COPILOT" in screen codes: C=3, O=15, P=16, I=9, L=12, O=15, T=20
    byte 3,15,16,9,12,15,20,0

start_msg:
    // "PRESS SPACE TO START" in screen codes
    byte 16,18,5,19,19,32,19,16,1,3,5,32,20,15,32,19,20,1,18,20,0

controls_msg:
    // "WASD TO MOVE" in screen codes: W=23, A=1, S=19, D=4, space=32, T=20, O=15, space=32, M=13, O=15, V=22, E=5
    byte 23,1,19,4,32,20,15,32,13,15,22,5,0

//----------------------------------------------
// Food position table (x,y pairs), 6 entries
//----------------------------------------------
food_table:
    byte 10,10, 30,10, 15,15, 5,6, 35,20, 20,5

//----------------------------------------------
// Simple delay loop to control game speed
// Uses delay_current for variable speed
//----------------------------------------------
delay:
    ldx delay_current
.outer:
    ldy #$ff
.inner:
    dey
    bne .inner
    dex
    bne .outer
    rts

//----------------------------------------------
// Update speed - called each game tick
// Decreases delay over time (speeds up game)
//----------------------------------------------
update_speed:
    // decrement speed timer
    dec speed_timer
    bne .no_speed_change

    // reset speed timer
    lda #SPEED_INCREASE_INTERVAL
    sta speed_timer

    // check if we're already at max speed
    lda delay_current
    cmp #DELAY_MIN
    beq .no_speed_change
    bcc .no_speed_change    // safety check

    // decrease delay (increase speed)
    dec delay_current

    // also decrease star timeout over time (stars vanish faster)
    lda star_timeout
    cmp #STAR_TIMEOUT_MIN
    beq .no_speed_change
    bcc .no_speed_change
    dec star_timeout

.no_speed_change:
    rts

//----------------------------------------------
// Place food at next position from table
//----------------------------------------------
place_food:
    lda food_idx
    asl           // multiply index by 2
    tay
    lda food_table,y
    sta food_x
    iny
    lda food_table,y
    sta food_y
    lda food_idx
    clc
    adc #1
    sta food_idx
    cmp #6        // number of entries in food_table
    bne pf_exit
    lda #0
    sta food_idx
pf_exit:
    rts
