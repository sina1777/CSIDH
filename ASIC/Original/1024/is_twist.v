module is_twist #(
    parameter N = 512,                          // Prime bit-width
    parameter word_size = 32,
    parameter p = 512'h65b48e8f740f89bffc8ab0d15e3e4c4ab42d083aedc88c425afbfcc69322c9cda7aac6c567f35507516730cc1f0b4f25c2721bf457aca8351b81b90533c6c87b,  // CSIDH-512 prime
    parameter p_inv = 512'hd8c3904b18371bcd3512da337a97b3451232b9eb013dee1eb081b3aba7d05f8534ed3ea7f1de34c4f6fe2bc33e915395fe025ed7d0d3b1aa66c1301f632e294d,  // Precomputed (-p)^-1 mod 2^512
    parameter fp1 = 512'h3496e2e117e0ec8006ea9e5d4383676a97a5ef8a246ee77b4a080672d9ba6c64b0aa7275301955f15d319e67c1e961b47b1bc81750a6af95c8fc8df598726f0a,
    parameter p_minus_1_halves = 512'h32da4747ba07c4dffe455868af1f26255a16841d76e446212d7dfe63499164e6d3d56362b3f9aa83a8b398660f85a792e1390dfa2bd6541a8dc0dc8299e3643d
) (
    input wire clk,
    input wire rst,
    input wire [N-1:0] x, Ax,
    output reg done,
    output reg twist,
    
    // internal wires
    output reg [N-1:0] A,
    output reg [N-1:0] B,
    input wire [N-1:0] mul,
    
    output reg [1:0] op,
    
    output reg rst_mul,
    input wire done_mul
);


reg [9:0] i;

reg [3:0] state;

reg [N-1:0] t;
reg [N-1:0] final;
    
   
always@(posedge clk)
begin
	if (rst)
	begin
		state <= 4'b0000;
		rst_mul <= 1;
		done <= 0;
		i <= 10'b0;
		final <= fp1;
	end
	else
	begin
		case (state)
                    // 
                	4'b0000: begin
				if (done_mul==1 & rst_mul==0)
				begin
					t <= mul;
					rst_mul <= 1;
					state <= 4'b0001;
				end
				else
				begin
		    		      rst_mul <= 0;
				end	
                        
        	        end
			4'b0001: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					t <= mul;
					rst_mul <= 1;
					state <= 4'b0010;
				end
				else
				begin
		          rst_mul <= 0;
				end	
                   	end
		 	4'b0010: begin
				if (done_mul==1 & rst_mul==0)
				begin
					t <= mul;
					rst_mul <= 1;
					state <= 4'b0011;
				end
				else
				begin
		    		      rst_mul <= 0;
				end	
                    	end
			4'b0011: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					t <= mul;
					rst_mul <= 1;
					i <= i+1;
					state <= (p_minus_1_halves[i]) ? 4'b0100 : 4'b0101;
				end
				else
				begin
		            rst_mul <= 0;
				end	
                   	end
		 	4'b0100: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					final <= mul;
					rst_mul <= 1;
					state <= 4'b0101;
				end
				else
				begin
		              rst_mul <= 0;
				end	
                    	end
			4'b0101: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					t <= mul;
					rst_mul <= 1;
					i <= i+1;
					state <= (i != 10'b0) ? ((p_minus_1_halves[i]) ? 4'b0100 : 4'b0110) : 4'b0111;
				end
				else
				begin
		          rst_mul <= 0;
				end	
                   	end
			4'b0110: begin
				state <= 4'b0101;
                   	end
			4'b0111: begin
				done <= 1'b1;
				twist <= (final == fp1) ? 1'b0 : 1'b1;
                   	end
			default: begin

			end
		endcase
	end
end
always@(*)begin
case (state)
	4'b0000: begin
        	A = x;
		B = Ax;
		op = 2'b01;
                        
        end
	4'b0001: begin
        	A = t;
		B = x; 
		op = 2'b00;      
        end
	4'b0010: begin
		A = t;
		B = fp1; 
		op = 2'b01;                
        end
	4'b0011: begin
        	A = t;
		B = x; 
		op = 2'b00;      
        end
	4'b0100: begin
        	A = t;
		B = final; 
		op = 2'b00;       
        end
	4'b0101: begin
        	A = t;
		B = t;  
		op = 2'b00;      
        end
	default: begin

	end
endcase

end

endmodule


