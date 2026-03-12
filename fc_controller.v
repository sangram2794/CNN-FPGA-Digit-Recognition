module fc_controller (
    input  clk, reset, start,
    output reg mac_enable,
    output reg mac_reset,
    output reg [9:0] mem_addr,
    output reg [3:0] neuron_idx,
    output reg done
);
    localparam IDLE=2'd0, CALC=2'd1, NEXT=2'd2, DONE=2'd3;
    reg [1:0] state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            mem_addr   <= 0;
            neuron_idx <= 0;
        end else begin
            case (state)
                IDLE: begin
                    mem_addr   <= 0;
                    neuron_idx <= 0;
                    if (start) state <= CALC;
                end
                CALC: begin
                    if (mem_addr == 10'd675) begin
                        mem_addr <= 0;
                        state    <= NEXT;
                    end else
                        mem_addr <= mem_addr + 1;
                end
                NEXT: begin
                    if (neuron_idx == 4'd9)
                        state <= DONE;
                    else begin
                        neuron_idx <= neuron_idx + 1;
                        state      <= CALC;
                    end
                end
                DONE: state <= IDLE;
            endcase
        end
    end

    always @(*) begin
        mac_enable = (state == CALC);
        mac_reset  = (state == IDLE) || (state == NEXT);
        done       = (state == DONE);
    end
endmodule

