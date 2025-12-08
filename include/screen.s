//----------------------------------------------
// Screen initialization and utilities
//----------------------------------------------

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
// Row address lookup tables (25 rows)
//----------------------------------------------
row_lo:
    byte $00,$28,$50,$78,$a0,$c8,$f0,$18,$40,$68,$90,$b8,$e0,$08,$30,$58,$80,$a8,$d0,$f8,$20,$48,$70,$98,$c0
row_hi:
    byte $04,$04,$04,$04,$04,$04,$04,$05,$05,$05,$05,$05,$05,$06,$06,$06,$06,$06,$06,$06,$07,$07,$07,$07,$07
