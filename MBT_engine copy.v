`timescale 1ns / 1ps


module MBT_engine(
    input wire clk_fast,
    // input clk_slow,
    input wire rst,

    // Delete when module is added
    // input mbt_response,
    output wire rst_MBT,
    output wire [3:0] valid,
    // output [6:0] d_out0,
    // output [6:0] d_out1,
    // output [6:0] d_out2,
    // output [6:0] d_out3,
    output wire [3:0] WEA,
    output wire [16:0] addr,


    // DBG
    output [15:0] DBG_I_X,
    output [15:0] DBG_I_Y,
    output [1:0] DBG_state,
    output DBG_response,
    output [3:0] DBG_MBT_response,

    input wire [15:0] x_min,
    input wire [15:0] y_max,
    input wire [1:0] zoom_level,
    output wire [31:0] d_out,
    output wire ready
    );

    wire [15:0] i_x_w, i_y_w;
    wire [1:0] state;

    wire rst2MBT, start2MBT;
    wire resetMBT;

    wire start;

    wire [3:0] MBT_response;

    wire mbt_response;

    wire [15:0] c_real_0, c_img_0, c_real_1, c_img_1, c_real_2, c_img_2, c_real_3, c_img_3;
    wire [6:0] d_out0, d_out1, d_out2, d_out3;


    MBT_controller MBT_CONTROLLER(
        .clk(clk_fast),
        .rst(rst),
        .mbt_response(mbt_response),
        .i_x(i_x_w),
        .i_y(i_y_w),

        //DBG
        .DBG_controller_state(state),


        .start(start),
        .ready(ready),
        .rst_MBT(resetMBT)
    );

    fetch_param MBT_DISTRIBUTOR(
        .i_x(i_x_w),
        .i_y(i_y_w),
        .x_min(x_min),
        .y_max(y_max),
        .zoom_level(zoom_level),
        .start(start),
        .rstMBT(resetMBT),
        .start2MBT(start2MBT),
        .rst2MBT(rst2MBT),
        .c_real_0(c_real_0),
        .c_img_0(c_img_0),
        .c_real_1(c_real_1),
        .c_img_1(c_img_1),
        .c_real_2(c_real_2),
        .c_img_2(c_img_2),
        .c_real_3(c_real_3),
        .c_img_3(c_img_3)
    );

    MBT_ALU mbt_module_0(
        .clk(clk_fast),
        .rst(rst2MBT),
        .start(start2MBT),
        .c_real(c_real_0),
        .c_img(c_img_0),
        // .DBG_state(MBT_response[0]),
        .valid(valid[0]),
        .d_out(d_out0)
    );

    MBT_ALU mbt_module_1(
        .clk(clk_fast),
        .rst(rst2MBT),
        .start(start2MBT),
        .c_real(c_real_1),
        .c_img(c_img_1),
        // .DBG_state(MBT_response[1]),
        .valid(valid[1]),
        .d_out(d_out1)
    );

    MBT_ALU mbt_module_2(
        .clk(clk_fast),
        .rst(rst2MBT),
        .start(start2MBT),
        .c_real(c_real_2),
        .c_img(c_img_2),
        // .DBG_state(MBT_response[2]),
        .valid(valid[2]),
        .d_out(d_out2)
    );

    MBT_ALU mbt_module_3(
        .clk(clk_fast),
        .rst(rst2MBT),
        .start(start2MBT),
        .c_real(c_real_3),
        .c_img(c_img_3),
        // .DBG_state(MBT_response[3]),
        .valid(valid[3]),
        .d_out(d_out3)
    );

    MBT_output_interface MBT_Interface(
        .clk(clk_fast),
        .rst(rst),
        .valid(valid),
        .d_out0(d_out0),
        .d_out1(d_out1),
        .d_out2(d_out2),
        .d_out3(d_out3),
        // .MBT_response(MBT_response),
        .WEA(WEA),
        .response(mbt_response),
        .Data2A(d_out)
    );

    addr_decoder_32bit DECODER_32B (
        .i_x(i_x_w),
        .i_y(i_y_w),
        .addr(addr)
    );

    // DEBUG
    assign DBG_I_X = i_x_w;
    assign DBG_I_Y = i_y_w;
    assign DBG_state = state;
    assign DBG_response = mbt_response;
    assign DBG_MBT_response = MBT_response;
    assign rst_MBT = rst2MBT;
endmodule
