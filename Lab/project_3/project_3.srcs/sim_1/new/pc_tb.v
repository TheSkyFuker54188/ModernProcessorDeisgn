`timescale 1ns / 1ps

module pc_tb;
    reg        clock = 0;
    reg        reset = 1;
    reg        jumpEnabled = 0;
    reg [31:0] jumpInput = 32'd0;
    wire [31:0] pcValue;
    integer    errors = 0;

    localparam CLK_HALF = 5;
    localparam [31:0] RESET_VEC = 32'h0000_3000;

    program_counter dut (
        .reset(reset),
        .clock(clock),
        .jumpEnabled(jumpEnabled),
        .jumpInput(jumpInput),
        .pcValue(pcValue)
    );

    always #(CLK_HALF) clock = ~clock;

    task automatic expect_at_negedge(input [31:0] expected, input [127:0] label);
    begin
        @(negedge clock);
        if (pcValue !== expected) begin
            errors = errors + 1;
            $error("%s: expected %h, got %h", label, expected, pcValue);
        end else begin
            $display("%s passed: %h", label, pcValue);
        end
    end
    endtask

    task automatic expect_after_cycles(input integer cycles, input [31:0] expected, input [127:0] label);
    begin
        repeat (cycles) @(posedge clock);
        @(negedge clock);
        if (pcValue !== expected) begin
            errors = errors + 1;
            $error("%s: expected %h, got %h", label, expected, pcValue);
        end else begin
            $display("%s passed: %h", label, pcValue);
        end
    end
    endtask

    initial begin
        $display("%0t: reset asserted", $time);

        expect_at_negedge(RESET_VEC, "Reset hold cycle 1");
        expect_at_negedge(RESET_VEC, "Reset hold cycle 2");

        reset = 0;
        $display("%0t: reset deasserted", $time);

        expect_after_cycles(1, 32'h0000_3004, "Auto increment 1");
        expect_after_cycles(1, 32'h0000_3008, "Auto increment 2");

        @(negedge clock);
        jumpInput = 32'h0000_3040;
        jumpEnabled = 1;

        expect_after_cycles(1, 32'h0000_3040, "Jump load");
        jumpEnabled = 0;

        expect_after_cycles(1, 32'h0000_3044, "Post jump increment 1");
        expect_after_cycles(1, 32'h0000_3048, "Post jump increment 2");

        if (errors == 0) begin
            $display("[PASS] PC test completed with no errors.");
        end else begin
            $fatal(1, "[FAIL] PC test found %0d error(s).", errors);
        end

        $finish;
    end
endmodule
