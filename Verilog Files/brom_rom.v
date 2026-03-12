module bram_rom #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 784,
    parameter ADDR_WIDTH = 10,
    parameter INIT_FILE  = ""
)(
    input clk,
    input [ADDR_WIDTH-1:0] addr,
    output reg signed [DATA_WIDTH-1:0] data_out
);
    reg signed [DATA_WIDTH-1:0] memory [0:DEPTH-1];
    initial begin
        if (INIT_FILE != "") $readmemh(INIT_FILE, memory);
    end
    always @(posedge clk) begin
        data_out <= memory[addr];
    end
endmodule
