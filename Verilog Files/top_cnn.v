module top_cnn (
    input        CLOCK_50,
    input [3:0]  KEY,
    output [6:0] HEX0,
    output       LEDG0,
    output [17:0] LEDR
);
    wire clk   = CLOCK_50;
    wire reset = ~KEY[0];
    wire start = ~KEY[1];

    // ── CONV STAGE ───────────────────────────────────────────────────
    wire [9:0] pixel_addr;
    wire [3:0] weight_addr;
    wire       conv_mac_en, conv_mac_rst;
    wire       conv_out_valid;
    wire [9:0] conv_out_idx;
    wire       conv_done;
    wire signed [7:0]  pixel_data, conv_w_data;
    wire signed [19:0] conv_result;

    conv_controller conv_fsm (
        .clk(clk), .reset(reset), .start(start),
        .pixel_addr(pixel_addr),
        .weight_addr(weight_addr),
        .mac_enable(conv_mac_en),
        .mac_reset(conv_mac_rst),
        .conv_out_valid(conv_out_valid),
        .out_idx(conv_out_idx),
        .done(conv_done)
    );

    // *** CHANGE THIS LINE TO SWITCH IMAGES ***
    bram_rom #(.DATA_WIDTH(8), .DEPTH(784), .ADDR_WIDTH(10),
               .INIT_FILE("image_1_label_7.mem"))
    image_mem (.clk(clk), .addr(pixel_addr), .data_out(pixel_data));

    bram_rom #(.DATA_WIDTH(8), .DEPTH(9), .ADDR_WIDTH(4),
               .INIT_FILE("conv_weights.mem"))
    conv_w_mem (.clk(clk), .addr(weight_addr), .data_out(conv_w_data));

    mac_unit conv_mac (
        .clk(clk), .reset(conv_mac_rst), .enable(conv_mac_en),
        .pixel(pixel_data), .weight(conv_w_data),
        .accumulator(conv_result)
    );

    // Scale conv result to 8-bit for buffer
    wire signed [7:0] conv_scaled = conv_result[15:8];

    // ── CONV BUFFER ──────────────────────────────────────────────────
    wire [9:0]       fc_pixel_addr;
    wire signed [7:0] fc_pixel_data;

    conv_buffer cbuf (
        .clk(clk),
        .write_en(conv_out_valid),
        .write_addr(conv_out_idx),
        .write_data(conv_scaled),
        .read_addr(fc_pixel_addr),
        .read_data(fc_pixel_data)
    );

    // ── FC STAGE ─────────────────────────────────────────────────────
    wire        fc_mac_en, fc_mac_rst;
    wire [3:0]  fc_neuron_idx;
    wire signed [7:0]  fc_w_data;
    wire signed [19:0] fc_result;
    wire        fc_done;

    wire [13:0] fc_w_addr = ({10'd0, fc_neuron_idx} * 14'd676)
                           + {4'd0, fc_pixel_addr};

    fc_controller fc_fsm (
        .clk(clk), .reset(reset),
        .start(conv_done),
        .mac_enable(fc_mac_en),
        .mac_reset(fc_mac_rst),
        .mem_addr(fc_pixel_addr),
        .neuron_idx(fc_neuron_idx),
        .done(fc_done)
    );

    bram_rom #(.DATA_WIDTH(8), .DEPTH(6760), .ADDR_WIDTH(14),
               .INIT_FILE("fc_weights.mem"))
    fc_w_mem (.clk(clk), .addr(fc_w_addr), .data_out(fc_w_data));

    mac_unit fc_mac (
        .clk(clk), .reset(fc_mac_rst), .enable(fc_mac_en),
        .pixel(fc_pixel_data),
        .weight(fc_w_data),
.accumulator(fc_result)
    );

    // ── ARGMAX ───────────────────────────────────────────────────────
    reg fc_mac_rst_prev;
    always @(posedge clk) fc_mac_rst_prev <= fc_mac_rst;
    wire neuron_done = fc_mac_rst & ~fc_mac_rst_prev & ~fc_done;

    wire [3:0] best_digit;

    argmax argmax_unit (
        .clk(clk), .reset(reset),
        .write_en(neuron_done),
        .neuron_idx(fc_neuron_idx),
        .score(fc_result),
        .best_digit(best_digit)
    );
    // ── OUTPUT ───────────────────────────────────────────────────────
    seg7_decoder disp (.digit(best_digit), .seg(HEX0));
    assign LEDG0      = fc_done;
    assign LEDR[3:0]  = best_digit;
    assign LEDR[17:4] = 14'd0;
endmodule
