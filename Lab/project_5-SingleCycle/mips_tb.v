module mips_tb;

reg reset, clock;

// Change the TopLevel module's name to yours
TopLevel topLevel(.reset(reset), .clock(clock), .halted());

integer k;
initial begin
    // posedge clock

    // Hold reset for one cycle
    reset = 1;
    clock = 0; #1;
    clock = 1; #1;
    clock = 0; #1;
    reset = 0; #1;
    // $stop; // 注释掉以使仿真继续运行直到 syscall

    #1;
    // 运行直到 TopLevel 触发 syscall（halted 置位）或达到最大时钟次数
    for (k = 0; k < 1000000; k = k + 1) begin // 最多 1,000,000 个时钟周期
        clock = 1; #5;
        clock = 0; #5;
        if (topLevel.halted) begin
            $display("Testbench detected halt at cycle %0d", k);
            $finish;
        end
    end

    $display("Timeout: reached max cycles without syscall, dumping partial DataMemory...");
    // 如果需要，也可以在这里跨层访问 data_memory.memory 打印，但通常只在 syscall 时打印
    $finish;
end
    
endmodule
