`timescale 1ns / 1ps

module AdaptiveThreshold (
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] mag_p00, mag_p01, mag_p02,
    input  wire [15:0] mag_p10, mag_p11, mag_p12,
    input  wire [15:0] mag_p20, mag_p21, mag_p22,
    input  wire [7:0]  alpha_offset,
    output reg  [15:0] adaptive_thresh
);

    reg [19:0] sum_mag;
    wire [15:0] local_mean;

    // Fast shift approximation for division by 9: (sum >> 3) - (sum >> 6)
    assign local_mean = (sum_mag >> 3) - (sum_mag >> 6);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum_mag         <= 20'd0;
            adaptive_thresh <= 16'd0;
        end else begin
            // Adder tree for 3x3 magnitude neighborhood
            sum_mag <= mag_p00 + mag_p01 + mag_p02 +
                       mag_p10 + mag_p11 + mag_p12 +
                       mag_p20 + mag_p21 + mag_p22;

            // Compute local mean plus offset
            adaptive_thresh <= local_mean + alpha_offset;
        end
    end

endmodule