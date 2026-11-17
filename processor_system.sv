module processor_system (
    input logic clk_i,
    input logic resetn_i,

    // Входы и выходы периферии
    input logic [15:0] sw_i,  // Переключатели

    output logic [15:0] led_o,  // Светодиоды

    input logic kclk_i,  // Тактирующий сигнал клавиатуры
    input logic kdata_i, // Сигнал данных клавиатуры

    output logic [6:0] hex_led_o,  // Вывод семисегментных индикаторов
    output logic [7:0] hex_sel_o,  // Селектор семисегментных индикаторов

    input  logic rx_i,  // Линия приёма по UART
    output logic tx_o,  // Линия передачи по UART

    output logic [3:0] vga_r_o,  // Красный канал vga
    output logic [3:0] vga_g_o,  // Зелёный канал vga
    output logic [3:0] vga_b_o,  // Синий канал vga
    output logic       vga_hs_o,  // Линия горизонтальной синхронизации vga
    output logic vga_vs_o  // Линия вертикальной синхронизации vga
);

  logic sysclk, rst;
  sys_clk_rst_gen divider (
      .ex_clk_i     (clk_i),
      .ex_areset_n_i(resetn_i),
      .div_i        (5),
      .sys_clk_o    (sysclk),
      .sys_reset_o  (rst)
  );

  logic [15:0] irq_req;
  logic [15:0] irq_ret;
  logic [31:0] instr_addr;
  logic [31:0] instr;

  instr_mem instr_mem_unit (
      .read_addr_i(instr_addr),
      .read_data_o(instr)
  );


  logic        core_we;
  logic [31:0] core_addr;
  logic [31:0] core_wd;
  logic [31:0] core_rd;
  logic [ 3:0] core_size;
  logic        stall;
  logic        core_req;
  logic [15:0] irq_req;
  logic [15:0] irq_ret;
  processor_core core (
      .clk_i       (sysclk),
      .rst_i       (rst),
      .stall_i     (stall),
      .instr_i     (instr),
      .mem_rd_i    (core_rd),
      .instr_addr_o(instr_addr),
      .mem_addr_o  (core_addr),
      .mem_size_o  (core_size),
      .mem_req_o   (core_req),
      .mem_we_o    (core_we),
      .mem_wd_o    (core_wd),
      .irq_req_i   (irq_req),
      .irq_ret_o   (irq_ret)
  );
  logic        mem_req;
  logic        mem_we;
  logic [ 3:0] mem_be;
  logic [31:0] mem_addr;
  logic [31:0] mem_wd;
  logic [31:0] mem_rd;
  logic        mem_ready;

  lsu lsu_unit (
      .clk_i       (sysclk),
      .rst_i       (rst),
      // Интерфейс с ядром
      .core_req_i  (core_req),
      .core_we_i   (core_we),
      .core_size_i (core_size),
      .core_addr_i (core_addr),
      .core_wd_i   (core_wd),
      .core_rd_o   (core_rd),
      .core_stall_o(stall),
      // Интерфейс с памятью
      .mem_req_o   (mem_req),
      .mem_we_o    (mem_we),
      .mem_be_o    (mem_be),
      .mem_addr_o  (mem_addr),
      .mem_wd_o    (mem_wd),
      .mem_rd_i    (mem_rd),
      .mem_ready_i (mem_ready)
  );
  localparam DATA_MEM = 8'h0;
  localparam PS2 = 8'h03;
  localparam VGA = 8'h07;


  logic data_mem_req;
  logic vga_req;
  logic ps2_req;
  always_comb begin
    data_mem_req = '0;
    vga_req      = '0;
    ps2_req      = '0;
    case (mem_addr[31:24])
      DATA_MEM: data_mem_req = mem_req;
      PS2:      ps2_req = mem_req;
      VGA:      vga_req = mem_req;
      default: begin
        data_mem_req = '0;
        vga_req      = '0;
        ps2_req      = '0;
      end
    endcase
  end

  logic [31:0] data_mem_rd;
  logic [31:0] vga_rd;
  logic [31:0] ps2_rd;
  always_comb begin
    data_mem_rd = '0;
    vga_rd      = '0;
    ps2_rd      = '0;
    case (mem_addr[31:24])
      DATA_MEM: mem_rd = data_mem_rd;
      PS2:      mem_rd = ps2_rd;
      VGA:      mem_rd = vga_rd;
      default:  mem_rd = '0;
    endcase
  end

  data_mem data_mem_unit (
      .clk_i         (sysclk),
      .mem_req_i     (data_mem_req),
      .write_enable_i(mem_we),
      .byte_enable_i (mem_be),
      .addr_i        (mem_addr),
      .write_data_i  (mem_wd),
      .read_data_o   (data_mem_rd),
      .ready_o       (mem_ready)
  );


  ps2_sb_ctrl unit_ps2_sb_ctrl (
      .addr_i(mem_addr),
      .clk_i(sysclk),
      .interrupt_request_o(irq_req),
      .interrupt_return_i(irq_ret),
      .kclk_i(kclk_i),
      .kdata_i(kdata_i),
      .read_data_o(ps2_rd),
      .req_i(ps2_req),
      .rst_i(rst),
      .write_data_i(mem_wd),
      .write_enable_i(mem_we)
  );

  vga_sb_ctrl unit_vga_sb_ctrl (
      .addr_i(mem_addr),
      .clk100m_i(clk_i),
      .clk_i(sysclk),
      .mem_be_i(mem_be),
      .read_data_o(vga_rd),
      .req_i(vga_req),
      .rst_i(rst),
      .vga_b_o(vga_b_o),
      .vga_g_o(vga_g_o),
      .vga_hs_o(vga_hs_o),
      .vga_r_o(vga_r_o),
      .vga_vs_o(vga_vs_o),
      .write_data_i(mem_wd),
      .write_enable_i(mem_we)
  );









endmodule
