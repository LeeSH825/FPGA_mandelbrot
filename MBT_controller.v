`timescale 1ns / 1ps


module MBT_controller(
    input wire clk,
    input wire rst,
    input wire mbt_response,

	// DBG
	output wire [1:0] DBG_controller_state,

	output reg [15:0] i_x,
    output reg [15:0] i_y,
	output reg start,
    output reg ready,
    output reg rst_MBT
    );

    // FSM variables
    reg [1:0] state, next_state;
    parameter IDLE = 2'b00;
    parameter WORK = 2'b01;
    parameter WAIT = 2'b10;
    parameter FINISH = 2'b11;

    reg finished;
	reg start_reg;

    reg init_mbt;

    // pixel position
    reg [15:0] current_X;
    reg [15:0] current_Y;

    // FSM -> State Transition Block
    always@(posedge clk) begin
        if (rst == 1) begin
            state <= IDLE;
        end
        else begin
            case(state)
            IDLE: begin
                state <= WORK;
            end
            WORK: begin
				if (finished == 1) begin
					state <= FINISH;
				end
				else begin
					state <= WAIT;
				end
            end
            WAIT: begin
                if (mbt_response == 1) begin
                    state <= WORK;
                end
                else begin
                    state <= WAIT;
                end
            end
            FINISH: begin
                state <= FINISH;
            end
            default: begin
                state <= IDLE;
            end
            endcase
        end
    end

    always @(posedge clk) begin
        if (rst == 1) begin
            finished <= 0;
            current_X <= 0;
            current_Y <= 0;
			start_reg <= 0;
            init_mbt <= 1;
        end
        else begin
            case (state)
                IDLE: begin
                    finished <= 0;
                    current_X <= -4;
                    current_Y <= -1;
					start_reg <= 0;
                    init_mbt <= 0;
                end
                WORK: begin
					// if (finished == 1)
                    finished <= 0;
					start_reg <= 1;
                    init_mbt <= 0;
                    if (current_X < 796)begin      // until it reachs to end of horizontal
                        current_X <= current_X + 4;
                        current_Y <= current_Y;
                    end
                    else begin                      // when it reachs to end
                        current_X <= 0;				// -> increase vertical
                        current_Y <= current_Y + 1;
                    end
                end
                WAIT: begin
					start_reg <= 0;
                    init_mbt <= 0;
					if ((current_X == 796) && (current_Y == 599)) begin
						current_X <= current_X;
						current_Y <= current_Y;
						if (mbt_response == 1) begin
							finished <= 1;
						end
						else begin
							finished <= 0;
						end
						// finished <= 0;
					end
					else begin
						current_X <= current_X;
						current_Y <= current_Y;
						finished <= 0;
					end
                end
                FINISH: begin
                    finished <= 1;
                    init_mbt <= 0;
					start_reg <= 0;
                    current_X <= 0;
                    current_Y <= 0;
                end
                default: begin
                    finished <= 0;
                    init_mbt <= 0;
					start_reg <= 0;
                    current_X <= 0;
                    current_Y <= 0;
                end
            endcase
        end
    end

	always@(*) begin
		i_x <= current_X;
		i_y <= current_Y;
		ready <= finished;
		rst_MBT <= finished | mbt_response | init_mbt;
		start = start_reg;
	end

	// DBG
	assign DBG_controller_state = state;

endmodule
