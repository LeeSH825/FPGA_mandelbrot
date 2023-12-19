`timescale 1ns / 1ps

/* Description
**
** fixed point (16-bit, (11,16)) => 22,32
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

module fetch_param #(
	// Parameterized values
	parameter Q = 11,
	parameter N = 16
	)
    (
    input wire clk,
    input wire [15:0] i_x,
    input wire [15:0] i_y,
    input wire [N-1:0] x_min,
    input wire [N-1:0] y_max,
    input wire [1:0] zoom_level,

    input wire start,
    input wire rstMBT,
	// neg slack -> changed to register
    // output wire start2MBT,
    // output wire rst2MBT,
	output reg start2MBT,
    output reg rst2MBT,

    // DEBUG
    output wire [N-1:0] grid_man,
    output wire [N-1:0] probe,

	// neg slack -> changed to register
    // output wire [N-1:0] c_real_0,
    // output wire [N-1:0] c_img_0,
    // output wire [N-1:0] c_real_1,
    // output wire [N-1:0] c_img_1,
    // output wire [N-1:0] c_real_2,
    // output wire [N-1:0] c_img_2,
    // output wire [N-1:0] c_real_3,
    // output wire [N-1:0] c_img_3    
	output reg [N-1:0] c_real_0,
    output reg [N-1:0] c_img_0,
    output reg [N-1:0] c_real_1,
    output reg [N-1:0] c_img_1,
    output reg [N-1:0] c_real_2,
    output reg [N-1:0] c_img_2,
    output reg [N-1:0] c_real_3,
    output reg [N-1:0] c_img_3
    );

    // Grid => initial value: 1/2^(8) = 0.00390625
    reg [N-1:0] grid_ROM [3:0];
    initial begin
        grid_ROM[0] = 16'h0008;		// 1/2^(8) 	= 0.00390625		1
        grid_ROM[1] = 16'h0004;		// 1/2^(9) 	= 0.001953125		0.5
        grid_ROM[2] = 16'h0002;		// 1/2^(10) = 0.0009765625		0.25
        grid_ROM[3] = 16'h0001;		// 1/2^(11) = 0.00048828125		0.125
    end
    reg [N-1:0] grid_ROMx2 [3:0];
    initial begin
        grid_ROMx2[0] = 16'h0010;		// 1/2^(8) 	= 0.0078125		    1 * 2
        grid_ROMx2[1] = 16'h0008;		// 1/2^(9) 	= 0.00390625		0.5 * 2
        grid_ROMx2[2] = 16'h0004;		// 1/2^(10) = 0.001953125		0.25 * 2
        grid_ROMx2[3] = 16'h0002;		// 1/2^(11) = 0.0009765625		0.125 * 2
    end
    reg [N-1:0] grid_ROMx3 [3:0];
    initial begin
        grid_ROMx3[0] = 16'h0018;		// 1/2^(8) 	= 0.01171875		1 * 3
        grid_ROMx3[1] = 16'h000C;		// 1/2^(9) 	= 0.005859375		0.5 * 3
        grid_ROMx3[2] = 16'h0006;		// 1/2^(10) = 0.0029296875		0.25 * 3
        grid_ROMx3[3] = 16'h0003;		// 1/2^(11) = 0.00146484375		0.125 * 3
    end
    reg [N-1:0] grid_ROMx4 [3:0];
    initial begin
        grid_ROMx4[0] = 16'h0020;		// 1/2^(8) 	= 0.015625  		1 * 4
        grid_ROMx4[1] = 16'h0010;		// 1/2^(9) 	= 0.0078125 		0.5 * 4
        grid_ROMx4[2] = 16'h0008;		// 1/2^(10) = 0.00390625		0.25 * 4
        grid_ROMx4[3] = 16'h0004;		// 1/2^(11) = 0.001953125		0.125 * 4
    end    
    // reg [N-1:0] grid_ROM [3:0];
    // initial begin
    //     grid_ROM[0] = 32'h00002000;		// 1/2^(8) 	= 0.00390625		    LVL1 : / 1
    //     grid_ROM[1] = 32'h00000800;		// 1/2^(9) 	= 0.0009765625		    LVL2 : / 4
    //     grid_ROM[2] = 32'h00000200;		// 1/2^(10) = 0.000244140625	    LVL3 : / 32
    //     grid_ROM[3] = 32'h00000080;		// 1/2^(11) = 0.00006103515625		LVL4 : / 64
    // end
    // reg [N-1:0] grid_ROMx2 [3:0];
    // initial begin
    //     grid_ROMx2[0] = 32'h00004000;	// 1/2^(8) 	= 0.0078125		        LVL1 * 2
    //     grid_ROMx2[1] = 32'h00001000;	// 1/2^(9) 	= 0.001953125		    LVL2 * 2
    //     grid_ROMx2[2] = 32'h00000400;	// 1/2^(10) = 0.00048828125		    LVL3 * 2
    //     grid_ROMx2[3] = 32'h00000100;	// 1/2^(11) = 0.0001220703125	    LVL4 * 2
    // end
    // reg [N-1:0] grid_ROMx3 [3:0];
    // initial begin
    //     grid_ROMx3[0] = 32'h00006000;	// 1/2^(8) 	= 0.01171875		    LVL1 * 3
    //     grid_ROMx3[1] = 32'h00001800;	// 1/2^(9) 	= 0.0029296875		    LVL2 * 3
    //     grid_ROMx3[2] = 32'h00000600;	// 1/2^(10) = 0.000732421875	    LVL3 * 3
    //     grid_ROMx3[3] = 32'h00000180;	// 1/2^(11) = 0.00018310546875	    LVL4 * 3
    // end
    // reg [N-1:0] grid_ROMx4 [3:0];
    // initial begin
    //     grid_ROMx4[0] = 32'h00008000;	// 1/2^(8) 	= 0.015625  			LVL1 * 4
    //     grid_ROMx4[1] = 32'h00002000;	// 1/2^(9) 	= 0.00390625 			LVL2 * 4
    //     grid_ROMx4[2] = 32'h00000800;	// 1/2^(10) = 0.0009765625			LVL3 * 4
    //     grid_ROMx4[3] = 32'h00000200;	// 1/2^(11) = 0.000244140625		LVL4 * 4
    // end
    reg [N-1:0] grid, gridx2, gridx3, gridx4;

    // Zoom Level param
    parameter LVL0 = 2'b00;
    parameter LVL1 = 2'b01;
    parameter LVL2 = 2'b10;
    parameter LVL3 = 2'b11;

    // padding (11,16) -> (11,24)
    wire [23:0] padding_i_x, padding_i_y;
    // wire [N-1:0] padding_i_x, padding_i_y;
    // wire [23:0] padding_grid;
    wire [N-1:0] padding_grid;

    // To find right coordinate
    wire [23:0] c_real_w_stage1, c_img_w_stage1;
    // wire [N-1:0] c_real_w_stage1, c_img_w_stage1;
    wire [N-1:0] c_real, c_img;

    // To find next coordinates
    wire [N-1:0] c_real0, c_real1, c_real2, c_real3;

    // Set grid with zoomlevel
    always @(zoom_level) begin
        case (zoom_level)
        LVL0: begin
            grid <= grid_ROM[0];
            gridx2 <= grid_ROMx2[0];
            gridx3 <= grid_ROMx3[0];
            gridx4 <= grid_ROMx4[0];
        end
        LVL1: begin
            grid <= grid_ROM[1];
            gridx2 <= grid_ROMx2[1];
            gridx3 <= grid_ROMx3[1];
            gridx4 <= grid_ROMx4[1];
        end
        LVL2: begin
            grid <= grid_ROM[2];
            gridx2 <= grid_ROMx2[2];
            gridx3 <= grid_ROMx3[2];
            gridx4 <= grid_ROMx4[2];
        end
        LVL3: begin
            grid <= grid_ROM[3];
            gridx2 <= grid_ROMx2[3];
            gridx3 <= grid_ROMx3[3];
            gridx4 <= grid_ROMx4[3];
        end
        default: begin
            grid <= grid_ROM[0];
            gridx2 <= grid_ROMx2[0];
            gridx3 <= grid_ROMx3[0];
            gridx4 <= grid_ROMx4[0];
        end
        endcase
    end

    // padding 
	assign padding_i_x = {i_x[N-1], i_x[12:0], 11'b0};
    assign padding_i_y = {i_y[N-1], i_y[12:0], 11'b0};
    // assign padding_i_x = {i_x[10:0], 22'b0};
    // assign padding_i_y = {i_y[10:0], 22'b0};
    assign padding_grid = {grid[N-1],8'b0, grid[N-2:Q], grid[Q-1:0]};

    /*********************************
	**  FIND c_real -> Start      **
	*********************************/
    qmult #(Q,24) uut_c_real_w_stage1 (	// c * i_x
		.i_multiplicand(padding_i_x), 
		.i_multiplier(padding_grid),
		// .i_multiplier(grid),
		.o_result(c_real_w_stage1)
		// .ovr(ovp)
	);
    // reg [23:0] c_real_r_stage1;

    // always@(posedge)
    qadd #(Q,N) uut_c_real (			// c * i_x + x_min
		.a(c_real_w_stage1[N-1:0]),
		.b(x_min),
		.c(c_real)
	);
    /*********************************
	**  FIND c_real -> Finish       **
	*********************************/
    reg [N-1:0] c_real_r;
    always @(posedge clk) begin
        c_real_r <= c_real;
    end

    /*********************************
	**  FIND c_img -> Start         **
	*********************************/
    qmult #(Q, 24) uut_c_img_w_stage1 (	    // c * i_y
        .i_multiplicand(padding_i_y), 
        .i_multiplier(grid),
        .o_result(c_img_w_stage1)
        // .ovr(ovp)
    );

	reg [23:0] c_img_r_stage1;

	always @(posedge clk) begin
		c_img_r_stage1 <= c_img_w_stage1;
	end

    qadd #(Q,N) uut_c_img (			// - c * i_y + y_max
        .a(-c_img_r_stage1[N-1:0]),
        .b(y_max),
        .c(c_img)
    );
    /*********************************
	**  FIND c_img -> Finish        **
	*********************************/


    /*********************************
	**  FIND next coord -> Start    **
	*********************************/
    qadd #(Q,N) uut_c_real0 (			// for module 0
        .a(c_real_r),
        .b(0),
        .c(c_real0)
    );

    qadd #(Q,N) uut_c_real1 (			// for module 1
        .a(c_real_r),
        .b(gridx2),
        .c(c_real1)
    );

    qadd #(Q,N) uut_c_real2 (			// for module 2
        .a(c_real_r),
        .b(gridx3),
        .c(c_real2)
    );

    qadd #(Q,N) uut_c_real3 (			// for module 3
        .a(c_real_r),
        .b(gridx4),
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

	always@(posedge clk) begin
		// to Module_0
		c_real_0 <= c_real0;
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
