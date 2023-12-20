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
	parameter N = 16,
    parameter P = 24
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
	output reg start2MBT,
    output reg rst2MBT,

    // DEBUG
    output wire [N-1:0] grid_man,
    output wire [N-1:0] probe,
 
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
    // FOR (11,16)
    // reg [N-1:0] grid_ROM [3:0];
    // initial begin                                   // TODO: cahgne
    //     grid_ROM[0] = 16'h0008;		// 1/2^(8) 	= 0.00390625		1
    //     grid_ROM[1] = 16'h0004;		// 1/2^(9) 	= 0.001953125		0.5
    //     grid_ROM[2] = 16'h0002;		// 1/2^(10) = 0.0009765625		0.25
    //     grid_ROM[3] = 16'h0001;		// 1/2^(11) = 0.00048828125		0.125
    // end
    // reg [N-1:0] grid_ROMx2 [3:0];
    // initial begin
    //     grid_ROMx2[0] = 16'h0010;		// 1/2^(8) 	= 0.0078125		    1 * 2
    //     grid_ROMx2[1] = 16'h0008;		// 1/2^(9) 	= 0.00390625		0.5 * 2
    //     grid_ROMx2[2] = 16'h0004;		// 1/2^(10) = 0.001953125		0.25 * 2
    //     grid_ROMx2[3] = 16'h0002;		// 1/2^(11) = 0.0009765625		0.125 * 2
    // end
    // reg [N-1:0] grid_ROMx3 [3:0];
    // initial begin
    //     grid_ROMx3[0] = 16'h0018;		// 1/2^(8) 	= 0.01171875		1 * 3
    //     grid_ROMx3[1] = 16'h000C;		// 1/2^(9) 	= 0.005859375		0.5 * 3
    //     grid_ROMx3[2] = 16'h0006;		// 1/2^(10) = 0.0029296875		0.25 * 3
    //     grid_ROMx3[3] = 16'h0003;		// 1/2^(11) = 0.00146484375		0.125 * 3
    // end
    // FOR (21,32)
    reg [N-1:0] grid_ROM [3:0];
    initial begin
        grid_ROM[0] = 32'h00002000;		// 1/2^(8) 	= 0.00390625		    LVL1 : / 1
        grid_ROM[1] = 32'h00000800;		// 1/2^(9) 	= 0.0009765625		    LVL2 : / 4
        grid_ROM[2] = 32'h00000200;		// 1/2^(10) = 0.000244140625	    LVL3 : / 32
        grid_ROM[3] = 32'h00000080;		// 1/2^(11) = 0.00006103515625		LVL4 : / 64
    end
    reg [N-1:0] grid_ROMx2 [3:0];
    initial begin
        grid_ROMx2[0] = 32'h00004000;	// 1/2^(8) 	= 0.0078125		        LVL1 * 2
        grid_ROMx2[1] = 32'h00001000;	// 1/2^(9) 	= 0.001953125		    LVL2 * 2
        grid_ROMx2[2] = 32'h00000400;	// 1/2^(10) = 0.00048828125		    LVL3 * 2
        grid_ROMx2[3] = 32'h00000100;	// 1/2^(11) = 0.0001220703125	    LVL4 * 2
    end
    reg [N-1:0] grid_ROMx3 [3:0];
    initial begin
        grid_ROMx3[0] = 32'h00006000;	// 1/2^(8) 	= 0.01171875		    LVL1 * 3
        grid_ROMx3[1] = 32'h00001800;	// 1/2^(9) 	= 0.0029296875		    LVL2 * 3
        grid_ROMx3[2] = 32'h00000600;	// 1/2^(10) = 0.000732421875	    LVL3 * 3
        grid_ROMx3[3] = 32'h00000180;	// 1/2^(11) = 0.00018310546875	    LVL4 * 3
    end

    reg [N-1:0] grid, gridx2, gridx3;

    // Zoom Level param
    parameter LVL0 = 2'b00;
    parameter LVL1 = 2'b01;
    parameter LVL2 = 2'b10;
    parameter LVL3 = 2'b11;

    // To find right coordinate
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
        end
        LVL1: begin
            grid <= grid_ROM[1];
            gridx2 <= grid_ROMx2[1];
            gridx3 <= grid_ROMx3[1];
        end
        LVL2: begin
            grid <= grid_ROM[2];
            gridx2 <= grid_ROMx2[2];
            gridx3 <= grid_ROMx3[2];
        end
        LVL3: begin
            grid <= grid_ROM[3];
            gridx2 <= grid_ROMx2[3];
            gridx3 <= grid_ROMx3[3];
        end
        default: begin
            grid <= grid_ROM[0];
            gridx2 <= grid_ROMx2[0];
            gridx3 <= grid_ROMx3[0];
        end
        endcase
    end

    parameter X = 0;
    parameter Y = 1;
    CTU #(Q, N, P) CTI_c_real (
        .clk(clk),
        .start_coord(x_min),
        .axis(X),
        .pixel_coord(i_x),
        .zoom_level(zoom_level),
        .real_coord(c_real)
    );

    CTU #(Q, N, P) CTU_c_img (
        .clk(clk),
        .start_coord(y_max),
        .axis(Y),
        .pixel_coord(i_y),
        .zoom_level(zoom_level),
        .real_coord(c_img)
    );

    reg [N-1:0] c_real_r, c_img_r;
    always @(posedge clk) begin
        c_real_r <= c_real;
        c_img_r <= c_img;
    end


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
        .b(grid),
        .c(c_real1)
    );

    qadd #(Q,N) uut_c_real2 (			// for module 2
        .a(c_real_r),
        .b(gridx2),
        .c(c_real2)
    );

    qadd #(Q,N) uut_c_real3 (			// for module 3
        .a(c_real_r),
        .b(gridx3),
        .c(c_real3)
    );
    /*********************************
	**  FIND next coord -> Finish   **
	*********************************/

	always@(posedge clk) begin
		// to Module_0
		c_real_0 <= c_real0;
		c_img_0 <= c_img_r;
		// to Module_1
		c_real_1 <= c_real1;
		c_img_1 <= c_img_r;
		// to Module_2
		c_real_2 <= c_real2;
		c_img_2 <= c_img_r;
		// to Module_3
		c_real_3 <= c_real3;
		c_img_3 <= c_img_r;

		// simply copy values
		start2MBT <= start;
		rst2MBT <= rstMBT;
	end

    // DBG
    assign grid_man = grid;

endmodule
