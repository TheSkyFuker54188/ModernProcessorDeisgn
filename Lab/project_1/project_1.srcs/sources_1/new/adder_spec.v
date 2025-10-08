`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// adder_spec: 实验指定接口包装。
// 固定 cin=0，忽略 cout/overflow，只输出 sum。
//////////////////////////////////////////////////////////////////////////////////
module adder_spec (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] sum
);
    wire cout_unused;
    wire overflow_unused;
    adder u_core (
        .a(a),
        .b(b),
        .cin(1'b0),
        .sum(sum),
        .cout(cout_unused),
        .overflow(overflow_unused)
    );
endmodule
