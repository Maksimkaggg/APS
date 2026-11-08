module decoder (
  input  logic [31:0]  fetched_instr_i,
  output logic [1:0]   a_sel_o,
  output logic [2:0]   b_sel_o,
  output logic [4:0]   alu_op_o,
  output logic [2:0]   csr_op_o,
  output logic         csr_we_o,
  output logic         mem_req_o,
  output logic         mem_we_o,
  output logic [2:0]   mem_size_o,
  output logic         gpr_we_o,
  output logic [1:0]   wb_sel_o,
  output logic         illegal_instr_o,
  output logic         branch_o,
  output logic         jal_o,
  output logic         jalr_o,
  output logic         mret_o
);
  import decoder_pkg::*;

logic [6:0] opcode;
assign opcode = fetched_instr_i[6:0];

logic [2:0] funct3;
assign funct3 = fetched_instr_i[14:12];

logic [6:0] funct7;
assign funct7 = fetched_instr_i[31:25];

logic [11:0] imm;
assign imm = fetched_instr_i[31:20];

logic [4:0] rs1;
assign rs1 = fetched_instr_i[19:15];

always_comb begin
    a_sel_o = 2'b00;
    b_sel_o = 3'b000;
    alu_op_o = ALU_ADD;
    csr_op_o = CSR_RW;
    csr_we_o = 1'b0;
    mem_req_o = 1'b0;
    mem_we_o = 1'b0;
    mem_size_o = LDST_W;
    gpr_we_o = 1'b0;
    wb_sel_o = 2'b00;
    illegal_instr_o = 1'b0;
    branch_o = 1'b0;
    jal_o = 1'b0;
    jalr_o = 1'b0;
    mret_o = 1'b0;
    if (opcode[1:0] != 2'b11)
            illegal_instr_o = 1'b1;
    else begin
        case(opcode[6:2])
            LOAD_OPCODE: begin
                mem_req_o = 1'b1;
                gpr_we_o = 1'b1;
                a_sel_o = OP_A_RS1;
                b_sel_o = OP_B_IMM_I;
                wb_sel_o = WB_LSU_DATA;
                case(funct3)
                    3'b000 : mem_size_o = LDST_B;
                    3'b001 : mem_size_o = LDST_H;
                    3'b010 : mem_size_o = LDST_W;
                    3'b100 : mem_size_o = LDST_BU;
                    3'b101 : mem_size_o = LDST_HU;
                    default: begin illegal_instr_o = 1'b1; mem_req_o = 1'b0; gpr_we_o = 1'b0; end
                endcase
            end
    
            MISC_MEM_OPCODE: begin  
            if (funct3 != 3'b000) illegal_instr_o = 1'b1;
            end
    


            OP_IMM_OPCODE: begin
                gpr_we_o = 1'b1;
                a_sel_o = OP_A_RS1;
                b_sel_o = OP_B_IMM_I;
                wb_sel_o = WB_EX_RESULT;
                case(funct3)
                    3'b000: alu_op_o = ALU_ADD;
                    3'b001: begin 
                        if (funct7 == 7'd0) alu_op_o = ALU_SLL;
                        else  begin illegal_instr_o = 1'b1; gpr_we_o = 1'b0; end
                        end
                    3'b010: alu_op_o = ALU_SLTS;
                    3'b011: alu_op_o = ALU_SLTU;
                    3'b100: alu_op_o = ALU_XOR;
                    3'b101: begin
                        case(funct7)
                        7'b0000000: alu_op_o = ALU_SRL;
                        7'b0100000: alu_op_o = ALU_SRA;
                        default: begin illegal_instr_o = 1'b1; gpr_we_o = 1'b0; end
                        endcase
                    end
                    3'b110: alu_op_o = ALU_OR;
                    3'b111: alu_op_o = ALU_AND;
                    default: begin illegal_instr_o = 1'b1; gpr_we_o = 1'b0; end
                endcase
            end
    
    
    
    
            AUIPC_OPCODE: begin
                gpr_we_o = 1'b1;
                a_sel_o = OP_A_CURR_PC;
                b_sel_o = OP_B_IMM_U;   
                wb_sel_o = WB_EX_RESULT;    
            end
    
            STORE_OPCODE: begin
                a_sel_o = OP_A_RS1;
                b_sel_o = OP_B_IMM_S;
                mem_req_o = 1'b1;
                mem_we_o = 1'b1;
                case (funct3)
                    3'b000: mem_size_o = LDST_B;
                    3'b001: mem_size_o = LDST_H;
                    3'b010: mem_size_o = LDST_W;
                    default: begin illegal_instr_o = 1'b1; mem_req_o = 1'b0; mem_we_o = 1'b0; end
                endcase
            end
    
            OP_OPCODE: begin
                gpr_we_o = 1'b1;
                a_sel_o = OP_A_RS1;
                b_sel_o = OP_B_RS2;
                wb_sel_o = WB_EX_RESULT;
                case(funct3)
                    3'b000: begin
                        case(funct7)
                        7'b0000000: alu_op_o = ALU_ADD;
                        7'b0100000: alu_op_o = ALU_SUB;
                        default: begin illegal_instr_o = 1'b1; gpr_we_o = 1'b0; end
                        endcase
                    end
                    3'b001: begin 
                        if (funct7 == 7'd0) alu_op_o = ALU_SLL;
                        else  begin illegal_instr_o = 1'b1; gpr_we_o = 1'b0; end
                        end
                    3'b010: begin 
                        if (funct7 == 7'd0) alu_op_o = ALU_SLTS;
                        else  begin illegal_instr_o = 1'b1; gpr_we_o = 1'b0; end
                        end
                    3'b011: begin 
                        if (funct7 == 7'd0) alu_op_o = ALU_SLTU;
                        else  begin illegal_instr_o = 1'b1; gpr_we_o = 1'b0; end
                        end
                    3'b100: begin 
                        if (funct7 == 7'd0) alu_op_o = ALU_XOR;
                        else  begin illegal_instr_o = 1'b1; gpr_we_o = 1'b0; end
                        end
                    3'b101: begin
                        case(funct7)
                        7'b0000000: alu_op_o = ALU_SRL;
                        7'b0100000: alu_op_o = ALU_SRA;
                        default: begin illegal_instr_o = 1'b1; gpr_we_o = 1'b0; end
                        endcase
                    end
                    3'b110: begin 
                        if (funct7 == 7'd0) alu_op_o = ALU_OR;
                        else  begin illegal_instr_o = 1'b1; gpr_we_o = 1'b0; end
                        end
                    3'b111: begin 
                        if (funct7 == 7'd0) alu_op_o = ALU_AND;
                        else  begin illegal_instr_o = 1'b1; gpr_we_o = 1'b0; end
                        end
                    default: begin illegal_instr_o = 1'b1; gpr_we_o = 1'b0; end
                endcase
            end
    
    
            LUI_OPCODE: begin
                gpr_we_o = 1'b1;
                a_sel_o = OP_A_ZERO;
                b_sel_o = OP_B_IMM_U;   
                wb_sel_o = WB_EX_RESULT; 
            end
    
    
    
            BRANCH_OPCODE: begin
                a_sel_o = OP_A_RS1;
                b_sel_o = OP_B_RS2;
                branch_o = 1'b1;
                 case(funct3)
                    3'b000: alu_op_o = ALU_EQ;
                    3'b001: alu_op_o = ALU_NE;
                    3'b100: alu_op_o = ALU_LTS;
                    3'b101: alu_op_o = ALU_GES; 
                    3'b110: alu_op_o = ALU_LTU;
                    3'b111: alu_op_o = ALU_GEU;
                    default: begin illegal_instr_o = 1'b1; branch_o = 1'b0; end
                endcase       
            end
    
    
            JALR_OPCODE: begin
                if (funct3 == 3'b0) begin
                    a_sel_o = OP_A_CURR_PC;
                    b_sel_o = OP_B_INCR;
                    alu_op_o = ALU_ADD;
                    gpr_we_o = 1'b1;
                    wb_sel_o = WB_EX_RESULT;
                    jalr_o = 1'b1;
                end
                else begin
                    gpr_we_o = 1'b0;
                    jalr_o = 1'b0;
                    illegal_instr_o = 1'b1;
                end
            end
    
    
            JAL_OPCODE: begin
                a_sel_o = OP_A_CURR_PC;
                b_sel_o = OP_B_INCR;
                alu_op_o = ALU_ADD;
                gpr_we_o = 1'b1;
                wb_sel_o = WB_EX_RESULT;
                jal_o = 1'b1;
            end
    
    
            SYSTEM_OPCODE: begin
                    csr_we_o = 1'b1;
                    gpr_we_o = 1'b1;
                    wb_sel_o = WB_CSR_DATA;
                    case(funct3)
                        3'b001: csr_op_o = CSR_RW;
                        3'b010: csr_op_o = CSR_RS;
                        3'b011: csr_op_o = CSR_RC; 
                        3'b101: csr_op_o = CSR_RWI;
                        3'b110: csr_op_o = CSR_RSI;
                        3'b111: csr_op_o = CSR_RCI;
                        3'b000: begin 
                            csr_we_o = 1'b0;
                            gpr_we_o = 1'b0;
                            case(imm)
                                12'd0: illegal_instr_o = 1'b1;
                                12'd1: illegal_instr_o = 1'b1;
                                12'b001100000010: begin if(rs1 == 5'd0) mret_o = 1'b1;
                                else illegal_instr_o = 1'b1; end
                                default: illegal_instr_o = 1'b1;
                            endcase
                            end
                        default: begin illegal_instr_o = 1'b1; csr_we_o = 1'b0; gpr_we_o = 1'b0; end
                    endcase   
                end    
    
        default: illegal_instr_o = 1'b1;
        endcase
    end
end


endmodule