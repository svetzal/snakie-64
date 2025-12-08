//----------------------------------------------
// Snake mechanics
//----------------------------------------------

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
