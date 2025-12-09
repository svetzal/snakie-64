//----------------------------------------------
// Drawing routines
//----------------------------------------------

//----------------------------------------------
// Clear the red color from heart position when eaten
// Resets color RAM at food_x, food_y to white
//----------------------------------------------
clear_heart_color:
    lda food_y
    cmp #25
    bcs .clear_done      // skip if invalid row
    tax
    lda row_lo,x
    sta ptr_lo
    lda row_hi,x
    clc
    adc #$d4             // convert to color RAM address
    sta ptr_hi
    ldy food_x
    cpy #40
    bcs .clear_done      // skip if invalid column
    lda #$01             // white
    sta (ptr_lo),y
.clear_done:
    rts

//----------------------------------------------
// Draw snake and food
// Only erases old tail position, draws head/tail
//----------------------------------------------
draw_snake:
    // erase old tail position (where snake was)
    // Safety: validate old_tail_y is in range 0-24
    lda old_tail_y
    cmp #25
    bcs .skip_erase      // skip if invalid row
    tax
    lda row_lo,x
    sta ptr_lo
    lda row_hi,x
    sta ptr_hi
    ldy old_tail_x
    cpy #40
    bcs .skip_erase      // skip if invalid column
    lda #$20
    sta (ptr_lo),y

    // reset color RAM to white at erased position
    lda ptr_hi
    clc
    adc #$d4        // convert to color RAM address
    sta ptr_hi
    lda #$01        // white
    sta (ptr_lo),y
.skip_erase:

    // draw tail first (if length > 1)
    lda snake_len
    cmp #2
    bcc .draw_body_segments

    // tail is at index snake_len-1
    // determine tail direction by comparing tail to segment before it
    ldx snake_len
    dex              // X = tail index

    // compare tail X to previous segment X
    // Use Y to index previous segment to avoid body_x-1,x syntax
    txa
    tay
    dey              // Y = previous segment index
    lda body_x,y     // previous segment X
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
    cmp #25
    bcs .skip_tail   // skip if invalid row
    tay
    lda row_lo,y
    sta ptr_lo
    lda row_hi,y
    sta ptr_hi
    lda body_x,x
    cmp #40
    bcs .skip_tail   // skip if invalid column
    tay
    pla              // restore tail character
    sta (ptr_lo),y
    jmp .draw_body_segments

.skip_tail:
    pla              // discard saved character

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
    cmp #25
    bcs .skip_body_seg  // skip if invalid row
    tay
    lda row_lo,y
    sta ptr_lo
    lda row_hi,y
    sta ptr_hi
    lda body_x,x
    cmp #40
    bcs .skip_body_seg  // skip if invalid column
    tay
    lda #$51        // body character (filled circle)
    sta (ptr_lo),y
.skip_body_seg:
    inx
    cpx snake_len
    bne .draw_body

.draw_head:
    // draw head (always at index 0)
    lda body_y
    cmp #25
    bcs .draw_food   // skip if invalid row
    tay
    lda row_lo,y
    sta ptr_lo
    lda row_hi,y
    sta ptr_hi
    lda body_x
    cmp #40
    bcs .draw_food   // skip if invalid column
    tay
    lda #$57        // head character (filled diamond)
    sta (ptr_lo),y

.draw_food:
    // draw food (heart = $53)
    lda food_y
    cmp #25
    bcs .skip_food   // skip if invalid row
    tax
    lda row_lo,x
    sta ptr_lo
    lda row_hi,x
    sta ptr_hi
    lda food_x
    cmp #40
    bcs .skip_food   // skip if invalid column
    tay
    lda #$53        // treat character (heart)
    sta (ptr_lo),y

    // set heart color to red
    lda ptr_hi
    clc
    adc #$d4        // convert to color RAM address
    sta ptr_hi
    ldy food_x
    lda #$02        // red
    sta (ptr_lo),y
.skip_food:

    // draw star if present (with blinking effect)
    lda star_x
    beq .no_star    // no star present

    // increment blink counter for flashing effect
    inc blink_counter
    lda blink_counter
    and #$08        // blink every 8 frames
    beq .no_star    // don't draw during off-phase (makes it blink)

    // draw star at star_x, star_y
    lda star_y
    tax
    lda row_lo,x
    sta ptr_lo
    lda row_hi,x
    sta ptr_hi
    ldy star_x
    lda #$2a        // star character (*)
    sta (ptr_lo),y

    // set star color to yellow for visibility
    // Color RAM is at $D800, screen RAM at $0400
    // row_hi contains $04-$07, need $D8-$DB
    // So we add $D4 to the high byte
    lda ptr_hi
    clc
    adc #$d4        // $D800 - $0400 = $D400 offset for high byte
    sta ptr_hi
    // ptr_lo stays the same (low byte offset is identical)
    ldy star_x
    lda #$07        // yellow
    sta (ptr_lo),y

.no_star:

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
    sta temp_lo
    lda score_hi
    sta temp_hi

    // Extract digits by repeated subtraction
    // Start with 10000s place at column 8
    ldx #0         // digit counter

    // 10000s digit (10000 = $2710)
    lda #0
    sta temp_digit
.div_10000:
    lda temp_lo
    sec
    sbc #$10       // low byte of 10000
    tay
    lda temp_hi
    sbc #$27       // high byte of 10000
    bcc .done_10000
    sta temp_hi
    sty temp_lo
    inc temp_digit
    jmp .div_10000
.done_10000:
    lda temp_digit
    clc
    adc #$30       // convert to screen code digit
    sta $0408

    // 1000s digit (1000 = $03E8)
    lda #0
    sta temp_digit
.div_1000:
    lda temp_lo
    sec
    sbc #$e8       // low byte of 1000
    tay
    lda temp_hi
    sbc #$03       // high byte of 1000
    bcc .done_1000
    sta temp_hi
    sty temp_lo
    inc temp_digit
    jmp .div_1000
.done_1000:
    lda temp_digit
    clc
    adc #$30
    sta $0409

    // 100s digit
    lda #0
    sta temp_digit
.div_100:
    lda temp_lo
    sec
    sbc #100
    tay
    lda temp_hi
    sbc #0
    bcc .done_100
    sta temp_hi
    sty temp_lo
    inc temp_digit
    jmp .div_100
.done_100:
    lda temp_digit
    clc
    adc #$30
    sta $040a

    // 10s digit
    lda #0
    sta temp_digit
.div_10:
    lda temp_lo
    sec
    sbc #10
    bcc .done_10
    sta temp_lo
    inc temp_digit
    jmp .div_10
.done_10:
    lda temp_digit
    clc
    adc #$30
    sta $040b

    // 1s digit (remainder)
    lda temp_lo
    clc
    adc #$30
    sta $040c

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
