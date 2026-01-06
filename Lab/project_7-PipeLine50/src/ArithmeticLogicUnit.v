`timescale 1ns/1ps
`include "cpu_defs.vh"

module ArithmeticLogicUnit (
    input wire [31:0] operand_a,
    input wire [31:0] operand_b,
    input wire [4:0] shamt,
    input wire [3:0] control,
    output reg [31:0] result,
    output wire zero
);
    always @(*) begin
        case (control)
            `ALU_CTRL_ADD:  result = operand_a + operand_b;
            `ALU_CTRL_SUB:  result = operand_a - operand_b;
            `ALU_CTRL_OR:   result = operand_a | operand_b;
            `ALU_CTRL_AND:  result = operand_a & operand_b;
            `ALU_CTRL_XOR:  result = operand_a ^ operand_b;
            `ALU_CTRL_NOR:  result = ~(operand_a | operand_b);
            `ALU_CTRL_SLT:  result = ($signed(operand_a) < $signed(operand_b)) ? 32'd1 : 32'd0;
            `ALU_CTRL_SLTU: result = (operand_a < operand_b) ? 32'd1 : 32'd0;
            `ALU_CTRL_SLL:  result = operand_b << shamt;
            `ALU_CTRL_SRA:  result = $signed(operand_b) >>> shamt;
            `ALU_CTRL_SLLV: result = operand_b << operand_a[4:0];
            `ALU_CTRL_SRAV: result = $signed(operand_b) >>> operand_a[4:0];
            `ALU_CTRL_LUI:  result = operand_b << 16;
            `ALU_CTRL_PASS: result = operand_b;
            default:        result = 32'b0;
        endcase
    end

    assign zero = (result == 32'b0);
endmodule
