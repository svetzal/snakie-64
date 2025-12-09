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
    sta old_tail_x    // initialize old tail to starting position
    lda #12
    sta snake_y
    sta body_y
    sta old_tail_y    // initialize old tail to starting position
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

    // Initialize speed system
    lda #DELAY_START
    sta delay_current
    lda #SPEED_INCREASE_INTERVAL
    sta speed_timer

    // Initialize star system
    lda #0
    sta star_x        // no star present
    sta star_y
    sta star_timer
    sta blink_counter
    lda #STAR_TIMEOUT_START
    sta star_timeout
    lda #STAR_SPAWN_INTERVAL
    sta star_spawn_timer

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
    // Use Y to read from previous position, X to write to current position
    // This avoids the body_x-1,x syntax which may confuse c2
    cpx #0
    beq skip_shift

    // X = tail index, we need to shift from X-1 to X, then X-2 to X-1, etc.
    // Use a different approach: start at tail, work backwards
.shift_loop:
    txa              // save current index
    tay              // Y = destination index
    dey              // Y = source index (one less than destination)
    lda body_x,y     // read from source
    sta body_x,x     // write to destination
    lda body_y,y     // read from source
    sta body_y,x     // write to destination
    dex              // move to next position
    bne .shift_loop  // continue until X=0

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
    // First check for heart (primary treat)
    lda snake_x
    cmp food_x
    bne .check_star
    lda snake_y
    cmp food_y
    bne .check_star

    // Ate heart - grow snake (if not at max length)
    lda snake_len
    cmp #100             // max length (well under 128 limit)
    bcs .skip_grow       // don't grow if at max

    // grow snake by duplicating the tail position
    // Store current tail coords in temp, then write to new position
    ldx snake_len
    dex                  // X = current tail index
    lda body_x,x         // get current tail X
    sta temp_lo          // save in temp
    lda body_y,x         // get current tail Y
    sta temp_hi          // save in temp

    inx                  // X = new tail index
    lda temp_lo
    sta body_x,x         // store X at new tail position
    lda temp_hi
    sta body_y,x         // store Y at new tail position
    inc snake_len

.skip_grow:
    // Clear the red color from eaten heart position
    jsr clear_heart_color

    // Slow down when eating heart (counteracts natural speed increase)
    lda delay_current
    clc
    adc #HEART_SLOWDOWN
    bcs .cap_delay        // overflow check
    cmp #DELAY_START
    bcc .store_delay
.cap_delay:
    lda #DELAY_START      // cap at starting speed
.store_delay:
    sta delay_current

    jsr place_food
    rts

.check_star:
    // Check if star is present (star_x != 0)
    lda star_x
    beq no_eat

    // Check if snake head is at star position
    lda snake_x
    cmp star_x
    bne no_eat
    lda snake_y
    cmp star_y
    bne no_eat

    // Ate star - speed up (decrease delay) and add bonus points
    // Does NOT grow snake!
    lda delay_current
    sec
    sbc #STAR_SPEEDUP
    bcc .cap_delay_min   // underflow check
    cmp #DELAY_MIN
    bcs .store_star_delay
.cap_delay_min:
    lda #DELAY_MIN       // cap at max speed
.store_star_delay:
    sta delay_current

    // Add star bonus points (100 points)
    lda score_lo
    clc
    adc #STAR_POINTS_LO
    sta score_lo
    lda score_hi
    adc #STAR_POINTS_HI
    sta score_hi

    // Remove star from playfield
    jsr erase_star
    lda #0
    sta star_x
    sta star_y

no_eat:
    rts

//----------------------------------------------
// Erase star from screen
//----------------------------------------------
erase_star:
    lda star_x
    beq .erase_done      // no star to erase
    lda star_y
    tax
    lda row_lo,x
    sta ptr_lo
    lda row_hi,x
    sta ptr_hi
    ldy star_x
    lda #$20             // space
    sta (ptr_lo),y

    // Reset color RAM back to white
    lda ptr_hi
    clc
    adc #$d4             // convert to color RAM address
    sta ptr_hi
    ldy star_x
    lda #$01             // white
    sta (ptr_lo),y

.erase_done:
    rts

//----------------------------------------------
// Update star - handle spawn and timeout
// Call this each game tick
//----------------------------------------------
update_star:
    // Check if star exists
    lda star_x
    beq .try_spawn_star

    // Star exists - decrement timer
    dec star_timer
    bne .star_update_done

    // Timer expired - remove star
    jsr erase_star
    lda #0
    sta star_x
    sta star_y
    jmp .star_update_done

.try_spawn_star:
    // No star present - check if we should spawn one
    dec star_spawn_timer
    bne .star_update_done

    // Reset spawn timer
    lda #STAR_SPAWN_INTERVAL
    sta star_spawn_timer

    // Random chance to spawn (use low byte of timer/raster as random)
    lda $d012            // VIC raster line as pseudo-random
    cmp #STAR_SPAWN_CHANCE
    bcs .star_update_done  // no spawn this time

    // Spawn a star at a random position
    // Use raster line for X position (range 2-36 to avoid edges)
    lda $d012
    and #$1f             // 0-31
    clc
    adc #3               // 3-34
    sta star_x

    // Use different timing for Y (range 2-22)
    lda $d011            // another VIC register
    and #$0f             // 0-15
    clc
    adc #3               // 3-18
    sta star_y

    // Check star isn't on food position
    lda star_x
    cmp food_x
    bne .check_star_body
    lda star_y
    cmp food_y
    beq .cancel_spawn

.check_star_body:
    // Check star isn't on snake body (simplified - just check head)
    lda star_x
    cmp snake_x
    bne .spawn_ok
    lda star_y
    cmp snake_y
    beq .cancel_spawn

.spawn_ok:
    // Set star timer to current timeout
    lda star_timeout
    sta star_timer
    jmp .star_update_done

.cancel_spawn:
    lda #0
    sta star_x
    sta star_y

.star_update_done:
    rts
