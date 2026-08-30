`timescale 1ns / 1ps

module ExactMult (
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    output wire [15:0] result
);

    // Standard exact hardware multiplication
    assign result = a * b;

endmodule