module led_sb_ctrl (
    /*
    Часть интерфейса модуля, отвечающая за подключение к системной шине
*/
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        req_i,
    input  logic        write_enable_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,
    output logic [31:0] read_data_o,

    /*
    Часть интерфейса модуля, отвечающая за подключение к периферии
*/
    output logic [15:0] led_o
);

  logic [15:0] led_val;
  logic        led_mode;

  logic        wrire_req;
  logic        read_req;
  assign write_req = req_i & write_enable_i;
  assign read_req  = req_i & ~write_enable_i;

  logic is_valid_addr;
  logic is_rst_addr;
  logic is_mode_addr;

  assign is_valid_addr = (addr_i == 32'h0) ? 'd1 : 'd0;
  assign is_mode_addr  = (addr_i == 32'h4) ? 'd1 : 'd0;
  assign is_rst_addr   = (addr_i == 32'h24) ? 'd1 : 'd0;

  logic rst;
  assign rst = ((write_data_i == 32'd1) & is_rst_addr & wrire_req) | (rst_i);

  logic val_en;
  assign val_en = wrire_req & is_valid_addr;

  always_ff @(posedge clk_i) begin
    if (rst) begin
      led_val <= '0;
    end else if (val_en) begin
      led_val <= write_data_i[15:0];
    end
  end

  logic mode_en;
  assign mode_en = wrire_req & is_mode_addr;
  always_ff @(posedge clk_i) begin
    if (rst) begin
      led_mode <= '0;
    end else if (mode_en) begin
      led_mode <= write_data_i[0];
    end
  end


  logic [31:0] cntr;
  always_ff @(posedge clk_i) begin
    if (rst | ~led_mode | (cntr >= 32'd20_000_000)) begin
      cntr <= '0;
    end else begin
      cntr <= 1'd1;
    end
  end

  logic less;
  assign less  = (cntr < 32'd10_000_000);
  assign led_o = (less) ? led_val : 16'd0;

  logic [31:0] read_data_d;
  logic [31:0] read_data_r;
  logic en_rd;
  assign en_rd = (read_req) & (is_valid_addr | is_mode_addr);
  assign read_data_d = (is_valid_addr) ? {16'd0, led_val} : {31'd0, led_mode};

  always_ff @(posedge clk_i) begin
    if (rst) begin
      read_data_r <= '0;
    end else begin
      read_data_r <= read_data_d;
    end
  end

  assign read_data_o = read_data_r;

endmodule
