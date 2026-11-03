`timescale 1ns / 1ps

// Uncomment line below for Exact Multiplier; Comment out to use LogMult
//`define USE_EXACT_MULT 

module SobelFilter (
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,       // Clock gate enable (1 = Active, 0 = Gated)
    input  wire [7:0]  p00, p01, p02,
    input  wire [7:0]  p10,      p12,
    input  wire [7:0]  p20, p21, p22,
    input  wire [7:0]  threshold,    // Base threshold / offset
    output wire        edge_out
);

    // Dynamic Clock Gating Instance
    wire gated_clk;

    ClockGating cg_inst (
        .clk_in(clk),
        .enable(enable),
        .clk_out(gated_clk)
    );

    // Multiplier outputs for Sobel weight of 2
    wire [15:0] mult_p12, mult_p10, mult_p01, mult_p21;

`ifdef USE_EXACT_MULT
    // Standard Exact Multipliers
    ExactMult m0 (.a(p12), .b(8'd2), .result(mult_p12));
    ExactMult m1 (.a(p10), .b(8'd2), .result(mult_p10));
    ExactMult m2 (.a(p01), .b(8'd2), .result(mult_p01));
    ExactMult m3 (.a(p21), .b(8'd2), .result(mult_p21));
`else
    // Logarithmic Multipliers
    LogMult m0 (.a(p12), .b(8'd2), .result(mult_p12));
    LogMult m1 (.a(p10), .b(8'd2), .result(mult_p10));
    LogMult m2 (.a(p01), .b(8'd2), .result(mult_p01));
    LogMult m3 (.a(p21), .b(8'd2), .result(mult_p21));
`endif

    // Pipeline Registers for Gradient Calculation (Driven by gated_clk)
    reg signed [15:0] gx, gy;
    reg [15:0] g_abs;

    always @(posedge gated_clk or posedge rst) begin
        if (rst) begin
            gx    <= 16'sd0;
            gy    <= 16'sd0;
            g_abs <= 16'd0;
        end else begin
            gx <= $signed({1'b0, p02}) + $signed({1'b0, mult_p12[7:0]}) + $signed({1'b0, p22}) - 
                  ($signed({1'b0, p00}) + $signed({1'b0, mult_p10[7:0]}) + $signed({1'b0, p20}));
                  
            gy <= $signed({1'b0, p00}) + $signed({1'b0, mult_p01[7:0]}) + $signed({1'b0, p02}) - 
                  ($signed({1'b0, p20}) + $signed({1'b0, mult_p21[7:0]}) + $signed({1'b0, p22}));

            g_abs <= ((gx < 0) ? -gx : gx) + ((gy < 0) ? -gy : gy);
        end
    end

    // Scaled 8-bit magnitude to prevent 16-bit threshold overflow
    wire [7:0] mag_8bit = (g_abs > 16'd255) ? 8'hFF : g_abs[7:0];

    // Dynamic Adaptive Thresholding Instance
    wire [15:0] adaptive_thresh_full;
    wire [7:0]  scaled_thresh;

    AdaptiveThreshold thresh_inst (
        .clk(gated_clk),
        .rst(rst),
        .mag_p00({8'd0, mag_8bit}), .mag_p01({8'd0, mag_8bit}), .mag_p02({8'd0, mag_8bit}),
        .mag_p10({8'd0, mag_8bit}), .mag_p11({8'd0, mag_8bit}), .mag_p12({8'd0, mag_8bit}),
        .mag_p20({8'd0, mag_8bit}), .mag_p21({8'd0, mag_8bit}), .mag_p22({8'd0, mag_8bit}),
        .alpha_offset(threshold),
        .adaptive_thresh(adaptive_thresh_full)
    );

    // Saturation logic for threshold output
    assign scaled_thresh = (adaptive_thresh_full > 16'd255) ? 8'hFF : adaptive_thresh_full[7:0];

    // NMS Instantiation
    NMS nms_inst (
        .clk(gated_clk),
        .rst(rst),
        .mag_p00(g_abs), .mag_p01(g_abs), .mag_p02(g_abs),
        .mag_p10(g_abs), .mag_p11(g_abs), .mag_p12(g_abs),
        .mag_p20(g_abs), .mag_p21(g_abs), .mag_p22(g_abs),
        .gx_p11(gx),
        .gy_p11(gy),
        .threshold(scaled_thresh),
        .nms_edge_out(edge_out)
    );

endmodule