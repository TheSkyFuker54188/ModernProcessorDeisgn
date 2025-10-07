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
    integer error_count = 0;          // 统计错误次数
    localparam integer NUM_VECTORS = 256;  // 测试向量数，可按需修改

    initial begin
        // 可设置固定随机种子: 例如 $urandom(32'h20251007);
        for (i = 0; i < NUM_VECTORS; i = i + 1) begin
`ifdef ADDER_32BIT
            a <= $urandom();
            b <= $urandom();
`else
            a <= i % 16;       // low 4 bits vary quickly
            b <= i / 16;       // high 4 bits iterate
`endif
            // 给组合逻辑一个最小稳定时间，再检查 diff
            #1;
            if (diff !== 32'b0) begin
                error_count = error_count + 1;
                $display("MISMATCH #%0d @%0t  a=%h  b=%h  sum=%h  diff=%h", error_count, $time, a, b, sum, diff);
            end
            #9; // 补足本次迭代到 10ns 间隔，保持与原始节奏一致（1+9=10）
        end
        if (error_count == 0) begin
            $display("SUMMARY: %0d vectors tested, NO mismatches. PASS.", NUM_VECTORS);
        end else begin
            $display("SUMMARY: %0d vectors tested, %0d mismatches. FAIL.", NUM_VECTORS, error_count);
        end
        $finish;
    end
endmodule

