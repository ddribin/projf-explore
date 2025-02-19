// Project F Library - 24x18 Display Timings for Testing
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module display_timings_24x18 #(
    CORDW=16,   // signed coordinate width (bits)
    H_RES=24,   // horizontal resolution (pixels)
    V_RES=18,   // vertical resolution (lines)
    H_FP=2,     // horizontal front porch
    H_SYNC=2,   // horizontal sync
    H_BP=4,     // horizontal back porch
    V_FP=1,     // vertical front porch
    V_SYNC=1,   // vertical sync
    V_BP=2,     // vertical back porch
    H_POL=1,    // horizontal sync polarity (0:neg, 1:pos)
    V_POL=1     // vertical sync polarity (0:neg, 1:pos)
    ) (
    input  wire logic clk_pix,  // pixel clock
    input  wire logic rst,      // reset
    output      logic hsync,    // horizontal sync
    output      logic vsync,    // vertical sync
    output      logic de,       // data enable (low in blanking intervals)
    output      logic frame,    // high at start of frame
    output      logic line,     // high at start of active line
    output      logic signed [CORDW-1:0] sx,  // horizontal screen position
    output      logic signed [CORDW-1:0] sy   // vertical screen position
    );

    // horizontal timings
    localparam signed H_STA  = 0 - H_FP - H_SYNC - H_BP;    // horizontal start
    localparam signed HS_STA = H_STA + H_FP;                // sync start
    localparam signed HS_END = HS_STA + H_SYNC;             // sync end
    localparam signed HA_STA = 0;                           // active start
    localparam signed HA_END = H_RES - 1;                   // active end

    // vertical timings
    localparam signed V_STA  = 0 - V_FP - V_SYNC - V_BP;    // vertical start
    localparam signed VS_STA = V_STA + V_FP;                // sync start
    localparam signed VS_END = VS_STA + V_SYNC;             // sync end
    localparam signed VA_STA = 0;                           // active start
    localparam signed VA_END = V_RES - 1;                   // active end

    logic signed [CORDW-1:0] x, y;  // screen position

    // generate horizontal and vertical syncs with correct polarity
    always_ff @(posedge clk_pix) begin
        hsync <= H_POL ? (x > HS_STA && x <= HS_END)
                      : ~(x > HS_STA && x <= HS_END);
        vsync <= V_POL ? (y > VS_STA && y <= VS_END)
                      : ~(y > VS_STA && y <= VS_END);
    end

    // control signals
    always_ff @(posedge clk_pix) begin
        de    <= (y >= VA_STA && x >= HA_STA);
        frame <= (y == V_STA  && x == H_STA);
        line  <= (y >= VA_STA && x == H_STA);
        if (rst) frame <= 0;  // don't assert frame in reset
    end

    // calculate horizontal and vertical screen position
    always_ff @(posedge clk_pix) begin
        if (x == HA_END) begin  // last pixel on line?
            x <= H_STA;
            y <= (y == VA_END) ? V_STA : y + 1;  // last line on screen?
        end else begin
            x <= x + 1;
        end
        if (rst) begin
            x <= H_STA;
            y <= V_STA;
        end
    end

    // align screen position with sync and control signals
    always_ff @ (posedge clk_pix) begin
        sx <= x;
        sy <= y;
        if (rst) begin
            sx <= H_STA;
            sy <= V_STA;
        end
    end
endmodule
