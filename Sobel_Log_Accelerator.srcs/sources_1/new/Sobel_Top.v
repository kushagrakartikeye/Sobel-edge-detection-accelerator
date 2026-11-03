`timescale 1ns / 1ps

module Sobel_Top (
    input  wire       clk,          // 100MHz system clock
    input  wire       rst,          // CPU RESET button (C12 - Active Low)
    input  wire       enable,       // Switch SW0 (J15)
    input  wire [7:0] threshold,    // Switches SW1-SW8
    input  wire       uart_rxd,     // UART RX pin (C4)
    output wire       uart_txd,     // UART TX pin (D4)
    output wire       edge_out      // LED LD0 (H17)
);

    // Internal active-high reset derived from active-low pin C12
    wire internal_rst = ~rst;

    // UART Signals
    wire [7:0] rx_data;
    wire       rx_done;
    reg        tx_start;
    reg  [7:0] tx_data;
    wire       tx_busy;

    // TX FIFO Signals (Deep FIFO to prevent dropping bytes during high-speed burst streaming)
    reg  [7:0] tx_fifo [0:255];
    reg  [7:0] tx_fifo_wr_ptr = 8'd0;
    reg  [7:0] tx_fifo_rd_ptr = 8'd0;
    wire       tx_fifo_empty = (tx_fifo_wr_ptr == tx_fifo_rd_ptr);
    reg        tx_sending    = 1'b0;

    // 3x3 Sliding Window Registers for Pixel Stream
    reg [7:0] row0_0, row0_1, row0_2;
    reg [7:0] row1_0, row1_1, row1_2;
    reg [7:0] row2_0, row2_1, row2_2;

    wire core_edge_out;

    // Instantiate Core Sobel Filter Accelerator
    SobelFilter uut (
        .clk(clk),
        .rst(internal_rst),
        .enable(enable),
        .threshold(threshold),
        .p00(row0_0), .p01(row0_1), .p02(row0_2),
        .p10(row1_0),            .p12(row1_2),
        .p20(row2_0), .p21(row2_1), .p22(row2_2),
        .edge_out(core_edge_out)
    );

    assign edge_out = core_edge_out;

    // 1. Sliding window shift and writing into TX FIFO
    always @(posedge clk or posedge internal_rst) begin
        if (internal_rst) begin
            row0_0 <= 8'd0; row0_1 <= 8'd0; row0_2 <= 8'd0;
            row1_0 <= 8'd0; row1_1 <= 8'd0; row1_2 <= 8'd0;
            row2_0 <= 8'd0; row2_1 <= 8'd0; row2_2 <= 8'd0;
            tx_fifo_wr_ptr <= 8'd0;
        end else begin
            if (rx_done && enable) begin
                // Slide window horizontally and vertically
                row0_0 <= row0_1; row0_1 <= row0_2; row0_2 <= row1_0;
                row1_0 <= row1_1; row1_1 <= row1_2; row1_2 <= row2_0;
                row2_0 <= row2_1; row2_1 <= row2_2; row2_2 <= rx_data;

                // Push processed result into TX FIFO queue
                tx_fifo[tx_fifo_wr_ptr] <= core_edge_out ? 8'hFF : 8'h00;
                tx_fifo_wr_ptr          <= tx_fifo_wr_ptr + 1'b1;
            end
        end
    end

    // 2. Automated TX FIFO Controller to feed UART Transmitter without dropping bytes
    always @(posedge clk or posedge internal_rst) begin
        if (internal_rst) begin
            tx_start       <= 1'b0;
            tx_data        <= 8'd0;
            tx_fifo_rd_ptr <= 8'd0;
            tx_sending     <= 1'b0;
        end else begin
            tx_start <= 1'b0; // default single-cycle pulse

            if (!tx_sending) begin
                if (!tx_fifo_empty && !tx_busy) begin
                    tx_data        <= tx_fifo[tx_fifo_rd_ptr];
                    tx_start       <= 1'b1;
                    tx_fifo_rd_ptr <= tx_fifo_rd_ptr + 1'b1;
                    tx_sending     <= 1'b1;
                end
            end else begin
                if (tx_busy) begin
                    tx_sending <= 1'b0;
                end
            end
        end
    end

    // UART Receiver (115200 baud at 100MHz clock -> 868 clks per bit)
    uart_rx #(.CLKS_PER_BIT(868)) u_uart_rx (
        .clk(clk),
        .rst(internal_rst),
        .rx(uart_rxd),
        .data_out(rx_data),
        .rx_done(rx_done)
    );

    // UART Transmitter
    uart_tx #(.CLKS_PER_BIT(868)) u_uart_tx (
        .clk(clk),
        .rst(internal_rst),
        .tx_start(tx_start),
        .data_in(tx_data),
        .tx(uart_txd),
        .tx_busy(tx_busy)
    );

endmodule


// =========================================================================
// UART Receiver Module
// =========================================================================
module uart_rx #(parameter CLKS_PER_BIT = 868) (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] data_out,
    output reg        rx_done
);
    localparam S_IDLE = 2'b00, S_RX_START = 2'b01, S_RX_DATA = 2'b10, S_RX_STOP = 2'b11;
    reg [1:0] state = S_IDLE;
    reg [15:0] clk_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] rx_byte = 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            rx_done <= 0;
            data_out <= 0;
            clk_count <= 0;
            bit_index <= 0;
        end else begin
            rx_done <= 0;
            case (state)
                S_IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;
                    if (rx == 1'b0) state <= S_RX_START;
                end
                S_RX_START: begin
                    if (clk_count == (CLKS_PER_BIT / 2)) begin
                        if (rx == 1'b0) begin
                            clk_count <= 0;
                            state <= S_RX_DATA;
                        end else begin
                            state <= S_IDLE;
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
                S_RX_DATA: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        rx_byte[bit_index] <= rx;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state <= S_RX_STOP;
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
                S_RX_STOP: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        data_out <= rx_byte;
                        rx_done <= 1'b1;
                        state <= S_IDLE;
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
            endcase
        end
    end
endmodule


// =========================================================================
// UART Transmitter Module
// =========================================================================
module uart_tx #(parameter CLKS_PER_BIT = 868) (
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_start,
    input  wire [7:0] data_in,
    output reg        tx,
    output reg        tx_busy
);
    localparam S_IDLE = 2'b00, S_TX_START = 2'b01, S_TX_DATA = 2'b10, S_TX_STOP = 2'b11;
    reg [1:0] state = S_IDLE;
    reg [15:0] clk_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] tx_data = 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            tx <= 1'b1;
            tx_busy <= 1'b0;
            clk_count <= 0;
            bit_index <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    tx <= 1'b1;
                    tx_busy <= 1'b0;
                    clk_count <= 0;
                    bit_index <= 0;
                    if (tx_start) begin
                        tx_data <= data_in;
                        tx_busy <= 1'b1;
                        state <= S_TX_START;
                    end
                end
                S_TX_START: begin
                    tx <= 1'b0;
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        state <= S_TX_DATA;
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
                S_TX_DATA: begin
                    tx <= tx_data[bit_index];
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state <= S_TX_STOP;
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
                S_TX_STOP: begin
                    tx <= 1'b1;
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        tx_busy <= 1'b0;
                        state <= S_IDLE;
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
            endcase
        end
    end
endmodule