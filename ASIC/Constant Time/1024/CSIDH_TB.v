


module CSIDH_TB(

    );
    
     // Parameters
    parameter N = 1024;                        // Prime bit-width
    parameter word_size = 32;
    parameter p = 1024'h0ece55ed427012a9d89dec879007ebd7216c22bc86f21a080683cf25db31ad5bf06de2471cf9386e4d6c594a8ad82d2df811d9c419ec83297611ad4f90441c800978dbeed90a2b58b97c56d1de81ede56b317c5431541f40642aca4d5a313709c2cab6a0e287f1bd514ba72cb8d89fd3a1d81eebbc3d344ddbe34c5460e36453;  // CSIDH-512 prime
    parameter p_inv = 1024'he6b14ff7a8473e0a0dd4b06020e7d66c69a7664077c881339e0ec706aceba3b22071fcf91a8e874db4ca0a3acd608970bc448a790ae4ead38440b17a6335f826a93ab1dd3f816e35e6d7f7ff7198303c2107172bba71ff71b74d3be5b4035fb49cc0eff5aa616b6e393ac935721044ea900965ed4020071fd2c2c24160038025; // Precomputed (-p)^-1 mod 2^512  // Precomputed (-p)^-1 mod 2^512
    parameter fp1 = 1024'h 044c4b3e968ec2b89d834aff6f7956b6c7d1b17b09ec4577913f3e7c71b37ce508b3f947137340acdbce120cc7a4fff286d089fa474b4a3f28d37db76b7a1b7f5ef9652396531f1baebe3c10395f33c3e1b6be68b969ecb9592890dd02bb585a1089df50f4f8f26d99f9e607b99d62f240a5f2587fef86d465e7ee6590e6567d;
    parameter p_minus_1_halves = 1024'h07672af6a1380954ec4ef643c803f5eb90b6115e43790d040341e792ed98d6adf836f1238e7c9c3726b62ca5456c1696fc08ece20cf64194bb08d6a7c8220e4004bc6df76c8515ac5cbe2b68ef40f6f2b598be2a18aa0fa032156526ad189b84e1655b507143f8dea8a5d3965c6c4fe9d0ec0f75de1e9a26edf1a62a3071b229;
    parameter NUM_PRIMES = 130;
    parameter cost_ratio_inv_mul = 1536;

    // Signals
    reg clk;
    reg rst;
    wire done;
    reg [N-1:0] A_in;
    reg [519:0] private;
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
	//private = 520'h1212112122222221122122012020112122121010121110200211102212211121012112122221212120211121122011212200212221021112221201110211212110;                       // u[191:128]
	private	= 520'h0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111;
        
        
	#100 rst = 0;
    end

    // Monitor signals
endmodule