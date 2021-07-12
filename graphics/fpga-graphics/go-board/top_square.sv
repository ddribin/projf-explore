// Project F: FPGA Graphics - Top Square (Arty Pmod VGA)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_square (
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

    // 32 x 32 pixel square
    logic q_draw;
    always_comb q_draw = (sx < 32 && sy < 32) ? 1 : 0;


    // VGA output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        vga_r <= !de ? 3'h0 : (q_draw ? 3'h7 : 3'h0);
        vga_g <= !de ? 3'h0 : (q_draw ? 3'h4 : 3'h4);
        vga_b <= !de ? 3'h0 : (q_draw ? 3'h0 : 3'h7);
    end
endmodule
