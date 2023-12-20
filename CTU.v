`timescale 1ns / 1ps


module CTU #(
    parameter Q = 21,
    parameter N = 32,
    parameter P = 24   // For under 16-bit precision
    )(
	input wire clk,
    input wire [N-1:0] start_coord,
    input wire axis,
    input wire [15:0] pixel_coord,
    input wire [1:0] zoom_level,
    output wire [N-1:0] real_coord
    );
    // Grid => initial value: 1/2^(8) = 0.00390625
	// FOR (11,16)
    // reg [N-1:0] grid_ROM [3:0];
	// reg [N-1:0] grid;
    // initial begin                       // TODO: change
    //     grid_ROM[0] = 16'h0008;		// 1/2^(8) 	= 0.00390625		1
    //     grid_ROM[1] = 16'h0004;		// 1/2^(9) 	= 0.001953125		0.5
    //     grid_ROM[2] = 16'h0002;		// 1/2^(10) = 0.0009765625		0.25
    //     grid_ROM[3] = 16'h0001;		// 1/2^(11) = 0.00048828125		0.125
    // end
	// FOR (21,32)
	reg [N-1:0] grid_ROM [3:0];
    reg [N-1:0] grid;
    initial begin
        grid_ROM[0] = 32'h00002000;		// 1/2^(8) 	= 0.00390625		    LVL1 : / 1
        grid_ROM[1] = 32'h00000800;		// 1/2^(9) 	= 0.0009765625		    LVL2 : / 4
        grid_ROM[2] = 32'h00000200;		// 1/2^(10) = 0.000244140625	    LVL3 : / 32
        grid_ROM[3] = 32'h00000080;		// 1/2^(11) = 0.00006103515625		LVL4 : / 64
    end

    // Zoom Level param
    parameter LVL0 = 2'b00;
    parameter LVL1 = 2'b01;
    parameter LVL2 = 2'b10;
    parameter LVL3 = 2'b11;

    always @(zoom_level) begin
        case (zoom_level)
		LVL0: grid <= grid_ROM[0];
		LVL1: grid <= grid_ROM[1];
		LVL2: grid <= grid_ROM[2];
		LVL3: grid <= grid_ROM[3];
		default: grid <= grid_ROM[0];
        endcase
    end

	wire [P-1:0] padding_grid;
	assign padding_grid = {{(P-N){1'b0}}, grid[N-1:Q], grid[Q-1:0]};

	wire [P-1:0] padding_pixel_coord;
    assign padding_pixel_coord = {pixel_coord[P-Q-1:0], {(Q){1'b0}}};

	wire [P-1:0] stage1_w;
	qmult #(Q, P) uut_stage1 (				// grid * i_{x,y}
		.i_multiplicand(padding_grid),
		.i_multiplier(padding_pixel_coord),
		.o_result(stage1_w)
	);

    reg [N-1:0] coord_axis;
    always @(posedge clk) begin
        if (axis == 0) begin 	// axis : X
            coord_axis <= stage1_w[N-1:0];
        end
        else begin 				// axis : Y
            coord_axis <= -(stage1_w[N-1:0]);
        end
    end

	qadd #(Q, N) uut_stage2 (				// start_coord + grid * i_x
		.a(coord_axis),				// start_coord - grid * i_y
		.b(start_coord),
		.c(real_coord)
	);

endmodule
