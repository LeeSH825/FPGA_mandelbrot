`timescale 1ns / 1ps

/* Description
**
** fixed point (16-bit, (11,16))
** 		=> Sign: 1-bit, Exp: 4-bit, Frac: 11-bit
** 		=> Expression Range: -16 ~ N-1.99951171875
** 		=> Resolution: 0.00048828125
** |1|<- 4 bits ->|<- 11 bits ->|
** |S|       IIII|   FFFFFFFFFFF|
*/

/*Note
** localparam x_min = 16'hf800;		// -2
** localparam x_max = 16'h0480; 	// 1.125
** localparam y_min = 16'hfb50;		// -1.171875
** localparam y_max = 16'h04b0;		// 1.171875
**
** Grid => initial value: 1/2^(8) = 0.00390625
** reg grid_ROM [3:0];
** initial begin
** 	grid_ROM[0] = 16'h0008;		// 1/2^(8) 	= 0.00390625		1
** 	grid_ROM[1] = 16'h0004;		// 1/2^(9) 	= 0.001953125		0.5
** 	grid_ROM[2] = 16'h0002;		// 1/2^(10) = 0.0009765625		0.25
** 	grid_ROM[3] = 16'h0801;		// 1/2^(11) = 0.00048828125		0.125
** end
*/

module MBT_ALU #(
	// Parameterized values
	parameter Q = 21,
	parameter N = 32
	)
	(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [N-1:0] c_real,
    input wire [N-1:0] c_img,
    // input wire zoom_level,

    // DEBUG
    // output wire DBG_state,
    // output wire [N-1:0] DBG_real,
	// output wire [N-1:0] DBG_img,

    output wire valid,
    output wire [6:0] d_out
    );

    // FSM Param
    reg [2:0] state;
    parameter IDLE = 3'b000;
	parameter INIT1 = 3'b001;
	parameter INIT2 = 3'b011;
	parameter INIT3 = 3'b111;
	parameter INIT4 = 3'b110;
    parameter CALC = 3'b100;
	parameter FIN  = 3'b101;

    // CALC Flag
    reg is_finished;
	// Calc Param
    reg [6:0] iter;

	// To check if it is in the MandelBrot set
	// FOR (11,16)
	// localparam TWO = 16'h1000;					// TODO: cahnge
	// localparam FOUR = 16'h2000;
	// FOR (21,32)
	localparam TWO = 32'h00400000;
	localparam FOUR = 32'h00800000;

	wire [N-1:0] threshold_w;
	reg [N-1:0] threshold_r;


	// To find z_n1_real
	wire [N-1:0] z_n_real_sq_w, z_n_img_sq_w;
	wire [N-1:0] sq_sub_w;
	wire [N-1:0] z_n1_real_w;
	// To find z_n1_img
	wire [N-1:0] z_n1_img_w_stage1, z_n1_img_w_stage2;
	// reg [N-1:0] z_n1_img_r_stage2;
	wire [N-1:0] z_n1_img_w;
	// To fond z_n1_abs
	wire [N-1:0] z_n1_real_sq_w, z_n1_img_sq_w;
	wire [N-1:0] z_n1_abs_w;
	// z from last iter
	reg [N-1:0] z_n_real_r, z_n_img_r;

	// State Transition Block
    always@(posedge clk) begin
        if (rst == 1) begin
            state <= IDLE;
        end
        else begin 
            case(state)
            IDLE : begin
                if (start == 1)begin
                    state <= INIT1;
                end
                else begin
                    state <= IDLE;
                end
            end
			INIT1: begin
				state <= INIT2;
			end
			INIT2: begin
				state <= INIT3;
			end
			INIT3: begin
				state <= INIT4;
			end
			INIT4: begin
				state <= CALC;
			end
            CALC : begin
				if (is_finished == 1) begin
                	state <= FIN;
				end
				else  begin
					state <= INIT1;
				end
            end
			FIN : begin
				state <= FIN;
			end
            default: begin
                state <= state;
            end
            endcase
        end
    end

	// Check if it is MandelBrot Set
    always @(posedge clk) begin
        if (rst == 1) begin
            // reset all to zero
			iter <= 0;
			is_finished <= 0;
            z_n_real_r <= 0;
            z_n_img_r <= 0;
			//
			z_n1_real_r <= 0;
			z_n1_img_r <= 0;
			z_n1_abs_r <= 0;
			z_n1_img_r_stage1 <= 0;
			z_n_real_sq_r <= 0;
			z_n_img_sq_r <= 0;
			z_n1_img_r_stage2 <= 0;
			sq_sub_r <= 0;
        end
        case (state)
        IDLE: begin
			iter <= 0;
			is_finished <= 0;
            z_n_real_r <= 0;
            z_n_img_r <= 0;
			//
			z_n1_real_r <= 0;
			z_n1_img_r <= 0;
			z_n1_abs_r <= 0;
			z_n1_img_r_stage1 <= 0;
			z_n_real_sq_r <= 0;
			z_n_img_sq_r <= 0;
			z_n1_img_r_stage2 <= 0;
			sq_sub_r <= 0;
        end
		INIT1: begin   				// Find sq : STAGE 1
			iter <= iter;
			is_finished <= is_finished;
			z_n_real_r <= z_n_real_r;
			z_n_img_r <= z_n_img_r;
			// get z_n1_real_r
			z_n1_real_r <= z_n1_real_r;
			z_n1_img_r <= z_n1_img_r;

			z_n1_abs_r <= z_n1_abs_r;
			// get stage1
			z_n1_img_r_stage1 <= z_n1_img_w_stage1;
			z_n_real_sq_r <= z_n_real_sq_w;
			z_n_img_sq_r <= z_n_img_sq_w;

			z_n1_img_r_stage2 <= z_n1_img_r_stage2;
			sq_sub_r <= sq_sub_r;
		end
		INIT2: begin   				// Find sq_sub : STAGE 2
			iter <= iter;
			is_finished <= is_finished;
			z_n_real_r <= z_n_real_r;
			z_n_img_r <= z_n_img_r;
			// get z_n1_real_r & z_n1_img_r
			z_n1_real_r <= z_n1_real_r;
			z_n1_img_r <= z_n1_img_r;

			z_n1_abs_r <= z_n1_abs_r;
			// get stage1
			z_n1_img_r_stage1 <= z_n1_img_r_stage1;
			//
			z_n_real_sq_r <= z_n_real_sq_r;
			z_n_img_sq_r <= z_n_img_sq_r;

			z_n1_img_r_stage2 <= z_n1_img_w_stage2;
			sq_sub_r <= sq_sub_w;
		end
		INIT3: begin 				// Find z_n1 : STAGE 3
			iter <= iter;
			is_finished <= is_finished;
			z_n_real_r <= z_n_real_r;
			z_n_img_r <= z_n_img_r;
			// get z_n1_real_r & z_n1_img_r
			z_n1_real_r <= z_n1_real_w;
			z_n1_img_r <= z_n1_img_w;

			z_n1_abs_r <= z_n1_abs_r;
			// get stage1
			z_n1_img_r_stage1 <= z_n1_img_r_stage1;
			z_n_real_sq_r <= z_n_real_sq_r;
			z_n_img_sq_r <= z_n_img_sq_r;
			z_n1_img_r_stage2 <= z_n1_img_r_stage2;
			sq_sub_r <= sq_sub_r;
		end
		INIT4: begin   				// Find z_n1_abs : STAGE 4
			iter <= iter;
			is_finished <= is_finished;
			z_n_real_r <= z_n_real_r;
			z_n_img_r <= z_n_img_r;
			// get z_n1_real_r & z_n1_img_r
			z_n1_real_r <= z_n1_real_r;
			z_n1_img_r <= z_n1_img_r;

			z_n1_abs_r <= z_n1_abs_w;
			// get stage1
			z_n1_img_r_stage1 <= z_n1_img_r_stage1;
			z_n_real_sq_r <= z_n_real_sq_r;
			z_n_img_sq_r <= z_n_img_sq_r;
			z_n1_img_r_stage2 <= z_n1_img_r_stage2;
			sq_sub_r <= sq_sub_r;
		end
        CALC: begin
			if (iter == 99) begin 	// calc finished
				iter <= iter;
				is_finished <= 1;
				z_n_real_r <= z_n_real_r;
            	z_n_img_r <= z_n_img_r;
				z_n1_real_r <= z_n1_real_r;
				z_n1_img_r <= z_n1_img_r;
				z_n1_abs_r <= z_n1_abs_r;
				z_n1_img_r_stage1 <= z_n1_img_r_stage1;
				z_n_real_sq_r <= z_n_real_sq_r;
				z_n_img_sq_r <= z_n_img_sq_r;
				z_n1_img_r_stage2 <= z_n1_img_r_stage2;
				sq_sub_r <= sq_sub_r;
			end
			else if (iter < 99) begin // Still have to Calculate
				if (is_finished == 0) begin
					// If threshold is (+) it means z_n1 exceeds 2
					if (threshold_w[N-1] == 0) begin 	
						iter <= iter;
						is_finished <= 1;
					end
					else begin
						iter <= iter + 1;
						is_finished <= 0;
					end
					z_n_real_r <= z_n1_real_r;
					z_n_img_r <= z_n1_img_r;
					z_n1_real_r <= z_n1_real_r;
					z_n1_img_r <= z_n1_img_r;
					z_n1_abs_r <= z_n1_abs_r;
					z_n1_img_r_stage1 <= z_n1_img_r_stage1;
					z_n_real_sq_r <= z_n_real_sq_r;
					z_n_img_sq_r <= z_n_img_sq_r;
					z_n1_img_r_stage2 <= z_n1_img_r_stage2;
					sq_sub_r <= sq_sub_r;
				end
				else begin 					// Calc Finished
					iter <= iter;
					is_finished <= is_finished;
					z_n_real_r <= z_n_real_r;
					z_n_img_r <= z_n_img_r;
					z_n1_real_r <= z_n1_real_r;
					z_n1_img_r <= z_n1_img_r;
					z_n1_abs_r <= z_n1_abs_r;
					z_n1_img_r_stage1 <= z_n1_img_r_stage1;
					z_n_real_sq_r <= z_n_real_sq_r;
					z_n_img_sq_r <= z_n_img_sq_r;
					z_n1_img_r_stage2 <= z_n1_img_r_stage2;
					sq_sub_r <= sq_sub_r;
				end
			end
			else begin // Same as default
				iter <= iter;
				is_finished <= is_finished;
				z_n_real_r <= z_n_real_r;
				z_n_img_r <= z_n_img_r;
				z_n1_real_r <= z_n1_real_r;
				z_n1_img_r <= z_n1_img_r;
				z_n1_abs_r <= z_n1_abs_r;
				z_n1_img_r_stage1 <= z_n1_img_r_stage1;
				z_n_real_sq_r <= z_n_real_sq_r;
				z_n_img_sq_r <= z_n_img_sq_r;
				z_n1_img_r_stage2 <= z_n1_img_r_stage2;
				sq_sub_r <= sq_sub_r;
			end
        end
		FIN : begin
			iter <= iter;
			is_finished <= 1;
			z_n_real_r <= z_n_real_r;
			z_n_img_r <= z_n_img_r;
			z_n1_real_r <= z_n1_real_r;
			z_n1_img_r <= z_n1_img_r;
			z_n1_abs_r <= z_n1_abs_r;
			z_n1_img_r_stage1 <= z_n1_img_r_stage1;
			z_n_real_sq_r <= z_n_real_sq_r;
			z_n_img_sq_r <= z_n_img_sq_r;
			z_n1_img_r_stage2 <= z_n1_img_r_stage2;
			sq_sub_r <= sq_sub_r;
		end
        default: begin
			iter <= 0;
			is_finished <= 0;
            z_n_real_r <= 0;
            z_n_img_r <= 0;
			//
			z_n1_real_r <= 0;
			z_n1_img_r <= 0;
			z_n1_abs_r <= 0;
			z_n1_img_r_stage1 <= 0;
			z_n_real_sq_r <= 0;
			z_n_img_sq_r <= 0;
			z_n1_img_r_stage2 <= 0;
			sq_sub_r <= 0;
        end
        endcase
    end

	reg [N-1:0] z_n1_real_r, z_n1_img_r;
	reg [N-1:0] z_n_real_sq_r, z_n_img_sq_r;
	reg [N-1:0] z_n1_abs_r;
	reg [N-1:0] z_n1_img_r_stage1;


	/*********************************
	**  FIND z_n1_real -> Start      **
	*********************************/
	qmult #(Q,N) uut_z_n_real_sq_w (	// (z_n_real)^2
		.i_multiplicand(z_n_real_r), 
		.i_multiplier(z_n_real_r), 
		.o_result(z_n_real_sq_w)
		// .ovr(ovp)
	);

	qmult #(Q,N) uut_z_n_img_sq_w (	// (z_n_img)^2
		.i_multiplicand(z_n_img_r), 
		.i_multiplier(z_n_img_r), 
		.o_result(z_n_img_sq_w)
		// .ovr(ovp)
	);
	
	// INIT1
	//---------------------------------
	// INIT2

	qadd #(Q,N) uut_sq_subtract (	// (z_n_real)^2 - (z_n_img)^2
		.a(z_n_real_sq_r), 
		.b(-z_n_img_sq_r), 
		.c(sq_sub_w)
	);

	reg [N-1:0] sq_sub_r;

	qadd #(Q,N) uut_z_n1_real_stage2 (	// (z_n_real)^2 - (z_n_img)^2 + C_real
		.a(sq_sub_r), 
		.b(c_real), // toggle
		.c(z_n1_real_w)
	);
	// INIT2
	/*********************************
	**  FIND z_n1_real -> Finish    **
	*********************************/


	/*********************************
	**  FIND z_n1_img -> Start      **
	*********************************/
	qmult #(Q,N) uut_z_n1_img_w_stage1 (	// 2 * z_n_real
		.i_multiplicand(TWO), 
		.i_multiplier(z_n_real_r), 
		.o_result(z_n1_img_w_stage1)
		// .ovr(ovp)
	);

	// INIT1
	// ------------------------------------
	// INIT2
	reg [N-1:0] z_n1_img_r_stage2;
	qmult #(Q,N) uut_z_n1_img_w_stage2 (	// 2 * z_n_real * z_n_img
		.i_multiplicand(z_n1_img_r_stage1), 
		.i_multiplier(z_n_img_r), 
		.o_result(z_n1_img_w_stage2)
		// .ovr(ovp)
	);

	// INIT2
	//-----------------------------------------
	// INIT3
	qadd #(Q,N) uut_z_n1_img_w (			// 2 * z_n_real * z_n_img + C_img
		.a(z_n1_img_r_stage2), 
		.b(c_img), // toggle
		.c(z_n1_img_w)
	);
	// INIT3
	/*********************************
	**  FIND z_n1_img -> Finish     **
	*********************************/


	/*********************************
	**  FIND z_n1_abs -> Start      **
	*********************************/
	// INIT4
	qmult #(Q,N) uut_z_n1_real_sq_w (		// (z_n1_real)^2
		.i_multiplicand(z_n1_real_r), 
		.i_multiplier(z_n1_real_r), 
		.o_result(z_n1_real_sq_w)
		// .ovr(ovp)
	);

	qmult #(Q,N) uut_z_n1_img_sq_w (		// (z_n1_img)^2
		.i_multiplicand(z_n1_img_r), 
		.i_multiplier(z_n1_img_r), 
		.o_result(z_n1_img_sq_w)
		// .ovr(ovp)
	);

	qadd #(Q,N) uut_z_n1_abs_w (			// (z_n1_real)^2 + (z_n1_img)^2
		.a(z_n1_real_sq_w), 
		.b(z_n1_img_sq_w),
		.c(z_n1_abs_w)
	);
	// INIT4

	/*********************************
	**  FIND z_n1_abs -> Finish     **
	*********************************/


	/*********************************
	**  FIND threshold -> Start     **
	*********************************/
	qadd #(Q,N) uut_threshold_subtract (	// (z_n1_real)^2 + (z_n1_img)^2 - r
		.a(z_n1_abs_r), 
		.b(-FOUR), // toggle
		.c(threshold_w)
	);
	/*********************************
	**  FIND threshold -> Finish    **
	*********************************/

    assign valid = is_finished;
    assign d_out = iter;

    // DEBUG part
    // assign DBG_state = rst ? 0: state;
    // assign DBG_real = z_n1_real_w;
	// assign DBG_img = z_n1_img_w;

endmodule

