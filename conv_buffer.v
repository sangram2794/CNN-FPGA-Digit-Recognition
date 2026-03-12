module conv_buffer (
    input clk,
    input        write_en,
    input [9:0]  write_addr,
    input signed [7:0]  write_data,
    input [9:0]  read_addr,
    output reg signed [7:0] read_data
);
    reg signed [7:0] buf [0:675];

    always @(posedge clk) begin
        if (write_en)
            buf[write_addr] <= write_data;
        read_data <= buf[read_addr];
    end
endmodule
