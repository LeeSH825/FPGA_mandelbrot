`timescale 1ns / 1ps


module addr_decoder_8bit(
    input wire [15:0] i_x,
    input wire [15:0] i_y,
    output wire [18:0] addr
    );

    reg [15:0] temp_x, temp_y;

    always @(i_x or i_y) begin
        if (i_x < 0) begin
            temp_x <= 0;
        end
        else begin
            temp_x <= i_x;
        end
        if (i_y < 0) begin
            temp_y <= 0;
        end
        else begin
            temp_y <= i_y;
        end
    end

    assign addr = temp_x + (temp_y * 800);

endmodule
