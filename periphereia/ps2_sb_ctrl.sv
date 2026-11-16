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

  logic       keycode_valid;
  logic [7:0] keycode;
  logic [7:0] scan_code;
  logic       scan_code_is_unread;


  PS2Receiver inut_PS2Receiver (
      .clk_i(clk_i),
      .kclk_i(kclk_i),
      .rst_i(rst_i),
      .kdata_i(kdata_i),
      .keycode_o(keycode),
      .keycode_valid_o(keycode_valid)
  );

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      keycode_valid <= '0;
    end else if (keycode_valid) begin
      scan_code <= keycode;
    end
  end


  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      scan_code_is_unread <= '0;
    end else if (keycode_valid) begin
      scan_code_is_unread <= 'd1;
    end
  end



endmodule
