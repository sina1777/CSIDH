module xMUL #(
    parameter N = 512,                          // Prime bit-width
    parameter word_size = 32,
    parameter p = 512'h65b48e8f740f89bffc8ab0d15e3e4c4ab42d083aedc88c425afbfcc69322c9cda7aac6c567f35507516730cc1f0b4f25c2721bf457aca8351b81b90533c6c87b,  // CSIDH-512 prime
    parameter p_inv = 512'hd8c3904b18371bcd3512da337a97b3451232b9eb013dee1eb081b3aba7d05f8534ed3ea7f1de34c4f6fe2bc33e915395fe025ed7d0d3b1aa66c1301f632e294d,  // Precomputed (-p)^-1 mod 2^512
    parameter fp1 = 512'h3496e2e117e0ec8006ea9e5d4383676a97a5ef8a246ee77b4a080672d9ba6c64b0aa7275301955f15d319e67c1e961b47b1bc81750a6af95c8fc8df598726f0a
) (
    input wire clk,
    input wire rst,
    input wire [N-1:0] Px, Pz, Ax, Az,
    input wire [N-1:0] k,
    output reg [N-1:0] Qx, Qz,
    output reg done,
    
    
    // xDBLADD
    input wire doneU,
    output reg rstU,
    
    output reg [N-1:0] PxU, PzU, QxU, QzU, PQxU, PQzU,
    output wire [N-1:0] AxU, AzU,
    input wire [N-1:0] RxU, RzU, SxU, SzU, 
    
        // internal wires
    output wire [N-1:0] A,
    output wire [N-1:0] B,
    input wire [N-1:0] mul,
    
    output wire [1:0] op,
    
    output wire rst_mul,
    input wire done_mul,
    
    // mul internal connection for xDBLADD
    input wire [N-1:0] A_DBLADD,
    input wire [N-1:0] B_DBLADD,
    output wire [N-1:0] mul_DBLADD,
    input wire [1:0] op_DBLADD,

    
    input wire rst_mul_DBLADD,
    output wire done_mul_DBLADD
    
);

assign A = A_DBLADD;
assign B = B_DBLADD;
assign mul_DBLADD = mul;

assign op = op_DBLADD;


assign rst_mul = rst_mul_DBLADD;
assign done_mul_DBLADD = done_mul;

assign AxU = Ax;
assign AzU = Az;

reg [N-1:0] Rx, Rz;
reg [N-1:0] Pcopyx, Pcopyz;

reg [8:0] i;
reg [2:0] state;
reg done_len;



   
always@(posedge clk)
begin
	if (rst)
	begin
		
		rstU <= 1'b1;
		state <= 3'b000;
		done <= 0;
		i <= 9'b111111111;
		//R = P
		Rx <= Px;
		Rz <= Pz;
		// Pcopy = P
		Pcopyx <= Px;
		Pcopyz <= Pz;

		// Q = point in infinity Qx = fp1, Qz = fp0
		Qx <= fp1;
		Qz <= 0;
		done_len <= 1'b0;
	end
	else if (done_len == 1'b0)
	begin
		if (k[i]) begin
			done_len <= 1'b1;
		end
		else begin
			i <= i - 1'b1;
		end
	end
	else 
	begin
		case(state)
			// initializtion phase
			3'b000: begin
				if (k[i]==1) begin
					state <= 3'b001;
					Qx <= Rx;
					Qz <= Rz;
					Rx <= Qx;
					Rz <= Qz;
				end
				else begin
					state <= 3'b010;
				end
				
			end
			3'b001: begin
				
				if (doneU==1 & rstU==0)
				begin
					// in this case we shoud inverse the Q and R again
					Qx <= SxU;
					Qz <= SzU;
					Rx <= RxU;
					Rz <= RzU;
					rstU <= 1;
					if (i == 0) begin
						state <= 3'b011;
					end
					else begin
						i <= i-1;
						state <= 3'b000;
					end
				end
				else
				begin
		          rstU <= 0;
				end	
				
			end
			3'b010: begin
				
				if (doneU==1 & rstU==0)
				begin
					// in this case we shoud inverse the Q and R again
					Qx <= RxU;
					Qz <= RzU;
					Rx <= SxU;
					Rz <= SzU;
					rstU <= 1;
					if (i == 0) begin
						state <= 3'b011;
					end
					else begin
						i <= i-1;
						state <= 3'b000;
					end
				end
				else
				begin
		          rstU <= 0;
				end	
				
			end
			3'b011: begin
				done <= 1'b1;
			end
			default: begin

			end

		endcase
	end
end
always@(*)begin
	// defining xDBLADD inputs
	PxU = Qx;
	PzU = Qz;

	QxU = Rx;
	QzU = Rz;

	PQxU = Pcopyx;
	PQzU = Pcopyz;	
	
end

endmodule

