`timescale 1us/1us
module ForwardingUnit (
    input wire ex_mem_reg_write,
    input wire ex_mem_mem_to_reg,
    input wire [4:0] ex_mem_dest,
    input wire mem_wb_reg_write,
    input wire [4:0] mem_wb_dest,
    input wire [4:0] id_ex_rs,
    input wire [4:0] id_ex_rt,
    output reg [1:0] forwardAE,
    output reg [1:0] forwardBE
);
    always @(*) begin
        forwardAE = 2'b00;
        forwardBE = 2'b00;

        if (ex_mem_reg_write && !ex_mem_mem_to_reg && (ex_mem_dest != 5'd0) && (ex_mem_dest == id_ex_rs)) begin
            forwardAE = 2'b10;
        end else if (mem_wb_reg_write && (mem_wb_dest != 5'd0) && (mem_wb_dest == id_ex_rs)) begin
            forwardAE = 2'b01;
        end

        if (ex_mem_reg_write && !ex_mem_mem_to_reg && (ex_mem_dest != 5'd0) && (ex_mem_dest == id_ex_rt)) begin
            forwardBE = 2'b10;
        end else if (mem_wb_reg_write && (mem_wb_dest != 5'd0) && (mem_wb_dest == id_ex_rt)) begin
            forwardBE = 2'b01;
        end
    end
endmodule
