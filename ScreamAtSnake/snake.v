module snake(
	input [17:0] SW,
	input [3:0] KEY,
	input CLOCK_50,
	input [0:0] GPIO,
	
	input PS2_KBCLK,
	input PS2_KBDAT,
	
	output [17:0] LEDR,
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
	output VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N,
	output [9:0] VGA_R, VGA_G, VGA_B
	);
	// VGA information for drawing
	wire [2:0] colour;
	wire [7:0] x; 
	wire [6:0] y;
	wire plot;
	
	// Keyboard input
	wire [7:0] key_input;
	
	wire clk;
	assign clk = CLOCK_50;
	
	// Directional buttons currently being pressed
	wire mv_left, mv_right, mv_down, mv_up;
	// Assign to keys until keyboard :
	
	
	input_control input_control(
		.switch(SW[0]),
		.key_input(key_input[3:0]),
		.keys(KEY[3:0]),
		.mv_left(mv_left),
		.mv_right(mv_right),
		.mv_down(mv_down),
		.mv_up(mv_up),
		.last_apple_colour(last_apple_colour)
	);
	
//	assign mv_left = ~KEY[3];
//	assign mv_right = ~KEY[0];
//	assign mv_down = ~KEY[2];
//	assign mv_up = ~KEY[1];
	
//	assign mv_left = key_input[2];
//	assign mv_right = key_input[3];
//	assign mv_down = key_input[1];
//	assign mv_up = key_input[0];
	
	
	// Any button is being pressed to start the game
	wire press_button;
	assign press_button = mv_left || mv_right || mv_down || mv_up;
	
	// Controls for the datapath
	wire [1:0] direction;
	wire grow, dead;
	
	// Game info
	wire [1023:0] snake_x;
	wire [1023:0] snake_y;
	wire [7:0] snake_size;
	wire [7:0] apple_x;
	wire [6:0] apple_y;
	wire collsion; // keeps track of whether the snake has collided with anything or not
	// last color of the apple eaten by snake
	wire [2:0] last_apple_colour;
	
	wire [27:0] counter;
	
	wire resetn;
	assign resetn = 1'b1; // vga reset is active low -> to have reset always off we set this to 1
	
	// current state of the game
	wire [4:0] state;
	// previous state of the game
	wire [4:0] prev_state;
	// for debugging, show current state on leds
	assign LEDR[4:0] = state;
	
	wire [14:0] random_out;
	wire [14:0] random_out2;
	
	// added output signal for sound module
	wire [0:0] sound_out_wire;
	Sound_Module SM(.sound(GPIO[0]), .out(sound_out_wire), .enable(SW[1]));

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(clk),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(plot),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "title_screen.colour.mif";
	
	keyboard kb(
		.mapped_key(key_input[7:0]),
		.kb_clock(PS2_KBCLK),
		.kb_data(PS2_KBDAT)
	);
	
	// Create the control and datapath
	control c0(
		.diff(SW[17:16]),
		.clk(clk),
		.press_button(press_button),
		
		.counter(counter),
		
		.mv_left(mv_left),
		.mv_right(mv_right),
		.mv_down(mv_down),
		.mv_up(mv_up),
		
		.snake_x(snake_x),
		.snake_y(snake_y),
		.snake_size(snake_size),
		
		.apple_x(apple_x),
		.apple_y(apple_y),
		
		.collision(collision),

		.plot(plot),
		.grow(grow),
		.dead(dead),
		.direction(direction),
		.curr_state(state),
		.prev_state(prev_state),
		.sound_in(sound_out_wire)
		);
	//60sec timer for time trial snake mode
	wire [24:0] t;
	Timer timer(.clkin(CLOCK_50), .clkout(t),
		.timereset(SW[13]));
		
	datapath d0(
		.times(t),
		.timer(SW[13]),
		.close(SW[14]),
		.clk(clk),
		.direction(direction),
		.grow(grow),
		.dead(dead),
		.random_in(random_out),
		.random_in2(random_out),
		
		.LEDR(LEDR[17:5]),
		
		.counter(counter),
		
		.snake_x(snake_x),
		.snake_y(snake_y),
		.snake_size(snake_size),
		
		.apple_x(apple_x),
		.apple_y(apple_y),
		
		.draw_x(x),
		.draw_y(y),
		.colour(colour),
		.current_state(state),
		.prev_state(prev_state),

		.collision(collision),
		.last_apple_colour(last_apple_colour),
		.hex0(HEX0),
		.hex1(HEX1),
		.hex2(HEX2),
		.hex4(HEX4),
		.hex5(HEX5),
		.hex6(HEX6),
		.wall(SW[12:11]),
		.maze(SW[10])
		//.ghost(SW[9])
		);
		
		
		
	wire slow_clk;
	wire [27:0] max_ticks;
	assign max_ticks = 27'd50_000 - 1;
	
	rate_divider rate(
		.enable(slow_clk),
		.par_load(1'b0),
		.max_ticks(max_ticks),
		.clk(clk)
		);
	
	random random(
		.clock(CLOCK_50),
		.max_number(15'b111111111111111),
		.num_out(random_out)
	);
	random random2(
		.clock(CLOCK_50),
		.max_number(15'b111111111111111),
		.num_out(random_out2)
	);
	
	HEXH(HEX7);
	
	
	HEXDec(
		.Input(4'b1100),
		.Hex(HEX3)
	);
//	clock hexs
//	hex_display hex_0(
//		.IN(counter[3:0]),
//		.OUT(HEX0)
//		);
//
//	hex_display hex_1(
//		.IN(counter[7:4]),
//		.OUT(HEX1)
//		);
//	
//	hex_display hex_2(
//		.IN(counter[11:8]),
//		.OUT(HEX2)
//		);
//	
//	hex_display hex_3(
//		.IN(counter[15:12]),
//		.OUT(HEX3)
//		);
//	
//	hex_display hex_4(
//		.IN(counter[19:16]),
//		.OUT(HEX4)
//		);
//	
//	hex_display hex_5(
//		.IN(counter[23:20]),
//		.OUT(HEX5)
//		);
//	
//	hex_display hex_6(
//		.IN(counter[27:24]),
//		.OUT(HEX6)
//		);
	
// snake size hexs
//	hex_display hex_0(
//		.IN(snake_size[3:0]),
//		.OUT(HEX0)
//		);
//	
//	hex_display hex_1(
//		.IN(snake_size[7:4]),
//		.OUT(HEX1)
//		);

// apple coordinates (random)
//	hex_display hex_0(
//		.IN(apple_x[3:0]),
//		.OUT(HEX0)
//		);
//
//	hex_display hex_1(
//		.IN(apple_x[7:4]),
//		.OUT(HEX1)
//		);
//
//	hex_display hex_2(
//		.IN(apple_y[3:0]),
//		.OUT(HEX2)
//		);
//
//	hex_display hex_3(
//		.IN({1'b0, apple_y[6:4]}),
//		.OUT(HEX3)
//		);
		
endmodule

module control(
	input [1:0] diff,
	input clk,
	// Input to start game / move between menus
	input press_button,
	// Ticks spent in current state (log(160 * 120) bits)
	input [27:0] counter,
	// Direction inputs
	input mv_left, mv_right, mv_down, mv_up,
	// Snake position, 8 bits per coordinate (piece of snake) 
	// head of snake is snake_x[7:0] , snake_y[7:0], second piece is [15:8], etc.
	input [1023:0] snake_x, 
	input [1023:0] snake_y,
	// Size of the snake
	input [7:0] snake_size,
	// Apple position
	input [7:0] apple_x,
	input [6:0] apple_y,
	// information from datapath on whether the snake has collided with anything (death)
	input collision,

	// Randomly generated wall positions
	//input [num_random_walls * 8:0] wall_x,
	//input [num_random_walls * 8:0] wall_y,

	// Whether a pixel is being drawn this tick
	output reg plot,
	// Snake hits apple -> grow /// Snake hit wall or itself -> dead
	output reg grow, dead,
	// Left: 00 / Right: 01 / Down: 10 / Up: 11
	output reg [1:0] direction,
	// Current state (for testing purposes)
	// Has extra bit so that space can be used if needed
	output [4:0] curr_state, prev_state,
	//input from sound module
	input sound_in
	);
	
	reg [4:0] previous_state, current_state, next_state; 

	wire vsync_wire;
	
	localparam 	S_MAIN_MENU 	= 5'd0, // menu state
					S_STARTING 		= 5'd1, // press start game button
					S_STARTING_WAIT= 5'd2, // stop pressing start game button
					S_LOAD_GAME		= 5'd3, // load initial snake pos, random walls
					S_MAKE_APPLE	= 5'd4, // load apple position
					S_CLR_SCREEN	= 5'd5, // clear the screen
					S_DRAW_WALLS	= 5'd6, // redraw each part of the game
					S_DRAW_APPLE	= 5'd7,
					S_DRAW_SNAKE 	= 5'd8,
					S_MOVING			= 5'd9, // take the next step in the game
					S_MUNCHING		= 5'd10,
					S_DEAD			= 5'd11,
					S_SCORE_MENU	= 5'd12,
					S_DELAY			= 5'd13, // to make sure the game isn't too sonic speedy
					S_MAKE_APPLE_X = 5'd14, // load apple X
					S_MAKE_APPLE_Y = 5'd15, // load apply Y
					S_COLLISION_CHECK = 5'd16, // check if snaking is colliding with walls / itself
					S_DRAW_END 		= 5'd18; // draw end game screen after dying

	localparam 	LEFT 	= 2'b00,
					RIGHT = 2'b01,
					DOWN 	= 2'b10,
					UP 	= 2'b11;

	wire [27:0] CLR_SCREEN_MAX, DRAW_WALLS_MAX, DRAW_SNAKE_MAX, DELAY_MAX, COLLISION_MAX, DRAW_END_MAX;
	assign CLR_SCREEN_MAX = 28'd32_000; // 160 * 120
	assign DRAW_WALLS_MAX = 28'd32_000; // 4 * 160 + 4 * (120 - 4) - size of walls (add # randomly generated walls)
	assign DRAW_SNAKE_MAX = snake_size;
	assign COLLISION_MAX = snake_size + 1; // currently checking all snake blocks + 1 check for predetermined walls, this size can be expanded to check for other collisions in the future
	assign DRAW_END_MAX = 2500;
	reg [27:0] speed;
	
	// defining a new look-up table to change number of ticks thus making the game move faster or slower to change game difficuly
	always @ (*)
	begin
		case(diff)
			3'b00: speed <= 28'd9_000_000;
			3'b01: speed <= 28'd4_000_000;
			3'b10: speed <= 28'd4_000_000;
			3'b11: speed <= 28'd1_000_000;
		endcase
	end
	delay_calc delayer(
		.snake_size(snake_size),
		.base_ticks(speed - 1),
		.delay_max(DELAY_MAX)
		);
		
	rate_divider vsync(
		.clk(clk),
		.enable(vsync_wire),
		.max_ticks(DELAY_MAX),
		.par_load(1'b0)
	);
	
	//assign DELAY_MAX = 28'd10_000_000 - 1;
    
    // Next state logic aka our state table
    always@(*)
    begin: state_table 
        case (current_state)
			S_MAIN_MENU: next_state = press_button ? S_STARTING : S_MAIN_MENU; // Stay on menu until start game
			S_STARTING: next_state = press_button ? S_STARTING_WAIT : S_STARTING; // Stay on starting while button is held
			S_STARTING_WAIT: next_state = press_button ? S_STARTING_WAIT : S_LOAD_GAME; // Switch to game when start game button is released
			S_LOAD_GAME: next_state = S_MAKE_APPLE_X;
			S_MAKE_APPLE_X: next_state = S_MAKE_APPLE_Y;
			S_MAKE_APPLE_Y: next_state = S_CLR_SCREEN;
			S_CLR_SCREEN: begin
				if (counter == CLR_SCREEN_MAX)
					next_state = S_DRAW_WALLS;
				else
					next_state = S_CLR_SCREEN;
				end
			S_DRAW_WALLS: begin
				if (counter == DRAW_WALLS_MAX)
					next_state = S_DRAW_APPLE;
				else
					next_state = S_DRAW_WALLS;
				end
			S_DRAW_APPLE: next_state = S_DRAW_SNAKE;
			S_DRAW_SNAKE: begin
				if (counter == DRAW_SNAKE_MAX)
					next_state = S_DELAY;
				else
					next_state = S_DRAW_SNAKE;
				end
			S_DELAY: begin			
				if (counter == DELAY_MAX)
					next_state = S_MOVING;
				else
					next_state = S_DELAY;
				end
			S_MOVING: begin
				// check if the snake head touched a wall or itself
				// need some way to check as the possible values
				if (collision)	// if there is a collision, the snake dies
					next_state = S_DEAD;
				else if (snake_x[7:0] == apple_x[7:0] && snake_y[7:0] == {1'b0, apple_y[6:0]}) 	// check the snake head touched the apple
					next_state = S_MUNCHING;
				else
					next_state = S_COLLISION_CHECK;
				end
			S_COLLISION_CHECK: begin
				if (counter == COLLISION_MAX)
					next_state = S_CLR_SCREEN;
				else
					next_state = S_COLLISION_CHECK;
				end
			S_MUNCHING: next_state = S_MAKE_APPLE_X;
			S_DEAD: next_state = S_DRAW_END;
			S_DRAW_END: begin
				if (counter == DRAW_END_MAX)
					next_state = S_SCORE_MENU;
				else
					next_state = S_DRAW_END;
				end
			S_SCORE_MENU: next_state = press_button ? S_STARTING : S_SCORE_MENU; // Stay on menu until restart game
			default:     next_state = S_MAIN_MENU;
        endcase
    end // state_table
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
		plot = 1'b0;
		grow = 1'b0;
		dead = 1'b0;
		// start off as going left
		//direction = RIGHT;
		//direction = 2'b0; // don't wanna change direction constantly I guess

      case (current_state)
			S_CLR_SCREEN: begin
				plot = 1'b1;
				end
			S_DRAW_WALLS: begin
				plot = 1'b1;
				end
			S_DRAW_APPLE: begin
				plot = 1'b1;
				end
			S_DRAW_SNAKE: begin
				plot = 1'b1;
				end
			S_DRAW_END: begin
				plot = 1'b1;
				end
			S_MOVING: begin
				// Adding functionality to check if sound is being input for non-complacent snake
				if ((mv_left && sound_in)  && direction != RIGHT)
					direction = LEFT;
				else if ((mv_right && sound_in) && direction != LEFT)
					direction = RIGHT;
				else if ((mv_down && sound_in) && direction != UP)
					direction = DOWN;
				else if ((mv_up && sound_in) && direction != DOWN)
					direction = UP;
				end
			S_MUNCHING: begin
				grow = 1'b1;
				end
			S_DEAD: begin
				dead = 1'b1;
				plot = 1'b1;
				end
        default: begin // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
				plot = 1'b0;
				grow = 1'b0;
				dead = 1'b0;
				//direction = RIGHT;
				end
      endcase
    end // enable_signals
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
		previous_state <= current_state;
        current_state <= next_state;
    end // state_FFS
	 
	assign curr_state = current_state;
	assign prev_state = previous_state;
	
endmodule

module Timer(input clkin, 
				output reg [24:0] clkout,
				input timereset);
	reg [24:0] counter;
	initial 
	begin
		 counter = 0;
		 clkout = 0;
	end

	always @(posedge clkin) begin
		if(timereset == 1'b0)
		begin 
			counter <= 0;
			clkout <= 0;
		end
		else if (counter == 24999999) 
		begin
			counter <= 0;
				if (clkout == 80) 
				begin
					clkout <= 0;
				end 
				else 
				begin
					clkout <= clkout + 1;
				end
		end 
		else 
		begin
			counter <= counter + 1;
		end
	end
endmodule	
module datapath(
	input [24:0] times,
	input clk,
	input timer,
	input close,
	input [1:0] direction,
	input grow, dead,
	input [4:0] current_state, prev_state,
	input [14:0] random_in,
	input [14:0] random_in2,
	
	output [12:0] LEDR,
	
	output reg [27:0] counter,
	
	output reg [1023:0] snake_x,
	output reg [1023:0] snake_y,
	output reg [7:0] snake_size,
	
	output reg [7:0] apple_x,
	output reg [6:0] apple_y,
	
	output reg [2:0] colour,
	output reg [7:0] draw_x,
	output reg [6:0] draw_y,

	output reg collision,
	output reg [2:0] last_apple_colour,
	output [6:0] hex0,
	output [6:0] hex1,
	output [6:0] hex2,
	output [6:0] hex4,
	output [6:0] hex5,
	output [6:0] hex6,
	input [2:0] wall,
	input maze
	//input ghost
	);
	
	reg [1:0]snake_dir;
	reg [1:0]last_dir;
	
	// Wall registers
	reg [7:0] apple_x_wall;
	reg [7:0] apple_x_wall2;
	reg [7:0] apple_x_wall3;
	reg [7:0] apple_x_wall4;
	reg [7:0] apple_x_wall5;
	reg [6:0] apple_y_wall;
	reg [6:0] apple_y_wall2;
	reg [6:0] apple_y_wall3;
	reg [6:0] apple_y_wall4;
	reg [7:0] apple_y_wall5;
	
	// Maze Registers
	// Dimensions are 101 y values and 152 x values it seems
	// Top right corner is x=0 and y=0. So top and bottom are
	// actually flipped
	reg [6:0] block1_top = 7'd50;
	reg [6:0] block1_bottom = 7'd20;
	reg [7:0] block1_right = 8'd145;
	reg [7:0] block1_left = 8'd0;
	reg [6:0] block2_top = 7'd115;
	reg [6:0] block2_bottom = 7'd55;
	reg [7:0] block2_right = 8'd170;
	reg [7:0] block2_left = 8'd3;
	/*
	reg [6:0] block3_top = 7'd70;
	reg [6:0] block3_bottom = 7'd50;
	reg [7:0] block3_right = 8'd20;
	reg [7:0] block3_left = 8'd20;
	*/
	reg [7:0] maze_apple_x = 8'd152;
	reg [6:0] maze_apple_y = 7'd117;
	reg maze_complete = 1'b0;
	// If adding more blocks, add it in collision and walls state
	/*
	// Ghost registers
	reg [7:0] ghost_x = 8'd0;
	reg [6:0] ghost_y = 7'd0;
	reg [2:0] ghost_path; // Calculates optimal ghost direction
	reg [7:0] ghost_x_diff;
	reg [6:0] ghost_y_diff;
	reg ghost_right = 1'b0;
	reg ghost_up = 1'b0;
	*/
	localparam 	LEFT 	= 2'b00,
					RIGHT = 2'b01,
					DOWN 	= 2'b10,
					UP 	= 2'b11;
					
	localparam 	S_MAIN_MENU = 5'd0, // menu state
					S_STARTING 		= 5'd1, // press start game button
					S_STARTING_WAIT= 5'd2, // stop pressing start game button
					S_LOAD_GAME		= 5'd3, // load initial snake pos, random walls
					S_MAKE_APPLE	= 5'd4, // load apple position
					S_CLR_SCREEN	= 5'd5, // clear the screen
					S_DRAW_WALLS	= 5'd6, // redraw each part of the game
					S_DRAW_APPLE	= 5'd7,
					S_DRAW_SNAKE 	= 5'd8,
					S_MOVING			= 5'd9, // take the next step in the game
					S_MUNCHING		= 5'd10,
					S_DEAD			= 5'd11,
					S_SCORE_MENU	= 5'd12,
					S_DELAY			= 5'd13,
					S_MAKE_APPLE_X = 5'd14,
					S_MAKE_APPLE_Y = 5'd15,
					S_COLLISION_CHECK = 5'd16, // check if snaking is colliding with walls / itself
					S_DRAW_SCORE 	= 5'd17, // draw score information
					S_DRAW_END 		= 5'd18; // draw end game screen after dying

	// Used for assigning colour to each piece of the snake
	reg [383:0] snake_colour;
	reg [383:0] snake_colour_000;
	reg [383:0] snake_colour_001;
	reg [383:0] snake_colour_010;
	reg [383:0] snake_colour_011;
	reg [383:0] snake_colour_100;
	reg [383:0] snake_colour_101;
	reg [383:0] snake_colour_110;

	reg [14:0] rainbow_order;
	

	// used for assigning colour for the apple / determining what happens when eating said apple
	reg [2:0] apple_colour;
	// Used for drawing the snake, gets initialized to actual values then shifted down by 8 bits to get to the next coord per counter tick 
	reg [1023:0] snake_draw_x;
	reg [1023:0] snake_draw_y;
	reg [383:0] snake_draw_colour;
	// For drawing score;
	reg [7:0] x,y;
	reg [7:0] x_offset, y_offset, width;
	reg [7:0] high_nums_offset;
	// To update highscores
	reg update;
	reg got_high;
	// toggle to oscilate
	reg [3:0] poison_counter;
	reg toggle;
	reg [3:0]p_counter = 4'b0;
	 // Input logic
    always @(posedge clk)
    begin: enable_signals
        // By default make all our signals 0
		
		// if the state has changed, reset the counter, collision and copies of snake information 
		if(prev_state != current_state)
			begin
			counter = 28'd0;
			snake_draw_x = snake_x;
			snake_draw_y = snake_y;
			snake_draw_colour = snake_colour;
			score_info = {hi5_num, hi4_num, hi3_num, hi2_num, hi1_num, highscore_text_wire, score_num_wire, score_text_wire};
			endgame_overlay = endgame_grid;
//			hi1_val = hi1;
//			hi2_val = hi2;
//			hi3_val = hi3;
//			hi4_val = hi4;
//			hi5_val = hi5;
//			score_text = score_text_wire;
//			score_num = score_num_wire;
			//collision = 1'b0;
			end

        case (current_state)
			S_MAIN_MENU: begin
			
//					highscore_tracker highscores2(
//						.curr_score(score),
//						.curr_hi1(8'b0),
//						.curr_hi2(8'b0),
//						.curr_hi3(8'b0),
//						.curr_hi4(8'b0),
//						.curr_hi5(8'b0),
//						.update(update),
//						.hi1(hi1),
//						.hi2(hi2),
//						.hi3(hi3),
//						.hi4(hi4),
//						.hi5(hi5),
//					);

				snake_size = 8'd5;
	
				end
			S_STARTING: begin
				end
			S_STARTING_WAIT: begin
				end
			S_LOAD_GAME: begin
				// init basic colors for the snake (might be able to do this outside of always block)
				snake_colour_000 = 384'b100110010011101100110010011101100110010011101100110010011101100110010011101100110010011101100110010011101100110010011101100110010011101100110010011101100110010011101100110010011101100110010011101100110010011101100110010011101100110010011101100110010011101100110010011101100110010011101100110010011101100110010011101100110010011101100110010011101100110010011101100110010011101100110010;
				snake_colour_001 = 384'b001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001;//001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001001;
				snake_colour_010 = 384'b010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010;//010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010010;
				snake_colour_011 = 384'b011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011;//011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011011;
				snake_colour_100 = 384'b100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100;//100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100100;
				snake_colour_101 = 384'b101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101;//101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101101;
				snake_colour_110 = 384'b110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110;//110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110110;

				collision = 1'b0;

				// initializing snake position
				snake_x[7:0] = 8'd30;
				snake_y[6:0] = 7'd20;
				snake_x[15:8] = 8'd31;
				snake_y[14:8] = 7'd20;
				snake_x[23:16] = 8'd32;
				snake_y[22:16] = 7'd20;
				snake_x[31:24] = 8'd33;
				snake_y[30:24] = 7'd20;
				snake_x[39:32] = 8'd34;
				snake_y[38:32] = 7'd20;
				snake_x[1023:40] = 0;
				snake_y[1023:39] = 0;
				
				// If maze feature turned on, adjust snake position
				if (maze == 1'b1)
					begin
						snake_x[7:0] = 8'd30;
						snake_y[6:0] = 7'd5;
						snake_x[15:8] = 8'd31;
						snake_y[14:8] = 7'd5;
						snake_x[23:16] = 8'd32;
						snake_y[22:16] = 7'd5;
						snake_x[31:24] = 8'd33;
						snake_y[30:24] = 7'd5;
						snake_x[39:32] = 8'd34;
						snake_y[38:32] = 7'd5;
						maze_complete = 1'b0;
					end
				
				// initializing snake colour and size
				rainbow_order = 15'b100_110_010_011_101;
				snake_colour[2:0] = rainbow_order[14:12];
				snake_colour[5:3] = rainbow_order[11:9];
				snake_colour[8:6] = rainbow_order[8:6];
				snake_colour[11:9] = rainbow_order[5:3];
				snake_colour[14:12] = rainbow_order[2:0];
				snake_colour[383:15] = 0;
				snake_size = 8'd5;
				
				// didn't get high score yet!
				got_high = 1'b0;
				// positionally load random walls 
				end
			S_MAKE_APPLE_X: begin
					if(random_in[7:0] >= 8'd150)
					begin
						apple_x[7:0] <= random_in[7:0] - 8'd110;
					end
					else
					begin
						apple_x[7:0] <= random_in[7:0] + 8'd3;
					end
					// update last apple colour
					last_apple_colour = apple_colour;
					// set the apple's colour based off of it's position (randomly)
					if(apple_x[2:0] > 3'b000)
						apple_colour = apple_x[2:0]; // default red apple
					else
						apple_colour = 3'b100; // set to default colour instead of black
					if(timer == 1'b1)// time trial mode enabled, adjust apple position to fit within walls
						if(random_in[7:0] > (8'd150 - times - apple_colour)) 
							apple_x[7:0] <= random_in[7:0] - 8'd110- times - 3 - apple_colour;
						else if(random_in[7:0] <= (8'd3 + times + apple_colour))
							apple_x[7:0] <= random_in[7:0] + 8'd3 + times + 3 + apple_colour;
					if(close == 1'b1)// score trial mode enabled, adjust apple position to fit within walls
						if(random_in[7:0] > (8'd150 - snake_size - apple_colour)) 
							apple_x[7:0] <= random_in[7:0] - 8'd110- snake_size - 3 - apple_colour;
						else if(random_in[7:0] <= (8'd3 + snake_size + apple_colour))
							apple_x[7:0] <= random_in[7:0] + 8'd3 + snake_size + 3 + apple_colour;
			
				end
				
			S_MAKE_APPLE_Y: begin
				if(random_in[14:8] >= 7'd100)
				begin
					apple_y[6:0] <= random_in[14:8] + 7'd2 - 7'd100;
				end
				else
				begin
					apple_y[6:0] <= random_in[14:8] + 7'd2;
				end
				if(timer == 1'b1 && close == 1'b0)// time trial mode enabled, adjust apple position to fit within walls
					if(random_in[14:8] >= (7'd100- times - 7- apple_colour))
						apple_y[6:0] <= random_in[14:8] + 7'd2 - 7'd100 - times  - apple_colour + 3;
					else if(random_in[14:8] <= (7'd2 + times + apple_colour))
						apple_y[6:0] <= random_in[14:8] + 7'd2 + times + apple_colour + 3;
				if(close == 1'b1 && timer == 1'b0)// score trial mode enabled, adjust apple position to fit within walls
					if(random_in[14:8] >= (7'd100- snake_size - apple_colour))
						apple_y[6:0] <= random_in[14:8] + 7'd2 - 7'd100 - snake_size - apple_colour + 3;
					else if(random_in[14:8] <= (7'd2 + snake_size + apple_colour))
						apple_y[6:0] <= random_in[14:8] + 7'd2 + snake_size + 3 + apple_colour;
				// Generating coordinates for the apple walls randomly
				if(random_in2[7:0] >= 8'd150)
					begin
						// Make wall to the right
						apple_x_wall[7:0] = apple_x[7:0] + 1;
						//apple_y_wall[6:0] = {1'b0, apple_y[6:0]};
						apple_y_wall[6:0] = apple_y[6:0];
						
					end
				else if(random_in2[7:0] >= 8'd100)
					begin
						// Wall to the left
						apple_x_wall[7:0] = apple_x[7:0] - 1;
						// apple_y_wall[6:0] = {1'b0, apple_y[6:0]};
						apple_y_wall[6:0] = apple_y[6:0];
					end
				else if(random_in2[7:0] >= 8'd50)
					begin
						// Wall at the top
						apple_x_wall[7:0] = apple_x[7:0];
						apple_y_wall[6:0] = apple_y[6:0] + 1;
						// apple_y_wall[6:0] = {1'b0, apple_y[6:0] + 1};
					end
				else
					begin
						// wall to the bottom
						apple_x_wall[7:0] = apple_x[7:0];
						apple_y_wall[6:0] = apple_y[6:0];
					end
				// Check if the walls are too high (Should fix bug)
				if(apple_y_wall[6:0] <= 8'd0)
					begin
						apple_y_wall[6:0] = apple_y_wall - 2;
					end
				// Set apples somewhere else if maze
				if (maze == 1'b1)
					begin
						// Putting apple on top right corner
						apple_x[7:0] = maze_apple_x;
						apple_y[6:0] = maze_apple_y;
					end
					
				apple_x_wall2[7:0] = apple_x_wall[7:0] + 5;
				apple_x_wall3[7:0] = apple_x_wall[7:0] + 5;
				apple_x_wall4[7:0] = apple_x_wall[7:0] - 5;
				apple_x_wall5[7:0] = apple_x_wall[7:0] - 5;
				apple_y_wall2[6:0] = apple_y_wall[6:0] + 5;
				apple_y_wall3[6:0] = apple_y_wall[6:0] - 5;
				apple_y_wall4[6:0] = apple_y_wall[6:0] + 5;
				apple_y_wall5[6:0] = apple_y_wall[6:0] - 5;
				
			end
			
			S_CLR_SCREEN: begin
				// set colour to black
				colour = 3'b000;
				// draw x / y for each value represented by the counter
				draw_x = counter[14:7];
				draw_y = counter[6:0]; 
				counter = counter + 1'b1;
				end
			S_DRAW_WALLS: begin
				// set colour to red
				colour = 3'b100;
				// if the counter represents a value where the border wall should be drawn (right side stops at pixel 120)
				if(counter[14:7] < 8'd2 || counter[14:7] > 8'd158 || counter[6:0] < 7'd2 || counter[6:0] > 7'd117)
					begin
					draw_x = counter[14:7];
					draw_y = counter[6:0];
					end
				// Checking if extra feature wall was added
				if (wall == 2'b01)
					// 5 dots wall
					begin
						if(counter[14:7] == apple_x_wall && counter[6:0] == apple_y_wall)
						begin
							draw_x = counter[14:7];
							draw_y = counter[6:0];
						end
						else if(counter[14:7] == apple_x_wall2 && counter[6:0] == apple_y_wall2)
						begin
							draw_x = counter[14:7];
							draw_y = counter[6:0];
						end
						else if(counter[14:7] == apple_x_wall3 && counter[6:0] == apple_y_wall3)
						begin
							draw_x = counter[14:7];
							draw_y = counter[6:0];
						end
						else if(counter[14:7] == apple_x_wall4 && counter[6:0] == apple_y_wall4)
						begin
							draw_x = counter[14:7];
							draw_y = counter[6:0];
						end
						else if(counter[14:7] == apple_x_wall5 && counter[6:0] == apple_y_wall5)
						begin
							draw_x = counter[14:7];
							draw_y = counter[6:0];
						end
					end
				else if (wall == 2'b10)
					// Y lines wall
					begin
						if(counter[14:7] == apple_x_wall && counter[6:0] == apple_y_wall)
						begin
							draw_x = counter[14:7];
							draw_y = counter[6:0];
						end
						else if(counter[14:7] == apple_x_wall2 && counter[6:0] >= apple_y_wall2)
						begin
							draw_x = counter[14:7];
							draw_y = counter[6:0];
						end
						else if(counter[14:7] == apple_x_wall3 && counter[6:0] <= apple_y_wall3)
						begin
							draw_x = counter[14:7];
							draw_y = counter[6:0];
						end
						else if(counter[14:7] == apple_x_wall4 && counter[6:0] >= apple_y_wall4)
						begin
							draw_x = counter[14:7];
							draw_y = counter[6:0];
						end
						else if(counter[14:7] == apple_x_wall5 && counter[6:0] <= apple_y_wall5)
						begin
							draw_x = counter[14:7];
							draw_y = counter[6:0];
						end
					end
				else if (wall == 2'b11)
					// X and Y lines wall
					begin
						if(counter[14:7] == apple_x_wall && counter[6:0] == apple_y_wall)
						begin
							draw_x = counter[14:7];
							draw_y = counter[6:0];
						end
						else if(counter[14:7] == apple_x_wall2 && counter[6:0] >= apple_y_wall2)
						begin
							draw_x = counter[14:7];
							draw_y = counter[6:0];
						end
						else if(counter[14:7] >= apple_x_wall3 && counter[6:0] == apple_y_wall3)
						begin
							draw_x = counter[14:7];
							draw_y = counter[6:0];
						end
						else if(counter[14:7] <= apple_x_wall4 && counter[6:0] == apple_y_wall4)
						begin
							draw_x = counter[14:7];
							draw_y = counter[6:0];
						end
						else if(counter[14:7] == apple_x_wall5 && counter[6:0] <= apple_y_wall5)
						begin
							draw_x = counter[14:7];
							draw_y = counter[6:0];
						end
					end
				if (maze == 1'b1)
					begin
						// Draw maze feature
						if((counter[14:7] <= block1_right && counter[14:7] >= block1_left) && (counter[6:0] <= block1_top && counter[6:0] >= block1_bottom))
						begin
							draw_x = counter[14:7];
							draw_y = counter[6:0];
						end
						else if((counter[14:7] <= block2_right && counter[14:7] >= block2_left) && (counter[6:0] <= block2_top && counter[6:0] >= block2_bottom))
						begin
							draw_x = counter[14:7];
							draw_y = counter[6:0];
						end
						/*
						else if((counter[14:7] <= block3_right && counter[14:7] >= block3_left) && (counter[6:0] <= block3_top && counter[6:0] >= block3_bottom))
						begin
							draw_x = counter[14:7];
							draw_y = counter[6:0];
						end
						*/
					end
				/*
				// Check if ghost feature is enabled (Couldn't get it working in time)
				if (ghost == 1'b1)
				begin
					// Check which direction ghost is closest to the snake head
					// Check if ghost should go right or left
					if ((ghost_x - snake_x) <= 0)
					begin
						// Snake is to the right of ghost
						ghost_x_diff = snake_x - ghost_x;
						ghost_right = 1'b1; // Ghost should go right
					end
					else
					begin
						// Snake is to the left of ghost
						ghost_x_diff = ghost_x - snake_x;
						ghost_right = 1'b0;
					end
					// Check if ghost should go up or down
					if ((ghost_y - snake_y) <= 0)
					begin
						// Snake is above ghost
						ghost_y_diff = snake_x - ghost_x;
						ghost_up = 1'b1;
					end
					else
					begin
						// Snake is below ghost
						ghost_y_diff = ghost_x - snake_x;
						ghost_up = 1'b0;
					end
					// Check if ghost should go x or y
					if (ghost_x_diff >= ghost_y_diff)
					begin
						// Should change x coordinate
						if (ghost_right == 1'b1)
						begin
							// Ghost should go right
							ghost_path = 2'b00;
						end
						else
						begin
							// Ghost should go left
							ghost_path = 2'b01;
						end
					end
					else
					begin
						// Should change y coordinate
						if (ghost_up == 1'b1)
						begin
							// Ghost should go up
							ghost_path = 2'b10;
						end
						else
						begin
							// Ghost should go down
							ghost_path = 2'b11;
						end
					end
					// Now draw the ghost
					if (ghost_path == 2'b00)
					begin 
						// Move right
						ghost_x = ghost_x + 1;
					end
					else if (ghost_path == 2'b01)
					begin 
						// Move left
						ghost_x = ghost_x - 1;
					end
					else if (ghost_path == 2'b10)
					begin 
						// Move up
						ghost_y = ghost_y + 1;
					end
					else if (ghost_path == 2'b11)
					begin 
						// Move down
						ghost_y = ghost_y - 1;
					end
					// Check if we can draw the ghost
					if(counter[14:7] == ghost_x && counter[6:0] == ghost_y)
					begin
						// Draw the ghost
						draw_x = ghost_x;
						draw_y = ghost_y;
					end
				end
				*/
				if(timer == 1'b1 && close == 1'b0)
				// if the counter represents a value where the border wall should be drawn (right side stops at pixel 120)
					if(counter[14:7] < 8'd2+ times || counter[14:7] > 8'd158-times || counter[6:0] < 7'd2+times || counter[6:0] > 7'd117-times)
						begin
						draw_x = counter[14:7];
						draw_y = counter[6:0] ;
						end
				if(timer == 1'b0 && close == 1'b1)
				// if the counter represents a value where the border wall should be drawn (right side stops at pixel 120)
					if(counter[14:7] < 8'd2+ snake_size || counter[14:7] > 8'd158-snake_size || counter[6:0] < 7'd2+snake_size || counter[6:0] > 7'd117-snake_size)
						begin
						draw_x = counter[14:7];
						draw_y = counter[6:0] ;
						end
				counter = counter + 1'b1;
				end
			S_DRAW_APPLE: begin
				// set colour to red
				colour = apple_colour[2:0];
				draw_x = apple_x;
				draw_y = apple_y;
				end
			S_DRAW_SNAKE: begin
				// set colour to the snake's intended colour
				colour = snake_draw_colour[2:0];
				// draw the first values of the register
				draw_x = snake_draw_x[7:0];
				draw_y = snake_draw_y[6:0];
				// shift  bits to get the next snake block
				snake_draw_x = snake_draw_x >> 8;
				snake_draw_y = snake_draw_y >> 8;
				snake_draw_colour = snake_draw_colour >> 3;
				counter = counter + 1'b1;
				end
			S_DELAY: begin
				counter = counter + 1'b1;
				end
			S_MOVING: begin
				if(direction != last_dir)
				begin
					last_dir <= direction;
					snake_dir <= direction;
				end
				// not sure if these checks should be done only in moving state
				// wondering if they'll register if you press the button at the wrong time
				if (snake_dir == LEFT)
					begin
					// move everything back one (lose the last saved coord)
					snake_x = snake_x << 8;
					snake_y = snake_y << 8;
					// decrease the head's x coord by 1 to go left
					snake_x[7:0] = snake_x[15:8] - 1'b1;
					snake_y[7:0] = snake_y[15:8];
					end
				else if (snake_dir == RIGHT)
					begin
					// move everything back one (lose the last saved coord)
					snake_x = snake_x << 8;
					snake_y = snake_y << 8;
					// increase the head's x coord by 1 to go right
					snake_x[7:0] = snake_x[15:8] + 1'b1;
					snake_y[7:0] = snake_y[15:8];
					end
				else if (snake_dir == DOWN)
					begin
					// move everything back one (lose the last saved coord)
					snake_x = snake_x << 8;
					snake_y = snake_y << 8;
					// increase the head's y coord by 1 to go down
					snake_x[7:0] = snake_x[15:8];
					snake_y[7:0] = snake_y[15:8] + 1'b1;
					end
				else if (snake_dir == UP)
					begin
					// move everything back one (lose the last saved coord)
					snake_x = snake_x << 8;
					snake_y = snake_y << 8;
					// decrease the head's y coord by 1 to go up
					snake_x[7:0] = snake_x[15:8];
					snake_y[7:0] = snake_y[15:8] - 1'b1;
					end

				// if the last apple eaten was white, make the snake disco
				if(last_apple_colour[2:0] == 3'b111)
					begin
					// maintain rainbow colour order
					snake_colour = snake_colour << 3;
					snake_colour[2:0] = rainbow_order[2:0];
					rainbow_order = rainbow_order >> 3;
					rainbow_order[14:12] = snake_colour[2:0];
					end
					
				// Defining purple apple to be the new steroid apple
				if(last_apple_colour[2:0] == 3'b101 && p_counter < 4'b1111)
					begin
						if(poison_counter == 3'b100)
								poison_counter = 0;
						if(poison_counter == 0)
						begin

							// increment snake size
							snake_size = snake_size + 1;
							p_counter = p_counter + 1;
							if(toggle == 1)
								begin
									toggle = 0;
									snake_colour = snake_colour_100;
								end
							else
								begin
									toggle = 1;
									snake_colour = snake_colour_101;
								end
						end
						poison_counter = poison_counter + 1;
					end
				else if (last_apple_colour[2:0] == 3'b101 )
					snake_colour = snake_colour_101;
					
				// changed poison apple to green apple
				if(last_apple_colour[2:0] == 3'b010 && snake_size > 5)
					begin
						if(poison_counter == 3'b100)
								poison_counter = 0;
						if(poison_counter == 0)
						begin
							// decrement snake size
							snake_size = snake_size - 1;
							if(toggle == 1)
								begin
									toggle = 0;
									snake_colour = snake_colour_100;
								end
							else
								begin
									toggle = 1;
									snake_colour = snake_colour_010;
								end
						end
						poison_counter = poison_counter + 1;
					end
				else if (last_apple_colour[2:0] == 3'b010 )
					snake_colour = snake_colour_010;
					
				if (last_apple_colour[2:0] != 3'b101)
					p_counter = 2'd0;
				end
					
			S_MUNCHING: begin
					// update snake size based on apple colour
					snake_size = snake_size + apple_colour[2:0];

					// maintain rainbow colour order
					snake_colour_000 = snake_colour_000 << 3;
					snake_colour_000[2:0] = rainbow_order[2:0];
					rainbow_order = rainbow_order >> 3;
					rainbow_order[14:12] = snake_colour_000[2:0];

					// change colour of snake based on colour of apple
					if(apple_colour == 3'b111)
						snake_colour = snake_colour_000;
					else if (apple_colour == 3'b001)
						snake_colour = snake_colour_001;
					else if (apple_colour == 3'b010)
						snake_colour = snake_colour_010;
					else if (apple_colour == 3'b011)
						snake_colour = snake_colour_011;
					else if (apple_colour == 3'b100)
						snake_colour = snake_colour_100;
					else if (apple_colour == 3'b101)
						snake_colour = snake_colour_101;
					else if (apple_colour == 3'b110)
						snake_colour = snake_colour_110;
				end

			S_COLLISION_CHECK: begin
				// check if the snake is colliding with itself
				if(counter < snake_size)
				begin
					// if some part of the snake that is not the head is in the same position as the head, there is a collision
					if(snake_x[7:0] == snake_draw_x[7:0] && snake_y[7:0] == snake_draw_y[7:0] && counter != 0)
						collision = 1'b1;

					// shift to the next part of the snake
					snake_draw_x = snake_draw_x >> 8;
					snake_draw_y = snake_draw_y >> 8;
					
				end
				// check if the snake is colliding with the walls
				else
				begin
					// if the snake makes contact with the predetermined walls, there is a collision
					if(snake_x[7:0] < 8'd2 || snake_x[7:0] > 8'd158 || snake_y[7:0] < 8'd2 || snake_y[7:0] > 8'd117)
					begin
						collision = 1'b1;
					end
					//adjust collision postion based on time trial closing walls
					if(close == 1'b0 && timer == 1'b1 && (snake_x[7:0] < 8'd2+times || snake_x[7:0] > 8'd158-times || snake_y[7:0] < 8'd2+times || snake_y[7:0] > 8'd117-times))
						collision = 1'b1;
					//adjust collision position based on score trial closing walls
					if(timer == 1'b0 && close == 1'b1 && (snake_x[7:0] < 8'd2+snake_size || snake_x[7:0] > 8'd158-snake_size || snake_y[7:0] < 8'd2+snake_size || snake_y[7:0] > 8'd117-snake_size))
						collision = 1'b1;
					// If extra wall feature is enabled
					if (wall == 2'b01)
					// 5 dot wall
					begin
						// Adding extra walls based on apples location
						if(snake_x[7:0] == apple_x_wall && snake_y[7:0] == apple_y_wall)
						begin
							collision = 1'b1;
						end
						else if(snake_x[7:0] == apple_x_wall2 && snake_y[7:0] == apple_y_wall2)
						begin
							collision = 1'b1;
						end
						else if(snake_x[7:0] == apple_x_wall3 && snake_y[7:0] == apple_y_wall3)
						begin
							collision = 1'b1;
						end
						else if(snake_x[7:0] == apple_x_wall4 && snake_y[7:0] == apple_y_wall4)
						begin
							collision = 1'b1;
						end
						else if(snake_x[7:0] == apple_x_wall5 && snake_y[7:0] == apple_y_wall5)
						begin
							collision = 1'b1;
						end
					end
					else if (wall == 2'b10)
					// Y line wall
					begin
						// Adding extra walls based on apples location
						if(snake_x[7:0] == apple_x_wall && snake_y[7:0] == apple_y_wall)
						begin
							collision = 1'b1;
						end
						else if(snake_x[7:0] == apple_x_wall2 && snake_y[7:0] >= apple_y_wall2)
						begin
							collision = 1'b1;
						end
						else if(snake_x[7:0] == apple_x_wall3 && snake_y[7:0] <= apple_y_wall3)
						begin
							collision = 1'b1;
						end
						else if(snake_x[7:0] == apple_x_wall4 && snake_y[7:0] >= apple_y_wall4)
						begin
							collision = 1'b1;
						end
						else if(snake_x[7:0] == apple_x_wall5 && snake_y[7:0] <= apple_y_wall5)
						begin
							collision = 1'b1;
						end
					end
					else if (wall == 2'b11)
					// X and Y line wall
					begin
						// Adding extra walls based on apples location
						if(snake_x[7:0] == apple_x_wall && snake_y[7:0] == apple_y_wall)
						begin
							collision = 1'b1;
						end
						else if(snake_x[7:0] == apple_x_wall2 && snake_y[7:0] >= apple_y_wall2)
						begin
							collision = 1'b1;
						end
						else if(snake_x[7:0] >= apple_x_wall3 && snake_y[7:0] == apple_y_wall3)
						begin
							collision = 1'b1;
						end
						else if(snake_x[7:0] <= apple_x_wall4 && snake_y[7:0] == apple_y_wall4)
						begin
							collision = 1'b1;
						end
						else if(snake_x[7:0] == apple_x_wall5 && snake_y[7:0] <= apple_y_wall5)
						begin
							collision = 1'b1;
						end
					end
					// Check if maze feature turned on
					if (maze == 1'b1)
						begin
							// Check if touching maze blocks
							if((snake_x[7:0] <= block1_right && snake_x[7:0] >= block1_left) && (snake_y[7:0] <= block1_top && snake_y[7:0] >= block1_bottom))
							begin
								collision = 1'b1;
							end
							else if((snake_x[7:0] <= block2_right && snake_x[7:0] >= block2_left) && (snake_y[7:0] <= block2_top && snake_y[7:0] >= block2_bottom))
							begin
								collision = 1'b1;
							end
							/*
							else if((snake_x[7:0] <= block3_right && snake_x[7:0] >= block3_left) && (snake_y[7:0] <= block3_top && snake_y[7:0] >= block3_bottom))
							begin
								collision = 1'b1;
							end
							*/
							// Check if touching maze apple being touched
							if(snake_x[7:0] == maze_apple_x && snake_y[7:0] == maze_apple_y)
							begin
								// End the game and flag it so we know maze apple reached
								collision = 1'b1;
								maze_complete = 1'b1;
							end
						end
						/*
					// Check if ghost feature enabled
					if (ghost == 1'b1)
						begin
							// Check if head is colliding with ghost
							if(snake_x[7:0] == ghost_x && snake_y[7:0] == ghost_y)
							begin
								collision = 1'b1;
							end
						end
					*/
				end

				/**
				To perform collision checking on non-predetermined walls, write similiar code to well checking for whether the snake collides
				with itself or not. Have all x / y coords of the walls in a register, shift through the register and check one by one for collision, do this while the counter is less than the number of wall pieces that need to be checked.
				**/

				counter = counter + 1;
				end
			S_DEAD: begin
				// you got top score
				if (score > hi1) begin
					hi5 = hi4;
					hi4 = hi3;
					hi3 = hi2;
					hi2 = hi1;
					hi1 = score;
					got_high = 1'b1;
				end
				// got 2nd best score
				else if (score > hi2) begin
					hi5 = hi4;
					hi4 = hi3;
					hi3 = hi2;
					hi2 = score;
					got_high = 1'b1;
				end
				// got the bronze
				else if (score > hi3) begin
					hi5 = hi4;
					hi4 = hi3;
					hi3 = score;
					got_high = 1'b1;
				end
				// at least you made 4th!
				else if (score > hi4) begin
					hi5 = hi4;
					hi4 = score;
					got_high = 1'b1;
				end
				// bottom of the highscores buddy. at least you made it somewhere
				else if (score > hi5) begin
					hi5 = score;
					got_high = 1'b1;
				end
				else
					got_high = 1'b0;
				end
			S_DRAW_END: begin
				// for starting to draw
				if (counter == 0)
				begin
					x = 0;
					y = 0;
				end
				// information for drawing
				width = 100;
				x_offset = 25;
				y_offset = 10;
				
				// draw the current information at the calculated position in yellow
				colour = 3'b110;
				if(endgame_overlay[0] == 1)
				begin
					draw_x = 12 + x_offset + x;
					draw_y = 20 + y_offset + y;
				end
				
				// set the position of the next pixel
				if (x == width - 1)
				begin
					x = 0;
					y = y + 1;
				end
				else
					x = x + 1;
				
				// move to next overlay pixel and increment counter
				endgame_overlay = endgame_overlay >> 1;
				counter = counter + 1'b1;
				end
			S_SCORE_MENU: begin
				// scores not implemented
				end
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals
	 
	 // all the score information
	 reg [1239:0] score_info;
	 
	 // The pixel information for the word "SCORE"
	 wire [209:0] score_text_wire;
	 score_text score_text_module(
		.OUT(score_text_wire)
		);
	wire [489:0] highscore_text_wire;
	highscore_text highscore_text_module(
		.OUT(highscore_text_wire)
		);
	
	 // Pixel information for the player's current score (their size)
	 wire [89:0] score_num_wire;
	 wire [7:0] score;
	 
	 assign score = snake_size - 8'd5;
	 score_to_display display_score(
		.score_display(score_num_wire),
		.score_input(score)
		);
		
	wire [11:0] hexval;
	DectoHexDisplay dec(.score_input(score), .hexval(hexval));
	HEXDec(
		.Input(hexval[3:0]),
		.Hex(hex0)
	);
	
	HEXDec(
		.Input(hexval[7:4]),
		.Hex(hex1)
	);
	
	HEXDec(
		.Input(hexval[11:8]),
		.Hex(hex2)
	);
		
	// get the highscores
	
	reg [7:0] hi1, hi2, hi3, hi4, hi5;
	// initialize them all to 0
	initial begin
		hi1 = 8'd0;
		hi2 = 8'd0;
		hi3 = 8'd0;
		hi4 = 8'd0;
		hi5 = 8'd0;
	end
	
	
	// get the pixel information to draw highscores
	wire [89:0] hi1_num, hi2_num, hi3_num, hi4_num, hi5_num;
	score_to_display display_hi1(
		.score_display(hi1_num),
		.score_input(hi1)
		);
		
	score_to_display display_hi2(
		.score_display(hi2_num),
		.score_input(hi2)
		);
		
	score_to_display display_hi3(
		.score_display(hi3_num),
		.score_input(hi3)
		);
		
	score_to_display display_hi4(
		.score_display(hi4_num),
		.score_input(hi4)
		);
		
	score_to_display display_hi5(
		.score_display(hi5_num),
		.score_input(hi5)
		);
		
	wire [11:0] hexhi;
	
	DectoHexDisplay dec2(.score_input(hi1), .hexval(hexhi));
	HEXDec(
		.Input(hexhi[3:0]),
		.Hex(hex4)
	);
	
	HEXDec(
		.Input(hexhi[7:4]),
		.Hex(hex5)
	);
	
	HEXDec(
		.Input(hexhi[11:8]),
		.Hex(hex6)
	);
		
	// end game screen draw stuff
	wire [2499:0] endgame_grid;
	reg [2499:0] endgame_overlay;
	game_overlay overlay_0(
		.OUT(endgame_grid),
		.is_high_score(got_high),
		.is_win(maze_complete),
		.clock(clk)
		);
	
endmodule

// switch between key controls and keyboard controls based on input
module input_control(
	input switch,
	input [3:0] key_input,
	input [3:0] keys,
	input [2:0]last_apple_colour,
	output reg mv_left, mv_right, mv_down, mv_up
	);
	always @(switch)
   begin
		if(switch)
		begin
			mv_left = key_input[2];
			mv_right = key_input[3];
			mv_down = key_input[1];
			mv_up = key_input[0];
		end
		else
		begin
			mv_left = ~keys[3];
			mv_right = ~keys[0];
			mv_down = ~keys[2];
			mv_up = ~keys[1];
		end
	end
endmodule
