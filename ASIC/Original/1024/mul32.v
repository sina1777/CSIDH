// 32x32 Unsigned Multiplier - Final Corrected Version
module mul32 (
    input  wire         clk,
    input  wire [31:0]  A,
    input  wire [31:0]  B,
    output reg  [63:0]  C = 64'd0 // Initialize C to prevent simulation 'x'
);

    // Treat inputs as 33-bit signed numbers for correct unsigned multiplication
    wire signed [32:0] a_signed = {1'b0, A};
    wire signed [33:0] b_signed_padded = {{1'b0, B}, 1'b0};

    // 17 partial products, 66 bits wide
    wire signed [65:0] pp [0:16];

    // Pipeline Registers
    reg signed [65:0] stage1_sum_reg;
    reg signed [65:0] pp_stage2_reg [9:16]; 

    // Combinational Logic: Booth PP Generation for pp[0] through pp[15]
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : booth_pp_gen
            assign pp[i] = (b_signed_padded[2*i+2:2*i] == 3'b000) ? 66'd0 :
                           (b_signed_padded[2*i+2:2*i] == 3'b001) ? {{33{a_signed[32]}}, a_signed} << (2*i) :
                           (b_signed_padded[2*i+2:2*i] == 3'b010) ? {{33{a_signed[32]}}, a_signed} << (2*i) :
                           (b_signed_padded[2*i+2:2*i] == 3'b011) ? {{32{a_signed[32]}}, a_signed, 1'b0} << (2*i) :
                           (b_signed_padded[2*i+2:2*i] == 3'b100) ? -({{32{a_signed[32]}}, a_signed, 1'b0} << (2*i)) :
                           (b_signed_padded[2*i+2:2*i] == 3'b101) ? -({{33{a_signed[32]}}, a_signed} << (2*i)) :
                           (b_signed_padded[2*i+2:2*i] == 3'b110) ? -({{33{a_signed[32]}}, a_signed} << (2*i)) :
                           66'd0;
        end
    endgenerate

    // ** BUG FIX: Special case for the final partial product pp[16] **
    // This prevents reading out of bounds. The window is formed from the last two
    // bits of the multiplier, with the MSB correctly sign-extended.
    wire signed [2:0] final_window = {b_signed_padded[33], b_signed_padded[33], b_signed_padded[32]};
    assign pp[16] = (final_window == 3'b000) ? 66'd0 :
                    (final_window == 3'b001) ? {{33{a_signed[32]}}, a_signed} << 32 :
                    (final_window == 3'b010) ? {{33{a_signed[32]}}, a_signed} << 32 :
                    (final_window == 3'b011) ? {{32{a_signed[32]}}, a_signed, 1'b0} << 32 :
                    (final_window == 3'b100) ? -({{32{a_signed[32]}}, a_signed, 1'b0} << 32) :
                    (final_window == 3'b101) ? -({{33{a_signed[32]}}, a_signed} << 32) :
                    (final_window == 3'b110) ? -({{33{a_signed[32]}}, a_signed} << 32) :
                    66'd0;

    // == STAGE 1: Latch first part of the sum and second set of PPs ==
    always @(posedge clk) begin
        stage1_sum_reg <= pp[0] + pp[1] + pp[2] + pp[3] + pp[4] +
                          pp[5] + pp[6] + pp[7] + pp[8];
        
        pp_stage2_reg[9]  <= pp[9];
        pp_stage2_reg[10] <= pp[10];
        pp_stage2_reg[11] <= pp[11];
        pp_stage2_reg[12] <= pp[12];
        pp_stage2_reg[13] <= pp[13];
        pp_stage2_reg[14] <= pp[14];
        pp_stage2_reg[15] <= pp[15];
        pp_stage2_reg[16] <= pp[16];
    end

    // == STAGE 2: Final Addition ==
    always @(posedge clk) begin
        C <= (stage1_sum_reg + pp_stage2_reg[9]  + pp_stage2_reg[10] + 
                               pp_stage2_reg[11] + pp_stage2_reg[12] +
                               pp_stage2_reg[13] + pp_stage2_reg[14] + 
                               pp_stage2_reg[15] + pp_stage2_reg[16]);
    end

endmodule
