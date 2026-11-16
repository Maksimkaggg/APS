module sw_sb_ctrl (
    /*
    Часть интерфейса модуля, отвечающая за подключение к системной шине
*/
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        req_i,
    input  logic        write_enable_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,    // не используется, добавлен для
                                         // совместимости с системной шиной
    output logic [31:0] read_data_o,

    /*
    Часть интерфейса модуля, отвечающая за отправку запросов на прерывание
    процессорного ядра
*/

    output logic interrupt_request_o,
    input  logic interrupt_return_i,

    /*
    Часть интерфейса модуля, отвечающая за подключение к периферии
*/
    input logic [15:0] sw_i
);

  logic [15:0] sw_i_r;
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      sw_i_r <= '0;
    end else begin
      sw_i_r <= sw_i;
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      read_data_o <= '0;
    end else if (sw_i_r != sw_i & interrupt_return_i) begin
      read_data_o <= {16'd0, sw_i};
    end
  end

  always_comb begin
    if (sw_i_r != sw_i) begin
      interrupt_request_o = 'd1;
    end else if (~interrupt_return_i) begin
      interrupt_request_o = 'd1;
    end
  end


endmodule
