module csr_controller(

  input  logic                 clk_i,
  input  logic                 rst_i,
  input  logic                trap_i,

  input  logic [ 2:0]       opcode_i,

  input  logic [11:0]         addr_i,
  input  logic [31:0]           pc_i,
  input  logic [31:0]       mcause_i,
  input  logic [31:0]     rs1_data_i,
  input  logic [31:0]     imm_data_i,
  input  logic        write_enable_i,

  output logic [31:0]    read_data_o,
  output logic [31:0]          mie_o,
  output logic [31:0]         mepc_o,
  output logic [31:0]        mtvec_o
);

  import csr_pkg::*;

  logic [31:0] operation;
  always_comb begin
    case (opcode_i)
      CSR_RW : operation =                rs1_data_i;
      CSR_RS : operation =  rs1_data_i | read_data_o;
      CSR_RC : operation = read_data_o & ~rs1_data_i;
      CSR_RWI: operation =                imm_data_i;
      CSR_RSI: operation =  imm_data_i | read_data_o;
      CSR_RCI: operation = read_data_o & ~imm_data_i;
      default: operation =                        '0;
    endcase
  end

  logic en_r_1;
  logic en_r_2;
  logic en_r_3;
  logic en_r_4;
  logic en_r_5;
  always_comb begin
    case (addr_i)
      MIE_ADDR     : en_r_1 = write_enable_i;
      MTVEC_ADDR   : en_r_2 = write_enable_i;
      MSCRATCH_ADDR: en_r_3 = write_enable_i;
      MEPC_ADDR    : en_r_4 = write_enable_i;
      MCAUSE_ADDR  : en_r_5 = write_enable_i;
      default: begin
                    en_r_1 =            'd0;
                    en_r_2 =            'd0;
                    en_r_3 =            'd0;
                    en_r_4 =            'd0;
                    en_r_5 =            'd0;
      end
    endcase
  end


  logic [31:0] mie;
  assign mie_o = mie;
  always_ff @(posedge clk_i) begin
    if(rst_i) begin
      mie <=        '0;
    end
    else if (en_r_1) begin
      mie <= operation;
    end
  end


  logic [31:0] mtvec;
  assign mtvec_o = mtvec;
  always_ff @(posedge clk_i) begin
    if(rst_i) begin
      mtvec <=        '0;
    end
    else if (en_r_2) begin
      mtvec <= operation;
    end
  end


  logic [31:0] r_o3;
  always_ff @(posedge clk_i) begin
    if(rst_i) begin
      r_o3 <=        '0;
    end
    else if (en_r_3) begin
      r_o3 <= operation;
    end
  end


  logic [31:0]      mepc;
  logic [31:0] mult_pc_i;
  assign mepc_o    =   mepc;
  assign mult_pc_i = (trap_i) ? pc_i : operation;
  always_ff @(posedge clk_i) begin
    if(rst_i) begin
      mepc <=        '0;
    end
    else if (en_r_4 | trap_i) begin
      mepc <= mult_pc_i;
    end
  end


  logic [31:0]          r_o5;
  logic [31:0] mult_mcause_i;
  assign mult_mcause_i = (trap_i) ? mcause_i : operation;
  always_ff @(posedge clk_i) begin
    if(rst_i) begin
      r_o5 <=            '0;
    end
    else if (en_r_5 | trap_i) begin
      r_o5 <= mult_mcause_i;
    end
  end


  always_comb begin
    case (addr_i)
      MIE_ADDR     : read_data_o =   mie;
      MTVEC_ADDR   : read_data_o = mtvec;
      MSCRATCH_ADDR: read_data_o =  r_o3;
      MEPC_ADDR    : read_data_o =  mepc;
      MCAUSE_ADDR  : read_data_o =  r_o5;
      default      : read_data_o =    '0;
    endcase
  end



endmodule