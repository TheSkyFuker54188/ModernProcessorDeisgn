`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/08 20:38:44
// Design Name: 
// Module Name: alu_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module alu_tb();
    reg [31:0] in1,in2;
    reg [5:0] op;
    reg [31:0] ans;
    reg cov;
    
    wire [31:0] out;
    wire ov;
    
    alu uut(.A(in1),.B(in2),.C(out),.Op(op),.Over(ov));
   
    wire correct;
    assign correct=(out==ans)&&(ov==cov);
    
    integer i,j,ii,jj;

    // 统计 & 记录
    integer total_vectors = 0;
    integer error_count   = 0;
    integer first_err_time = -1;
    reg [31:0] first_exp, first_got;
    reg first_ov_exp, first_ov_got;

    // 每个  operation 的错误数（索引用 op 的低 6 位）
    integer op_err[0:63];
    integer op_cnt[0:63];

    // 便于调试：当发现错误时是否立即停仿（设置为 1 立即停止）
    localparam STOP_ON_FIRST_ERROR = 0;

    // 任务：在每个测试向量后调用，自动计数
    task record_result;
        begin
            total_vectors = total_vectors + 1;
            op_cnt[op]    = op_cnt[op] + 1;
            if(!correct) begin
                error_count = error_count + 1;
                op_err[op]  = op_err[op] + 1;
                if(first_err_time < 0) begin
                    first_err_time = $time;
                    first_exp      = ans;
                    first_got      = out;
                    first_ov_exp   = cov;
                    first_ov_got   = ov;
                end
                if(STOP_ON_FIRST_ERROR) begin
                    $display("[FATAL] First error at %0t ns op=%b in1=%h in2=%h expC=%h gotC=%h expOv=%b gotOv=%b", $time, op, in1, in2, ans, out, cov, ov);
                    $finish;
                end
            end
        end
    endtask

    // 清零数组
    integer k;
    initial begin
        for(k=0;k<64;k=k+1) begin
            op_err[k]=0; op_cnt[k]=0; end
    end
    
    initial begin
        op=6'b100000;
        for(i=0;i<32;i=i+1)
            for(ii=0;ii<16;ii=ii+1)
                for(j=0;j<32;j=j+1)
                    for(jj=0;jj<16;jj=jj+1)
                        begin
                            in1=ii<<i;
                            in2=jj<<j;
                            ans=in1+in2;
                            cov=(in1[31]==in2[31]&&in1[31]!=ans[31]);
                            #2; record_result();
                        end;
        #5
        op=6'b100010;
        for(i=0;i<32;i=i+1)
            for(ii=0;ii<16;ii=ii+1)
                for(j=0;j<32;j=j+1)
                    for(jj=0;jj<16;jj=jj+1)
                        begin
                            in1=ii<<i;
                            in2=jj<<j;
                            ans=in1-in2;
                            cov=(in1[31]!=in2[31]&&in1[31]!=ans[31]);
                            #2; record_result();
                        end;
        #5
        cov = 0;
        op=6'b100001;
        for(i=0;i<32;i=i+1)
            for(ii=0;ii<4;ii=ii+1)
                for(j=0;j<32;j=j+1)
                    for(jj=0;jj<4;jj=jj+1)
                        begin
                            in1=ii<<i;
                            in2=jj<<j;
                            ans=in1+in2;
                            #2; record_result();
                        end;
        #5
        op=6'b100011;
        for(i=0;i<32;i=i+1)
            for(ii=0;ii<4;ii=ii+1)
                for(j=0;j<32;j=j+1)
                    for(jj=0;jj<4;jj=jj+1)
                        begin
                            in1=ii<<i;
                            in2=jj<<j;
                            ans=in1-in2;
                            #2; record_result();
                        end;
        #5
        op=6'b000000;
        for(i=0;i<32;i=i+1)
            for(j=0;j<32;j=j+1)
                for(jj=0;jj<128;jj=jj+1)
                    begin
                        in1=i;
                        in2=jj<<j;
                        ans=(in2)<<in1[4:0];
                        #2; record_result();
                    end;
        #5
        op=6'b000010;
        for(i=0;i<32;i=i+1)
            for(j=0;j<32;j=j+1)
                for(jj=0;jj<128;jj=jj+1)
                    begin
                        in1=i;
                        in2=jj<<j;
                        ans=(in2)>>in1[4:0];
                        #2; record_result();
                    end;      
        #5
        op=6'b000011;
        for(i=0;i<32;i=i+1)
            for(j=0;j<32;j=j+1)
                for(jj=0;jj<128;jj=jj+1)
                    begin
                        in1=i;
                        in2=jj<<j;
                        ans=$signed(in2)>>>in1[4:0];
                        #2; record_result();
                    end;
        #5
        op=6'b100100;
        for(i=0;i<32;i=i+1)
            for(ii=0;ii<8;ii=ii+1)
                for(j=0;j<32;j=j+1)
                    for(jj=0;jj<8;jj=jj+1)
                        begin
                            in1=ii<<i;
                            in2=jj<<j;
                            ans=in1&in2;
                            #2; record_result();
                        end;
        #5
        op=6'b100101;
        for(i=0;i<32;i=i+1)
            for(ii=0;ii<8;ii=ii+1)
                for(j=0;j<32;j=j+1)
                    for(jj=0;jj<8;jj=jj+1)
                        begin
                            in1=ii<<i;
                            in2=jj<<j;
                            ans=in1|in2;
                            #2; record_result();
                        end;
        #5
        op=6'b100110;
        for(i=0;i<32;i=i+1)
            for(ii=0;ii<8;ii=ii+1)
                for(j=0;j<32;j=j+1)
                    for(jj=0;jj<8;jj=jj+1)
                        begin
                            in1=ii<<i;
                            in2=jj<<j;
                            ans=in1^in2;
                            #2; record_result();
                        end;
        #5
        op=6'b100111;
        for(i=0;i<32;i=i+1)
            for(ii=0;ii<8;ii=ii+1)
                for(j=0;j<32;j=j+1)
                    for(jj=0;jj<8;jj=jj+1)
                        begin
                            in1=ii<<i;
                            in2=jj<<j;
                            ans=~(in1|in2);
                            #2; record_result();
                        end;
        // 输出总结
        $display("================ ALU TEST SUMMARY ================");
        $display("Total vectors : %0d", total_vectors);
        $display("Error count   : %0d", error_count);
        if(error_count==0) begin
            $display("RESULT        : PASS");
        end else begin
            $display("RESULT        : FAIL");
            $display("First error at %0t ns", first_err_time);
            $display("  op=%b in1=%h in2=%h", op, in1, in2);
            $display("  expected C=%h Over=%b", first_exp, first_ov_exp);
            $display("  got      C=%h Over=%b", first_got, first_ov_got);
            // 简单列出出现过错误的 op
            for(k=0;k<64;k=k+1) if(op_err[k]>0) begin
                $display("  OP %06b : %0d errors / %0d vectors", k[5:0], op_err[k], op_cnt[k]);
            end
        end
        $display("==================================================");
        $finish;
    end;
endmodule
