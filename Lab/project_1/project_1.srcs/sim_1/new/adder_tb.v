`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Self-checking Testbench for 32-bit CLA Adder
//////////////////////////////////////////////////////////////////////////////////
module adder_tb;
    reg  [31:0] a, b;
    reg         cin;
    wire [31:0] sum;
    wire        cout, overflow;

    // DUT
    adder dut (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout),
        .overflow(overflow)
    );

    reg [32:0] ref_full;
    integer i;

    task apply_and_check(input [31:0] aa, input [31:0] bb, input cc);
        begin
            a   = aa;
            b   = bb;
            cin = cc;
            #1; // allow combinational settle
            ref_full = {1'b0, aa} + {1'b0, bb} + cc;
            if (sum !== ref_full[31:0] || cout !== ref_full[32]) begin
                $display("ERROR @%0t a=%h b=%h cin=%b => sum=%h cout=%b (ref sum=%h cout=%b)",
                         $time, a, b, cin, sum, cout, ref_full[31:0], ref_full[32]);
                $stop;
            end
        end
    endtask

    initial begin
        // Directed cases
        apply_and_check(32'h0000_0000, 32'h0000_0000, 1'b0);
        apply_and_check(32'hFFFF_FFFF, 32'h0000_0001, 1'b0);
        apply_and_check(32'h7FFF_FFFF, 32'h0000_0001, 1'b0); // positive overflow scenario
        apply_and_check(32'h8000_0000, 32'h8000_0000, 1'b0); // negative overflow scenario
        apply_and_check(32'hAAAA_AAAA, 32'h5555_5555, 1'b1);

        // Random tests
        for (i = 0; i < 1000; i = i + 1) begin
            apply_and_check($urandom(), $urandom(), $urandom() % 2);
        end

        $display("ALL TESTS PASSED");
        $finish;
    end
endmodule
