
module CSIDH #(
    parameter N = 512,                          // Prime bit-width
    parameter word_size = 32,
    parameter p = 512'h65b48e8f740f89bffc8ab0d15e3e4c4ab42d083aedc88c425afbfcc69322c9cda7aac6c567f35507516730cc1f0b4f25c2721bf457aca8351b81b90533c6c87b,  // CSIDH-512 prime
    parameter p_inv = 512'hd8c3904b18371bcd3512da337a97b3451232b9eb013dee1eb081b3aba7d05f8534ed3ea7f1de34c4f6fe2bc33e915395fe025ed7d0d3b1aa66c1301f632e294d,  // Precomputed (-p)^-1 mod 2^512
    parameter fp1 = 512'h3496e2e117e0ec8006ea9e5d4383676a97a5ef8a246ee77b4a080672d9ba6c64b0aa7275301955f15d319e67c1e961b47b1bc81750a6af95c8fc8df598726f0a,
    parameter p_minus_1_halves = 512'h32da4747ba07c4dffe455868af1f26255a16841d76e446212d7dfe63499164e6d3d56362b3f9aa83a8b398660f85a792e1390dfa2bd6541a8dc0dc8299e3643d,
    parameter NUM_PRIMES = 74,
    parameter cost_ratio_inv_mul = 128,
    parameter four_sqrt_p = 512'h0000000000000000000000000000000000000000000000000000000000000002856f1399d91d6592142b9541e59682cd38d0cd95f8636a5617895e71e1a20b3f,
    parameter p_plus_one = 512'h65b48e8f740f89bffc8ab0d15e3e4c4ab42d083aedc88c425afbfcc69322c9cda7aac6c567f35507516730cc1f0b4f25c2721bf457aca8351b81b90533c6c87c
) (
    input wire clk,
    input wire rst,
    input wire [N-1:0] A_in,
    input wire [295:0] private,
    output reg [N-1:0] A_out,
    output reg done,
    output reg invalid
);
reg [40:0] cnt;

// Primes stored in 16-bit hex format
wire [11:0] PRIMES [0:NUM_PRIMES-1];

//-----------------------------------------------------------------------------
// Assign each element explicitly
//-----------------------------------------------------------------------------
assign PRIMES[ 0] = 12'h003;
assign PRIMES[ 1] = 12'h005;
assign PRIMES[ 2] = 12'h007;
assign PRIMES[ 3] = 12'h00B;
assign PRIMES[ 4] = 12'h00D;
assign PRIMES[ 5] = 12'h011;
assign PRIMES[ 6] = 12'h013;
assign PRIMES[ 7] = 12'h017;
assign PRIMES[ 8] = 12'h01D;
assign PRIMES[ 9] = 12'h01F;
assign PRIMES[10] = 12'h025;
assign PRIMES[11] = 12'h029;
assign PRIMES[12] = 12'h02B;
assign PRIMES[13] = 12'h02F;
assign PRIMES[14] = 12'h035;
assign PRIMES[15] = 12'h03B;
assign PRIMES[16] = 12'h03D;
assign PRIMES[17] = 12'h043;
assign PRIMES[18] = 12'h047;
assign PRIMES[19] = 12'h049;
assign PRIMES[20] = 12'h04F;
assign PRIMES[21] = 12'h053;
assign PRIMES[22] = 12'h059;
assign PRIMES[23] = 12'h061;
assign PRIMES[24] = 12'h065;
assign PRIMES[25] = 12'h067;
assign PRIMES[26] = 12'h06B;
assign PRIMES[27] = 12'h06D;
assign PRIMES[28] = 12'h071;
assign PRIMES[29] = 12'h07F;
assign PRIMES[30] = 12'h083;
assign PRIMES[31] = 12'h089;
assign PRIMES[32] = 12'h08B;
assign PRIMES[33] = 12'h095;
assign PRIMES[34] = 12'h097;
assign PRIMES[35] = 12'h09D;
assign PRIMES[36] = 12'h0A3;
assign PRIMES[37] = 12'h0A7;
assign PRIMES[38] = 12'h0AD;
assign PRIMES[39] = 12'h0B3;
assign PRIMES[40] = 12'h0B5;
assign PRIMES[41] = 12'h0BF;
assign PRIMES[42] = 12'h0C1;
assign PRIMES[43] = 12'h0C5;
assign PRIMES[44] = 12'h0C7;
assign PRIMES[45] = 12'h0D3;
assign PRIMES[46] = 12'h0DF;
assign PRIMES[47] = 12'h0E3;
assign PRIMES[48] = 12'h0E5;
assign PRIMES[49] = 12'h0E9;
assign PRIMES[50] = 12'h0EF;
assign PRIMES[51] = 12'h0F1;
assign PRIMES[52] = 12'h0FB;
assign PRIMES[53] = 12'h101;
assign PRIMES[54] = 12'h107;
assign PRIMES[55] = 12'h10D;
assign PRIMES[56] = 12'h10F;
assign PRIMES[57] = 12'h115;
assign PRIMES[58] = 12'h119;
assign PRIMES[59] = 12'h11B;
assign PRIMES[60] = 12'h125;
assign PRIMES[61] = 12'h133;
assign PRIMES[62] = 12'h137;
assign PRIMES[63] = 12'h139;
assign PRIMES[64] = 12'h13D;
assign PRIMES[65] = 12'h14B;
assign PRIMES[66] = 12'h151;
assign PRIMES[67] = 12'h15B;
assign PRIMES[68] = 12'h15D;
assign PRIMES[69] = 12'h161;
assign PRIMES[70] = 12'h167;
assign PRIMES[71] = 12'h16F;
assign PRIMES[72] = 12'h175;
assign PRIMES[73] = 12'h24B;

localparam SIZE_2_128 = 129'h100000000000000000000000000000000;
localparam SIZE_2_64  = 65'h10000000000000000;

reg [3:0] es [0:NUM_PRIMES-1]; 
// xISO internal connections
wire doneISO;
reg rstISO;
reg [N-1:0] PxISO, PzISO, AxISO, AzISO, KxISO, KzISO;
wire [N-1:0] PxNewISO, PzNewISO, AxNewISO, AzNewISO, KxNewISO, KzNewISO;
reg [9:0] l_ISO;
reg want_multiple;

// xDBLADD internal connections
reg rstDBLADD;
wire doneDBLADD;
reg [N-1:0] PxDBLADD, PzDBLADD, QxDBLADD, QzDBLADD, PQxDBLADD, PQzDBLADD, AxDBLADD, AzDBLADD;
wire [N-1:0] SxDBLADD, SzDBLADD, RxDBLADD, RzDBLADD; 

// xDBLADD internal connections FOR MUL
wire rstDBLADDMUL;
reg doneDBLADDMUL;
wire [N-1:0] PxDBLADDMUL, PzDBLADDMUL, QxDBLADDMUL, QzDBLADDMUL, PQxDBLADDMUL, PQzDBLADDMUL, AxDBLADDMUL, AzDBLADDMUL;
reg [N-1:0] SxDBLADDMUL, SzDBLADDMUL, RxDBLADDMUL, RzDBLADDMUL;

// xDBLADD internal connections FOR ISO
wire rstDBLADDISO;
reg doneDBLADDISO;
wire [N-1:0] PxDBLADDISO, PzDBLADDISO, QxDBLADDISO, QzDBLADDISO, PQxDBLADDISO, PQzDBLADDISO, AxDBLADDISO, AzDBLADDISO;
reg [N-1:0] SxDBLADDISO, SzDBLADDISO, RxDBLADDISO, RzDBLADDISO;  
    
    // mul internal connection for xDBL
wire [N-1:0] A_DBLADD;
wire [N-1:0] B_DBLADD;
reg [N-1:0] mul_DBLADD;

wire [1:0] op_DBLADD;


wire rst_mul_DBLADD;
reg done_mul_DBLADD;

    // mul internal connection for xDBL in xMUL
reg [N-1:0] A_DBLADDMUL;
reg [N-1:0] B_DBLADDMUL;
wire [N-1:0] mul_DBLADDMUL;

reg [1:0] op_DBLADDMUL;


reg rst_mul_DBLADDMUL;
wire done_mul_DBLADDMUL;

    // mul internal connection for xDBL in xISO
reg [N-1:0] A_DBLADDISO;
reg [N-1:0] B_DBLADDISO;
wire [N-1:0] mul_DBLADDISO;

reg [1:0] op_DBLADDISO;


reg rst_mul_DBLADDISO;
wire done_mul_DBLADDISO;
// mul internal connection for xISO
wire [N-1:0] A_ISO;
wire [N-1:0] B_ISO;
reg [N-1:0] mul_ISO;

wire [1:0] op_ISO;


wire rst_mul_ISO;
reg done_mul_ISO;

// prng rand module wires
wire [N-1:0] rand_prng;

// is_twist module wires
reg [N-1:0] Ax_is_twist, x_is_twist;
reg rst_is_twist;
wire done_is_twist;
wire twist_is_twist;

// mul internal connection for xTWIST
wire [N-1:0] A_TWIST;
wire [N-1:0] B_TWIST;
reg [N-1:0] mul_TWIST;

wire [1:0] op_TWIST;


wire rst_mul_TWIST;
reg done_mul_TWIST;

// affinize internal connections
wire doneAFF;
reg rstAFF;
reg [N-1:0] PxAFF, PzAFF, QxAFF, QzAFF;
wire [N-1:0] PxNewAFF, PzNewAFF, QxNewAFF, QzNewAFF;

// mul internal connection for xAFF
wire [N-1:0] A_AFF;
wire [N-1:0] B_AFF;
reg [N-1:0] mul_AFF;

wire [1:0] op_AFF;


wire rst_mul_AFF;
reg done_mul_AFF;


// xMUL module wires
wire [N-1:0] QxMUL, QzMUL;
wire doneMUL;
reg rstMUL;
reg [N-1:0] PxMUL, PzMUL, AxMUL, AzMUL;
reg [N-1:0] kMUL; 

// mul internal connection for xMUL
wire [N-1:0] A_MUL;
wire [N-1:0] B_MUL;
reg [N-1:0] mul_MUL;

wire [1:0] op_MUL;


wire rst_mul_MUL;
reg done_mul_MUL;

// mul module wires
reg [N-1:0] A;
reg [N-1:0] B;
wire [N-1:0] mul;
reg rst_mul;
reg rst_mul_wire;
wire done_mul;

reg [1:0]op;

    // Instantiate of xADD and xDBL 

    xISOG #(
        .word_size(word_size),
        .N(N),
	.p(p),
	.p_inv(p_inv),
	.fp1(fp1)
    ) uutISO (
        .clk(clk),
        .rst(rstISO),
        .done(doneISO),
        .Px(PxISO),
        .Pz(PzISO),
	.Ax(AxISO),
	.Az(AzISO),
        .Kx(KxISO),
	.Kz(KzISO),
	.l(l_ISO),
	.want_multiple(want_multiple),
	.AxNew(AxNewISO),
	.AzNew(AzNewISO),
	.KxNew(KxNewISO),
	.KzNew(KzNewISO),
	.PxNew(PxNewISO),
	.PzNew(PzNewISO),
		//internal wires
	.A(A_ISO),
	.B(B_ISO),
	.mul(mul_ISO),
	.op(op_ISO),
	.rst_mul_wire(rst_mul_ISO),
	.done_mul(done_mul_ISO),
	//internal wires
	.A_DBLADD(A_DBLADDISO),
	.B_DBLADD(B_DBLADDISO),
	.mul_DBLADD(mul_DBLADDISO),
	.op_DBLADD(op_DBLADDISO),
	.rst_mul_DBLADD(rst_mul_DBLADDISO),
	.done_mul_DBLADD(done_mul_DBLADDISO),
// XDBLADD internals
	.rstDBLADD(rstDBLADDISO),
        .doneDBLADD(doneDBLADDISO),
        .PxDBLADD(PxDBLADDISO),
        .PzDBLADD(PzDBLADDISO),
	.PQxDBLADD(PQxDBLADDISO),
	.PQzDBLADD(PQzDBLADDISO),
        .QxDBLADD(QxDBLADDISO),
	.QzDBLADD(QzDBLADDISO),
	.AxDBLADD(AxDBLADDISO),
	.AzDBLADD(AzDBLADDISO),
	.RxDBLADD(RxDBLADDISO),
	.RzDBLADD(RzDBLADDISO),
	.SxDBLADD(SxDBLADDISO),
	.SzDBLADD(SzDBLADDISO)
    );
    // Instantiate the Barrett Reduction FSM
    xDBLADD #(
        .word_size(word_size),
        .N(N),
	.p(p),
	.p_inv(p_inv),
	.fp1(fp1)
    ) uutDBLADD (
        .clk(clk),
        .rst(rstDBLADD),
        .done(doneDBLADD),
        .Px(PxDBLADD),
        .Pz(PzDBLADD),
	.PQx(PQxDBLADD),
	.PQz(PQzDBLADD),
        .Qx(QxDBLADD),
	.Qz(QzDBLADD),
	.Ax(AxDBLADD),
	.Az(AzDBLADD),
	.Rx(RxDBLADD),
	.Rz(RzDBLADD),
	.Sx(SxDBLADD),
	.Sz(SzDBLADD),
	//internal wires
	.A(A_DBLADD),
	.B(B_DBLADD),
	.mul(mul_DBLADD),
	.op(op_DBLADD),
	.rst_mul(rst_mul_DBLADD),
	.done_mul(done_mul_DBLADD)
    );

    is_twist #(
        .word_size(word_size),
        .N(N),
	.p(p),
	.p_inv(p_inv),
	.p_minus_1_halves(p_minus_1_halves),
	.fp1(fp1)
    ) uut_is_twist (
        .clk(clk),
        .rst(rst_is_twist),
        .done(done_is_twist),
        .Ax(Ax_is_twist),
        .x(x_is_twist),
	.twist(twist_is_twist),
		//internal wires
	.A(A_TWIST),
	.B(B_TWIST),
	.mul(mul_TWIST),
	.op(op_TWIST),
	.rst_mul(rst_mul_TWIST),
	.done_mul(done_mul_TWIST)
	
    );
    affinize #(
        .word_size(word_size),
        .N(N),
	.p(p),
	.p_inv(p_inv),
	.p_minus_1_halves(p_minus_1_halves),
	.fp1(fp1)
    ) uut_affinize (
        .clk(clk),
        .rst(rstAFF),
        .done(doneAFF),
        .Px(PxAFF),
        .Pz(PzAFF),
        .Qx(QxAFF),
	.Qz(QzAFF),
	.PxNew(PxNewAFF),
	.PzNew(PzNewAFF),
	.QxNew(QxNewAFF),
	.QzNew(QzNewAFF),
		//internal wires
	.A(A_AFF),
	.B(B_AFF),
	.mul(mul_AFF),
	.op(op_AFF),
	.rst_mul(rst_mul_AFF),
	.done_mul(done_mul_AFF)
    );
    xMUL #(
        .word_size(word_size),
        .N(N),
	.p(p),
	.p_inv(p_inv),
	.fp1(fp1)
    ) uutxMUL (
        .clk(clk),
        .rst(rstMUL),
        .done(doneMUL),
        .Px(PxMUL),
        .Pz(PzMUL),
        .Qx(QxMUL),
	.Qz(QzMUL),
	.Ax(AxMUL),
	.Az(AzMUL),
	.k(kMUL),
		//internal wires
	.A(A_MUL),
	.B(B_MUL),
	.mul(mul_MUL),
	.op(op_MUL),
	.rst_mul(rst_mul_MUL),
	.done_mul(done_mul_MUL),
		//internal wires
	.A_DBLADD(A_DBLADDMUL),
	.B_DBLADD(B_DBLADDMUL),
	.mul_DBLADD(mul_DBLADDMUL),
	.op_DBLADD(op_DBLADDMUL),
	.rst_mul_DBLADD(rst_mul_DBLADDMUL),
	.done_mul_DBLADD(done_mul_DBLADDMUL),
	// XDBLADD internals
	.rstU(rstDBLADDMUL),
        .doneU(doneDBLADDMUL),
        .PxU(PxDBLADDMUL),
        .PzU(PzDBLADDMUL),
	.PQxU(PQxDBLADDMUL),
	.PQzU(PQzDBLADDMUL),
        .QxU(QxDBLADDMUL),
	.QzU(QzDBLADDMUL),
	.AxU(AxDBLADDMUL),
	.AzU(AzDBLADDMUL),
	.RxU(RxDBLADDMUL),
	.RzU(RzDBLADDMUL),
	.SxU(SxDBLADDMUL),
	.SzU(SzDBLADDMUL)
    );
    full_multiplication #(
        .word_size(word_size),
        .N(N),
	.p(p),
	.p_inv(p_inv)
    ) uut1 (
        .clk(clk),
        .rst(rst_mul_wire),
        .done(done_mul),
        .A(A),
        .B(B),
	.C(mul),
	.op(op),
	.rand_prng(rand_prng)
    );


reg [5:0] state;
reg [N-1:0] Ax;
reg [N-1:0] Az;
reg [N-1:0] Px;
reg [N-1:0] Pz;
reg [N-1:0] Kx;
reg [N-1:0] Kz;
reg [N-1:0] tx;
reg [N-1:0] tz;

reg [N-1:0] k;
reg [N-1:0] cof;
reg [N-1:0] order;

reg twist;
reg [4:0] batch_size;
reg [6:0] prime_index;
reg [6:0] j;
reg [73:0] batch;
reg [73:0] seen;
reg [256:0] len_com;

integer i;

always@(posedge clk)
begin
	if (rst)
	begin
		cnt <= 0;
		rstISO <= 1'b1;
		j <= 0;
		batch <= 0;
		seen <= 0;
		cof <= 512'h1;
		order <= 512'h1;
		state <= 6'b000000;
		done <= 0;
		rst_mul <= 1'b1;
		batch_size <= 5'b00000;
		prime_index <= 7'b0;
		twist <= 1'b0;
		batch <= 74'b0;
		k <= 3'b100;
		rst_is_twist <= 1'b1;
		rstMUL <= 1'b1;
		rstAFF <= 1;
		// creating matrix
		for (i = 0; i < 74; i = i + 1) begin
      		// Map private[4i+3 : 4i] to es[i] (e.g., es[0] = private[3:0], es[1] = private[7:4], etc.)
      			es[73-i] <= private[4*i + 3 -: 4]; // -: notation for descending bit ranges
    		end
	end
	else 
	begin	
		cnt <= cnt + 1'b1;
		case(state)
			// start of validation of A_in
			6'b000000: begin
				if((A_in==512'h2) || (A_in > p))
				begin
					state <= 6'b111111;
				end
				else 
				begin
					state <= 6'b000001;
				end
			end
			6'b000001: begin
				Ax <= A_in;
				Az <= fp1;
				Pz <= fp1;
				if(A_in==mul)
				begin
					state <= 6'b111111;
				end
				else if (A_in==0)
				begin
					state <= 6'b000011;  
					Px <=  512'h273c2f8526afd895542e3af074bf6ec391645813a4982ec0c8fea9978660edef37e3979722a671ad1b2265995fae6fb740d0b3fc1d398d67092b3dac66979829;
				end
				else 
				begin
					state <= 6'b000010;
				end
			end
			// finish of validation.
			// assigning P 
			6'b000010: begin
				
				if (done_mul==1 & rst_mul==0)
				begin
					Px <= mul;
					rst_mul <= 1;
					state <= 6'b000011;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			// creating batch of 16 for not twisted
			6'b000011: begin
				if ((batch_size == 5'b10000) || (prime_index == 7'b1001010))
				begin
					if (batch_size == 5'b00000) begin
						state <= 6'b000100;
						twist <= 1'b1;
						prime_index <= 0;
					end
					else begin
						state <= 6'b000101;
						prime_index <= 0;
					end
				end
				else if ((es[prime_index][3] == twist) && (es[prime_index][2:0] != 3'b000))
				begin
					batch[prime_index] <= 1'b1;
					batch_size <= batch_size + 1'b1;
					prime_index <= prime_index + 1'b1;
				end
				else
				begin
					prime_index <= prime_index + 1'b1;
				end
			end
			6'b000100: begin
				if ((batch_size == 5'b10000) || (prime_index == 7'b1001010))
				begin
					state <= ((batch_size == 5'b00000) ? 6'b010110 : 6'b000101);
					prime_index <= 0;
				end
				else if ((es[prime_index][3] == twist) && (es[prime_index][2:0] != 3'b000))
				begin
					batch[prime_index] <= 1'b1;
					batch_size <= batch_size + 1'b1;
					prime_index <= prime_index + 1'b1;
				end
				else
				begin
					prime_index <= prime_index + 1'b1;
				end
			end
			// calculting k, multiply all primes excpet those in the batch
			6'b000101: begin
				if (prime_index == 7'b1001010)
				begin
					state <= 6'b000110;
					prime_index <= 7'b0;
				end
				else if (batch[prime_index] == 1'b0) begin
					if (done_mul==1 & rst_mul==0)
					begin
						k <= mul;
						prime_index <= prime_index + 1'b1;
						rst_mul <= 1;
					end
					else begin
					rst_mul <= 0;
					end
				end
				else begin
					prime_index <= prime_index + 1'b1;
				end
			end
			6'b000110: begin
				
				if (done_is_twist==1 & rst_is_twist==0)
				begin
					state <= ((twist_is_twist == twist) ? 6'b001001 : 6'b000111);
					rst_is_twist <= 1;
				end
				else begin
				    rst_is_twist <= 0;
				end
			end
			6'b000111: begin
				if (done_mul==1 & rst_mul==0)
				begin
					Px <= mul;
					rst_mul <= 1;
					state <= 6'b001000;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b001000: begin
				if (done_mul==1 & rst_mul==0)
				begin
					Px <= mul;
					rst_mul <= 1;
					state <= 6'b001001;
				end
				else begin
				    rst_mul <= 0;
				end
			end
			6'b001001: begin
				
				if (doneMUL==1 & rstMUL==0)
				begin
					Px <= QxMUL;
					Pz <= QzMUL;
					state <= 6'b001010;
					rstMUL <= 1;
					prime_index <= 7'b1001001; 
				end
				else begin
				    rstMUL <= 0;
				end
			end
			// start of iso for batch
			6'b001010: begin
				if (prime_index > 7'b1001010) begin
					state <= 6'b010000;
				end
				else if (batch[prime_index] == 1'b0) begin
					prime_index <= prime_index - 1'b1;
				end
				// // Compute the cofactor for the current prime.
				else begin
					if (j == prime_index)
					begin
						state <= 6'b001011;
						j <= 0;
					end 
					else if (batch[j])
					begin
						if (done_mul==1 & rst_mul==0)
						begin
							cof <= mul;
							rst_mul <= 1;
							j <= j + 1'b1;
						end
						else begin
							rst_mul <= 0;
						end
					end
					else begin
						j <= j + 1'b1;
					end
				end
			end
			6'b001011: begin
				if (cof < len_com) begin
					state <= 6'b001100;
				end
				else begin
					if (doneAFF==1 & rstAFF==0)
					begin
						Px <= PxNewAFF;
						Pz <= PzNewAFF;
						Ax <= QxNewAFF;
						Az <= QzNewAFF;
						rstAFF <= 1;
						state <= 6'b001100;
					end
					else begin
						rstAFF <= 0;
					end
				end
			end
			6'b001100: begin
				if (doneMUL==1 & rstMUL==0)
				begin
					Kx <= QxMUL;
					Kz <= QzMUL;
					state <= 6'b001101;
					rstMUL <= 1; 
				end
				else begin
					rstMUL <= 0;
				end
			end
			6'b001101: begin
				if (Kz == 0) begin
					state <= 6'b001010;
					prime_index <= prime_index - 1'b1;
					
				end
				else begin
					if (doneISO==1 & rstISO==0)
					begin
						Ax <= AxNewISO;
						Az <= AzNewISO;
						Px <= PxNewISO;
						Pz <= PzNewISO;
						Kx <= KxNewISO;
						Kz <= KzNewISO;
						state <= 6'b001110;
						rstISO <= 1; 
					end
					else begin
						rstISO <= 0;
					end
				end
			end
			6'b001110: begin
				if (~seen[prime_index])
				begin
					if (Kz != 0)
					begin	
						state <= 6'b111111;	
					end
					else begin
						if (done_mul==1 & rst_mul==0)
						begin
							order <= mul;
							rst_mul <= 1;
							state <= 6'b001111;
							seen[prime_index] <= 1'b1;
						end
						else begin
							rst_mul <= 0;
						end
					end
				end
				else begin
					state <= 6'b001111;
				end
			end
			6'b001111: begin
				es[prime_index] <= es[prime_index] - 1'b1;
				prime_index <= prime_index - 1'b1;
				cof <= 512'h1;
				state <= 6'b001010;
			end
			6'b010000: begin
				if (Az == 0) begin
					state <= 6'b111111;
				end
				else begin
					Px <= rand_prng;
					Pz <= fp1;
					state <= ((Ax == 0) ? 6'b010101 : 6'b010001);
					batch <= 0;
					prime_index <= 0;
					batch_size <= 0;
					k <= 3'b100;
				end
			end
			6'b010001: begin
				if (done_mul==1 & rst_mul==0)
				begin
					Px <= mul;
					state <= 6'b010010;
					rst_mul <= 1;
				end
				else begin
					rst_mul <= 0;
				end
			end
			6'b010010: begin
				if (done_mul==1 & rst_mul==0)
				begin
					Px <= mul;
					rst_mul <= 1;
					state <= 6'b010011;
				end
				else begin
				    rst_mul <= 0;
				end
				tx <= Ax;
				tz <= Az;
			end
			6'b010011: begin
				if (done_mul==1 & rst_mul==0)
				begin
					tz <= mul;
					state <= 6'b010100;
					rst_mul <= 1;
				end
				else begin
					rst_mul <= 0;
				end
			end
			6'b010100: begin
				if (doneAFF==1 & rstAFF==0)
				begin
					Px <= PxNewAFF;
					Pz <= PzNewAFF;
					Ax <= QxNewAFF;
					Az <= QzNewAFF;
					rstAFF <= 1;
					state <= 6'b000011;
				end
				else begin
					rstAFF <= 0;
				end
			end
			6'b010101: begin
				if (doneAFF==1 & rstAFF==0)
				begin
					Ax <= QxNewAFF;
					Az <= QzNewAFF;
					rstAFF <= 1;
					state <= 6'b000011;
				end
				else begin
					rstAFF <= 0;
				end
			end
			6'b010110: begin
				if (done_mul==1 & rst_mul==0)
				begin
					A_out <= mul;
					state <= 6'b010111;
					rst_mul <= 1;
				end
				else begin
					rst_mul <= 0;
				end
			end
			6'b010111: begin
				Px <= rand_prng;
				Pz <= fp1;
				if (order[N-1:N/2] > four_sqrt_p[N-1:N/2]) begin
					state <= 6'b111110;
				end
				else if (order[N-1:N/2] == four_sqrt_p[N-1:N/2]) begin
					state <= 6'b011000;
				end
				else begin
					state <= 6'b011001;
				end
			end
			6'b011000: begin
				if (order[N/2-1:0] > four_sqrt_p[N/2-1:0]) begin
					state <= 6'b111110;
				end
				else begin
					state <= 6'b011001;
				end
			end
			6'b011001: begin
				if (doneMUL==1 & rstMUL==0)
				begin
					Kx <= QxMUL;
					Kz <= QzMUL;
					rstMUL <= 1;
					state <= 6'b011010;
				end
				else begin
					rstMUL <= 0;
				end
			end
			6'b011010: begin
				if (Kz == 0) begin
					state <= 6'b111110;
				end
				else begin 
					state <= 6'b111111;
				end 
			end
			6'b111110: begin
				done <= 1'b1;
			end
			6'b111111: begin
				invalid <= 1'b1;
			end
			default: begin

			end

		endcase
	end
	
end
always@(*)begin
	case (state)
		6'b000000: begin
			A = p;
			B = 2'b10; 
			op = 2'b10; 
			rst_mul_wire = rst_mul;               
        	end
		6'b000010: begin
			A = A_in;
			B = rand_prng;
			op = 2'b00;  
			rst_mul_wire = rst_mul;                
        	end
		6'b000101: begin
			A = k;
			B = PRIMES[prime_index];   
			op = 2'b11; 
			rst_mul_wire = rst_mul;  
             
        	end	
		6'b000110: begin
			Ax_is_twist = Ax;
			x_is_twist = Px; 
			// mul internal connection for xTWIST
            A = A_TWIST;
            B = B_TWIST;
            mul_TWIST = mul;
            op = op_TWIST;
            
            rst_mul_wire = rst_mul_TWIST;
            done_mul_TWIST = done_mul;                    
        	end	
		6'b000111: begin
			A = Ax;
			B = Px; 
			op = 2'b01;  
			rst_mul_wire = rst_mul;                
        	end
		6'b001000: begin
			A = 0;
			B = Px;  
			op = 2'b10;
			rst_mul_wire = rst_mul;   	               
        	end
		6'b001001: begin
			PxMUL = Px;
			PzMUL = Pz;
			AxMUL = Ax;
			AzMUL = Az;
			kMUL = k; 
			// mul internal connection for xMUL
            A = A_MUL;
            B = B_MUL;
            mul_MUL = mul;
 	    op = op_MUL;
           

            rst_mul_wire= rst_mul_MUL;
            done_mul_MUL = done_mul;    
		//XDBL INTERCONECTS
			PxDBLADD = PxDBLADDMUL;
			PzDBLADD = PzDBLADDMUL;      
			AxDBLADD = AxDBLADDMUL;
			AzDBLADD = AzDBLADDMUL;
			QxDBLADD = QxDBLADDMUL;
			QzDBLADD = QzDBLADDMUL;
			PQxDBLADD = PQxDBLADDMUL;
			PQzDBLADD = PQzDBLADDMUL;
			
			RxDBLADDMUL = RxDBLADD;
			RzDBLADDMUL = RzDBLADD;
			SxDBLADDMUL = SxDBLADD;
			SzDBLADDMUL = SzDBLADD;

			rstDBLADD = rstDBLADDMUL;
			doneDBLADDMUL = doneDBLADD;
		// multiplyier interconnects for xdblmul
		 A_DBLADDMUL = A_DBLADD;
           	 B_DBLADDMUL = B_DBLADD;
            	 mul_DBLADD = mul_DBLADDMUL;
		op_DBLADDMUL = op_DBLADD;

            
            rst_mul_DBLADDMUL = rst_mul_DBLADD;
            done_mul_DBLADD = done_mul_DBLADDMUL; 
             
     
        	end
		6'b001010: begin
			A = cof;
			B = PRIMES[j];  
			op = 2'b11;
			rst_mul_wire = rst_mul;                  
        	end	
		6'b001011: begin
			if (Az == fp1)
			begin
				len_com = SIZE_2_128;
			end
			else begin

				len_com = SIZE_2_64; 
			end  
			PxAFF = Px;
			PzAFF = Pz;
			QxAFF = Ax;
			QzAFF = Az; 
			// mul internal connection for xAFF
            A = A_AFF;
            B = B_AFF;
            mul_AFF = mul;
            op = op_AFF;
						
            
            rst_mul_wire = rst_mul_AFF;
            done_mul_AFF = done_mul;          
        	end
		6'b001100: begin
			PxMUL = Px;
			PzMUL = Pz;
			AxMUL = Ax;
			AzMUL = Az;
			kMUL = cof;  
			// mul internal connection for xMUL
            A = A_MUL;
            B = B_MUL;
            mul_MUL = mul;
            op = op_MUL;

            
            rst_mul_wire = rst_mul_MUL;
            done_mul_MUL = done_mul;      
		//XDBL INTERCONECTS
			PxDBLADD = PxDBLADDMUL;
			PzDBLADD = PzDBLADDMUL;      
			AxDBLADD = AxMUL;
			AzDBLADD = AzMUL;
			QxDBLADD = QxDBLADDMUL;
			QzDBLADD = QzDBLADDMUL;
			PQxDBLADD = PQxDBLADDMUL;
			PQzDBLADD = PQzDBLADDMUL;
			
			RxDBLADDMUL = RxDBLADD;
			RzDBLADDMUL = RzDBLADD;
			SxDBLADDMUL = SxDBLADD;
			SzDBLADDMUL = SzDBLADD;

			rstDBLADD = rstDBLADDMUL;
			doneDBLADDMUL = doneDBLADD;
		// multiplyier interconnects for xdblmul
		 A_DBLADDMUL = A_DBLADD;
           	 B_DBLADDMUL = B_DBLADD;
            	 mul_DBLADD = mul_DBLADDMUL;
            	 op_DBLADDMUL = op_DBLADD;

            
            rst_mul_DBLADDMUL = rst_mul_DBLADD;
            done_mul_DBLADD = done_mul_DBLADDMUL; 
                       
        	end	
		6'b001101: begin
			PxISO = Px;
			PzISO = Pz;
			AxISO = Ax;
			AzISO = Az;
			KxISO = Kx;
			KzISO = Kz;
			l_ISO = PRIMES[prime_index]; 
			want_multiple = ~seen[prime_index]; 
			// mul internal connection for xISO
            A = A_ISO;
            B = B_ISO;
            mul_ISO = mul;
            op = op_ISO;

            
            rst_mul_wire = rst_mul_ISO;
            done_mul_ISO = done_mul;

		//XDBL INTERCONECTS
			PxDBLADD = PxDBLADDISO;
			PzDBLADD = PzDBLADDISO;      
			AxDBLADD = AxDBLADDISO;
			AzDBLADD = AzDBLADDISO;
			QxDBLADD = QxDBLADDISO;
			QzDBLADD = QzDBLADDISO;
			PQxDBLADD = PQxDBLADDISO;
			PQzDBLADD = PQzDBLADDISO;
			
			RxDBLADDISO = RxDBLADD;
			RzDBLADDISO = RzDBLADD;
			SxDBLADDISO = SxDBLADD;
			SzDBLADDISO = SzDBLADD;

			rstDBLADD = rstDBLADDISO;
			doneDBLADDISO = doneDBLADD;
		// multiplyier interconnects for xdblmul
		 A_DBLADDISO = A_DBLADD;
           	 B_DBLADDISO = B_DBLADD;
            	 mul_DBLADD = mul_DBLADDISO;
            	 op_DBLADDISO = op_DBLADD;

            
            rst_mul_DBLADDISO = rst_mul_DBLADD;
            done_mul_DBLADD = done_mul_DBLADDISO; 
                              
        	end	
		6'b001110: begin
			A = order;
			B = PRIMES[prime_index]; 
			op = 2'b11; 
			rst_mul_wire = rst_mul;                  
        	end	
		6'b010001: begin
			A = Px;
			B = Px;  
			op = 2'b00; 
			rst_mul_wire = rst_mul;                 
        	end
		6'b010010: begin
			A = Px;
			B = fp1;   
			op = 2'b10; 
			rst_mul_wire = rst_mul;              
        	end
		6'b010011: begin
			A = Px;
			B = tz;  
			op = 2'b00;
			rst_mul_wire = rst_mul;                
        	end
		6'b010100: begin
			PxAFF = tx;
			PzAFF = tz;
			QxAFF = Ax;
			QzAFF = Az; 
			// mul internal connection for xAFF
            A = A_AFF;
            B = B_AFF;
            mul_AFF = mul;
	    op = op_AFF;
            
            rst_mul_wire = rst_mul_AFF;
            done_mul_AFF = done_mul;             
        	end
		6'b010101: begin
			PxAFF = fp1;
			PzAFF = fp1;
			QxAFF = Ax;
			QzAFF = Az; 
			// mul internal connection for xAFF
            A = A_AFF;
            B = B_AFF;
            mul_AFF = mul;
            
	    op = op_AFF;
            
            rst_mul_wire = rst_mul_AFF;

        	end
		6'b010110: begin
			A = Ax;
			B = 1'b1;  
			op = 2'b00;   
			rst_mul_wire = rst_mul;               
        	end
		6'b011001: begin
			PxMUL = Px;
			PzMUL = Pz;
			AxMUL = Ax;
			AzMUL = Az;
			kMUL = p_plus_one;  
			// mul internal connection for xMUL
         	 	A = A_MUL;
     	  		B = B_MUL;
         		mul_MUL = mul;
         		op = op_MUL;

            
          		rst_mul_wire = rst_mul_MUL;
         		done_mul_MUL = done_mul;      
		//XDBL INTERCONECTS
			PxDBLADD = PxDBLADDMUL;
			PzDBLADD = PzDBLADDMUL;      
			AxDBLADD = AxMUL;
			AzDBLADD = AzMUL;
			QxDBLADD = QxDBLADDMUL;
			QzDBLADD = QzDBLADDMUL;
			PQxDBLADD = PQxDBLADDMUL;
			PQzDBLADD = PQzDBLADDMUL;
			
			RxDBLADDMUL = RxDBLADD;
			RzDBLADDMUL = RzDBLADD;
			SxDBLADDMUL = SxDBLADD;
			SzDBLADDMUL = SzDBLADD;

			rstDBLADD = rstDBLADDMUL;
			doneDBLADDMUL = doneDBLADD;
		// multiplyier interconnects for xdblmul
			A_DBLADDMUL = A_DBLADD;
           		B_DBLADDMUL = B_DBLADD;
            		mul_DBLADD = mul_DBLADDMUL;
            		op_DBLADDMUL = op_DBLADD;

            
          		rst_mul_DBLADDMUL = rst_mul_DBLADD;
          		done_mul_DBLADD = done_mul_DBLADDMUL; 
                       
        	end	
		default: begin 

		end
	endcase

	
end

endmodule