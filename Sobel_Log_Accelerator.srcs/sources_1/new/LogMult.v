module LogMult (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [15:0] result
);
    wire [3:0] msb_a, msb_b;
    
    assign msb_a = a[7] ? 4'd7 : a[6] ? 4'd6 : a[5] ? 4'd5 : a[4] ? 4'd4 :
                   a[3] ? 4'd3 : a[2] ? 4'd2 : a[1] ? 4'd1 : 4'd0;
                   
    assign msb_b = b[7] ? 4'd7 : b[6] ? 4'd6 : b[5] ? 4'd5 : b[4] ? 4'd4 :
                   b[3] ? 4'd3 : b[2] ? 4'd2 : b[1] ? 4'd1 : 4'd0;

    wire [4:0] sum_msb = msb_a + msb_b;
    
    assign result = (a == 0 || b == 0) ? 16'd0 : (1'b1 << sum_msb);
endmodule