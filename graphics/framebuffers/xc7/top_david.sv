// Project F: Framebuffers - Top David (Arty Pmod VGA)
// (C)2021 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

`default_nettype none
`timescale 1ns / 1ps

module top_david (
    input  wire logic clk_100m,     // 100 MHz clock
    input  wire logic btn_rst,      // reset button (active low)
    output      logic vga_hsync,    // horizontal sync
    output      logic vga_vsync,    // vertical sync
    output      logic [3:0] vga_r,  // 4-bit VGA red
    output      logic [3:0] vga_g,  // 4-bit VGA green
    output      logic [3:0] vga_b   // 4-bit VGA blue
    );

    // generate pixel clock
    logic clk_pix;
    logic clk_locked;
    clock_gen_480p clock_pix_inst (
       .clk(clk_100m),
       .rst(!btn_rst),  // reset button is active low
       .clk_pix,
       .clk_locked
    );

    // display timings
    localparam CORDW = 16;
    logic hsync, vsync;
    logic de, frame, line;
    display_timings_480p #(.CORDW(CORDW)) display_timings_inst (
        .clk_pix,
        .rst(!clk_locked),  // wait for pixel clock lock
        /* verilator lint_off PINCONNECTEMPTY */
        .sx(),
        .sy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .hsync,
        .vsync,
        .de,
        .frame,
        .line
    );

    logic frame_sys;  // start of new frame in system clock domain
    xd xd_frame (.clk_i(clk_pix), .clk_o(clk_100m),
                 .rst_i(1'b0), .rst_o(1'b0), .i(frame), .o(frame_sys));

    // framebuffer (FB)
    localparam FB_WIDTH   = 160;
    localparam FB_HEIGHT  = 120;
    localparam FB_CIDXW   = 4;
    localparam FB_CHANW   = 4;
    localparam FB_SCALE   = 4;
    localparam FB_IMAGE   = "david.mem";
    localparam FB_PALETTE = "david_palette.mem";

    logic fb_we;  // write enable
    logic signed [CORDW-1:0] fbx, fby;  // draw coordinates
    logic [FB_CIDXW-1:0] fb_cidx;  // draw colour index
    logic [FB_CHANW-1:0] fb_red, fb_green, fb_blue;  // colours for display output

    framebuffer_bram #(
        .WIDTH(FB_WIDTH),
        .HEIGHT(FB_HEIGHT),
        .CIDXW(FB_CIDXW),
        .CHANW(FB_CHANW),
        .SCALE(FB_SCALE),
        .F_IMAGE(FB_IMAGE),
        .F_PALETTE(FB_PALETTE)
    ) fb_inst (
        .clk_sys(clk_100m),
        .clk_pix,
        .rst_sys(1'b0),
        .rst_pix(1'b0),
        .de,
        .frame,
        .line,
        .we(fb_we),
        .x(fbx),
        .y(fby),
        .cidx(fb_cidx),
        /* verilator lint_off PINCONNECTEMPTY */
        .clip(),
        .busy(),
        /* verilator lint_on PINCONNECTEMPTY */
        .red(fb_red),
        .green(fb_green),
        .blue(fb_blue)
    );

    // draw box around framebuffer
    enum {IDLE, TOP, RIGHT, BOTTOM, LEFT, DONE} state;
    always_ff @(posedge clk_100m) begin
        case (state)
            TOP:
                if (fbx < FB_WIDTH-1) begin
                    fbx <= fbx + 1;
                end else begin
                    state <= RIGHT;
                end
            RIGHT:
                if (fby < FB_HEIGHT-1) begin
                    fby <= fby + 1;
                end else begin
                    fbx <= 0;
                    fby <= 0;
                    state <= LEFT;
                end
            LEFT:
                if (fby < FB_HEIGHT-1) begin
                    fby <= fby + 1;
                end else begin
                    state <= BOTTOM;
                end
            BOTTOM:
                if (fbx < FB_WIDTH-1) begin
                    fbx <= fbx + 1;
                end else begin
                    fb_we <= 0;
                    state <= DONE;
                end
            IDLE:
                if (frame_sys) begin
                    fbx <= 0;
                    fby <= 0;
                    fb_cidx <= 4'h0;  // palette index
                    fb_we <= 1;
                    state <= TOP;
                end
            default: state <= DONE;  // done forever!
        endcase
    end

    // reading from FB takes one cycle: delay display signals to match
    logic hsync_p1, vsync_p1;
    always_ff @(posedge clk_pix) begin
        hsync_p1 <= hsync;
        vsync_p1 <= vsync;
    end

    // VGA output
    always_ff @(posedge clk_pix) begin
        vga_hsync <= hsync_p1;
        vga_vsync <= vsync_p1;
        vga_r <= fb_red;
        vga_g <= fb_green;
        vga_b <= fb_blue;
    end
endmodule
