module xDBLADD #(
    parameter N = 512,                          // Prime bit-width
    parameter word_size = 32,
    parameter p = 512'h65b48e8f740f89bffc8ab0d15e3e4c4ab42d083aedc88c425afbfcc69322c9cda7aac6c567f35507516730cc1f0b4f25c2721bf457aca8351b81b90533c6c87b,  // CSIDH-512 prime
    parameter p_inv = 512'hd8c3904b18371bcd3512da337a97b3451232b9eb013dee1eb081b3aba7d05f8534ed3ea7f1de34c4f6fe2bc33e915395fe025ed7d0d3b1aa66c1301f632e294d,  // Precomputed (-p)^-1 mod 2^512
    parameter fp1 = 512'h3496e2e117e0ec8006ea9e5d4383676a97a5ef8a246ee77b4a080672d9ba6c64b0aa7275301955f15d319e67c1e961b47b1bc81750a6af95c8fc8df598726f0a
) (
    input wire clk,
    input wire rst,
    input wire [N-1:0] Px, Pz, Qx, Qz, PQx, PQz, Ax, Az,
    output reg [N-1:0] Sx, Sz, Rx, Rz,
    output reg done,
    
    // internal wires
    output reg [N-1:0] A,
    output reg [N-1:0] B,
    input wire [N-1:0] mul,
    
    output reg [1:0] op,

    
    output reg rst_mul,
    input wire done_mul
);


reg [4:0] state;

reg [N-1:0] a1;
reg [N-1:0] b1;
reg [N-1:0] c1;
reg [N-1:0] d1;
    
always@(posedge clk)
begin
	if (rst)
	begin
		state <= 5'b00000;
		rst_mul <= 1;
		done <= 0;
	end
	else
	begin
		case (state)
                    // 
                	5'b00000: begin
				if (done_mul==1 & rst_mul==0)
				begin
					b1 <= mul;
					rst_mul <= 1;
					state <= 5'b10101;
				end
				else
				begin
		    		      rst_mul <= 0;
				end	
                        
        	        end
                	5'b10101: begin
				if (done_mul==1 & rst_mul==0)
				begin
					a1 <= mul;
					rst_mul <= 1;
					state <= 5'b00001;
				end
				else
				begin
		    		      rst_mul <= 0;
				end	
                        
        	        end
			5'b00001: begin
				if (done_mul==1 & rst_mul==0)
				begin
					d1 <= mul;
					rst_mul <= 1;
					state <= 5'b10110;
				end
				else
				begin
		    		      rst_mul <= 0;
				end	
                        
                   	end
			5'b10110: begin
				if (done_mul==1 & rst_mul==0)
				begin
					c1 <= mul;
					rst_mul <= 1;
					state <= 5'b00010;
				end
				else
				begin
		    		      rst_mul <= 0;
				end	
                        
                   	end
		 	5'b00010: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					Rx <= mul;
					rst_mul <= 1;
					state <= 5'b00011;
				end
				else
				begin
		          rst_mul <= 0;
				end	
                    	end
			5'b00011: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					Sx <= mul;
					rst_mul <= 1;
					state <= 5'b00100;
				end
				else
				begin
		              rst_mul <= 0;
				end	
                    	end
			5'b00100: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					c1 <= mul;
					rst_mul <= 1;
					state <= 5'b00101;
				end
				else
				begin
		          rst_mul <= 0;
				end	
                    	end
			5'b00101: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					d1 <= mul;
					rst_mul <= 1;
					state <= 5'b00110;
				end
				else
				begin
		          rst_mul <= 0;
				end	
			end
			5'b00110: begin
				if (done_mul==1 & rst_mul==0)
				begin
					b1 <= mul;
					rst_mul <= 1;
					state <= 5'b10111;
				end
				else
				begin
		    		      rst_mul <= 0;
				end	
			end
			5'b10111: begin
				if (done_mul==1 & rst_mul==0)
				begin
					a1 <= mul;
					rst_mul <= 1;
					if(Az==fp1)begin
						state <= 5'b01000;
					end
					else begin
						state <= 5'b00111;
					end
					
				end
				else
				begin
		    		      rst_mul <= 0;
				end	
				
				
			end
			5'b00111: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					Rz <= mul;
					rst_mul <= 1;
					state <= 5'b01001;
				end
				else
				begin
		          rst_mul <= 0;
				end	
			end
			5'b01000: begin
				if (done_mul==1 & rst_mul==0)
				begin
					Rz <= mul;
					rst_mul <= 1;
					state <= 5'b01001;
				end
				else
				begin
		      			rst_mul <= 0;
				end
			end
			5'b01001: begin
				if (done_mul==1 & rst_mul==0)
				begin
					Sx <= mul;
					rst_mul <= 1;
					state <= 5'b01010;
				end
				else
				begin
		      			rst_mul <= 0;
				end
                    	end
			5'b01010: begin
				if (done_mul==1 & rst_mul==0)
				begin
					Rz <= mul;
					rst_mul <= 1;
					state <= 5'b01011;
				end
				else
				begin
		      			rst_mul <= 0;
				end
                    	end
			5'b01011: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					Rx <= mul;
					rst_mul <= 1;
					state <= 5'b01100;
				end
				else
				begin
		          rst_mul <= 0;
				end	
			end
			5'b01100: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					Sx <= mul;
					rst_mul <= 1;
					state <= 5'b01101;
				end
				else
				begin
		          rst_mul <= 0;
				end	
			end
			5'b01101: begin
				if (done_mul==1 & rst_mul==0)
				begin
					Sz <= mul;
					rst_mul <= 1;
					state <= 5'b11000;
				end
				else
				begin
		      			rst_mul <= 0;
				end
                    	end
			5'b11000: begin
				if (done_mul==1 & rst_mul==0)
				begin
					Rz <= mul;
					rst_mul <= 1;
					state <= 5'b01110;
				end
				else
				begin
		      			rst_mul <= 0;
				end
                    	end
			5'b01110: begin
				if (done_mul==1 & rst_mul==0)
				begin
					Sx <= mul;
					rst_mul <= 1;
					state <= 5'b01111;
				end
				else
				begin
		      			rst_mul <= 0;
				end
                    	end
			5'b01111: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					Rz <= mul;
					rst_mul <= 1;
					state <= 5'b10000;
				end
				else
				begin
		          rst_mul <= 0;
				end	
			end
			5'b10000: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					Sx <= mul;
					rst_mul <= 1;
					state <= 5'b10001;
				end
				else
				begin
		          rst_mul <= 0;
				end	
			end
			5'b10001: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					Sz <= mul;
					rst_mul <= 1;
					if(PQz==fp1)begin
						state <= 5'b10011;
					end
					else begin
						state <= 5'b10010;
					end
				end
				else
				begin
		              rst_mul <= 0;
				end	
			end
			5'b10010: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					Sx <= mul;
					rst_mul <= 1;
					state <= 5'b10011;
				end
				else
				begin
		          rst_mul <= 0;
				end	
			end
			5'b10011: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					Sz <= mul;
					rst_mul <= 1;
					state <= 5'b10100;
				end
				else
				begin
		          rst_mul <= 0;
				end	
			end
			5'b10100: begin
				done <= 1;
                    	end
			default: begin

			end
		endcase
	end
end
always@(*)begin
case (state)
	5'b00000: begin
		A = Qx;
		B = Qz;
		op = 2'b10;
                        
        end
	5'b10101: begin
        	A = Qx;
		B = Qz;
		op = 2'b01;
		
    
        end
	5'b00001: begin
		A = Px;
		B = Pz;
		op = 2'b10;
                        
        end
	5'b10110: begin
        	A = Px;
		B = Pz;
		op = 2'b01;
                        
        end
	5'b00010: begin
		A = c1;
		B = c1;
		op = 2'b00;                 
        end
	5'b00011: begin
		A = d1;
		B = d1; 
		op = 2'b00;                  
        end
	5'b00100: begin
		A = c1;
		B = b1;
		op = 2'b00;                  
        end
	5'b00101: begin
		A = d1;
		B = a1;
		op = 2'b00;  
                        
        end
	5'b00110: begin
		A = Rx;
		B = Sx;
		op = 2'b10;  
      
        end
	5'b10111: begin
		A = Az;
		B = Az;
		op = 2'b01;  
                        
        end
	5'b00111: begin
		A = Sx;
		B = a1;
		op = 2'b00;                 
        end
	5'b01000: begin
		A = Sx;
		B = Sx;   
		op = 2'b01;              
        end
	5'b01001: begin
		A = Ax;
		B = a1;  
		op = 2'b01;               
        end
	5'b01010: begin
		A = Rz;
		B = Rz;  
		op = 2'b01;               
        end
	5'b01011: begin
		A = Rx;
		B = Rz;  
		op = 2'b00;               
        end
	5'b01100: begin
		A = Sx;
		B = b1; 
		op = 2'b00;                
        end
	5'b01101: begin
		A = c1;
		B = d1;
		op = 2'b10;  
                        
        end
	5'b11000: begin
		A = Rz;
		B = Sx;
		op = 2'b01;  
                        
        end
	5'b01110: begin
		A = c1;
		B = d1;
		op = 2'b01;  
                        
        end
	5'b01111: begin
		A = Rz;
		B = b1; 
		op = 2'b00;                
        end
	5'b10000: begin
		A = Sx;
		B = Sx; 
		op = 2'b00;                  
        end
	5'b10001: begin
		A = Sz;
		B = Sz;  
		op = 2'b00;                 
        end
	5'b10010: begin
		A = Sx;
		B = PQz;   
		op = 2'b00;                
        end
	5'b10011: begin
		A = Sz;
		B = PQx;   
		op = 2'b00;                
        end
	default: begin

	end
endcase

end

endmodule



