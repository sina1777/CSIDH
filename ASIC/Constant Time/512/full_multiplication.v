module full_multiplication  #(
    parameter N = 512,                          // Prime bit-width
    parameter word_size = 32,
    parameter p = 512'h1b81b90533c6c87bc2721bf457aca835516730cc1f0b4f25a7aac6c567f355075afbfcc69322c9cdb42d083aedc88c42fc8ab0d15e3e4c4a65b48e8f740f89bf,  // CSIDH-512 prime
    parameter p_inv = 512'h6cc7c46331f06031c5e0b893adbb34d66d34329cbe09ad2e2401809d24ba4fe7d472982d79780cda4e391517c081cc016eb964f056a4b21e89ac9fe58a8a99c1  // Precomputed (-p)^-1 mod 2^512
) (
    input clk,
    input rst,
    input wire [N-1:0] A,                      // 512-bit input 
    input wire [N-1:0] B,
    input wire [1:0] op,			// 512-bit input
    output reg [N-1:0] C,                 // 512-bit reduced output
    output wire [N-1:0] rand_prng,
    output reg done
);

// multiplication control signals
reg [N-1:0] A_mul;
reg [N-1:0] B_mul;
wire done_mul;
reg rst_mul;
reg [2*N-1:0] T; 
wire [2*N-1:0] C_mul;
// add module wires
reg [N-1:0] X;
reg [N-1:0] Y;
reg carry;
wire [N:0] add;

reg rst_add;
reg rst_sub;

wire done_add;
wire done_sub;

reg c_in;
// sub module wires
reg [N-1:0] S1;
reg [N-1:0] S2;
wire [N-1:0] sub;
    adder #(
        .N(N),
	.p(p)
    ) uut2 (
        .X(X),
        .Y(Y),
	.c_in(carry),
	.Z(add),
	.clk(clk),
	.rst(rst_add),
	.done(done_add)
    );

    sub #(
        .N(N),
	.p(p)
    ) uut3 (
        .X(S1),
        .Y(S2),
	.Z(sub),
	.clk(clk),
	.rst(rst_sub),
	.done(done_sub)
    );

multiplication #(
        .word_size(word_size),
        .N(N)
    ) uut (
        .clk(clk),
        .rst(rst_mul),
        .done(done_mul),
	.low_bit(op[1]),
        .A(A_mul),
        .B(B_mul),
	.C(C_mul),
	.rand_prng(rand_prng)
    );

// ==================================================
// Step 1: Compute m = (T_low * p_inv) mod 2^512
// ==================================================
wire [N-1:0] T_low = T[N-1:0];                  // Extract lower 512 bits of T
reg [N-1:0] m;                // Lower 512 bits of product (mod 2^512)
reg [2:0] state;
reg [1023:0] m_times_p;

// Step 2: Compute T + m * p (1024-bit addition)
reg [1024:0] T_plus_mp;
// ==================================================
// Step 3: Divide by R = 2^512 (right shift 512 bits)
// ==================================================
//reg [N:0] reduced = T_plus_mp[2*N:N];       // Upper 513 bits after shift

// ==================================================
// Step 4: Final subtraction (if result >= p)
// ==================================================
wire [N:0] p_extended = {1'b0, p};              // Zero-extend p to 513 bits
reg [N:0] sub_result;  // 513-bit subtraction



always@(posedge clk)
begin
	if(rst)
	begin
		T_plus_mp <= 0;
		m_times_p <= 0;
		carry <= 1'b0;
		state <= 3'b011;
		rst_mul <= 1'b1;
		done <= 1'b0;
		rst_add <= 1'b1;
		rst_sub <= 1'b1;
	end
	else if (done) begin

	end
	else
	begin
	case (op)
	2'b00: begin
		case (state)
			// ==================================================
			// Step 1: Compute m = (T_low * p_inv) mod 2^512
			// Lower 512 bits of product (mod 2^512)
			// ==================================================
			3'b000: begin
				if (done_mul==1 & rst_mul==0)
				begin
					m <= C_mul;
					rst_mul <= 1;
					state <= 3'b001;
				end
				else
				begin
                    rst_mul <= 0;
				end	
			end
			// Step 2: Compute T + m * p (1024-bit addition)
			3'b001: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					m_times_p <= C_mul;
					rst_mul <= 1;
					state <= 3'b100;
					
				end
				else
				begin
                  			rst_mul <= 0;
				end	
			end
			3'b100: begin
				if (done_add==1 & rst_add==0)
				begin
					rst_add <= 1;
					T_plus_mp[N-1:0] <= add[N-1:0];
					carry <= add[N];
					state <= 3'b101;
				end
				else begin
					rst_add <= 0;
				end
			end
			3'b101: begin
				if (done_add==1 & rst_add==0)
				begin
					rst_add <= 1;
					T_plus_mp[2*N-1:N] <= add[N-1:0];
					state <= 3'b110;
					
				end
				else begin
					rst_add <= 0;
				end
			end
			3'b110: begin
				if (done_sub==1 & rst_sub==0)
				begin
					rst_sub <= 1;
					sub_result <= sub;
					
					if (T_plus_mp[2*N:2*N-N/2] > p_extended[N:N/2]) begin
						done<= 1'b1;
						C <= sub[N-1:0];
					end
					else if (T_plus_mp[2*N:2*N-N/2] == p_extended[N:N/2]) begin
						state <= 3'b010;
					end
					else begin
						C <= T_plus_mp[2*N-1:N];
						done<= 1'b1;
					end
				end
				else begin
					rst_sub <= 0;
				end
			end
			// turn done to 1 when calculation finished
			3'b010: begin
				if (T_plus_mp[2*N-N/2-1:N] > p_extended[N/2-1:0]) begin
					C <= sub_result[N-1:0];
				end
				else begin
					C <= T_plus_mp[2*N-1:N];
				end
				done <= 1;
			end
			3'b011: begin
				if (done_mul==1 & rst_mul==0)
				begin
					T <= C_mul;
					rst_mul <= 1;
					state <= 2'b000;
					
				end
				else begin
				    rst_mul <= 0;
				end
			end
			default: begin

			end
		endcase
	end
	2'b11: begin
		if (done_mul==1 & rst_mul==0)
		begin
			rst_mul <= 1;
			done <= 1;
			C <= C_mul;
					
		end
		else begin
			rst_mul <= 0;
		end
	end
	2'b01: begin
		case (state)
		2'b11: begin
			if (done_add==1 & rst_add==0)
			begin
				rst_add <= 1;
				
				if (add > p) begin
					state <= 2'b00;
					T <= add;
				end
				else begin
					done <= 1'b1;
					C <= add;
				end
					
			end
			else begin
				rst_add <= 0;
			end
		end
		2'b00: begin
			if (done_sub==1 & rst_sub==0)
			begin
				rst_sub <= 1;
				C <= sub;
				done <= 1'b1;
				
					
			end
			else begin
				rst_sub <= 0;
			end
		end
		default: begin

		end
		endcase
	end
	2'b10: begin
		case (state)
		2'b11: begin
			state <= (A < B) ? 2'b01 : 2'b10;
		end
		2'b01: begin
			if (done_add==1 & rst_add==0)
			begin
				rst_add <= 1;
				T <= add;	
				state <= 2'b00;
			end
			else begin
				rst_add <= 0;
			end
		end
		2'b00: begin
			if (done_sub==1 & rst_sub==0)
			begin
				rst_sub <= 1;
				C <= sub;
				done <= 1'b1;
				
					
			end
			else begin
				rst_sub <= 0;
			end
		end
		2'b10: begin
			if (done_sub==1 & rst_sub==0)
			begin
				rst_sub <= 1;
				C <= sub;
				done <= 1'b1;
				
					
			end
			else begin
				rst_sub <= 0;
			end
		end
		default: begin
			done <= 1'b1;
		end
		endcase
	end
	default: begin
	
	
	end
	endcase
	
	end
end

always@(*) begin
	case (op)
	2'b00: begin
	
	case (state)
		3'b000: begin
			A_mul = T_low;
			B_mul = p_inv;
		end
		3'b001: begin
			A_mul = m;
			B_mul = p;
		end
		3'b100: begin
			X = T[N-1:0];
			Y = m_times_p[N-1:0];
		end
		3'b101: begin
			X = T[2*N-1:N];
			Y = m_times_p[2*N-1:N];
		end
		3'b110: begin
			S1 = T_plus_mp[2*N-1:N];
			S2 = p_extended[N-1:0];
		end
		3'b011: begin
			A_mul = A;
			B_mul = B;
		end
		default: begin

		end
	endcase
	end
	2'b11: begin
		A_mul = A;
		B_mul = B;
		
	end
	2'b01: begin
		case (state) 
		2'b11: begin
			X = A;
			Y = B;
		end
		2'b00: begin
			S1 = T;
			S2 = p;
		end
		default: begin

		end
		endcase
	end
	2'b10: begin
		case (state) 
		2'b01: begin
			X = A;
			Y = p;
		end
		2'b00: begin
			S1 = T;
			S2 = B;
		end
		2'b10: begin
			S1 = A;
			S2 = B;
		end
		default: begin

		end
		endcase
	end
	default: begin

	
	end
	endcase

end
endmodule

module multiplication #(
    parameter N = 512,  // Prime field bit-width (e.g., 511 for CSIDH-512)
    parameter word_size = 32,
    parameter chunks = N/word_size
)(
    input wire clk,
    input wire rst,
    input wire low_bit,
    input wire [N-1:0] A, B,
    output wire [2*N-1:0] C,
    output reg [N-1:0] rand_prng,
    output reg done
);


reg [4:0] state;
// Partial products: 64 bits each (32x32) up
wire [2*word_size-1:0] partials_up [0:chunks-1];
reg [word_size:0] sum_partials0_up [0:chunks];
reg [word_size:0] sum_partials1_up [0:chunks];
reg [chunks-1:0] carry_up;
// Partial products: 64 bits each (32x32) down
wire [2*word_size-1:0] partials_down [0:chunks-1];
reg [word_size:0] sum_partials0_down [0:chunks];
reg [word_size:0] sum_partials1_down [0:chunks];
reg [chunks-1:0] carry_down;

reg [word_size-1:0] B_up;
reg [word_size-1:0] B_down;

reg [N+word_size-1:0] temp_partial_up;
reg [N+word_size-1:0] temp_partial_mem_up1;
reg [N+word_size-1:0] temp_partial_mem_up2;
reg [N+word_size-1:0] temp_partial_down;
reg [N+word_size-1:0] temp_partial_mem_down1;
reg [N+word_size-1:0] temp_partial_mem_down2;


integer i;

reg [2*N-1:0] temp_mul_up;
reg [2*N-1:0] temp_mul_down;

reg [2*N-1:0] temp_mul;
reg [2*N-1:0] test;
assign C = temp_mul;


reg [N+(2*word_size)-1:0] sum_up;
reg [word_size:0] sum1_partials0_up [0:chunks+1];
reg [word_size:0] sum1_partials1_up [0:chunks+1];
reg [chunks+1:0] carrysum_up;

reg [N+(2*word_size)-1:0] sum_down;
reg [N+(2*word_size)-1:0] sum_down_temp;
reg [word_size:0] sum1_partials0_down [0:chunks+1];
reg [word_size:0] sum1_partials1_down [0:chunks+1];
reg [chunks+1:0] carrysum_down;
reg last_carry;

reg [N+(2*word_size)-1:0] X_up;
reg [N+(2*word_size)-1:0] Y_up;
reg [N+(2*word_size)-1:0] X_down;
reg [N+(2*word_size)-1:0] Y_down;

// 1. Declare the generate loop variable
    genvar j;

    // 2. Begin the generate block
    generate
        // 3. Write the for loop from 0 to 7
        for (j = 0; j < chunks; j = j + 1) begin : mul_instance_block_down // 4. Name the block

            // Instantiate the mul32 module for each value of 'i'
            mul32 uut_down (
                .clk(clk),
                .A(A[(j+1)*word_size-1 -: word_size]),         // Connects the same A to all instances
                .B(B_down),       // Connects the i-th B input
                .C(partials_down[j])        // Connects to the i-th C output
            );

        end
    endgenerate

	genvar z;

    // 2. Begin the generate block
    generate
        // 3. Write the for loop from 0 to 7
        for (z = 0; z < chunks; z = z + 1) begin : mul_instance_block_up // 4. Name the block

            // Instantiate the mul32 module for each value of 'i'
            mul32 uut_up (
                .clk(clk),
                .A(A[(z+1)*word_size-1 -: word_size]),         // Connects the same A to all instances
                .B(B_up),       // Connects the i-th B input
                .C(partials_up[z])        // Connects to the i-th C output
            );

        end
    endgenerate

always@(posedge clk)
begin
	if(rst)
	begin
		state <= 0;
		B_up <=  B[(4'b1001)*word_size-1 -: word_size];
		B_down <=  B[(4'b0001)*word_size-1 -: word_size];
		done <= 0;
		temp_mul_up <= 0;
		temp_mul_down <= 0;
	end
	else 
	begin
		if (done) begin

		end
		else if ((low_bit == 1)) begin
			case (state) 
			3'b000: begin
				B_up <=  B[(4'b0010)*word_size-1 -: word_size];
				B_down <=  B[(4'b0001)*word_size-1 -: word_size];
				state <= 3'b001;
			end
			3'b001: begin
				state <= 3'b111;
			end
			3'b111: begin
				state <= 3'b110;
			end
			3'b110: begin
				state <= 3'b010;
				temp_partial_mem_up1 <= temp_partial_up;
				temp_partial_mem_down1 <= temp_partial_down;
			end
			3'b010: begin
				state <= 3'b101;
			end
			3'b101: begin
				state <= 3'b011;
				temp_mul <= sum_up;
				done <= 1'b1;
			end
			

			endcase

		end
		else begin
			case (state) 
			5'b00000: begin
				B_up <=  B[(4'b1010)*word_size-1 -: word_size];
				B_down <=  B[(4'b0010)*word_size-1 -: word_size];
				state <= 5'b00001;
			end
			5'b00001: begin
				state <= 5'b10111;
			end
			5'b10111: begin
				state <= 5'b00010;
			end
			5'b00010: begin
				state <= 5'b00011;
				temp_partial_mem_up1 <= temp_partial_up;
				temp_partial_mem_down1 <= temp_partial_down;
				B_up <=  B[(4'b1011)*word_size-1 -: word_size];
				B_down <=  B[(4'b0011)*word_size-1 -: word_size];
			end
			5'b00011: begin
				state <= 5'b00100;
				temp_partial_mem_up2 <= temp_partial_up;
				temp_partial_mem_down2 <= temp_partial_down;
				B_up <=  B[(4'b1100)*word_size-1 -: word_size];
				B_down <=  B[(4'b0100)*word_size-1 -: word_size];
				
			end
			5'b00100: begin
				state <= 5'b00101;
				
				temp_mul_up[(4'b1000)*word_size + (N+word_size-1) -: N+word_size] <= sum_up;
				temp_mul_down[(4'b0000)*word_size + (N+word_size-1) -: N+word_size] <= sum_down;
				
			end
			5'b00101: begin
				state <= 5'b00110;
				
			end
			5'b00110: begin
				state <= 5'b00111;
				temp_partial_mem_up1 <= temp_partial_up;
				temp_partial_mem_down1 <= temp_partial_down;
				temp_mul_up[(4'b1001)*word_size + (N+word_size-1) -: N+word_size] <= sum_up;
				temp_mul_down[(4'b0001)*word_size + (N+word_size-1) -: N+word_size] <= sum_down;
				B_up <=  B[(4'b1101)*word_size-1 -: word_size];
				B_down <=  B[(4'b0101)*word_size-1 -: word_size];
				
				
			end
			5'b00111: begin
				state <= 5'b01000;
				temp_partial_mem_up2 <= temp_partial_up;
				temp_partial_mem_down2 <= temp_partial_down;
				B_up <=  B[(4'b1110)*word_size-1 -: word_size];
				B_down <=  B[(4'b0110)*word_size-1 -: word_size];
				
				
			end
			5'b01000: begin
				state <= 5'b01001;
				temp_mul_up[(4'b1010)*word_size + (N+word_size-1) -: N+word_size] <= sum_up;
				temp_mul_down[(4'b0010)*word_size + (N+word_size-1) -: N+word_size] <= sum_down;
				
				
			end
			5'b01001: begin
				state <= 5'b01010;
			end
			5'b01010: begin
				state <= 5'b01011;
				temp_partial_mem_up1 <= temp_partial_up;
				temp_partial_mem_down1 <= temp_partial_down;
				temp_mul_up[(4'b1011)*word_size + (N+word_size-1) -: N+word_size] <= sum_up;
				temp_mul_down[(4'b0011)*word_size + (N+word_size-1) -: N+word_size] <= sum_down;
				B_up <=  B[(4'b1111)*word_size-1 -: word_size];
				B_down <=  B[(4'b0111)*word_size-1 -: word_size];
				
				
			end
			5'b01011: begin
				state <= 5'b01100;
				temp_partial_mem_up2 <= temp_partial_up;
				temp_partial_mem_down2 <= temp_partial_down;
				B_up <=  B[(5'b10000)*word_size-1 -: word_size];
				B_down <=  B[(4'b1000)*word_size-1 -: word_size];
				
				
			end
			5'b01100: begin
				state <= 5'b01101;
				temp_mul_up[(4'b1100)*word_size + (N+word_size-1) -: N+word_size] <= sum_up;
				temp_mul_down[(4'b0100)*word_size + (N+word_size-1) -: N+word_size] <= sum_down;
				
				
				
			end
			
			5'b01101: begin
				state <= 5'b01110;
			end
			5'b01110: begin
				state <= 5'b01111;
				temp_partial_mem_up1 <= temp_partial_up;
				temp_partial_mem_down1 <= temp_partial_down;
				temp_mul_up[(4'b1101)*word_size + (N+word_size-1) -: N+word_size] <= sum_up;
				temp_mul_down[(4'b0101)*word_size + (N+word_size-1) -: N+word_size] <= sum_down;
				
			end
			5'b01111: begin
				state <= 5'b10000;
				temp_partial_mem_up2 <= temp_partial_up;
				temp_partial_mem_down2 <= temp_partial_down;
				
			end
			5'b10000: begin
				state <= 5'b10001;
				temp_mul_up[(4'b1110)*word_size + (N+word_size-1) -: N+word_size] <= sum_up;
				temp_mul_down[(4'b0110)*word_size + (N+word_size-1) -: N+word_size] <= sum_down;
				
				
			end
			5'b10001: begin
				state <= 5'b10010;
			end
			5'b10010: begin
				state <= 5'b10011;
				temp_mul_up[(4'b1111)*word_size + (N+word_size-1) -: N+word_size] <= sum_up;
				temp_mul_down[(4'b0111)*word_size + (N+word_size-1) -: N+word_size] <= sum_down;
				
			end
			5'b10011: begin
				state <= 5'b10100;
				test <= temp_mul_up+ temp_mul_down;
			end	
			5'b10100: begin
				state <= 5'b10101;
			end
			5'b10101: begin
				//test <= temp_mul_up+ temp_mul_down;
				state <= 5'b10110;
				temp_mul[N+(2*word_size)-1 : 0] <= sum_down[N+(2*word_size)-1 : 0];
				
			end
			5'b10110: begin
				//test <= temp_mul_up+ temp_mul_down;
				temp_mul[2*N-1 : N+(2*word_size)] <= sum_up[N-(2*word_size)-1 : 0];
				done <= 1'b1;
			end
			endcase

		end
		//else if (done == 0) begin 
			//temp_mul <= temp_mul + (temp_partial_mem << (stage * word_size));
			//temp_mul <= temp_mul + (temp_partial << (stage * word_size));
			//done <= 1;
		//end
		
	end

end

always@(posedge clk) begin
	// make randomness
			rand_prng [63:0]     <= partials_down[3][63:0];    // Block 0 <= Block 1
			rand_prng [127:64]   <= partials_up[7][63:0];   // Block 1 <= Block 2
			rand_prng [191:128]  <= partials_down[13][63:0];   // Block 2 <= Block 3
			rand_prng [255:192]  <= partials_down[1][63:0];   // Block 3 <= Block 4
			rand_prng [319:256]  <= partials_up[11][63:0];   // Block 4 <= Block 5
			rand_prng [383:320]  <= partials_down[5][63:0];   // Block 5 <= Block 6
			rand_prng [447:384]  <= partials_up[12][63:0];   // Block 6 <= Block 7
			rand_prng [511:448]  <= partials_up[9][63:0];   // Block 7 <= Block 8
				
	// down

	
	for (i = 0; i < chunks+1; i = i + 1) begin
			if (i==0) begin
				sum_partials0_down[0] <= partials_down[0][31:0];
			end
			else if (i == chunks) begin
				sum_partials0_down[chunks] <= partials_down[chunks-1][63:32];
				sum_partials1_down[chunks] <= partials_down[chunks-1][63:32] + 1'b1;
			end
			else begin
                		sum_partials0_down[i] <= partials_down[i-1][63:32] + partials_down[i][31:0];
				sum_partials1_down[i] <= partials_down[i-1][63:32] + partials_down[i][31:0] + 1'b1;
			end
        end
	//up
	
	for (i = 0; i < chunks+1; i = i + 1) begin
			if (i==0) begin
				sum_partials0_up[0] <= partials_up[0][31:0];
			end
			else if (i == chunks) begin
				sum_partials0_up[chunks] <= partials_up[chunks-1][63:32];
				sum_partials1_up[chunks] <= partials_up[chunks-1][63:32] + 1'b1;
			end
			else begin
                		sum_partials0_up[i] <= partials_up[i-1][63:32] + partials_up[i][31:0];
				sum_partials1_up[i] <= partials_up[i-1][63:32] + partials_up[i][31:0] + 1'b1;
			end
        end
end


always@(*) begin
	for (i = 0; i < chunks+1; i = i + 1) begin
		if (i==0) begin
			temp_partial_down[31:0] = sum_partials0_down[0][31:0];
			carry_down [0] = 0;
		end
		else begin
			if (carry_down[i-1]) begin
				carry_down [i] = sum_partials1_down[i][32];
        			temp_partial_down[(i+1)*word_size-1 -: word_size] = sum_partials1_down[i][31:0];
			end
			else begin
				carry_down [i] = sum_partials0_down[i][32];
        			temp_partial_down[(i+1)*word_size-1 -: word_size] = sum_partials0_down[i][31:0];
			end
		end
        end


	for (i = 0; i < chunks+1; i = i + 1) begin
		if (i==0) begin
			temp_partial_up[31:0] = sum_partials0_up[0][31:0];
			carry_up [0] = 0;
		end
		else begin
			if (carry_up[i-1]) begin
				carry_up [i] = sum_partials1_up[i][32];
        			temp_partial_up[(i+1)*word_size-1 -: word_size] = sum_partials1_up[i][31:0];
			end
			else begin
				carry_up [i] = sum_partials0_up[i][32];
        			temp_partial_up[(i+1)*word_size-1 -: word_size] = sum_partials0_up[i][31:0];
			end
		end
        end
end
always@ (posedge clk) begin
	for (i = 0; i < chunks+2; i = i + 1) begin
        	sum1_partials0_up[i] <= X_up[32*i + 31 -: 32] + Y_up[32*i + 31 -: 32];
		sum1_partials1_up[i] <= X_up[32*i + 31 -: 32] + Y_up[32*i + 31 -: 32] + 1'b1;
        end
	for (i = 0; i < chunks+2; i = i + 1) begin
        	sum1_partials0_down[i] <= X_down[32*i + 31 -: 32] + Y_down[32*i + 31 -: 32];
		sum1_partials1_down[i] <= X_down[32*i + 31 -: 32] + Y_down[32*i + 31 -: 32] + 1'b1;
        end
	last_carry <= carrysum_down[chunks+1];
end
always@(*) begin
	for (i = 0; i < chunks+2; i = i + 1) begin
        	if (i==0) begin
			if (state == 5'b10110 && last_carry==1'b1) begin
				sum_up[31:0] = sum1_partials1_up[0][31:0];
                    		carrysum_up [0] = sum1_partials1_up[0][32];
			end
			else begin
  	              		sum_up[31:0] = sum1_partials0_up[0][31:0];
                    		carrysum_up [0] = sum1_partials0_up[0][32];
			end
                end
                else begin
                    if (carrysum_up [i-1]) begin
                        carrysum_up [i] = sum1_partials1_up[i][32];
                        sum_up[(i+1)*word_size-1 -: word_size] = sum1_partials1_up[i][31:0];
                    end
                    else begin
                        carrysum_up [i] = sum1_partials0_up[i][32];
                        sum_up[(i+1)*word_size-1 -: word_size] = sum1_partials0_up[i][31:0];
                    end
                end
       	end
	for (i = 0; i < chunks+2; i = i + 1) begin
        	if (i==0) begin
                    sum_down[31:0] = sum1_partials0_down[0][31:0];
                    carrysum_down [0] = sum1_partials0_down[0][32];
                end
                else begin
                    if (carrysum_down [i-1]) begin
                        carrysum_down [i] = sum1_partials1_down[i][32];
                        sum_down[(i+1)*word_size-1 -: word_size] = sum1_partials1_down[i][31:0];
                    end
                    else begin
                        carrysum_down [i] = sum1_partials0_down[i][32];
                        sum_down[(i+1)*word_size-1 -: word_size] = sum1_partials0_down[i][31:0];
			
                    end
                end
       	end

end
always@(*) begin
	if (low_bit) begin
		case (state) 
		3'b010: begin
			X_up = temp_partial_mem_up1 << (4'b0010 * word_size);
			Y_up = temp_partial_mem_down1;
		end
		
		endcase
	end
	else begin
		case (state) 
		5'b00011: begin
			X_up = temp_partial_mem_up1;
			Y_up = temp_mul_up >> ((4'b1000) * word_size);
			X_down = temp_partial_mem_down1;
			Y_down = temp_mul_down >> ((4'b0000) * word_size);
		end
		5'b00101: begin
			X_up = temp_partial_mem_up2;
			Y_up = temp_mul_up >> ((4'b1001) * word_size);
			X_down = temp_partial_mem_down2;
			Y_down = temp_mul_down >> ((4'b0001) * word_size);
		end
		5'b00111: begin
			X_up = temp_partial_mem_up1;
			Y_up = temp_mul_up >> ((4'b1010) * word_size);
			X_down = temp_partial_mem_down1;
			Y_down = temp_mul_down >> ((4'b0010) * word_size);
		end
		5'b01001: begin
			X_up = temp_partial_mem_up2;
			Y_up = temp_mul_up >> ((4'b1011) * word_size);
			X_down = temp_partial_mem_down2;
			Y_down = temp_mul_down >> ((4'b0011) * word_size);
		end
		5'b01011: begin
			X_up = temp_partial_mem_up1;
			Y_up = temp_mul_up >> ((4'b1100) * word_size);
			X_down = temp_partial_mem_down1;
			Y_down = temp_mul_down >> ((4'b0100) * word_size);
		end
		5'b01101: begin
			X_up = temp_partial_mem_up2;
			Y_up = temp_mul_up >> ((4'b1101) * word_size);
			X_down = temp_partial_mem_down2;
			Y_down = temp_mul_down >> ((4'b0101) * word_size);
		end
		5'b01111: begin
			X_up = temp_partial_mem_up1;
			Y_up = temp_mul_up >> ((4'b1110) * word_size);
			X_down = temp_partial_mem_down1;
			Y_down = temp_mul_down >> ((4'b0110) * word_size);
		end
		5'b10001: begin
			X_up = temp_partial_mem_up2;
			Y_up = temp_mul_up >> ((4'b1111) * word_size);
			X_down = temp_partial_mem_down2;
			Y_down = temp_mul_down >> ((4'b0111) * word_size);
		end
		5'b10011: begin
			X_down = temp_mul_up[N+(2*word_size)-1 : 0]; 
			Y_down = temp_mul_down[N+(2*word_size)-1 : 0];
			
		end
		5'b10100: begin
			X_up = temp_mul_up[2*N-1 : N+(2*word_size)]; 
			Y_up = temp_mul_down[2*N-1 : N+(2*word_size)];
		end

		default: begin
			
		end
		endcase
	end
end

endmodule

module adder #(
    parameter N = 512,                          // Prime bit-width
    parameter p = 512'h65b48e8f740f89bffc8ab0d15e3e4c4ab42d083aedc88c425afbfcc69322c9cda7aac6c567f35507516730cc1f0b4f25c2721bf457aca8351b81b90533c6c87b, // CSIDH-512 prime
    parameter word_size = 32,
    parameter chunks = N/word_size
    ) (
    input clk,
    input rst,
    input c_in,
    input wire [N-1:0] X, Y,
    output wire [N:0] Z,
    output reg done
);
reg state;
reg [N-1:0] sum;
integer i;
reg [word_size:0] sum_partials0 [0:chunks-1];
reg [word_size:0] sum_partials1 [0:chunks-1];
reg [chunks-1:0] carry;

assign Z[N-1:0] = sum[N-1:0];
assign Z[N] = carry[chunks-1];
always@ (posedge clk) begin
    if (rst) begin
        state <= 1'b0;
	done <= 1'b0;
    end
    else begin
        if (state) begin
            done <= 1'b1;
        end
        else begin
            for (i = 0; i < chunks; i = i + 1) begin
                sum_partials0[i] <= X[32*i + 31 -: 32] + Y[32*i + 31 -: 32];
		sum_partials1[i] <= X[32*i + 31 -: 32] + Y[32*i + 31 -: 32] + 1'b1;
            end
            state <= 1'b1;
        end
    end
end
always@(*) begin
    if (state) begin
            for (i = 0; i < chunks; i = i + 1) begin
                if (i==0) begin
			if (c_in) begin
				sum[31:0] = sum_partials1[0][31:0];
                    		carry [0] = sum_partials1[0][32];
			end
			else begin
                    		sum[31:0] = sum_partials0[0][31:0];
                    		carry [0] = sum_partials0[0][32];
			end
                end
                else begin
                    if (carry [i-1]) begin
                        carry [i] = sum_partials1[i][32];
                        sum[(i+1)*word_size-1 -: word_size] = sum_partials1[i][31:0];
                    end
                    else begin
                        carry [i] = sum_partials0[i][32];
                        sum[(i+1)*word_size-1 -: word_size] = sum_partials0[i][31:0];
                    end
                end
            end
    end
    else begin
    
    end
end

endmodule



module sub #(
    parameter N = 512,                          // Prime bit-width
    parameter p = 512'h65b48e8f740f89bffc8ab0d15e3e4c4ab42d083aedc88c425afbfcc69322c9cda7aac6c567f35507516730cc1f0b4f25c2721bf457aca8351b81b90533c6c87b, // CSIDH-512 prime
    parameter word_size = 32,
    parameter chunks = N/word_size
    ) (
    input wire clk,
    input wire rst,
    input wire [N:0] X, Y,
    output wire [N-1:0] Z,
    output reg done

// adder internal wires
    
);

reg state;
reg [N-1:0] sub;
integer i;
reg [word_size:0] sub_partials0 [0:chunks];
reg [word_size:0] sub_partials1 [0:chunks];
reg [chunks-1:0] borrow_out0;
reg [chunks-1:0] borrow_out1;
reg [chunks-1:0] borrow;



assign Z = sub[N-1:0];

always@ (posedge clk) begin
    if (rst) begin
        state <= 1'b0;
	done <= 1'b0;
    end
    else begin
        if (state) begin
            done <= 1'b1;
        end
        else begin
            for (i = 0; i < chunks; i = i + 1) begin
		if (X[32*i + 31 -: 32] < Y[32*i + 31 -: 32]) begin
			sub_partials0[i] <= {1'b1, X[32*i + 31 -: 32]} - Y[32*i + 31 -: 32];
			sub_partials1[i] <= {1'b1, X[32*i + 31 -: 32]} - Y[32*i + 31 -: 32] - 1'b1;
			borrow_out0[i] <= 1'b1;
              		borrow_out1[i] <= 1'b1;
		end
                else if (X[32*i + 31 -: 32] == Y[32*i + 31 -: 32]) begin
			sub_partials0[i] <= X[32*i + 31 -: 32] - Y[32*i + 31 -: 32];
			sub_partials1[i] <= {1'b1, X[32*i + 31 -: 32]} - Y[32*i + 31 -: 32] - 1'b1;
			borrow_out0[i] <= 1'b0;
              		borrow_out1[i] <= 1'b1;
		end
		else begin
			sub_partials0[i] <= X[32*i + 31 -: 32] - Y[32*i + 31 -: 32];
			sub_partials1[i] <= X[32*i + 31 -: 32] - Y[32*i + 31 -: 32] - 1'b1;
			borrow_out0[i] <= 1'b0;
              		borrow_out1[i] <= 1'b0;
		end
            end
            state <= 1'b1;
        end
    end
end
always@(*) begin
    if (state) begin
            for (i = 0; i < chunks ; i = i + 1) begin
                if (i == 0) begin
                    sub[31:0] = sub_partials0[0][31:0];
                    borrow[0] = borrow_out0[0];
                end
                else begin
                    if (borrow[i-1]) begin
                        borrow[i] = borrow_out1[i];
                        sub[(i+1)*word_size-1 -: word_size] = sub_partials1[i][31:0];
                    end
                    else begin
                        borrow[i] = borrow_out0[i];
                        sub[(i+1)*word_size-1 -: word_size] = sub_partials0[i][31:0];
                    end
                end
            end
    end
    else begin
    
    end
end
endmodule


