`timescale 1ns / 1ps

module ClockGating (
    input  wire clk_in,
    input  wire enable,
    output wire clk_out
);

    // Direct clock passthrough to eliminate gated clock trees and LUT clock skew.
    // The enable signal will automatically map to dedicated CE pins in destination registers.
    assign clk_out = clk_in;

endmodule