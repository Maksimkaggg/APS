module lsu (
    input logic clk_i,
    input logic rst_i,

    // Интерфейс с ядром
    input  logic        core_req_i,
    input  logic        core_we_i,
    input  logic [ 2:0] core_size_i,
    input  logic [31:0] core_addr_i,
    input  logic [31:0] core_wd_i,
    output logic [31:0] core_rd_o,
    output logic        core_stall_o,

    // Интерфейс с памятью
    output logic        mem_req_o,
    output logic        mem_we_o,
    output logic [ 3:0] mem_be_o,
    output logic [31:0] mem_addr_o,
    output logic [31:0] mem_wd_o,
    input  logic [31:0] mem_rd_i,
    input  logic        mem_ready_i
);
  import decoder_pkg::*;
  assign mem_req_o  = core_req_i;
  assign mem_we_o   = core_we_i;
  assign mem_addr_o = core_addr_i;


  logic [3:0] ldst_h;
  assign ldst_h = (core_addr_i[1]) ? 4'b1100 : 4'b0011;
  always_comb begin
    case (core_size_i)
      LDST_B:  mem_be_o = 4'b0001 << core_addr_i[1:0];
      LDST_H:  mem_be_o = ldst_h;
      LDST_W:  mem_be_o = 4'b1111;
      default: mem_be_o = 4'd0;
    endcase
  end


  always_comb begin
    case (core_size_i)
      LDST_B:  mem_wd_o = {{4{core_wd_i[7:0]}}};
      LDST_H:  mem_wd_o = {{2{core_wd_i[15:0]}}};
      LDST_W:  mem_wd_o = core_wd_i;
      default: mem_wd_o = 32'd0;
    endcase
  end

  always_comb begin
    case (core_size_i)
      LDST_W:  core_rd_o = mem_rd_i;
      LDST_B: begin
        case (core_addr_i[1:0])
          2'b00:   core_rd_o = {{24{mem_rd_i[7]}}, mem_rd_i[7:0]};
          2'b01:   core_rd_o = {{24{mem_rd_i[15]}}, mem_rd_i[15:8]};
          2'b10:   core_rd_o = {{24{mem_rd_i[23]}}, mem_rd_i[23:16]};
          2'b11:   core_rd_o = {{24{mem_rd_i[31]}}, mem_rd_i[31:24]};
          default: core_rd_o = 32'd0;
        endcase
      end
      LDST_BU: begin
        case (core_addr_i[1:0])
          2'b00:   core_rd_o = {24'd0, mem_rd_i[7:0]};
          2'b01:   core_rd_o = {24'd0, mem_rd_i[15:8]};
          2'b10:   core_rd_o = {24'd0, mem_rd_i[23:16]};
          2'b11:   core_rd_o = {24'd0, mem_rd_i[31:24]};
          default: core_rd_o = 32'd0;
        endcase
      end
      LDST_H: begin
        case (core_addr_i[1])
          1'b0: core_rd_o = {{16{mem_rd_i[15]}}, mem_rd_i[15:0]};
          1'b1: core_rd_o = {{16{mem_rd_i[31]}}, mem_rd_i[31:16]};
          default: core_rd_o = 32'd0;
        endcase
      end
      LDST_HU: begin
        case (core_addr_i[1])
          1'b0: core_rd_o = {16'd0, mem_rd_i[15:0]};
          1'b1: core_rd_o = {16'd0, mem_rd_i[31:16]};
          default: core_rd_o = 32'd0;
        endcase
      end
      default: core_rd_o = 32'd0;
    endcase
  end
  logic stall;
  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      stall <= '0;
    end else begin
      stall <= core_stall_o;
    end
  end


  assign core_stall_o = core_req_i & ~(stall & mem_ready_i);



endmodule
