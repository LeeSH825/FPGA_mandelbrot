`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/03/01 19:17:22
// Design Name: 
// Module Name: clk_1s_generator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// Generating 1Hz Clk Signal
module clk_1s_generator (
    input wire clk,
    input wire resetn,
    output reg clk_1s
    );
    
    reg [31:0] cnt;
    
    always @(negedge resetn or posedge clk) begin
        if ( !resetn ) begin
            clk_1s <= 0;
            cnt <= 0;
        end
        else begin
            if ( cnt == 32'd67_500_000) begin
                cnt <= 0;
                clk_1s = ~clk_1s;
            end
            else
                cnt <= cnt + 1;
        end
    end
    
endmodule
