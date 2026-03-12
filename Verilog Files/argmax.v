module argmax (
    input clk,
    input reset,
    input write_en,
    input [3:0] neuron_idx,
    input signed [19:0] score,
    output reg [3:0] best_digit
);
    reg signed [19:0] best_score;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            best_score <= -20'sh80000;
            best_digit <= 0;
        end else if (write_en) begin
            if (score > best_score) begin
                best_score <= score;
                best_digit <= neuron_idx;
            end
        end
    end
endmodule
