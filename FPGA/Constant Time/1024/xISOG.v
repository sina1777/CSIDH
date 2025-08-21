module xISOG #(
    parameter N = 512,                          // Prime bit-width
    parameter word_size = 32,
    parameter p = 512'h65b48e8f740f89bffc8ab0d15e3e4c4ab42d083aedc88c425afbfcc69322c9cda7aac6c567f35507516730cc1f0b4f25c2721bf457aca8351b81b90533c6c87b,  // CSIDH-512 prime
    parameter p_inv = 512'hd8c3904b18371bcd3512da337a97b3451232b9eb013dee1eb081b3aba7d05f8534ed3ea7f1de34c4f6fe2bc33e915395fe025ed7d0d3b1aa66c1301f632e294d,  // Precomputed (-p)^-1 mod 2^512
    parameter fp1 = 512'h3496e2e117e0ec8006ea9e5d4383676a97a5ef8a246ee77b4a080672d9ba6c64b0aa7275301955f15d319e67c1e961b47b1bc81750a6af95c8fc8df598726f0a
) (
    input wire clk,
    input wire rst,
    input wire [N-1:0] Px, Pz, Ax, Az, Kx, Kz,
    input wire [9:0] l,
    input wire want_multiple,
    output reg [N-1:0] AxNew, AzNew, KxNew, KzNew, PxNew, PzNew,
    output reg done,
    
    // internal wires
    output reg [N-1:0] A,
    output reg [N-1:0] B,
    input wire [N-1:0] mul,
    
    output reg [1:0] op,

    
    output reg rst_mul_wire,
    input wire done_mul,
    
    // xDBLADD
    input wire doneDBLADD,
    output reg rstDBLADD,
    
    output reg [N-1:0] PxDBLADD, PzDBLADD, QxDBLADD, QzDBLADD, PQxDBLADD, PQzDBLADD, 
    output wire [N-1:0] AxDBLADD, AzDBLADD,
    input wire [N-1:0] RxDBLADD, RzDBLADD, SxDBLADD, SzDBLADD,
    
    // mul internal connection for xDBLADD
    input wire [N-1:0] A_DBLADD,
    input wire [N-1:0] B_DBLADD,
    output reg [N-1:0] mul_DBLADD,
    
    input wire [1:0] op_DBLADD,

    
    input wire rst_mul_DBLADD,
    output reg done_mul_DBLADD
);



reg [8:0] i;
reg [3:0] j;

assign AxDBLADD = Ax;
assign AzDBLADD = Az;


reg [N-1:0] dx, dz;

reg [N-1:0] PRODx, PRODz, Qx, Qz;
reg [N-1:0] Mx[2:0], Mz[2:0];
reg [5:0] state;



reg done_mont;


reg done_edw;


wire [3:0] firstmod;
wire [2:0] secondmod; 
wire [1:0] thirdmod;
assign firstmod = (i[0] + 2*i[1] + i[2] + 2*i[3] + i[4] + 2*i[5] + i[6] + 2*i[7] + i[8]); 
assign secondmod = (firstmod[0] + 2*firstmod[1] + firstmod[2] + 2*firstmod[3]); 
assign thirdmod = (secondmod[0] + 2*secondmod[1] + secondmod[2]);
wire [1:0] imod3;
reg [1:0] i1mod3;
reg [1:0] i2mod3;
assign imod3 = (thirdmod == 2'b11) ? 2'b00 : thirdmod;
reg [N-1:0] t0;
reg [N-1:0] t1;
reg [N-1:0] t2;
reg rst_mul;


always@(posedge clk)
begin
	if (rst)
	begin
		
		rstDBLADD <= 1'b1;
		state <= 6'b000000;
		done <= 0;
		Mx[0] <= Kx;
		Mz[0] <= Kz;
		rst_mul <= 1;
		i <= 9'b000000001;
		done_mont <= 1'b0;
		done_edw <= 1'b0;
		j <= 4'b0000;

	end
	else 
	begin
		case(state)
			// montisog_eval_init start level 1
			6'b000000: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					Qx <= mul;
					rst_mul <= 1;
					state <= 6'b000001;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b000001: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					state <= 6'b000010;
					t0 <= mul;
					rst_mul <= 1'b1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b000010: begin
				if (done_mul==1 & rst_mul==0)
				begin
					Qx <= mul;
					rst_mul <= 1;
					state <= 6'b000011;
				end
				else begin
				    rst_mul <= 0;
				end
				
			end
			6'b000011: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					Qz <= mul;
					rst_mul <= 1;
					state <= 6'b000100;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b000100: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					state <= 6'b000101;
					t0 <= mul;
					rst_mul <= 1'b1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b000101: begin
				if (done_mul==1 & rst_mul==0)
				begin
					state <= 6'b000110;
					Qz <= mul;	
					rst_mul <= 1'b1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			//edwisog_curve_init, initializing prod
			6'b000110: begin
				if (done_mul==1 & rst_mul==0)
				begin
					state <= 6'b111001;
					PRODx <= mul;
					rst_mul <= 1'b1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b111001: begin
				if (done_mul==1 & rst_mul==0)
				begin
					state <= 6'b000111;
					PRODz <= mul;
					rst_mul <= 1'b1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			// calculating M[i] = i*K
			// i=1
			6'b000111: begin
				
				if (doneDBLADD==1 & rstDBLADD==0)
				begin
					Mx[1] <= RxDBLADD;
					Mz[1] <= RzDBLADD;
					rstDBLADD <= 1;
					if (l==3) begin
					state <= (want_multiple) ? 6'b001100 : 6'b001101;
					end
					else begin
					state <= 6'b111010;
					end
				end
				else begin
				    rstDBLADD <= 0;
				end
			end
			// start itrating over i<l/2-1
			6'b001000: begin
				if (doneDBLADD==1 & rstDBLADD==0)
				begin
					Mx[imod3] <= SxDBLADD;
					Mz[imod3] <= SzDBLADD;
					state <= 6'b111010;
					rstDBLADD <= 1;
				end
				else begin
				rstDBLADD <= 0;
				end
			end
			6'b111010: begin
				if (done_mul==1 & rst_mul==0)
				begin
					state <= 6'b001001;
					t1 <= mul;
					rst_mul <= 1'b1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b001001: begin
				if (done_mont==1)
				begin
					state <= 6'b111011;
					done_mont <= 1'b0;
				end
				else begin
					if (done_mul==1 & rst_mul==0)
					begin
						state <= 6'b110000;
						t0 <= mul;
						rst_mul <= 1'b1;
					end
					else begin
				  	  rst_mul <= 0;
					end
				end
			end
			6'b111011: begin
				if (done_mul==1 & rst_mul==0)
				begin
					state <= 6'b001010;
					t1 <= mul;
					rst_mul <= 1'b1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b001010: begin
				
				if (done_edw==1)
				begin
				    done_edw <= 0;
					if (i < (l >> 1)-1) begin
					state <= 6'b001000;
					i <= i+1;
					end
					else begin
					// we want multiple of K or P or not !!
					state <= (want_multiple) ? 6'b001011 : 6'b001101;
					i <= (l >> 1);
					end
				end
				else begin
					if (done_mul==1 & rst_mul==0)
					begin
						state <= 6'b110111;
						t0 <= mul;
						rst_mul <= 1'b1;
					end
					else begin
				 	   rst_mul <= 0;
					end
				end
			end
			// start of calculating multiple of K
			6'b001011: begin
				
				if (doneDBLADD==1 & rstDBLADD==0)
				begin
					Mx[imod3] <= SxDBLADD;
					Mz[imod3] <= SzDBLADD;
					state <= 6'b001100;
					rstDBLADD <= 1;
				end
				else begin
				    rstDBLADD <= 0;
				end
			end
			6'b001100: begin
				
				if (doneDBLADD==1 & rstDBLADD==0)
				begin
					KxNew <= SxDBLADD;
					KzNew <= SzDBLADD;
					state <= 6'b001101;
					rstDBLADD <= 1;
				end
				else begin
				    rstDBLADD <= 0;
				end
			end
			6'b001101: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					Qx <= mul;
					state <= 6'b001110;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b001110: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					Qz <= mul;
					state <= 6'b001111;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b001111: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					PxNew <= mul;
					state <= 6'b010000;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b010000: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					PzNew <= mul;
					state <= 6'b010001;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			// converting to edward form, calculating d based on A
			6'b010001: begin
				if (done_mul==1 & rst_mul==0)
				begin
					state <= 6'b010010;
					dx <= mul;
					rst_mul <= 1'b1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b010010: begin
				if (done_mul==1 & rst_mul==0)
				begin
					state <= 6'b010011;
					dx <= mul;
					rst_mul <= 1'b1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b010011: begin
				if (done_mul==1 & rst_mul==0)
				begin
					state <= 6'b010100;
					dz <= mul;
					rst_mul <= 1'b1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b010100: begin
				if (done_mul==1 & rst_mul==0)
				begin
					state <= 6'b010101;
					dz <= mul;
					rst_mul <= 1'b1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b010101: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					PRODx <= mul;
					state <= 6'b010110;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b010110: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					PRODx <= mul;
					state <= 6'b010111;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b010111: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					PRODx <= mul;
					state <= 6'b011000;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b011000: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					PRODz <= mul;
					state <= 6'b011001;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b011001: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					PRODz <= mul;
					state <= 6'b011010;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b011010: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					PRODz <= mul;
					state <= (l[j]) ? 6'b011011 : 6'b011101;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b011011: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					PRODx <= mul;
					state <= 6'b011100;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b011100: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					PRODz <= mul;
					state <= 6'b011101;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b011101: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					dx <= mul;
					state <= 6'b011110;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b011110: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					dz <= mul;
					j <= j+1; 
					state <= (j < 4'b1001) ? ((l[j+1]) ? 6'b011011 : 6'b011101) : 6'b011111;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b011111: begin
				dx <= PRODx;
				dz <= PRODz;
				state <= 6'b100000;
			end
			6'b100000: begin
				if (done_mul==1 & rst_mul==0)
				begin
					AxNew <= mul;
					state <= 6'b100001;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b100001: begin
				if (done_mul==1 & rst_mul==0)
				begin
					AxNew <= mul;
					state <= 6'b100010;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b100010: begin
				if (done_mul==1 & rst_mul==0)
				begin
					AzNew <= mul;
					state <= 6'b100011;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b100011: begin
				done <= 1;
				
			end
			
			// Start of mont consume, i use this instead of dedicated module
			6'b110000: begin
				if (done_mul==1 & rst_mul==0)
				begin
					t0 <= mul;
					state <= 6'b110001;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
				
			end
			6'b110001: begin
				if (done_mul==1 & rst_mul==0)
				begin
					t1 <= mul;
					state <= 6'b111100;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
				
			end
			6'b111100: begin
				if (done_mul==1 & rst_mul==0)
				begin
					t2 <= mul;
					state <= 6'b110010;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
				
			end
			6'b110010: begin
				if (done_mul==1 & rst_mul==0)
				begin
					t1 <= mul;
					state <= 6'b110011;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
				
			end
			6'b110011: begin
				if (done_mul==1 & rst_mul==0)
				begin
					t2 <= mul;
					state <= 6'b110100;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
				
			end
			6'b110100: begin
				if (done_mul==1 & rst_mul==0)
				begin
					Qx <= mul;
					state <= 6'b110101;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
				
			end
			6'b110101: begin
				if (done_mul==1 & rst_mul==0)
				begin
					t2 <= mul;
					state <= 6'b110110;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
				
			end
			6'b110110: begin
				if (done_mul==1 & rst_mul==0)
				begin
					Qz <= mul;
					state <= 6'b001001;
					rst_mul <= 1;
					done_mont <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
				
			end
			// finish of mont consume, i use this instead of dedicated module
			6'b110111: begin
				if (done_mul==1 & rst_mul==0)
				begin
					PRODx <= mul;
					state <= 6'b111000;
					rst_mul <= 1;
				end
				else begin
				    rst_mul <= 0;
				end
				
			end
			6'b111000: begin
				if (done_mul==1 & rst_mul==0)
				begin
					PRODz <= mul;
					state <= 6'b001010;
					rst_mul <= 1;
					done_edw <= 1'b1;
				end
				else begin
				    rst_mul <= 0;
				end
				
			end
			default: begin

			end

		endcase
	end
	
end
always@(*)begin
	case (state)
		6'b000000: begin
			A = Px;
			B = Kx;  
			op = 2'b00;   
			rst_mul_wire = rst_mul;            
        	end
		6'b000001: begin
			A = Pz;
			B = Kz;   
			op = 2'b00;
			rst_mul_wire = rst_mul;                       
        	end
		6'b000010: begin
			A = Qx;
			B = t0;   
			op = 2'b10;   
			rst_mul_wire = rst_mul;                    
        	end
		6'b000011: begin
			A = Px;
			B = Kz; 
			op = 2'b00; 
			rst_mul_wire = rst_mul;                     
        	end
		6'b000100: begin
			A = Pz;
			B = Kx;
			op = 2'b00;
			rst_mul_wire = rst_mul;                       
        	end
		6'b000101: begin
			A = Qz;
			B = t0;
			op = 2'b10; 
			rst_mul_wire = rst_mul;                      
        	end
		6'b000110: begin
			A = Kx;
			B = Kz;
			op = 2'b10;
			rst_mul_wire = rst_mul;                      
        	end
		6'b111001: begin
			A = Kx;
			B = Kz;
			op = 2'b01;  
			rst_mul_wire = rst_mul;                    
        	end
		6'b000111: begin
			PxDBLADD = Kx;
			PzDBLADD = Kz;  
 
			// mul internal connection for xDBLADD
            A = A_DBLADD;
            B = B_DBLADD;
            mul_DBLADD = mul;
            
            op = op_DBLADD;
            
            
            rst_mul_wire = rst_mul_DBLADD;
            done_mul_DBLADD = done_mul;        
        	end
		6'b001000: begin
			PxDBLADD = Mx[i1mod3];
			PzDBLADD = Mz[i1mod3]; 
			QxDBLADD = Kx;
			QzDBLADD = Kz;
			PQxDBLADD = Mx[i2mod3];
			PQzDBLADD = Mz[i2mod3]; 
			// mul internal connection for xDBLADD
            A = A_DBLADD;
            B = B_DBLADD;
            mul_DBLADD = mul;
            
            op = op_DBLADD;

            
            rst_mul_wire = rst_mul_DBLADD;
            done_mul_DBLADD = done_mul;       
        	end
		6'b001001: begin
           		A <= Px;
           		B <= Pz;    
			op = 2'b10;
			rst_mul_wire = rst_mul;   
        	end
		6'b111010: begin
           		A <= Mx[imod3];
           		B <= Mz[imod3]; 
			op = 2'b01; 
			rst_mul_wire = rst_mul;          
        	end
		6'b001010: begin
			A <= Mx[imod3];
          		B <= Mz[imod3];
  			op = 2'b10;
			rst_mul_wire = rst_mul;   

        	end
		6'b111011: begin

        		A <= Mx[imod3];
          		B <= Mz[imod3];
			op = 2'b01;  
			rst_mul_wire = rst_mul;   

        	end
		6'b001011: begin
			PxDBLADD = Mx[i1mod3];
			PzDBLADD = Mz[i1mod3]; 
			QxDBLADD = Kx;
			QzDBLADD = Kz;
			PQxDBLADD = Mx[i2mod3];
			PQzDBLADD = Mz[i2mod3];  
			// mul internal connection for xDBLADD
            A = A_DBLADD;
            B = B_DBLADD;
            mul_DBLADD = mul;
            
            op = op_DBLADD;

            
            rst_mul_wire = rst_mul_DBLADD;
            done_mul_DBLADD = done_mul;         
        	end
		6'b001100: begin
			PxDBLADD = Mx[imod3];
			PzDBLADD = Mz[imod3]; 
			QxDBLADD = Mx[i1mod3];
			QzDBLADD = Mz[i1mod3];
			PQxDBLADD = Kx;
			PQzDBLADD = Kz;  
			// mul internal connection for xDBLADD
            A = A_DBLADD;
            B = B_DBLADD;
            mul_DBLADD = mul;
            
            op = op_DBLADD;
            
            rst_mul_wire = rst_mul_DBLADD;
            done_mul_DBLADD = done_mul;     
        	end
		6'b001101: begin
			A = Qx;
			B = Qx;    
			op = 2'b00; 
			rst_mul_wire = rst_mul;            
        	end
		6'b001110: begin
			A = Qz;
			B = Qz;  
			op = 2'b00;
			rst_mul_wire = rst_mul;                  
        	end
		6'b001111: begin
			A = Qx;
			B = Px; 
			op = 2'b00;
			rst_mul_wire = rst_mul;                   
        	end
		6'b010000: begin
			A = Qz;
			B = Pz; 
			op = 2'b00; 
			rst_mul_wire = rst_mul;                  
        	end
		6'b010001: begin
			A = Ax;
			B = Az;
			op = 2'b10;
			rst_mul_wire = rst_mul;                    
        	end
		6'b010010: begin
			A = dx;
			B = Az;   
			op = 2'b10;  
			rst_mul_wire = rst_mul;               
        	end
		6'b010011: begin
			A = Ax;
			B = Az; 
			op = 2'b01; 
			rst_mul_wire = rst_mul;                  
        	end
		6'b010100: begin
			A = dz;
			B = Az;   
			op = 2'b01;   
			rst_mul_wire = rst_mul;              
        	end
		6'b010101: begin
			A = PRODx;
			B = PRODx; 
			op = 2'b00; 
			rst_mul_wire = rst_mul;                  
        	end
		6'b010110: begin
			A = PRODx;
			B = PRODx;  
			op = 2'b00; 
			rst_mul_wire = rst_mul;                 
        	end
		6'b010111: begin
			A = PRODx;
			B = PRODx; 
			op = 2'b00;  
			rst_mul_wire = rst_mul;                 
        	end
		6'b011000: begin
			A = PRODz;
			B = PRODz;  
			op = 2'b00;  
			rst_mul_wire = rst_mul;                
        	end
		6'b011001: begin
			A = PRODz;
			B = PRODz; 
			op = 2'b00; 
			rst_mul_wire = rst_mul;                  
        	end
		6'b011010: begin
			A = PRODz;
			B = PRODz;  
			op = 2'b00; 
			rst_mul_wire = rst_mul;                 
        	end
		6'b011011: begin
			A = dx;
			B = PRODx; 
			op = 2'b00;  
			rst_mul_wire = rst_mul;                 
        	end
		6'b011100: begin
			A = dz;
			B = PRODz; 
			op = 2'b00;     
			rst_mul_wire = rst_mul;              
        	end
		6'b011101: begin
			A = dx;
			B = dx;    
			op = 2'b00;   
			rst_mul_wire = rst_mul;             
        	end
		6'b011110: begin
			A = dz;
			B = dz;   
			op = 2'b00;    
			rst_mul_wire = rst_mul;             
        	end
		6'b100000: begin
			A = dx;
			B = dz;  
			op = 2'b01; 
			rst_mul_wire = rst_mul;                 
        	end
		6'b100001: begin
			A = AxNew;
			B = AxNew;     
			op = 2'b01; 
			rst_mul_wire = rst_mul;              
        	end
		6'b100010: begin
			A = dz;
			B = dx;  
			op = 2'b10; 
			rst_mul_wire = rst_mul;                 
        	end
        6'b110000: begin
			A = t0;
			B = t1;   
			op = 2'b00;
			rst_mul_wire = rst_mul;                 
        	end
        6'b110001: begin

          		  A <= Mx[imod3];
           		 B <= Mz[imod3];    
			op = 2'b10; 
			rst_mul_wire = rst_mul;                
        	end
        6'b111100: begin
			A <= Px;
           		B <= Pz;
			op = 2'b01;  
			rst_mul_wire = rst_mul;   
               
        	end
        6'b110010: begin
			A = t1;
			B = t2;
			op = 2'b00;  
			rst_mul_wire = rst_mul;                 
        	end
        6'b110011: begin
			A <= t0;
         		B <= t1;
			op = 2'b01; 
			rst_mul_wire = rst_mul;                   
        	end
        6'b110100: begin
			A = Qx;
			B = t2;  
			op = 2'b00;  
			rst_mul_wire = rst_mul;               
        	end
        6'b110101: begin
			A <= t0;
         		B <= t1;  
			op = 2'b10;
			rst_mul_wire = rst_mul;                  
        	end
        6'b110110: begin
			A = Qz;
			B = t2;   
			op = 2'b00;  
			rst_mul_wire = rst_mul;              
        	end
        6'b110111: begin
			A = PRODx;
			B = t0;     
			op = 2'b00; 
			rst_mul_wire = rst_mul;             
        	end
        6'b111000: begin
			A = PRODz;
			B = t1; 
			op = 2'b00; 
			rst_mul_wire = rst_mul;                 
        	end
		default: begin 

		end
	endcase

	case (imod3)
		2'b00: begin
			i1mod3 = 2'b10;
			i2mod3 = 2'b01;                 
        	end
		2'b01: begin
			i1mod3 = 2'b00;
			i2mod3 = 2'b10;                 
        	end
		2'b10: begin
			i1mod3 = 2'b01;
			i2mod3 = 2'b00;                 
        	end
		default: begin
             
        	end
		
	endcase
end

endmodule

