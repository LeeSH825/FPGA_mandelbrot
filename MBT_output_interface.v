`timescale 1ns / 1ps


module MBT_output_interface(
    input wire clk,
    input wire rst,
    input wire [3:0] valid,
    input wire [6:0] d_out0,
    input wire [6:0] d_out1,
    input wire [6:0] d_out2,
    input wire [6:0] d_out3,
    // input wire [3:0] MBT_response,
    output wire [3:0] WEA,
    output wire response,
    output wire [31:0] Data2A
    );

    reg [1:0] delay;

    // FSM -> State Transition Block
    always @(posedge clk) begin
        if (rst == 1) begin
            delay <= 0;
        end
        else begin
            delay[0] <= &valid[3:0];
            delay[1] <= delay[0];
        end
    end
    assign response = (&valid[3:0]) & (~delay[1]);
    assign WEA = valid;
    assign Data2A = {valid[3], d_out3, valid[2], d_out2, valid[1], d_out1, valid[0], d_out0};

endmodule
