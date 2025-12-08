//----------------------------------------------
// Input handling
//----------------------------------------------

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
