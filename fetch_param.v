`timescale 1ns / 1ps

/* Description
**
** fixed point (16-bit, (11,16))
** 		=> Sign: 1-bit, Exp: 4-bit, Frac: 11-bit
** 		=> Expression Range: -16 ~ 15.99951171875
** 		=> Resolution: 0.00048828125
** |1|<- 4 bits ->|<- 11 bits ->|
** |S|       IIII|   FFFFFFFFFFF|
**
** fixed point (24-bit, (11,24))
** 		=> Sign: 1-bit, Exp: 12-bit, Frac: 11-bit
** 		=> Expression Range: -4096 ~ 4095.99951171875
** 		=> Resolution: 0.00048828125
** |1|<- 12 bits ->|<- 11 bits ->|
** |S| IIIIIIIIIIII|   FFFFFFFFFFF|
*/

/*Note
** // Initial value (at zoom level 0)
** localparam x_min = 16'hf800;		// -2
** localparam x_max = 16'h0480; 	// 1.125
** localparam y_min = 16'hfb50;		// -1.171875
** localparam y_max = 16'h04b0;		// 1.171875
*/

module fetch_param(
    input wire [15:0] i_x,
    input wire [15:0] i_y,
    input wire [15:0] x_min,
    input wire [15:0] y_max,
    input wire [1:0] zoom_level,

    input wire start,
    input wire rstMBT,
	// neg slack -> changed to register
    // output wire start2MBT,
    // output wire rst2MBT,
	output reg start2MBT,
    output reg rst2MBT,

    // DEBUG
    output wire [15:0] grid_man,
    output wire [23:0] probe,

	// neg slack -> changed to register
    // output wire [15:0] c_real_0,
    // output wire [15:0] c_img_0,
    // output wire [15:0] c_real_1,
    // output wire [15:0] c_img_1,
    // output wire [15:0] c_real_2,
    // output wire [15:0] c_img_2,
    // output wire [15:0] c_real_3,
    // output wire [15:0] c_img_3    
	output reg [15:0] c_real_0,
    output reg [15:0] c_img_0,
    output reg [15:0] c_real_1,
    output reg [15:0] c_img_1,
    output reg [15:0] c_real_2,
    output reg [15:0] c_img_2,
    output reg [15:0] c_real_3,
    output reg [15:0] c_img_3
    );

    // Grid => initial value: 1/2^(8) = 0.00390625
    reg [15:0] grid_ROM [3:0];
    initial begin
        grid_ROM[0] = 16'h0008;		// 1/2^(8) 	= 0.00390625		1
        grid_ROM[1] = 16'h0004;		// 1/2^(9) 	= 0.001953125		0.5
        grid_ROM[2] = 16'h0002;		// 1/2^(10) = 0.0009765625		0.25
        grid_ROM[3] = 16'h0801;		// 1/2^(11) = 0.00048828125		0.125
    end
    reg [15:0] grid;

    // Zoom Level param
    parameter LVL0 = 2'b00;
    parameter LVL1 = 2'b01;
    parameter LVL2 = 2'b10;
    parameter LVL3 = 2'b11;

    // padding (11,16) -> (11,24)
    wire [23:0] padding_i_x, padding_i_y;
    wire [23:0] padding_grid;

    // To find right coordinate
    wire [23:0] c_real_w_stage1, c_img_w_stage1;
    wire [15:0] c_real, c_img;

    // To find next coordinates
    wire [15:0] c_real1, c_real2, c_real3;

    // Set grid with zoomlevel
    always @(zoom_level) begin
        case (zoom_level)
        LVL0: begin
            grid <= grid_ROM[0];
        end
        LVL1: begin
            grid <= grid_ROM[1];
        end
        LVL2: begin
            grid <= grid_ROM[2];
        end
        LVL3: begin
            grid <= grid_ROM[3];
        end
        default: begin
            grid <= grid_ROM[0];
        end
        endcase
    end

    // padding 
    assign padding_i_x = {i_x[15], i_x[12:0], 11'b0};
    assign padding_i_y = {i_y[15], i_y[12:0], 11'b0};
    assign padding_grid = {grid[15],8'b0, grid[14:11], grid[10:0]};

    /*********************************
	**  FIND c_real -> Start      **
	*********************************/
    qmult #(11,24) uut_c_real_w_stage1 (	// c * i_x
		.i_multiplicand(padding_i_x), 
		.i_multiplier(padding_grid),
		.o_result(c_real_w_stage1)
		// .ovr(ovp)
	);

    qadd #(11,16) uut_c_real (			// c * i_x + x_min
		.a(c_real_w_stage1[15:0]),
		.b(x_min),
		.c(c_real)
	);
    /*********************************
	**  FIND c_real -> Finish       **
	*********************************/


    /*********************************
	**  FIND c_img -> Start         **
	*********************************/
    qmult #(11,24) uut_c_img_w_stage1 (	    // c * i_y
        .i_multiplicand(padding_i_y), 
        .i_multiplier(padding_grid),
        .o_result(c_img_w_stage1)
        // .ovr(ovp)
    );

    qadd #(11,16) uut_c_img (			// c * i_x + y_max
        .a(-(c_img_w_stage1[15:0])),
        .b(y_max),
        .c(c_img)
    );
    /*********************************
	**  FIND c_img -> Finish        **
	*********************************/


    /*********************************
	**  FIND next coord -> Start    **
	*********************************/
    qadd #(11,16) uut_c_real1 (			// for module 1
        .a(c_real),
        .b(grid),
        .c(c_real1)
    );

    qadd #(11,16) uut_c_real2 (			// for module 2
        .a(c_real1),
        .b(grid),
        .c(c_real2)
    );

    qadd #(11,16) uut_c_real3 (			// for module 3
        .a(c_real2),
        .b(grid),
        .c(c_real3)
    );
    /*********************************
	**  FIND next coord -> Finish   **
	*********************************/



	// => Neg slack -> changed to register
	// divide c_real, c_img to 4 MBT modules
    // they must get same c_img since 800 % 4 = 0
    // // to Module_0
    // assign c_real_0 = c_real;
    // assign c_img_0 = c_img;
    // // to Module_1
    // assign c_real_1 = c_real1;
    // assign c_img_1 = c_img;
    // // to Module_2
    // assign c_real_2 = c_real2;
    // assign c_img_2 = c_img;
    // // to Module_3
    // assign c_real_3 = c_real3;
    // assign c_img_3 = c_img;
    // // simply copy values
    // assign start2MBT = start;
    // assign rst2MBT = rstMBT;

	always@(*) begin
		// to Module_0
		c_real_0 <= c_real;
		c_img_0 <= c_img;
		// to Module_1
		c_real_1 <= c_real1;
		c_img_1 <= c_img;
		// to Module_2
		c_real_2 <= c_real2;
		c_img_2 <= c_img;
		// to Module_3
		c_real_3 <= c_real3;
		c_img_3 <= c_img;

		// simply copy values
		start2MBT <= start;
		rst2MBT <= rstMBT;
	end

    // DBG
    assign grid_man = grid;
    assign probe = c_real_w_stage1;

endmodule
