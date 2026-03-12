module mac_unit (
    input clk,
    input reset,
    input enable,
    input signed [7:0] pixel,
    input signed [7:0] weight,
    output reg signed [19:0] accumulator
);
    always @(posedge clk or posedge reset) begin
        if (reset) accumulator <= 20'd0;
        else if (enable) accumulator <= accumulator + (pixel * weight);
    end
endmodule
