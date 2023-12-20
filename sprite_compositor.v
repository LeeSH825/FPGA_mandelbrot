`timescale 1ns / 1ps



module sprite_compositor(
    input wire [15:0] i_x,
    input wire [15:0] i_y,
    input wire i_v_sync,

    input wire rst,
    input wire btn2,
    input wire btn3,
    input wire sw,

    output reg [15:0] sprite_x_pos,
    output reg [15:0] sprite_y_pos,
    
    output wire [7:0] o_red,
    output wire [7:0] o_green,
    output wire [7:0] o_blue,
    output wire o_sprite_hit    
    );
    
    reg [15:0] sprite_x     = 16'd00;
    reg [15:0] sprite_y     = 16'd00; 

    reg sprite_x_flip       = 0;
    reg sprite_y_flip       = 0;
    wire sprite_hit_x, sprite_hit_y;
    wire [3:0] sprite_render_x;
    wire [3:0] sprite_render_y;
    
    assign sprite_hit_x = (i_x >= sprite_x) && (i_x < sprite_x + 16);
    assign sprite_hit_y = (i_y >= sprite_y) && (i_y < sprite_y + 16);
    assign sprite_render_x = (i_x - sprite_x);
    assign sprite_render_y = (i_y - sprite_y);
                                                                         
    assign o_red    = (sprite_hit_x && sprite_hit_y) ? 8'hFF : 8'hXX;
    assign o_green  = (sprite_hit_x && sprite_hit_y) ? 8'h00 : 8'hXX;
    assign o_blue   = (sprite_hit_x && sprite_hit_y) ? 8'h00 : 8'hXX;
    assign o_sprite_hit = (sprite_hit_y & sprite_hit_x);

    assign sprite_x_pos = sprite_x;
    assign sprite_y_pos = sprite_y;

   always @(posedge  i_v_sync ) begin
        if (rst == 1) begin
            sprite_x <= 0;
            sprite_y <= 0;
        end
        else begin
            if (btn3) begin
                if ((sprite_x > 0) && (sprite_x < 800-16)) begin
                    sprite_x <= sprite_x + (sw ? 1 : -1);
                end
                else if (sprite_x == 0) begin
                    sprite_x <= sprite_x + (sw ? 1 : 0);
                end
                else if (sprite_x == 800-16) begin
                    sprite_x <= sprite_x + (sw ? 0 : -1);
                end
                else begin
                    sprite_x <= sprite_x;
                end
            end
            else if (btn2) begin
                if ((sprite_y > 0) && (sprite_y < 600-16)) begin
                    sprite_y <= sprite_y + (sw ? 1 : -1);
                end
                else if (sprite_y == 0) begin
                    sprite_y <= sprite_y + (sw ? 1 : 0);
                end
                else if (sprite_y == 600-16) begin
                    sprite_y <= sprite_y + (sw ? 0 : -1);
                end
                else begin
                    sprite_y <= sprite_y;
                end
            end
            else begin
                sprite_x <= sprite_x;
                sprite_y <= sprite_y;
            end
        end
   end

endmodule
