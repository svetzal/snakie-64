//----------------------------------------------
// User interface screens
//----------------------------------------------

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
