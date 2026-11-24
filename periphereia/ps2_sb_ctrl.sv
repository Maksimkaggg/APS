module ps2_sb_ctrl (
    /*
    Часть интерфейса модуля, отвечающая за подключение к системной шине
*/
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic [31:0] addr_i,
    input  logic        req_i,
    input  logic [31:0] write_data_i,
    input  logic        write_enable_i,
    output logic [31:0] read_data_o,

    /*
    Часть интерфейса модуля, отвечающая за отправку запросов на прерывание
    процессорного ядра
*/

    output logic interrupt_request_o,
    input  logic interrupt_return_i,

    /*
    Часть интерфейса модуля, отвечающая за подключение к модулю,
    осуществляющему приём данных с клавиатуры
*/
    input logic kclk_i,
    input logic kdata_i
);
  logic       rst;
  logic       keycode_valid;
  logic [7:0] keycode;
  logic [7:0] scan_code;
  logic       scan_code_is_unread;


  PS2Receiver unit_PS2Receiver (
      .clk_i(clk_i),
      .kclk_i(kclk_i),
      .rst_i(rst),
      .kdata_i(kdata_i),
      .keycode_o(keycode),
      .keycode_valid_o(keycode_valid)
  );


  logic is_read_scan_code;
  logic is_read_flag_scan_code_is_unrd;
  logic is_write_rst;

  assign is_read_scan_code = (addr_i[23:0] == '0) ? 1'd1 : 1'd0;
  assign is_read_flag_scan_code_is_unrd = (addr_i[23:0] == 24'h4) ? 1'd1 : 1'd0;
  assign is_write_rst = (addr_i[23:0] == 24'h24) ? 1'd1 : 1'd0;

  assign rst = rst_i | (is_write_rst & req_i & (write_data_i == 32'd1) & write_enable_i);

  always_ff @(posedge clk_i) begin
    if (rst) begin
      scan_code <= '0;
    end else if (keycode_valid) begin
      scan_code <= keycode;
    end
  end

  assign interrupt_request_o = scan_code_is_unread;


  always_comb begin
    if (scan_code_is_unread) begin
      interrupt_request_o = 'd1;
    end else if (interrupt_return_i) begin
      interrupt_request_o = '0;
    end else begin
      interrupt_request_o = '0;
    end
  end


  logic [31:0] read_data;
  assign read_data_o = read_data;
  always_ff @(posedge clk_i) begin
    if (rst) begin
      read_data <= '0;
    end else if (req_i & ~write_enable_i & is_read_scan_code) begin
      read_data <= {24'd0, scan_code};
    end else if (req_i & ~write_enable_i & is_read_flag_scan_code_is_unrd) begin
      read_data <= {31'd0, scan_code_is_unread};
    end
  end

endmodule