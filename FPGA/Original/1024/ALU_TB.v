


module ALU_TB(

    );
    
   // Parameters
    parameter word_size = 32;        // Size of each word (base b = 2^32)
    parameter N = 1024;         // Number of bits in modulus N (1024 bits)
     parameter p = 1024'h0ece55ed427012a9d89dec879007ebd7216c22bc86f21a080683cf25db31ad5bf06de2471cf9386e4d6c594a8ad82d2df811d9c419ec83297611ad4f90441c800978dbeed90a2b58b97c56d1de81ede56b317c5431541f40642aca4d5a313709c2cab6a0e287f1bd514ba72cb8d89fd3a1d81eebbc3d344ddbe34c5460e36453;  // CSIDH-512 prime
    parameter p_inv = 1024'he6b14ff7a8473e0a0dd4b06020e7d66c69a7664077c881339e0ec706aceba3b22071fcf91a8e874db4ca0a3acd608970bc448a790ae4ead38440b17a6335f826a93ab1dd3f816e35e6d7f7ff7198303c2107172bba71ff71b74d3be5b4035fb49cc0eff5aa616b6e393ac935721044ea900965ed4020071fd2c2c24160038025; // Precomputed (-p)^-1 mod 2^512

    // Signals
    reg clk;
    reg rst;
    wire done;
    reg [N-1:0] A, B;
    wire [N-1:0] C;           // Ready signal when computation is done
    reg [1:0]op;

     
    
    // Instantiate the Barrett Reduction FSM
    full_multiplication #(
        .word_size(word_size),
        .N(N),
	.p(p),
	.p_inv(p_inv)
    ) uut (
        .clk(clk),
        .rst(rst),
        .done(done),
        .A(A),
        .B(B),
	.C(C),
	.op(op)
    );

    // Clock generation
    always begin
        #2.5 clk = ~clk; // 10 ns clock period
    end

    // Stimulus process
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
	                          

        // Apply reset
        #10 rst = 0; // Deassert reset after 10 ns
        // Test 1: Apply a random 2048-bit input u
        
	op = 2'b00;  
        B = 1024'h0184c5d2129fc4e566d7af0cebb272347c149db522faa4d8158f3af4971ae3a77d940a69c5c73c8fd10248148a441ec14dedb1b3aae0cee3c6ebd320e7ac6dc401b8063e048e552a6adacc27731d18e0bde2ef4b5c825b480e858f2cc1d63eba48fa02897d5db5a6c1eb9a4c34d2bb9db938e38134251fdb9721aba3ae1856f7;            // u[127:64]
	A = 1024'h0184c5d2129fc4e566d7af0cebb272347c149db522faa4d8158f3af4971ae3a77d940a69c5c73c8fd10248148a441ec14dedb1b3aae0cee3c6ebd320e7ac6dc401b8063e048e552a6adacc27731d18e0bde2ef4b5c825b480e858f2cc1d63eba48fa02897d5db5a6c1eb9a4c34d2bb9db938e38134251fdb9721aba3ae1856f7;               // u[191:128]
        
        
    end

    // Monitor signals
endmodule