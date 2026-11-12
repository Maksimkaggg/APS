module daisy_chain (

  input  logic [15:0] masked_irq_i,
  input  logic           irq_ret_i,
  input  logic             ready_i,
  input  logic               clk_i,
  input  logic               rst_i,

  output logic               irq_o,
  output logic [31:0]  irq_cause_o,
  output logic [15:0]    irq_ret_o
);

  logic [15:0]   cause;
  logic [15:0] cause_r;
  logic [15:0]   ready;
  assign ready[0] =                   ready_i;
  assign cause[0] = masked_irq_i[0] & ready_i;
  genvar i;
  generate
    for(i = 1; i < 16; i++) begin
      assign ready[i] =   ready[i-1] & ~cause[i-1];
      assign cause[i] = ready[i] & masked_irq_i[i];
    end
  endgenerate


  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      cause_r <=    '0;
    end
    else if (irq_o )begin
      cause_r <= cause;
    end
  end

  assign irq_ret_o   =  (irq_ret_i) ? cause_r : '0;
  assign irq_cause_o = {12'h800, cause, 4'b0000};
  assign irq_o       =                      |cause;


endmodule