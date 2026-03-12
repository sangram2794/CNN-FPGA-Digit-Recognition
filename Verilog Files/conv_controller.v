module conv_controller (
    input  clk, reset, start,
    output reg [9:0] pixel_addr,
    output reg [3:0] weight_addr,
    output reg mac_enable,
    output reg mac_reset,
    output reg conv_out_valid,
    output reg [9:0] out_idx,
    output reg done
);
    reg [4:0] out_row, out_col;
    reg [3:0] tap;

    wire [4:0] tap_row = tap / 3;
    wire [4:0] tap_col = tap % 3;

    localparam IDLE=2'd0, CALC=2'd1, SAVE=2'd2, DONE=2'd3;
    reg [1:0] state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            out_row <= 0; out_col <= 0; tap <= 0;
            out_idx <= 0;
            pixel_addr <= 0; weight_addr <= 0;
            mac_enable <= 0; mac_reset <= 1;
            conv_out_valid <= 0; done <= 0;
        end else begin
            conv_out_valid <= 0;
            done           <= 0;
            mac_enable     <= 0;
            mac_reset      <= 0;

            case (state)
                IDLE: begin
                    mac_reset <= 1;
                    out_row <= 0; out_col <= 0;
                    tap <= 0; out_idx <= 0;
                    if (start) state <= CALC;
                end

                CALC: begin
                    pixel_addr  <= (out_row + tap_row) * 28
                                  + (out_col + tap_col);
                    weight_addr <= tap;
                    mac_enable  <= 1;
                    if (tap == 4'd8)
                        state <= SAVE;
                    else
                        tap <= tap + 1;
                end

                SAVE: begin
                    conv_out_valid <= 1;
                    mac_reset      <= 1;
                    tap            <= 0;
                    if (out_col == 5'd25) begin
                        out_col <= 0;
                        if (out_row == 5'd25)
                            state <= DONE;
                        else begin
                            out_row <= out_row + 1;
                            out_idx <= out_idx + 1;
                            state   <= CALC;
                        end
                    end else begin
                        out_col <= out_col + 1;
                        out_idx <= out_idx + 1;
                        state   <= CALC;
                    end
                end

                DONE: begin
                    done  <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
