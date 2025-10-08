`timescale 1ns / 1ns
// 32 位 ALU  —— 组合逻辑，不产生时序单元。
// A, B: 操作数。Op: 功能码。C: 结果。Over: 仅对 ADD / SUB (有符号) 置位。
// 需要加法/减法时复用下方的 adder 模块（超前进位实现来自实验1）。

module alu(
	input  wire [31:0] A,
	input  wire [31:0] B,
	input  wire [5:0]  Op,
	output reg  [31:0] C,
	output reg         Over
);
	// 预先做加/减，两份结果，方便 case 中直接挑。
	wire [31:0] add_sum, sub_sum;
	wire add_of, sub_dummy_of;  // 减法不用 adder 自带的 overflow 判定，自己按题目公式算。

	// 加法：A + B
	adder u_add (
		.a(A), .b(B), .cin(1'b0), .sum(add_sum), .cout(), .overflow(add_of)
	);

	// 减法：A + (~B + 1)
	adder u_sub (
		.a(A), .b(~B), .cin(1'b1), .sum(sub_sum), .cout(), .overflow(sub_dummy_of)
	);

	// 有符号溢出判定：
	wire add_overflow_signed = (A[31] == B[31]) && (add_sum[31] != A[31]);
	wire sub_overflow_signed = (A[31] != B[31]) && (sub_sum[31] != A[31]);

	// 移位位数只取 A[4:0]
	wire [4:0] shamt = A[4:0];

	always @* begin
		C    = 32'h0;
		Over = 1'b0;
		case (Op)
			6'b100000: begin // ADD 有符号
				C    = add_sum;
				Over = add_overflow_signed;  // 不用无符号那套
			end
			6'b100001: begin // ADDU 无符号
				C    = add_sum;
				Over = 1'b0;
			end
			6'b100010: begin // SUB 有符号
				C    = sub_sum;
				Over = sub_overflow_signed;
			end
			6'b100011: begin // SUBU 无符号
				C    = sub_sum;
				Over = 1'b0;
			end
			6'b000000: begin // SLL 逻辑左移 (B << shamt)
				C    = B << shamt;
			end
			6'b000010: begin // SRL 逻辑右移 (B >> shamt)
				C    = B >> shamt;
			end
			6'b000011: begin // SRA 算术右移
				C    = $signed(B) >>> shamt;
			end
			6'b100100: begin // AND
				C    = A & B;
			end
			6'b100101: begin // OR
				C    = A | B;
			end
			6'b100110: begin // XOR
				C    = A ^ B;
			end
			6'b100111: begin // NOR
				C    = ~(A | B);
			end
			default: begin
				C    = 32'h0000_0000;
				Over = 1'b0;
			end
		endcase
	end
endmodule

// ------------------------------------------------------------
// 下方是来自实验1的超前进位加法器（精简注释版）。
// ------------------------------------------------------------

module cla4(
	input  wire [3:0] a,
	input  wire [3:0] b,
	input  wire       cin,
	output wire [3:0] sum,
	output wire       cout,
	output wire       P_group,
	output wire       G_group
);
	wire [3:0] p = a ^ b;
	wire [3:0] g = a & b;
	wire c1, c2, c3, c4;

	assign c1 = g[0] | (p[0] & cin);
	assign c2 = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
	assign c3 = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);
	assign c4 = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & cin);

	assign sum[0] = p[0] ^ cin;
	assign sum[1] = p[1] ^ c1;
	assign sum[2] = p[2] ^ c2;
	assign sum[3] = p[3] ^ c3;
	assign cout   = c4;

	assign P_group = &p;
	assign G_group = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
endmodule

module cla32(
	input  wire [31:0] a,
	input  wire [31:0] b,
	input  wire        cin,
	output wire [31:0] sum,
	output wire        cout,
	output wire        overflow
);
	wire [7:0] P_blk, G_blk;
	wire [8:0] C;  // C[0]=cin, C[8]=cout
	assign C[0] = cin;

	genvar i;
	generate for(i=0;i<8;i=i+1) begin: G_CLA4
		cla4 u (
			.a(a[4*i+3:4*i]), .b(b[4*i+3:4*i]), .cin(C[i]),
			.sum(sum[4*i+3:4*i]), .cout(), .P_group(P_blk[i]), .G_group(G_blk[i])
		);
	end endgenerate

	assign C[1] = G_blk[0] | (P_blk[0] & C[0]);
	assign C[2] = G_blk[1] | (P_blk[1] & G_blk[0]) | (P_blk[1] & P_blk[0] & C[0]);
	assign C[3] = G_blk[2] | (P_blk[2] & G_blk[1]) | (P_blk[2] & P_blk[1] & G_blk[0]) | (P_blk[2] & P_blk[1] & P_blk[0] & C[0]);
	assign C[4] = G_blk[3] | (P_blk[3] & G_blk[2]) | (P_blk[3] & P_blk[2] & G_blk[1]) | (P_blk[3] & P_blk[2] & P_blk[1] & G_blk[0]) | (P_blk[3] & P_blk[2] & P_blk[1] & P_blk[0] & C[0]);
	assign C[5] = G_blk[4] | (P_blk[4] & G_blk[3]) | (P_blk[4] & P_blk[3] & G_blk[2]) | (P_blk[4] & P_blk[3] & P_blk[2] & G_blk[1]) | (P_blk[4] & P_blk[3] & P_blk[2] & P_blk[1] & G_blk[0]) | (P_blk[4] & P_blk[3] & P_blk[2] & P_blk[1] & P_blk[0] & C[0]);
	assign C[6] = G_blk[5] | (P_blk[5] & G_blk[4]) | (P_blk[5] & P_blk[4] & G_blk[3]) | (P_blk[5] & P_blk[4] & P_blk[3] & G_blk[2]) | (P_blk[5] & P_blk[4] & P_blk[3] & P_blk[2] & G_blk[1]) | (P_blk[5] & P_blk[4] & P_blk[3] & P_blk[2] & P_blk[1] & G_blk[0]) | (P_blk[5] & P_blk[4] & P_blk[3] & P_blk[2] & P_blk[1] & P_blk[0] & C[0]);
	assign C[7] = G_blk[6] | (P_blk[6] & G_blk[5]) | (P_blk[6] & P_blk[5] & G_blk[4]) | (P_blk[6] & P_blk[5] & P_blk[4] & G_blk[3]) | (P_blk[6] & P_blk[5] & P_blk[4] & P_blk[3] & G_blk[2]) | (P_blk[6] & P_blk[5] & P_blk[4] & P_blk[3] & P_blk[2] & G_blk[1]) | (P_blk[6] & P_blk[5] & P_blk[4] & P_blk[3] & P_blk[2] & P_blk[1] & G_blk[0]) | (P_blk[6] & P_blk[5] & P_blk[4] & P_blk[3] & P_blk[2] & P_blk[1] & P_blk[0] & C[0]);
	assign C[8] = G_blk[7] | (P_blk[7] & G_blk[6]) | (P_blk[7] & P_blk[6] & G_blk[5]) | (P_blk[7] & P_blk[6] & P_blk[5] & G_blk[4]) | (P_blk[7] & P_blk[6] & P_blk[5] & P_blk[4] & G_blk[3]) | (P_blk[7] & P_blk[6] & P_blk[5] & P_blk[4] & P_blk[3] & G_blk[2]) | (P_blk[7] & P_blk[6] & P_blk[5] & P_blk[4] & P_blk[3] & P_blk[2] & G_blk[1]) | (P_blk[7] & P_blk[6] & P_blk[5] & P_blk[4] & P_blk[3] & P_blk[2] & P_blk[1] & G_blk[0]) | (P_blk[7] & P_blk[6] & P_blk[5] & P_blk[4] & P_blk[3] & P_blk[2] & P_blk[1] & P_blk[0] & C[0]);

	assign cout = C[8];
	// sum 由子模块直接驱动，这里不再额外 assign，避免形成自反赋值。
	assign overflow = (a[31] & b[31] & ~sum[31]) | (~a[31] & ~b[31] & sum[31]);
endmodule

module adder(
	input  wire [31:0] a,
	input  wire [31:0] b,
	input  wire        cin,
	output wire [31:0] sum,
	output wire        cout,
	output wire        overflow
);
	cla32 u (
		.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout), .overflow(overflow)
	);
endmodule

