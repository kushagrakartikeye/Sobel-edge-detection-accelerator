`timescale 1ns / 1ps

module Sobel_Top (
    input  wire       clk,
    input  wire       rst,
    input  wire       enable,
    input  wire [7:0] threshold,
    output wire       edge_out
);

    // Internal pixel registers (tied to test pattern values)
    // Avoids exposing 64 raw pixel pins to physical package sites
    reg [7:0] p00, p01, p02;
    reg [7:0] p10,      p12;
    reg [7:0] p20, p21, p22;

    // Simple test pattern generator for hardware verification
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            p00 <= 8'd10;  p01 <= 8'd10;  p02 <= 8'd10;
            p10 <= 8'd10;                 p12 <= 8'd200; // High gradient/edge
            p20 <= 8'd10;  p21 <= 8'd10;  p22 <= 8'd200;
        end
    end

    // Instantiate core accelerator
    SobelFilter uut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .threshold(threshold),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10),            .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .edge_out(edge_out)
    );

endmodule