//----------------------------------------------
// Constants and Zero-page Variables
//----------------------------------------------

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
