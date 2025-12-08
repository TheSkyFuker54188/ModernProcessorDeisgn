`timescale 1ns/1ps
`include "cpu_defs.vh"

module ArithmeticLogicUnit (
    input wire [31:0] operand_a,
    input wire [31:0] operand_b,
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
            `ALU_CTRL_PASS: result = operand_b;
            default:        result = 32'b0;
        endcase
    end

    assign zero = (result == 32'b0);
endmodule
