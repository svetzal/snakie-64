#include "c2/c64/c64.s"
#include "c2/mos/6502.s"

//----------------------------------------------
// Snake game for the Commodore 64 (single file)
// Assemble with c2 and load via RUN
//----------------------------------------------

basic_startup

// Zero-page variables - using $50-$5F which are free for user programs
var snake_x = $50
var snake_y = $51
var food_x  = $52
var food_y  = $53
var direction = $54  // 0=right,1=down,2=left,3=up
var food_idx = $55
var snake_len = $56  // current length of snake
var game_over = $57  // 0=playing, 1=game over

var ptr_lo  = $58  // indirect pointer low byte
var ptr_hi  = $59  // indirect pointer high byte
var old_tail_x = $5a  // old tail position for erasing
var old_tail_y = $5b
var score_lo = $5c    // score low byte
var score_hi = $5d    // score high byte

// Snake body storage (x and y arrays, max 100 segments)
var body_x = $0300
var body_y = $0380

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
    jsr draw_snake     // draw last so everything is up-to-date
    jsr increment_score
    jsr draw_score
    jmp main_loop

game_over_loop:
    jsr draw_game_over
    jsr get_key
    cmp #$20  // space bar to restart
    beq start
    jmp game_over_loop

//----------------------------------------------
// Initialize screen: colours, clear, border
//----------------------------------------------
init_screen:
    // set border and background to black
    lda #$00
    sta $d020
    sta $d021

    // fill colour RAM with white (colour code $01)
    lda #$01
    ldx #$00
col_fill:
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $db00,x
    inx
    bne col_fill

    // clear screen to spaces ($20)
    lda #$20
    ldx #$00
clearloop:
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    inx
    bne clearloop

    // draw top and bottom border (solid block = $a0)
    lda #$a0
    ldx #$00

    // draw top and bottom rows
.draw_top:
    sta $0400,x      // top row at $0400
    sta $07c0,x      // bottom row at $07c0 (row 24)
    inx
    cpx #40
    bne .draw_top

    // draw vertical borders on all rows
    ldx #$00
.draw_vert:
    // set pointer to current row start using row table
    lda row_lo,x
    sta ptr_lo
    lda row_hi,x
    sta ptr_hi
    // draw left border at column 0
    ldy #0
    lda #$a0
    sta (ptr_lo),y
    // draw right border at column 39
    ldy #39
    lda #$a0
    sta (ptr_lo),y
    inx
    cpx #25
    bne .draw_vert

    rts

//----------------------------------------------
// Initialize snake starting position and direction
//----------------------------------------------
init_snake:
    lda #20
    sta snake_x
    sta body_x
    lda #12
    sta snake_y
    sta body_y
    lda #0
    sta direction
    lda #0
    sta food_idx
    lda #1        // start with length 1
    sta snake_len
    lda #0        // game not over
    sta game_over
    lda #0        // reset score
    sta score_lo
    sta score_hi
    rts

//----------------------------------------------
// Get keypress via KERNAL GETIN ($FFE4)
//----------------------------------------------
get_key:
    jsr $ffe4
    rts   // A holds key code (0 if none)

//----------------------------------------------
// Update snake direction based on key in A
// Supports W/A/S/D or w/a/s/d
// Prevents 180-degree turns
//----------------------------------------------
update_direction:
    cmp #$57     // 'W'
    beq set_up
    cmp #$77     // 'w'
    beq set_up
    cmp #$53     // 'S'
    beq set_down
    cmp #$73     // 's'
    beq set_down
    cmp #$41     // 'A'
    beq set_left
    cmp #$61     // 'a'
    beq set_left
    cmp #$44     // 'D'
    beq set_right
    cmp #$64     // 'd'
    beq set_right
    rts

set_up:
    lda direction
    cmp #1       // if currently moving down, ignore
    beq .ignore_up
    lda #3
    sta direction
.ignore_up:
    rts
set_down:
    lda direction
    cmp #3       // if currently moving up, ignore
    beq .ignore_down
    lda #1
    sta direction
.ignore_down:
    rts
set_left:
    lda direction
    cmp #0       // if currently moving right, ignore
    beq .ignore_left
    lda #2
    sta direction
.ignore_left:
    rts
set_right:
    lda direction
    cmp #2       // if currently moving left, ignore
    beq .ignore_right
    lda #0
    sta direction
.ignore_right:
    rts

//----------------------------------------------
// Move snake one step according to direction
// Updates snake_x and snake_y without wrapping
//----------------------------------------------
move_snake:
    // decide movement
    lda direction
    cmp #0
    beq move_right
    cmp #1
    beq move_down
    cmp #2
    beq move_left
    // default move up
move_up:
    lda snake_y
    sec
    sbc #1
    sta snake_y
    rts
move_down:
    lda snake_y
    clc
    adc #1
    sta snake_y
    rts
move_left:
    lda snake_x
    sec
    sbc #1
    sta snake_x
    rts
move_right:
    lda snake_x
    clc
    adc #1
    sta snake_x
    rts

//----------------------------------------------
// Update snake body positions after movement
// Shifts body segments and stores new head position
//----------------------------------------------
update_body:
    // save old tail position before shifting (for erasing)
    ldx snake_len
    dex
    lda body_x,x
    sta old_tail_x
    lda body_y,x
    sta old_tail_y

    // shift body segments backward (from tail to head)
    cpx #0
    beq skip_shift
.shift_loop:
    lda body_x-1,x
    sta body_x,x
    lda body_y-1,x
    sta body_y,x
    dex
    bne .shift_loop

skip_shift:
    // store new head position
    lda snake_x
    sta body_x
    lda snake_y
    sta body_y
    rts

//----------------------------------------------
// Check collision with walls or self
// Sets game_over flag if collision detected
//----------------------------------------------
check_collision:
    // check wall collision
    // X must be between 1 and 38
    lda snake_x
    cmp #1
    bcc hit_wall
    cmp #39
    bcs hit_wall
    // Y must be between 1 and 23
    lda snake_y
    cmp #1
    bcc hit_wall
    cmp #24
    bcs hit_wall

    // check self collision (only if length > 1)
    lda snake_len
    cmp #2
    bcc no_collision

    // check if head position matches any body segment (skip head at index 0)
    ldx #1
.check_body:
    lda snake_x
    cmp body_x,x
    bne .next_segment
    lda snake_y
    cmp body_y,x
    beq hit_self
.next_segment:
    inx
    cpx snake_len
    bne .check_body

no_collision:
    rts

hit_wall:
hit_self:
    lda #1
    sta game_over
    rts

//----------------------------------------------
// Draw game over message
//----------------------------------------------
draw_game_over:
    // display "GAME OVER" at row 12, centered
    lda #12
    tax
    lda row_lo,x
    sta ptr_lo
    lda row_hi,x
    sta ptr_hi

    ldy #14  // start column for centering
    ldx #0
.draw_msg:
    lda game_over_msg,x
    beq .done
    sta (ptr_lo),y
    iny
    inx
    jmp .draw_msg
.done:

    // display "PRESS SPACE" at row 14
    lda #14
    tax
    lda row_lo,x
    sta ptr_lo
    lda row_hi,x
    sta ptr_hi

    ldy #12
    ldx #0
.draw_press:
    lda press_space_msg,x
    beq .done2
    sta (ptr_lo),y
    iny
    inx
    jmp .draw_press
.done2:
    rts

game_over_msg:
    // "GAME OVER" in screen codes: G=7, A=1, M=13, E=5, space=32, O=15, V=22, E=5, R=18
    byte 7,1,13,5,32,15,22,5,18,0
press_space_msg:
    // "PRESS SPACE" in screen codes: P=16, R=18, E=5, S=19, S=19, space=32, S=19, P=16, A=1, C=3, E=5
    byte 16,18,5,19,19,32,19,16,1,3,5,0

//----------------------------------------------
// Draw title screen
//----------------------------------------------
draw_title_screen:
    // display "SNAKE" at row 8 (big title)
    lda #8
    tax
    lda row_lo,x
    sta ptr_lo
    lda row_hi,x
    sta ptr_hi

    ldy #17  // center on 40 col screen
    ldx #0
.draw_title:
    lda title_msg,x
    beq .title_done
    sta (ptr_lo),y
    iny
    inx
    jmp .draw_title
.title_done:

    // display "A GAME BY" at row 11
    lda #11
    tax
    lda row_lo,x
    sta ptr_lo
    lda row_hi,x
    sta ptr_hi

    ldy #15
    ldx #0
.draw_by:
    lda by_msg,x
    beq .by_done
    sta (ptr_lo),y
    iny
    inx
    jmp .draw_by
.by_done:

    // display "COPILOT" at row 13
    lda #13
    tax
    lda row_lo,x
    sta ptr_lo
    lda row_hi,x
    sta ptr_hi

    ldy #16
    ldx #0
.draw_author:
    lda author_msg,x
    beq .author_done
    sta (ptr_lo),y
    iny
    inx
    jmp .draw_author
.author_done:

    // display "PRESS SPACE TO START" at row 18
    lda #18
    tax
    lda row_lo,x
    sta ptr_lo
    lda row_hi,x
    sta ptr_hi

    ldy #10
    ldx #0
.draw_start:
    lda start_msg,x
    beq .start_done
    sta (ptr_lo),y
    iny
    inx
    jmp .draw_start
.start_done:

    // display "WASD TO MOVE" at row 20
    lda #20
    tax
    lda row_lo,x
    sta ptr_lo
    lda row_hi,x
    sta ptr_hi

    ldy #14
    ldx #0
.draw_controls:
    lda controls_msg,x
    beq .controls_done
    sta (ptr_lo),y
    iny
    inx
    jmp .draw_controls
.controls_done:
    rts

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
// Clear play area (inside borders)
//----------------------------------------------
clear_play_area:
    ldx #1
.clear_rows:
    lda row_lo,x
    sta ptr_lo
    lda row_hi,x
    sta ptr_hi
    ldy #1
.clear_cols:
    lda #$20
    sta (ptr_lo),y
    iny
    cpy #39
    bne .clear_cols
    inx
    cpx #24
    bne .clear_rows
    rts

//----------------------------------------------
// Increment 16-bit score by 1
//----------------------------------------------
increment_score:
    inc score_lo
    bne .no_carry
    inc score_hi
.no_carry:
    rts

//----------------------------------------------
// Draw score at top of screen (row 0, after border)
// Displays 5-digit decimal score
//----------------------------------------------
draw_score:
    // We'll display "SCORE:" followed by the number
    // Position at row 0, starting at column 2

    // Draw "SCORE:" label (only need to do once, but simple to redraw)
    lda #19        // S
    sta $0402
    lda #3         // C
    sta $0403
    lda #15        // O
    sta $0404
    lda #18        // R
    sta $0405
    lda #5         // E
    sta $0406
    lda #58        // : (colon in screen code)
    sta $0407

    // Convert 16-bit score to decimal and display
    // We'll show up to 5 digits (max 65535)

    // Copy score to temp for division
    lda score_lo
    sta $60        // temp low
    lda score_hi
    sta $61        // temp high

    // Extract digits by repeated subtraction
    // Start with 10000s place at column 8
    ldx #0         // digit counter

    // 10000s digit (10000 = $2710)
    lda #0
    sta $62        // digit accumulator
.div_10000:
    lda $60
    sec
    sbc #$10       // low byte of 10000
    tay
    lda $61
    sbc #$27       // high byte of 10000
    bcc .done_10000
    sta $61
    sty $60
    inc $62
    jmp .div_10000
.done_10000:
    lda $62
    clc
    adc #$30       // convert to screen code digit
    sta $0408

    // 1000s digit (1000 = $03E8)
    lda #0
    sta $62
.div_1000:
    lda $60
    sec
    sbc #$e8       // low byte of 1000
    tay
    lda $61
    sbc #$03       // high byte of 1000
    bcc .done_1000
    sta $61
    sty $60
    inc $62
    jmp .div_1000
.done_1000:
    lda $62
    clc
    adc #$30
    sta $0409

    // 100s digit
    lda #0
    sta $62
.div_100:
    lda $60
    sec
    sbc #100
    tay
    lda $61
    sbc #0
    bcc .done_100
    sta $61
    sty $60
    inc $62
    jmp .div_100
.done_100:
    lda $62
    clc
    adc #$30
    sta $040a

    // 10s digit
    lda #0
    sta $62
.div_10:
    lda $60
    sec
    sbc #10
    bcc .done_10
    sta $60
    inc $62
    jmp .div_10
.done_10:
    lda $62
    clc
    adc #$30
    sta $040b

    // 1s digit (remainder)
    lda $60
    clc
    adc #$30
    sta $040c

    rts

//----------------------------------------------
// Check if snake eats food; if so, grow and place next food
// Must be called AFTER update_body so we can duplicate the tail
//----------------------------------------------
check_food:
    lda snake_x
    cmp food_x
    bne no_eat
    lda snake_y
    cmp food_y
    bne no_eat
    // grow snake by duplicating the tail position
    ldx snake_len
    dex                  // X = index of current tail
    lda body_x,x
    sta body_x+1,x       // copy tail X to new tail position
    lda body_y,x
    sta body_y+1,x       // copy tail Y to new tail position
    inc snake_len
    jsr place_food
no_eat:
    rts

//----------------------------------------------
// Draw snake and food
// Only erases old tail position, draws head/tail
//----------------------------------------------
draw_snake:
    // erase old tail position (where snake was)
    ldx old_tail_y
    lda row_lo,x
    sta ptr_lo
    lda row_hi,x
    sta ptr_hi
    ldy old_tail_x
    lda #$20
    sta (ptr_lo),y

    // draw tail first (if length > 1)
    lda snake_len
    cmp #2
    bcc .draw_body_segments

    // tail is at index snake_len-1
    // determine tail direction by comparing tail to segment before it
    ldx snake_len
    dex              // X = tail index

    // compare tail X to previous segment X
    lda body_x-1,x   // previous segment X
    cmp body_x,x     // tail X
    bne .tail_horizontal

    // X positions are same, so tail is vertical
    lda #$61         // vertical line
    jmp .draw_tail_char

.tail_horizontal:
    lda #$62         // horizontal line

.draw_tail_char:
    pha              // save tail character
    lda body_y,x
    tay
    lda row_lo,y
    sta ptr_lo
    lda row_hi,y
    sta ptr_hi
    lda body_x,x
    tay
    pla              // restore tail character
    sta (ptr_lo),y

.draw_body_segments:
    // draw body segments (skip head at 0 and tail at end)
    lda snake_len
    cmp #3
    bcc .draw_head   // skip body if length < 3

    ldx #1           // start at segment 1 (after head)
.draw_body:
    // check if this is the tail (skip it)
    txa
    clc
    adc #1
    cmp snake_len
    beq .draw_head   // if X+1 == snake_len, we're at tail, skip

    lda body_y,x
    tay
    lda row_lo,y
    sta ptr_lo
    lda row_hi,y
    sta ptr_hi
    lda body_x,x
    tay
    lda #$51        // body character (filled circle)
    sta (ptr_lo),y
    inx
    cpx snake_len
    bne .draw_body

.draw_head:
    // draw head (always at index 0)
    lda body_y
    tay
    lda row_lo,y
    sta ptr_lo
    lda row_hi,y
    sta ptr_hi
    lda body_x
    tay
    lda #$57        // head character (filled diamond)
    sta (ptr_lo),y

    // draw food (heart = $53)
    lda food_y
    tax
    lda row_lo,x
    sta ptr_lo
    lda row_hi,x
    sta ptr_hi
    lda food_x
    tay
    lda #$53        // treat character (heart)
    sta (ptr_lo),y

    rts

//----------------------------------------------
// Simple delay loop to control game speed
//----------------------------------------------
delay:
    ldx #$80
.outer:
    ldy #$ff
.inner:
    dey
    bne .inner
    dex
    bne .outer
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

//----------------------------------------------
// Row address lookup tables (25 rows)
//----------------------------------------------
row_lo:
    byte $00,$28,$50,$78,$a0,$c8,$f0,$18,$40,$68,$90,$b8,$e0,$08,$30,$58,$80,$a8,$d0,$f8,$20,$48,$70,$98,$c0
row_hi:
    byte $04,$04,$04,$04,$04,$04,$04,$05,$05,$05,$05,$05,$05,$06,$06,$06,$06,$06,$06,$06,$07,$07,$07,$07,$07

//----------------------------------------------
// Food position table (x,y pairs), 6 entries
//----------------------------------------------
food_table:
    byte 10,10, 30,10, 15,15, 5,6, 35,20, 20,5
