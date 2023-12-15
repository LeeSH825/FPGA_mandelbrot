`timescale 1ns / 1ps


module gfx(
    input wire [15:0] i_x,
    input wire [15:0] i_y,
    input wire i_v_sync,
    
    input wire btn1,
    input wire btn2,
    input wire btn3,
    
    output reg [7:0] o_red,
    output reg [7:0] o_green,
    output reg [7:0] o_blue

    );
    wire bg_hit, sprite_hit, sprite_hit2;
    wire [7:0] bg_red;
    wire [7:0] bg_green;
    wire [7:0] bg_blue;
    wire [7:0] sprite_red, sprite_red2;
    wire [7:0] sprite_green, sprite_green2;
    wire [7:0] sprite_blue, sprite_blue2;
   
   test_card_simple test_card_simple_1(
            .i_x (i_x),
            .o_red      (bg_red),
            .o_green    (bg_green),
            .o_blue     (bg_blue),
            .o_bg_hit   (bg_hit)
            );
  
     sprite_compositor sprite_compositor_1 (
        .i_x        (i_x),
        .i_y        (i_y),
        .i_v_sync   (i_v_sync),
        
        .o_red      (sprite_red),
        .o_green    (sprite_green),
        .o_blue     (sprite_blue),
        .o_sprite_hit   (sprite_hit)
    );
    
     sprite_compositor2 sprite_compositor_2 (
        .i_x        (i_x),
        .i_y        (i_y),
        .i_v_sync   (i_v_sync),
        
        .btn1(btn1),
        .btn2(btn2),
        .btn3(btn3),
        
        .o_red      (sprite_red2),
        .o_green    (sprite_green2),
        .o_blue     (sprite_blue2),
        .o_sprite_hit   (sprite_hit2)
    );
  
    always@(*) begin
    if(sprite_hit==1) begin
    o_red=sprite_red;
    o_green=sprite_green;
    o_blue=sprite_blue;
    end
    else if (sprite_hit2==1) begin
    o_red=sprite_red2;
    o_green=sprite_green2;
    o_blue=sprite_blue2;
    end
    else begin
    o_red=bg_red;
    o_green=bg_green;
    o_blue=bg_blue;
    end
    
    end
    
endmodule