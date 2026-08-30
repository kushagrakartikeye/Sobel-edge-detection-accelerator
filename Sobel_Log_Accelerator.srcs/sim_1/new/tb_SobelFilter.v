`timescale 1ns / 1ps

module tb_SobelFilter;
    reg clk;
    reg rst;
    reg [7:0] p00, p01, p02;
    reg [7:0] p10,      p12;
    reg [7:0] p20, p21, p22;
    reg [7:0] threshold;
    wire edge_out;

    // Instantiate Unit Under Test (UUT)
    SobelFilter uut (
        .clk(clk),
        .rst(rst),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10),           .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .threshold(threshold),
        .edge_out(edge_out)
    );

    // Clock generation (100 MHz)
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        threshold = 8'd50;
        
        // Initialize uniform region (no edge expected)
        p00=10; p01=10; p02=10;
        p10=10;         p12=10;
        p20=10; p21=10; p22=10;
        
        #20 rst = 0;
        
        // Test vertical edge transition
        #20;
        p00=0;  p01=0;  p02=255;
        p10=0;          p12=255;
        p20=0;  p21=0;  p22=255;

        #40;
        $finish;
    end
endmodule