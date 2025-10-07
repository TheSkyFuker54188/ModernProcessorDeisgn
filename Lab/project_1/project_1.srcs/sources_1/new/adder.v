`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 32-bit Carry Look-Ahead Adder (Two-Level: 4-bit CLA blocks)
// Author: (auto-generated)
// Date  : 2025/10/07
// Description:
//   Hierarchical fast adder composed of eight 4-bit CLA blocks with a second
//   level block carry look-ahead expansion. Provides sum, final carry-out and
//   signed overflow indication.
// 
// Notes:
//   * Purely combinational.
//   * overflow flag is meaningful only when interpreting inputs as signed.
//   * Can be adapted to other widths by parameterizing and generalizing the
//     block-level expansion logic.
//////////////////////////////////////////////////////////////////////////////////

// 4-bit CLA Block
module cla4 (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       cin,
    output wire [3:0] sum,
    output wire       cout,
    output wire       P_group,
    output wire       G_group
);
    wire [3:0] p, g;
    wire c1, c2, c3, c4;

    assign p = a ^ b;          // propagate
    assign g = a & b;          // generate

    // Bit-level carry (expanded form)
    assign c1 = g[0] | (p[0] & cin);
    assign c2 = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
    assign c3 = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);
    assign c4 = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1])
                      | (p[3] & p[2] & p[1] & g[0])
                      | (p[3] & p[2] & p[1] & p[0] & cin);

    // Sum bits
    assign sum[0] = p[0] ^ cin;
    assign sum[1] = p[1] ^ c1;
    assign sum[2] = p[2] ^ c2;
    assign sum[3] = p[3] ^ c3;

    assign cout = c4;

    // Group propagate / generate for block-level CLA
    assign P_group = &p; // p[3] & p[2] & p[1] & p[0]
    assign G_group = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
endmodule

// 32-bit CLA using 8x 4-bit CLA blocks and second-level block carry look-ahead
module cla32 (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire        cin,
    output wire [31:0] sum,
    output wire        cout,
    output wire        overflow
);
    wire [7:0] P_blk, G_blk;   // Block propagate / generate
    wire [8:0] C_blk;          // Block carries (C_blk[0]=cin, C_blk[8]=cout)
    assign C_blk[0] = cin;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : GEN_CLA4
            cla4 u_cla4 (
                .a      (a[4*i+3 : 4*i]),
                .b      (b[4*i+3 : 4*i]),
                .cin    (C_blk[i]),
                .sum    (sum[4*i+3 : 4*i]),
                .cout   (),
                .P_group(P_blk[i]),
                .G_group(G_blk[i])
            );
        end
    endgenerate

    // Second-level block carry look-ahead expansion
    assign C_blk[1] = G_blk[0] | (P_blk[0] & C_blk[0]);
    assign C_blk[2] = G_blk[1] | (P_blk[1] & G_blk[0]) | (P_blk[1] & P_blk[0] & C_blk[0]);
    assign C_blk[3] = G_blk[2] | (P_blk[2] & G_blk[1]) | (P_blk[2] & P_blk[1] & G_blk[0]) | (P_blk[2] & P_blk[1] & P_blk[0] & C_blk[0]);
    assign C_blk[4] = G_blk[3] | (P_blk[3] & G_blk[2]) | (P_blk[3] & P_blk[2] & G_blk[1]) | (P_blk[3] & P_blk[2] & P_blk[1] & G_blk[0]) | (P_blk[3] & P_blk[2] & P_blk[1] & P_blk[0] & C_blk[0]);
    assign C_blk[5] = G_blk[4] | (P_blk[4] & G_blk[3]) | (P_blk[4] & P_blk[3] & G_blk[2]) | (P_blk[4] & P_blk[3] & P_blk[2] & G_blk[1]) | (P_blk[4] & P_blk[3] & P_blk[2] & P_blk[1] & G_blk[0]) | (P_blk[4] & P_blk[3] & P_blk[2] & P_blk[1] & P_blk[0] & C_blk[0]);
    assign C_blk[6] = G_blk[5] | (P_blk[5] & G_blk[4]) | (P_blk[5] & P_blk[4] & G_blk[3]) | (P_blk[5] & P_blk[4] & P_blk[3] & G_blk[2]) | (P_blk[5] & P_blk[4] & P_blk[3] & P_blk[2] & G_blk[1]) | (P_blk[5] & P_blk[4] & P_blk[3] & P_blk[2] & P_blk[1] & G_blk[0]) | (P_blk[5] & P_blk[4] & P_blk[3] & P_blk[2] & P_blk[1] & P_blk[0] & C_blk[0]);
    assign C_blk[7] = G_blk[6] | (P_blk[6] & G_blk[5]) | (P_blk[6] & P_blk[5] & G_blk[4]) | (P_blk[6] & P_blk[5] & P_blk[4] & G_blk[3]) | (P_blk[6] & P_blk[5] & P_blk[4] & P_blk[3] & G_blk[2]) | (P_blk[6] & P_blk[5] & P_blk[4] & P_blk[3] & P_blk[2] & G_blk[1]) | (P_blk[6] & P_blk[5] & P_blk[4] & P_blk[3] & P_blk[2] & P_blk[1] & G_blk[0]) | (P_blk[6] & P_blk[5] & P_blk[4] & P_blk[3] & P_blk[2] & P_blk[1] & P_blk[0] & C_blk[0]);
    assign C_blk[8] = G_blk[7] | (P_blk[7] & G_blk[6]) | (P_blk[7] & P_blk[6] & G_blk[5]) | (P_blk[7] & P_blk[6] & P_blk[5] & G_blk[4]) | (P_blk[7] & P_blk[6] & P_blk[5] & P_blk[4] & G_blk[3]) | (P_blk[7] & P_blk[6] & P_blk[5] & P_blk[4] & P_blk[3] & G_blk[2]) | (P_blk[7] & P_blk[6] & P_blk[5] & P_blk[4] & P_blk[3] & P_blk[2] & G_blk[1]) | (P_blk[7] & P_blk[6] & P_blk[5] & P_blk[4] & P_blk[3] & P_blk[2] & P_blk[1] & G_blk[0]) | (P_blk[7] & P_blk[6] & P_blk[5] & P_blk[4] & P_blk[3] & P_blk[2] & P_blk[1] & P_blk[0] & C_blk[0]);

    assign cout = C_blk[8];

    // Signed overflow: (a[31] & b[31] & ~sum[31]) | (~a[31] & ~b[31] & sum[31])
    assign overflow = (a[31] & b[31] & ~sum[31]) | (~a[31] & ~b[31] & sum[31]);
endmodule

// Friendly wrapper top-level
module adder (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire        cin,
    output wire [31:0] sum,
    output wire        cout,
    output wire        overflow
);
    cla32 u_cla32 (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout),
        .overflow(overflow)
    );
endmodule


