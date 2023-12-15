`timescale 1ns / 1ps
`default_nettype none

module HDMI_TOP(
    input  wire CLK,                // board clock: 100 MHz on Arty/Basys3/Nexys
    input  wire RST_BTN,
    inout  wire hdmi_tx_cec,        // CE control bidirectional
    input  wire hdmi_tx_hpd,        // hot-plug detect
    inout  wire hdmi_tx_rscl,       // DDC bidirectional
    inout  wire hdmi_tx_rsda,
    
    input wire btn1,
    input wire btn2,
    input wire btn3,

    input wire sw0,
    input wire sw1,
    output wire ready, //LED
    output wire led3,
    output wire led4_r,
    output wire led5_r,
    output wire led5_g,
    output wire led5_b,
    
    output wire hdmi_tx_clk_n,      // HDMI clock differential negative
    output wire hdmi_tx_clk_p,      // HDMI clock differential positive
    output wire [2:0] hdmi_tx_n,    // Three HDMI channels differential negative
    output wire [2:0] hdmi_tx_p,     // Three HDMI channels differential positive
    output wire clk_lock,
    output wire de,
    output wire led
    );
    
    wire rst = RST_BTN;
    // Display Clocks
    wire pix_clk;                   // pixel clock
    wire pix_clk_5x;                // 5x clock for 10:1 DDR SerDes
 
 
    display_clocks #(               // 640x480  800x600 1280x720 1920x1080
        .MULT_MASTER(10.0),         //    31.5     10.0   37.125    37.125
        .DIV_MASTER(1),         //       5        1        5         5
       .DIV_5X(5.0),              //     5.0      5.0      2.0       1.0
        .DIV_1X(25),            //      25       25       10         5
        .IN_PERIOD(10.0)            // 100 MHz = 10 ns
    )
    
    display_clocks_inst
    (
       .i_clk(CLK),
       .i_rst(rst),
       .o_clk_1x(pix_clk),
       .o_clk_5x(pix_clk_5x),
       .o_locked(clk_lock)
      
    );

    // Display Timings
    wire signed [15:0] sx;          // horizontal screen position (signed)
    wire signed [15:0] sy;          // vertical screen position (signed)
    wire h_sync;                    // horizontal sync
    wire v_sync;                    // vertical sync
    wire frame;                     // frame start

    display_timings #(              // 640x480  800x600 1280x720 1920x1080
        .H_RES(800),               //     640      800     1280      1920
        .V_RES(600),                //     480      600      720      1080
        .H_FP(40),                 //      16       40      110        88
        .H_SYNC(128),                //      96      128       40        44
        .H_BP(88),                 //      48       88      220       148
        .V_FP(1),                   //      10        1        5         4
        .V_SYNC(4),                 //       2        4        5         5
        .V_BP(23),                  //      33       23       20        36
        .H_POL(1),                  //       0        1        1         1
        .V_POL(1)                   //       0        1        1         1
    )
    
    display_timings_inst (
        .i_pix_clk(pix_clk),
        .i_rst(rst),
        .o_hs(h_sync),
        .o_vs(v_sync),
        .o_de(de),
        .o_frame(frame),
        .o_sx(sx),
        .o_sy(sy)
    );

    // test card colour output
    wire [7:0] red;
    wire [7:0] green;
    wire [7:0] blue;

    wire [18:0] addrb;
    wire [7:0] doutb;

    (*KEEP="true"*) wire [3:0] wea;
    (*KEEP="true"*) wire [16:0] addr;
    (*KEEP="true"*) wire [31:0] dout;

    MBT_engine engine(
        .clk_fast(CLK),
        .rst(rst),
        .x_min(16'hf000),
        .y_max(16'h0960),
        .zoom_level(2'b00),
        .WEA(wea),
        .addr(addr),
        // .DBG_state({ready, led3}),
        .d_out(dout),
        .ready(ready)
    );

    // assign led3 = |addr;
    // assign led5_g = |dout;
    assign {led4_r, led5_r, led5_g, led5_b, led3} = addr[10:6];
    // assign {led3} = addr[10];
    // assign {led4_r, led5_r, led5_g, led5_b} = {dout[24], dout[16], dout[8],dout[0]};

    blk_mem_gen_0 BRAM(
        .clka(CLK),
        .addra(addr),
        .dina(dout),
        // .wea({4{|wea}}),
        .wea(wea),

        .clkb(pix_clk),
        .addrb(addrb),
        .doutb(doutb)
    );

    // blk_mem_gen_1 BRAM_SINGLE (
    //     .clka(pix_clk),
    //     .addra(addrb),
    //     .dina(0),
    //     .douta(doutb),
    //     .wea(0)
    // );

    addr_decoder_8bit O_Decoder (
        .i_x(sx),
        .i_y(sy),
        .addr(addrb)
    );

    palette colormap (
        .din({1'b1, doutb[6:0]}),
        .mode(sw1),
        .o_RED(red),
        .o_GREEN(green),
        .o_BLUE(blue)
    );

    // gfx gfx_inst (
    //     .i_y(sy),
    //     .i_x(sx),
    //     .i_v_sync(v_sync),
        
    //     .btn1(btn1),
    //     .btn2(btn2),
    //     .btn3(btn3),
        
    //     .o_red(red),
    //     .o_green(green),
    //     .o_blue(blue)
    //     );

    wire tmds_ch0_serial, tmds_ch1_serial, tmds_ch2_serial, tmds_chc_serial;
    HDMI_generator HDMI_out (
        .i_pix_clk(pix_clk),
        .i_pix_clk_5x(pix_clk_5x),
        .i_rst(rst),
        .i_de(de),
        .i_data_ch0(blue),
        .i_data_ch1(green),
        .i_data_ch2(red),
        .i_ctrl_ch0({v_sync, h_sync}),
        .i_ctrl_ch1(2'b00),
        .i_ctrl_ch2(2'b00),
        .o_tmds_ch0_serial(tmds_ch0_serial),
        .o_tmds_ch1_serial(tmds_ch1_serial),
        .o_tmds_ch2_serial(tmds_ch2_serial),
        .o_tmds_chc_serial(tmds_chc_serial),  // encode pixel clock via same path
        .rst_oserdes(led)
    );

    // TMDS Buffered Output
    OBUFDS #(.IOSTANDARD("TMDS_33"))
        tmds_buf_ch0 (.I(tmds_ch0_serial), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
    OBUFDS #(.IOSTANDARD("TMDS_33"))
        tmds_buf_ch1 (.I(tmds_ch1_serial), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
    OBUFDS #(.IOSTANDARD("TMDS_33"))
        tmds_buf_ch2 (.I(tmds_ch2_serial), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
    OBUFDS #(.IOSTANDARD("TMDS_33"))
        tmds_buf_chc (.I(tmds_chc_serial), .O(hdmi_tx_clk_p), .OB(hdmi_tx_clk_n));

    assign hdmi_tx_cec   = 1'bz;
    assign hdmi_tx_rsda  = 1'bz;
    assign hdmi_tx_rscl  = 1'b1;
endmodule