`timescale 1ns / 1ps
    import alu_opcodes_pkg::*;
module alu(
            input logic [31:0] a_i,
            input logic [31:0] b_i,
            input logic [ALU_OP_WIDTH-1:0] alu_op_i,
            
            output logic flag_o,
            output logic [31:0] result_o

    );
logic [31:0] adder;
fulladder32 fulladder32_gate_1(
                                .a_i(a_i),
                                .b_i(b_i),
                                .carry_i(1'b0),
                                .carry_o(),
                                .sum_o(adder)

);

always_comb
    case (alu_op_i)
        ALU_ADD: result_o = adder ;
        ALU_SUB: result_o = a_i - b_i;
        ALU_XOR: result_o = a_i ^ b_i;
        ALU_OR: result_o = a_i | b_i;
        ALU_AND: result_o = a_i & b_i;
        ALU_SRA: result_o = $signed(a_i) >>> b_i[4:0];
        ALU_SRL: result_o = a_i >> b_i[4:0];
        ALU_SLL: result_o = a_i << b_i[4:0];
        ALU_SLTS: result_o = $signed(a_i) < $signed(b_i);
        ALU_SLTU: result_o = a_i < b_i;
        default: result_o = 32'b0;
    endcase

always_comb
    case (alu_op_i)
        ALU_LTS: flag_o = $signed(a_i) < $signed(b_i);
        ALU_LTU: flag_o = a_i < b_i;
        ALU_GES: flag_o = $signed(a_i) >= $signed(b_i);
        ALU_GEU: flag_o = a_i >= b_i;
        ALU_EQ: flag_o = (a_i == b_i);
        ALU_NE: flag_o = (a_i != b_i);
        default : flag_o = 1'b0;
    endcase  
    
endmodule
