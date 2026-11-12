module processor_core (
  input  logic               clk_i,
  input  logic               rst_i,
  input  logic             stall_i,
  input  logic [31:0]      instr_i,
  input  logic [31:0]     mem_rd_i,
  input  logic [15:0]    irq_req_i,

  output logic [31:0] instr_addr_o,
  output logic [31:0]   mem_addr_o,
  output logic [ 2:0]   mem_size_o,
  output logic           mem_req_o,
  output logic            mem_we_o,
  output logic [31:0]     mem_wd_o,
  output logic [15:0]    irq_ret_o
);
  // константы
  logic [31:0] imm_I;
  assign imm_I =                                     {{20{instr_i[31]}},instr_i[31:20]};
  logic [31:0] imm_U;
  assign imm_U =                                              {instr_i[31:20], {12{0}}};
  logic [31:0] imm_S;
  assign imm_S =                     {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
  logic [31:0] imm_B;
  assign imm_B =   {{19{instr_i[31]}}, instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
  logic [31:0] imm_J;
  assign imm_J = {{11{instr_i[31]}}, instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};
  logic [31:0] imm_Z;
  assign imm_Z =                                                {27'b0 ,instr_i[19:15]};

  // декодер
  logic [1:0]   a_sel;
  logic [2:0]   b_sel;
  logic [4:0]  alu_op;
  logic        gpr_we;
  logic        wb_sel;
  logic       mem_req;
  logic          trap;
  logic        branch;
  logic           jal;
  logic          jalr;
  logic        csr_op;
  logic        csr_we;
  logic illegal_instr;
  logic        mem_we;
  logic      mem_size;
  logic          mret;

  assign mem_req_o  =    mem_req & ~trap;
  assign mem_we_o   =     mem_we & ~trap;
  assign mem_size_o =           mem_size;
  assign trap = irq || illegal_instr;
  decoder decoder_unit(
                      .fetched_instr_i(instr_i),
                                .a_sel_o(a_sel),
                                .b_sel_o(b_sel),
                              .alu_op_o(alu_op),
                              .csr_op_o(csr_op),
                              .csr_we_o(csr_we),
                            .mem_req_o(mem_req),
                              .mem_we_o(mem_we),
                          .mem_size_o(mem_size),
                              .gpr_we_o(gpr_we),
                              .wb_sel_o(wb_sel),
                .illegal_instr_o(illegal_instr),
                              .branch_o(branch),
                                    .jal_o(jal),
                                  .jalr_o(jalr),
                                  .mret_o(mret)
  );


  // PC
  logic [31:0]               pc;
  logic                    flag;
  // csr
  logic              irq_req_in;
  logic             irq_req_out;
  logic [31:0]           mcause;
  logic [31:0]             mepc;
  logic [31:0]            mtvec;
  // mux for PC
  logic [31:0]       mux_branch;
  logic [31:0]          mux_jal;
  logic [31:0]   result_summ_pc;
  logic [31:0]         mux_jalr;
  logic [31:0]         mux_trap;
  logic [31:0]         mux_mret;
  // jalr
  logic [31:0] result_summ_jalr;
  assign result_summ_jalr = rd1 + imm_I;

  // mux for PC
  assign mux_branch     =                                   (branch) ? imm_B : imm_J;
  assign mux_jal        =             (jal || (flag && branch)) ? mux_branch : 32'd4;
  assign result_summ_pc =                                               pc + mux_jal;
  assign mux_jalr       = (jalr) ? ({result_summ_jalr[31:1], 1'b0}) : result_summ_pc;
  assign mux_trap       =                                  (trap) ? mtvec : mux_jalr;
  assign mux_mret       =                                   (mret) ? mepc : mux_trap;
  //PC
  always_ff @(posedge clk_i or posedge rst_i) begin
      if (rst_i) begin
        pc <=      'd0;
      end
      else if (~stall_i || trap)
        pc <= mux_mret;
  end


  assign instr_addr_o = pc;


  // АЛУ
  logic [31:0]          a;
  logic [31:0]          b;
  logic [31:0]        rd1;
  logic [31:0]        rd2;
  logic [31:0] result_ALU;

  always_comb begin // от АЛУ
      case(a_sel)
      OP_A_RS1    : a = rd1;
      OP_A_CURR_PC: a =  pc;
      OP_A_ZERO   : a =  '0;
      default     : a =  '0;
      endcase
  end


  always_comb begin
      case(b_sel)
      OP_B_RS2  : b =   rd2;
      OP_B_IMM_I: b = imm_I;
      OP_B_IMM_U: b = imm_U;
      OP_B_IMM_S: b = imm_S;
      OP_B_INCR : b =   'd4;
      default   : b =    '0;
      endcase
  end

  alu alu_unit(
                            .a_i(a),
                            .b_i(b),
                  .alu_op_i(alu_op),
                      .flag_o(flag),
              .result_o(result_ALU)
  );

  assign mem_addr_o = result_ALU;

  // регистровый файл
  logic      write_enable;
  logic [31:0] write_data;
  logic [31:0]     csr_wd;
  logic [4:0]  write_addr;
  logic [4:0]  read_addr1;
  logic [4:0]  read_addr2;


  assign write_enable = gpr_we && ~(stall_i || trap);
  assign write_addr   =                instr_i[11:7];
  assign read_addr1   =               instr_i[19:15];
  assign read_addr2   =               instr_i[24:20];

  always_comb begin
    case (wb_sel)
      WB_EX_RESULT: write_data = result_ALU;
      WB_LSU_DATA : write_data =   mem_rd_i;
      WB_CSR_DATA : write_data =     csr_wd;
      default     : write_data =         '0;
    endcase
  end



  register_file reg_file(
                                          .clk_i(clk_i),
                          .write_enable_i(write_enable),
                              .write_addr_i(write_addr),
                              .read_addr1_i(read_addr1),
                              .read_addr2_i(read_addr2),
                              .write_data_i(write_data),
                                     .read_data1_o(rd1),
                                     .read_data2_o(rd2)
  );

  assign mem_wd_o = rd2;
  //IRQ
  logic [31:0]    mie;
  logic [31:0]  cause;
  logic           irq;
  interrupt_controller unit_interrupt(
                                                    .clk_i(clk_i),
                                                    .rst_i(rst_i),
                                      .exception_i(illegal_instr),
                                            .irq_req_i(irq_req_i),
                                                  .mie_i(mie[15:0]),
                                                    .mret_i(mret),
                                            .irq_ret_o(irq_ret_o),
                                              .irq_cause_o(cause),
                                                      .irq_o(irq)
  );



  //csr
  csr_controller unit_csr_contrl(
                                          .clk_i(clk_i),
                                          .rst_i(rst_i),
                                          .trap_i(trap),
                                      .opcode_i(csr_op),
                                .addr_i(instr_i[31:20]),
                                              .pc_i(pc),
                                      .mcause_i(mcause),
                                       .rs1_data_i(rd1),
                                     .imm_data_i(imm_Z),
                                .write_enable_i(csr_we),
                                   .read_data_o(csr_wd),
                                            .mie_o(mie),
                                          .mepc_o(mepc),
                                        .mtvec_o(mtvec)
  );

assign mcause = (illegal_instr) ? 32'h0000_0002 : cause;


endmodule