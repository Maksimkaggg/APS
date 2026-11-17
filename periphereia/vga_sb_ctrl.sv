module vga_sb_ctrl (
    input  logic        clk_i,
    input  logic        rst_i,
    input  logic        clk100m_i,
    input  logic        req_i,
    input  logic        write_enable_i,
    input  logic [ 3:0] mem_be_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,
    output logic [31:0] read_data_o,

    output logic [3:0] vga_r_o,
    output logic [3:0] vga_g_o,
    output logic [3:0] vga_b_o,
    output logic       vga_hs_o,
    output logic       vga_vs_o
);

  logic [31:0] read_data_char_map;
  logic [31:0] read_data_col_map;
  logic [31:0] read_data_char_tiff;
  logic        req_char_tiff;
  logic        req_char_map;
  logic        req_col_map;
  logic        write_enable_char_tiff;
  logic        write_enable_char_map;
  logic        write_enable_col_map;

  vgachargen unit_vgachargen (
      .char_map_addr_i(addr_i[11:2]),
      .char_map_be_i(mem_be_i),
      .char_map_rdata_o(read_data_char_map),
      .char_map_req_i(req_char_map),
      .char_map_wdata_i(write_data_i),
      .char_map_we_i(write_enable_char_map),
      .char_tiff_addr_i(addr_i[11:2]),
      .char_tiff_be_i(mem_be_i),
      .char_tiff_rdata_o(read_data_char_tiff),
      .char_tiff_req_i(req_char_tiff),
      .char_tiff_wdata_i(write_data_i),
      .char_tiff_we_i(write_enable_char_tiff),
      .clk100m_i(clk100m_i),
      .clk_i(clk_i),
      .col_map_addr_i(addr_i[11:2]),
      .col_map_be_i(mem_be_i),
      .col_map_rdata_o(read_data_col_map),
      .col_map_req_i(req_col_map),
      .col_map_wdata_i(write_data_i),
      .col_map_we_i(write_enable_col_map),
      .rst_i(rst_i),
      .vga_b_o(vga_b_o),
      .vga_g_o(vga_g_o),
      .vga_hs_o(vga_hs_o),
      .vga_r_o(vga_r_o),
      .vga_vs_o(vga_vs_o)
  );

  always_comb begin
    req_char_map           = 1'b0;
    req_col_map            = 1'b0;
    req_char_tiff          = 1'b0;

    write_enable_char_map  = 1'b0;
    write_enable_col_map   = 1'b0;
    write_enable_char_tiff = 1'b0;

    read_data_o            = 32'b0;
    case (addr_i[13:12])
      2'b00: begin
        req_char_map          = req_i;
        write_enable_char_map = write_enable_i;
        read_data_o           = read_data_char_map;
      end
      2'b01: begin
        req_col_map          = req_i;
        write_enable_col_map = write_enable_i;
        read_data_o          = read_data_col_map;
      end
      2'b10: begin
        req_char_tiff          = req_i;
        write_enable_char_tiff = write_enable_i;
        read_data_o            = read_data_char_tiff;
      end
      default: begin
        req_char_map           = '0;
        write_enable_char_map  = '0;
        read_data_o            = '0;
        req_col_map            = '0;
        write_enable_col_map   = '0;
        req_char_tiff          = '0;
        write_enable_char_tiff = '0;
      end
    endcase
  end

endmodule
