`timescale 1ns / 1ps

module tb_Sobel_Image;
    reg clk = 0;
    reg rst = 1;
    reg [7:0] threshold = 8'd40;
    
    reg [7:0] img_mem [0:16383];
    reg [7:0] p00, p01, p02, p10, p12, p20, p21, p22;
    wire edge_out;
    
    integer file_out, x, y;

    SobelFilter uut (
        .clk(clk), .rst(rst),
        .p00(p00), .p01(p01), .p02(p02),
        .p10(p10),           .p12(p12),
        .p20(p20), .p21(p21), .p22(p22),
        .threshold(threshold),
        .edge_out(edge_out)
    );

    always #5 clk = ~clk;

    initial begin
        $readmemh("image_in.hex", img_mem);
        file_out = $fopen("image_out.hex", "w");
        
        #20 rst = 0;

        for (y = 1; y < 127; y = y + 1) begin
            for (x = 1; x < 127; x = x + 1) begin
                @(posedge clk);
                p00 <= img_mem[(y-1)*128 + (x-1)];
                p01 <= img_mem[(y-1)*128 + x];
                p02 <= img_mem[(y-1)*128 + (x+1)];
                
                p10 <= img_mem[y*128 + (x-1)];
                p12 <= img_mem[y*128 + (x+1)];
                
                p20 <= img_mem[(y+1)*128 + (x-1)];
                p21 <= img_mem[(y+1)*128 + x];
                p22 <= img_mem[(y+1)*128 + (x+1)];

                @(posedge clk);
                $fdisplay(file_out, "%d", edge_out ? 255 : 0);
            end
        end

        $fclose(file_out);
        $display("SIMULATION COMPLETE: image_out.hex generated.");
        $finish;
    end
endmodule