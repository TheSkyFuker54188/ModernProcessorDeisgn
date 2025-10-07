`timescale 1ns / 1ps

`define ADDER_32BIT

module adder_tb;
    reg  [31:0] a, b;
    wire [31:0] sum;

    // Use wrapper that conforms to experiment-specified interface
    adder_spec uut(
        .a(a),
        .b(b),
        .sum(sum)
    );

`ifdef ADDER_32BIT
    localparam [31:0] ANS_MASK = 32'hFFFF_FFFF;
`else
    localparam [31:0] ANS_MASK = 32'h0000_000F; // 4-bit mode (if macro undefined)
`endif

    // Optional helper signal for manual waveform inspection: difference
    wire [31:0] diff = ((a + b) - sum) & ANS_MASK; // expect 0 when correct

    integer i;
    initial begin
        // Seed (optional) -> consistent randoms; comment out to vary each run
        // $urandom(seed_value);
        for (i = 0; i < 256; i = i + 1) begin
`ifdef ADDER_32BIT
            a <= $urandom();
            b <= $urandom();
`else
            a <= i % 16;       // low 4 bits vary quickly
            b <= i / 16;       // high 4 bits iterate
`endif
            #10;               // allow waveform visibility
        end
        $finish;
    end
endmodule

