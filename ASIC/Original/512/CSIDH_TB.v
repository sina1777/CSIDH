


module CSIDH_TB(

    );
    
     // Parameters
    parameter N = 512;                        // Prime bit-width
    parameter word_size = 32;
    parameter p = 512'h65b48e8f740f89bffc8ab0d15e3e4c4ab42d083aedc88c425afbfcc69322c9cda7aac6c567f35507516730cc1f0b4f25c2721bf457aca8351b81b90533c6c87b;  // CSIDH-512 prime
    parameter p_inv = 512'hd8c3904b18371bcd3512da337a97b3451232b9eb013dee1eb081b3aba7d05f8534ed3ea7f1de34c4f6fe2bc33e915395fe025ed7d0d3b1aa66c1301f632e294d;  // Precomputed (-p)^-1 mod 2^512
    parameter fp1 = 512'h3496e2e117e0ec8006ea9e5d4383676a97a5ef8a246ee77b4a080672d9ba6c64b0aa7275301955f15d319e67c1e961b47b1bc81750a6af95c8fc8df598726f0a;
    parameter p_minus_1_halves = 512'h32da4747ba07c4dffe455868af1f26255a16841d76e446212d7dfe63499164e6d3d56362b3f9aa83a8b398660f85a792e1390dfa2bd6541a8dc0dc8299e3643d;
    parameter NUM_PRIMES = 74;
    parameter cost_ratio_inv_mul = 128;

    // Signals
    reg clk;
    reg rst;
    wire done;
    reg [N-1:0] A_in;
    reg [295:0] private;
    wire [N-1:0] A_out;
    wire invalid;          // Ready signal when computation is done

     
    
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
        .rst(rst),
        .done(done),
        .A_in(A_in),
	.A_out(A_out),
        .private(private),
	.invalid(invalid)
    );

    // Clock generation
    always begin
        #5 clk = ~clk; // 10 ns clock period
    end

    // Stimulus process
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
	                          

        // Apply reset
        #10  // Deassert reset after 10 ns
        // Test 1: Apply a random 2048-bit input u
        
	
        A_in = 512'h0;               // u[127:64]
	private = 296'h45442401512052214345445234144121421111510445444112400341554250151454440214;                       // u[191:128]
	//private	= 296'h00000000000000000000000000000000000000000000000000001000000000000000000000;
        
        
	#100 rst = 0;
    end

    // Monitor signals
endmodule