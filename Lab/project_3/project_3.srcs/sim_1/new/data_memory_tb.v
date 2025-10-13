`timescale 1ns / 1ps

module data_memory_tb;
    reg        clock = 0;
    reg        reset = 1;
    reg        writeEnabled = 0;
    reg [31:0] address = 32'd0;
    reg [31:0] writeInput = 32'd0;
    wire [31:0] readResult;
    integer    errors = 0;

    localparam CLK_HALF = 5;

    data_memory dut (
        .reset(reset),
        .clock(clock),
        .address(address),
        .writeEnabled(writeEnabled),
        .writeInput(writeInput),
        .readResult(readResult)
    );

    always #(CLK_HALF) clock = ~clock;

    task write_word(input [31:0] addr, input [31:0] data);
    begin
        @(negedge clock); // prepare signals half cycle before write edge
        address = addr;
        writeInput = data;
        writeEnabled = 1;
        @(posedge clock); // perform write on rising edge
        @(negedge clock);
        writeEnabled = 0;
    end
    endtask

    always @(posedge clock) begin
        $display("TB @%0t: reset=%b writeEnabled=%b address=%h writeInput=%h", $time, reset, writeEnabled, address, writeInput);
    end

    initial begin
        repeat (2) @(posedge clock); // keep reset for a full cycle
        reset = 0;
        @(posedge clock);

    @(negedge clock);
    if (readResult !== 32'd0) begin
            errors = errors + 1;
            $error("Memory not cleared at %h", address);
        end else begin
            $display("Reset check passed at %h", address);
        end

    write_word(32'h0000_0000, 32'hDEAD_BEEF);
    @(negedge clock);
        $display("mem[0] = %h (after write)", dut.mem[0]);
        if (readResult !== 32'hDEAD_BEEF) begin
            errors = errors + 1;
            $error("Readback mismatch at %h", address);
        end else begin
            $display("Write/read check passed at %h", address);
        end

    write_word(32'h0000_0004, 32'hCAFE_1234);
    @(negedge clock);
        $display("mem[1] = %h (after write)", dut.mem[1]);
        if (readResult !== 32'hCAFE_1234) begin
            errors = errors + 1;
            $error("Readback mismatch at %h", address);
        end else begin
            $display("Write/read check passed at %h", address);
        end

    address = 32'h0000_0008;
    @(posedge clock);
    @(negedge clock);
        if (readResult !== 32'd0) begin
            errors = errors + 1;
            $error("Unexpected data at %h", address);
        end else begin
            $display("Unwritten address check passed at %h", address);
        end

        writeInput = 32'hABCD_EF01;
        @(posedge clock);
    @(negedge clock);
        if (readResult !== 32'd0) begin
            errors = errors + 1;
            $error("Write enable leak at %h", address);
        end else begin
            $display("Write-enable gating check passed at %h", address);
        end

    @(posedge clock);
    @(negedge clock);
        if (errors == 0) begin
            $display("[PASS] Data memory test completed with no errors.");
        end else begin
            $fatal(1, "[FAIL] Data memory test found %0d error(s).", errors);
        end

        $finish;
    end
endmodule
