//----------------------------------------------
// Constants and Zero-page Variables
//----------------------------------------------

//----------------------------------------------
// Game Tuning Constants (for easy playtesting)
//----------------------------------------------
var DELAY_START = $80           // Initial delay (starting speed) - higher = slower
var DELAY_MIN = $20             // Minimum delay (speed cap) - lower = faster
var SPEED_INCREASE_INTERVAL = 30 // Ticks between speed increases
var HEART_SLOWDOWN = $10        // How much hearts slow you down
var STAR_SPEEDUP = $08          // How much stars speed you up
var STAR_POINTS_LO = 100        // Point bonus for star (low byte)
var STAR_POINTS_HI = 0          // Point bonus for star (high byte)
var STAR_TIMEOUT_START = 76     // Initial star timeout (2x screen width)
var STAR_TIMEOUT_MIN = 10       // Minimum star timeout
var STAR_SPAWN_INTERVAL = 40    // Ticks between star spawn chances
var STAR_SPAWN_CHANCE = 50      // % chance star spawns (out of 256)

// Zero-page variables - using $50-$6F which are free for user programs
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

// Speed system variables
var delay_current = $5e   // Current delay value (higher = slower)
var speed_timer = $5f     // Counter for when to increase speed

// Temporary variables for score display math
var temp_lo = $60         // temp low byte for division
var temp_hi = $61         // temp high byte for division
var temp_digit = $62      // digit accumulator

// Star treat variables
var star_x = $63          // Star X position (0 = no star present)
var star_y = $64          // Star Y position
var star_timer = $65      // Countdown until star disappears
var star_timeout = $66    // Current timeout duration (decreases over time)
var star_spawn_timer = $67 // Countdown until next star spawn chance
var blink_counter = $68   // For star blinking effect

// Snake body storage (x and y arrays, max 100 segments)
// IMPORTANT: $0300-$033A contains system vectors (IRQ at $0314!)
// Using $C000-$C0FF which is free RAM (under BASIC ROM when ROM enabled,
// but we're running in RAM so it's available)
var body_x = $C000
var body_y = $C080
