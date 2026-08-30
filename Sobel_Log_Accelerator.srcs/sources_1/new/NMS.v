`timescale 1ns / 1ps

module NMS (
    input wire clk,
    input wire rst,
    input wire [15:0] mag_p00, mag_p01, mag_p02,
    input wire [15:0] mag_p10, mag_p11, mag_p12,
    input wire [15:0] mag_p20, mag_p21, mag_p22,
    input wire signed [15:0] gx_p11,
    input wire signed [15:0] gy_p11,
    input wire [7:0] threshold,
    output reg nms_edge_out
);

    wire [15:0] abs_gx = (gx_p11 < 0) ? -gx_p11 : gx_p11;
    wire [15:0] abs_gy = (gy_p11 < 0) ? -gy_p11 : gy_p11;

    // Estimate gradient sector using ratio thresholds without trigonometry
    wire dir_0   = (abs_gy <= ((abs_gx * 3) >> 3));
    wire dir_90  = (abs_gy >= ((abs_gx * 19) >> 3));
    wire dir_45  = !dir_0 && !dir_90 && ((gx_p11 > 0 && gy_p11 > 0) || (gx_p11 < 0 && gy_p11 < 0));
    wire dir_135 = !dir_0 && !dir_90 && !dir_45;

    reg is_max;

    always @(*) begin
        if (mag_p11 < threshold) begin
            is_max = 1'b0;
        end else if (dir_0) begin
            is_max = (mag_p11 >= mag_p10) && (mag_p11 >= mag_p12);
        end else if (dir_90) begin
            is_max = (mag_p11 >= mag_p01) && (mag_p11 >= mag_p21);
        end else if (dir_45) begin
            is_max = (mag_p11 >= mag_p02) && (mag_p11 >= mag_p20);
        end else begin
            is_max = (mag_p11 >= mag_p00) && (mag_p11 >= mag_p22);
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst)
            nms_edge_out <= 1'b0;
        else
            nms_edge_out <= is_max;
    end

endmodule