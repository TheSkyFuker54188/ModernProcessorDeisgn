`timescale 1ns / 1ps

module pc_tb;
    reg        clock = 0;
    reg        reset = 1;
    reg        jumpEnabled = 0;
    reg [31:0] jumpInput = 32'd0;
    wire [31:0] pcValue;
    integer    errors = 0;

    localparam CLK_HALF = 5;

    program_counter dut (
        .reset(reset),
        .clock(clock),
        .jumpEnabled(jumpEnabled),
        .jumpInput(jumpInput),
        .pcValue(pcValue)
    );

    always #(CLK_HALF) clock = ~clock;

    initial begin
        $display("%0t: reset asserted", $time);
        #(2*CLK_HALF);
        reset = 0;
        $display("%0t: reset deasserted", $time);

        repeat (2) @(posedge clock);
        if (pcValue !== 32'h0000_3008) begin
            errors = errors + 1;
            $error("Unexpected PC after auto-increment: %h", pcValue);
        end else begin
            $display("Auto-increment check passed: %h", pcValue);
        end

        jumpInput = 32'h0000_3040;
        jumpEnabled = 1;
        @(posedge clock);
        jumpEnabled = 0;

        repeat (2) @(posedge clock);
        if (pcValue !== 32'h0000_3048) begin
            errors = errors + 1;
            $error("Unexpected PC after jump sequence: %h", pcValue);
        end else begin
            $display("Jump sequence check passed: %h", pcValue);
        end

        if (errors == 0) begin
            $display("[PASS] PC test completed with no errors.");
        end else begin
            $fatal(1, "[FAIL] PC test found %0d error(s).", errors);
        end

        $finish;
    end
endmodule
