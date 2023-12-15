`timescale 1ns / 1ps


module addr_decoder_32bit(
    input wire [15:0] i_x,
    input wire [15:0] i_y,
    output reg [16:0] addr
    );

    wire [16:0] address;

    always @(address) begin
        if ((address >= 0) && (address <= 120000)) begin
            addr <= address;
        end
        else if (address < 0) begin
            addr <= 0;
        end
        else begin
            addr <= 120000;
        end
    end
    assign address = (i_x >> 2) + (i_y * 200);

endmodule
