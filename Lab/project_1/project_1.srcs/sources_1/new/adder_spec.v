`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Wrapper: adder_spec
// Purpose : Provide the experiment-specified interface
//           module adder(input [31:0] a, input [31:0] b, output [31:0] sum);
// Implementation: Reuse the enhanced CLA adder core (module adder) by
//                 tying cin=0 and discarding cout / overflow.
// Notes    : Core fast adder remains in adder.v (cla4 / cla32 / adder).
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
