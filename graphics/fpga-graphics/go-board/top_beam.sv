// Project F: FPGA Graphics - Top Beam (Arty Pmod VGA)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_beam (
    input  wire logic clk_25m,      // 25 MHz clock
    input  wire logic btn_rst,      // reset button (active low)
    output      logic vga_hsync,    // horizontal sync
    output      logic vga_vsync,    // vertical sync
    output      logic [2:0] vga_r,  // 3-bit VGA red
    output      logic [2:0] vga_g,  // 3-bit VGA green
    output      logic [2:0] vga_b   // 3-bit VGA blue
    );

    // generate pixel clock
    wire clk_pix = clk_25m;
    wire clk_locked = 1;

    // display timings
    localparam CORDW = 10;  // screen coordinate width in bits
    logic [CORDW-1:0] sx, sy;
    logic hsync, vsync, de;
    simple_display_timings_480p display_timings_inst (
        .clk_pix,
        .rst(!clk_locked),  // wait for clock lock
        .sx,
        .sy,
        .hsync,
        .vsync,
        .de
    );

    // size of screen with and without blanking
    localparam H_RES_FULL = 800;
    localparam V_RES_FULL = 525;
    localparam H_RES = 640;
    localparam V_RES = 480;

    logic animate;  // high for one clock tick at start of vertical blanking
    always_comb animate = (sy == V_RES && sx == 0);

    // square 'Q' - origin at top-left
    localparam Q_SIZE = 32;    // square size in pixels
    localparam Q_SPEED = 4;    // pixels moved per frame
    logic [CORDW-1:0] qx, qy;  // square position

    // update square position once per frame
    always_ff @(posedge clk_pix) begin
        if (animate) begin
            if (qx >= H_RES_FULL - Q_SIZE) begin
                qx <= 0;
                qy <= (qy >= V_RES_FULL - Q_SIZE) ? 0 : qy + Q_SIZE;
            end else begin
                qx <= qx + Q_SPEED;
            end
        end
    end

    // is square at current screen position?
    logic q_draw;
    always_comb begin
        q_draw = (sx >= qx) && (sx < qx + Q_SIZE)
              && (sy >= qy) && (sy < qy + Q_SIZE);
    end

    // VGA output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        vga_r <= !de ? 3'h0 : (q_draw ? 3'h7 : 3'h0);
        vga_g <= !de ? 3'h0 : (q_draw ? 3'h4 : 3'h4);
        vga_b <= !de ? 3'h0 : (q_draw ? 3'h0 : 3'h7);
    end
endmodule
