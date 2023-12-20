`timescale 1ns / 1ps


module ZMU #(
    parameter Q = 21,
    parameter N = 32,
    parameter P = 24   // For under 16-bit precision
    )(
    input wire clk,
    input wire rst,
    input wire [15:0] pixel_coord_X,
    input wire [15:0] pixel_coord_Y,
    input wire sw0,
    input wire zoom_btn,
    output wire [1:0] zoom_level,
    output wire [1:0] DBG_zoom,
    output wire [N-1:0] real_coord_X,
    output wire [N-1:0] real_coord_Y
    );


    // Detect posedge of btn
    reg btn_debounced;
    reg sig_dly;
    always @(posedge clk) begin
        sig_dly <= zoom_btn;
    end
    always @(posedge clk) begin
        btn_debounced = zoom_btn & ~sig_dly;
    end


    reg [N-1:0] zoom_pos_X [3:0];
    reg [N-1:0] zoom_pos_Y [3:0];
    wire [N-1:0] zoom_pos_X_cur, zoom_pos_Y_cur;
    reg [N-1:0] zoom_pos_X_last, zoom_pos_Y_last;


    // Zoom Level param
    parameter LVL0 = 2'b00;
    parameter LVL1 = 2'b01;
    parameter LVL2 = 2'b10;
    parameter LVL3 = 2'b11;
    reg [1:0] zoom_level_r, zoom_level_r_last;

    always@(posedge clk) begin
        if (rst == 1) begin
			zoom_level_r_last <= 0;
            zoom_pos_X_last <= zoom_pos_X[0];
			zoom_pos_Y_last <= zoom_pos_Y[0];
            // FOR (11,16)
            // zoom_pos_X[zoom_level_r] <= 16'hf000;                       // TODO: cahnge
            // zoom_pos_Y[zoom_level_r] <= 16'h0960;
            // FOR (21,32)
            zoom_pos_X[zoom_level_r] <= 32'hffc00000;
            zoom_pos_Y[zoom_level_r] <= 32'h00258000;
			zoom_pos_X[zoom_level_r+1] <= zoom_pos_X[zoom_level_r+1];
			zoom_pos_Y[zoom_level_r+1] <= zoom_pos_Y[zoom_level_r+1];
			zoom_level_r <= 0;
        end
		else begin
			if (btn_debounced == 1) begin
				if (sw0 == 1) begin         // Zoom In
					if (zoom_level_r < 3) begin
						zoom_level_r_last <= zoom_level_r;
						zoom_pos_X_last <= zoom_pos_X[zoom_level_r];
						zoom_pos_Y_last <= zoom_pos_Y[zoom_level_r];
						zoom_pos_X[zoom_level_r+1] <= zoom_pos_X_cur;
						zoom_pos_Y[zoom_level_r+1] <= zoom_pos_Y_cur;
						zoom_level_r <= zoom_level_r + 1;
					end
					else begin   // Zoom In MAX
						zoom_level_r_last <= zoom_level_r;
						zoom_pos_X[zoom_level_r+1] <= zoom_pos_X[zoom_level_r+1];
						zoom_pos_Y[zoom_level_r+1] <= zoom_pos_Y[zoom_level_r+1];
						zoom_level_r <= zoom_level_r;
					end
				end
				else begin                  // Zoom Out
					if (zoom_level_r > 0) begin
						zoom_level_r_last <= zoom_level_r;
						zoom_pos_X[zoom_level_r+1] <= zoom_pos_X[zoom_level_r+1];
						zoom_pos_Y[zoom_level_r+1] <= zoom_pos_Y[zoom_level_r+1];
						zoom_level_r <= zoom_level_r - 1;
					end
					else begin 				// Zoom Out MAX
						zoom_level_r_last <= zoom_level_r;
						zoom_pos_X[zoom_level_r+1] <= zoom_pos_X[zoom_level_r+1];
						zoom_pos_Y[zoom_level_r+1] <= zoom_pos_Y[zoom_level_r+1];
						zoom_level_r <= zoom_level_r;
					end
				end
			end
			else begin
				zoom_level_r_last <= zoom_level_r;
				zoom_pos_X_last <= zoom_pos_X[zoom_level_r];
				zoom_pos_Y_last <= zoom_pos_Y[zoom_level_r];
				zoom_pos_X[zoom_level_r] <= zoom_pos_X[zoom_level_r];
				zoom_pos_Y[zoom_level_r] <= zoom_pos_Y[zoom_level_r];
				zoom_pos_X[zoom_level_r+1] <= zoom_pos_X[zoom_level_r+1];
				zoom_pos_Y[zoom_level_r+1] <= zoom_pos_Y[zoom_level_r+1];
				zoom_level_r <= zoom_level_r;
			end
		end
    end

    parameter X = 0;
    parameter Y = 1;

    CTU #(Q, N, P) pointer_X_CTU(
        .clk(clk),
        .start_coord(zoom_pos_X_last),
        .axis(X),
        .pixel_coord(pixel_coord_X),
        .zoom_level(zoom_level_r_last),
        .real_coord(zoom_pos_X_cur)
    );

    CTU #(Q, N, P) pointer_Y_CTU(
        .clk(clk),
        .start_coord(zoom_pos_Y_last),
        .axis(Y),
        .pixel_coord(pixel_coord_Y),
        .zoom_level(zoom_level_r_last),
        .real_coord(zoom_pos_Y_cur)
    );

    assign real_coord_X = zoom_pos_X[zoom_level_r];
    assign real_coord_Y = zoom_pos_Y[zoom_level_r];
    assign zoom_level = zoom_level_r;
    assign DBG_zoom = zoom_level_r_last;
endmodule
