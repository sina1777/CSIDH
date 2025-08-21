


module CSIDH_Top #(
    parameter N = 512,                          // Prime bit-width
    parameter word_size = 32,
    parameter p = 512'h65b48e8f740f89bffc8ab0d15e3e4c4ab42d083aedc88c425afbfcc69322c9cda7aac6c567f35507516730cc1f0b4f25c2721bf457aca8351b81b90533c6c87b,  // CSIDH-512 prime
    parameter p_inv = 512'hd8c3904b18371bcd3512da337a97b3451232b9eb013dee1eb081b3aba7d05f8534ed3ea7f1de34c4f6fe2bc33e915395fe025ed7d0d3b1aa66c1301f632e294d,  // Precomputed (-p)^-1 mod 2^512
    parameter fp1 = 512'h3496e2e117e0ec8006ea9e5d4383676a97a5ef8a246ee77b4a080672d9ba6c64b0aa7275301955f15d319e67c1e961b47b1bc81750a6af95c8fc8df598726f0a,
    parameter p_minus_1_halves = 512'h32da4747ba07c4dffe455868af1f26255a16841d76e446212d7dfe63499164e6d3d56362b3f9aa83a8b398660f85a792e1390dfa2bd6541a8dc0dc8299e3643d,
    parameter NUM_PRIMES = 74,
    parameter cost_ratio_inv_mul = 128,
    parameter chunk = N/64
) (
    input wire clk,
    input wire rst,
    input wire [63:0] in,
    output reg [63:0] out,
    output reg done,
    output wire invalid
);

reg [6:0] counter;
reg [3:0] state; 
reg [N-1:0] A_in;
wire [N-1:0] A_out;
reg rst_CSIDH;
wire done_CSIDH;
reg [295:0] private;
    
    // Instantiate the Barrett Reduction FSM
    CSIDH #(
        .word_size(word_size),
        .N(N),
	.p(p),
	.p_inv(p_inv),
	.fp1(fp1),
	.p_minus_1_halves(p_minus_1_halves),
	.NUM_PRIMES(NUM_PRIMES),
	.cost_ratio_inv_mul(cost_ratio_inv_mul)
    ) uut (
        .clk(clk),
        .rst(rst_CSIDH),
        .done(done_CSIDH),
        .A_in(A_in),
	.A_out(A_out),
        .private(private),
	.invalid(invalid)
    );

always@(posedge clk) begin
	if (rst) begin
		A_in <= 0;
		counter <= 0;
		rst_CSIDH <= 1'b1;
		state <= 4'b0000;
	end
	else begin
		case (state)
		4'b0000: begin
			A_in[64*counter + 63 -: 64] <= in;
			counter <= counter + 1'b1;
			if (counter == (chunk-1'b1)) begin
				state <= 4'b0001;
				counter <= 0; 
			end
			else begin

			end
		end
		4'b0001: begin
			private[64*counter + 63 -: 64] <= in;
			counter <= counter + 1'b1;
			if (counter == 7'b0000101) begin
				state <= 4'b0010;
				counter <= 0; 
			end
			else begin

			end
		end
		4'b0010: begin
			rst_CSIDH <= 1'b0;
			if (done) begin
				state <= 4'b0011;
			end
			else begin
			end
		end
		4'b0011: begin
			out <= A_out[64*counter + 63 -: 64];
			counter <= counter + 1'b1;
			if (counter == (chunk-1'b1)) begin
				done <= 1'b1;
				 
			end
			else begin

			end
		end
		endcase
	
	end
end

    // Monitor signals
endmodule
