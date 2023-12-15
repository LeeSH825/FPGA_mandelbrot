`timescale 1ns / 1ps

/* Note
** mode   0: B&W   mode
**        1: Color mode
*/

module palette(
    input wire [7:0] din,
    input wire mode,

    // DEBUG
    output wire [6:0] DBG_index,

    output wire [7:0] o_RED,
    output wire [7:0] o_GREEN,
    output wire [7:0] o_BLUE
    );

    reg [23:0] palette_rom [31:0];

	wire [6:0] rom_idx;
    reg [7:0] r_RED, r_GREEN, r_BLUE;

    initial begin                       // ROM initialize
        palette_rom[0] <= 24'h000000;
        palette_rom[1] <= 24'h000008;
        palette_rom[2] <= 24'h000010;
        palette_rom[3] <= 24'h04001F;
        palette_rom[4] <= 24'h09012F;
        palette_rom[5] <= 24'h06023C;
        palette_rom[6] <= 24'h040449;
        palette_rom[7] <= 24'h020556;
        palette_rom[8] <= 24'h000764;
        palette_rom[9] <= 24'h061977;
        palette_rom[10] <= 24'h0C2C8A;
        palette_rom[11] <= 24'h123F9D;
        palette_rom[12] <= 24'h1852B1;
        palette_rom[13] <= 24'h2867C1;
        palette_rom[14] <= 24'h397DD1;
        palette_rom[15] <= 24'h5F99DB;
        palette_rom[16] <= 24'h86B5E5;
        palette_rom[17] <= 24'hACD0EE;
        palette_rom[18] <= 24'hD3ECF8;
        palette_rom[19] <= 24'hE2EADB;
        palette_rom[20] <= 24'hF1E9BF;
        palette_rom[21] <= 24'hF4D98F;
        palette_rom[22] <= 24'hF8C95F;
        palette_rom[23] <= 24'hFBB92F;
        palette_rom[24] <= 24'hFFAA00;
        palette_rom[25] <= 24'hFFAA00;
        palette_rom[26] <= 24'hCC8000;
        palette_rom[27] <= 24'hB26B00;
        palette_rom[28] <= 24'h995700;
        palette_rom[29] <= 24'h824601;
        palette_rom[30] <= 24'h6A3403;
        palette_rom[31] <= 24'h522205;
    end

	assign rom_idx = din[6:0];

	// mode
    always @(*) begin
        if (mode == 0)  begin   // Black & White Mode
                if (rom_idx < 99) begin   // not in MBT set -> White
                    r_RED <= 8'hFF;
                    r_GREEN <= 8'hFF;
                    r_BLUE <= 8'hFF;
                end
                else begin              // in MBT set -> Black
                    r_RED <= 8'h00;
                    r_GREEN <= 8'h00;
                    r_BLUE <= 8'h00;
                end
        end
        else begin              // Color Mode
                if (rom_idx < 32) begin
                    r_RED <= palette_rom[rom_idx[4:0]][23:16];
                    r_GREEN <= palette_rom[rom_idx[4:0]][15:8];
                    r_BLUE <= palette_rom[rom_idx[4:0]][7:0];
                end
                else begin
                    r_RED <= palette_rom[31][23:16];
                    r_GREEN <= palette_rom[31][15:8];
                    r_BLUE <= palette_rom[31][7:0];
                end
        end
    end

	// only when it is valid data
    assign o_RED = din[7] ? r_RED : 8'h00;
    assign o_GREEN = din[7] ? r_GREEN: 8'h00;
    assign o_BLUE = din[7] ? r_BLUE : 8'h00;

	//DBG
	assign DBG_index = rom_idx;

endmodule
