//----------------------------------------------
// Drawing routines
//----------------------------------------------

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
// Increment 16-bit score by 1
//----------------------------------------------
increment_score:
    inc score_lo
    bne .no_carry
    inc score_hi
.no_carry:
    rts
