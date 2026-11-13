module interrupt_controller (
    input logic        clk_i,
    input logic        rst_i,
    input logic        exception_i,
    input logic [15:0] irq_req_i,
    input logic [15:0] mie_i,
    input logic        mret_i,

    output logic [15:0] irq_ret_o,
    output logic [31:0] irq_cause_o,
    output logic        irq_o
);


  //reg exc_h
  logic set_exc;
  logic exc_h;
  logic reset_exc;
  logic in_exc;

  assign in_exc    = set_exc & ~reset_exc;
  assign set_exc   = exception_i | exc_h;
  assign reset_exc = mret_i;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      exc_h <= '0;
    end
    else begin
      exc_h <= in_exc;
    end
  end

  //irq_ret_o
  logic [15:0] irq_ret_out;
  logic        irq_ret_i;

  assign irq_ret_o = irq_ret_out;
  assign irq_ret_i = mret_i & ~set_exc;


  // reg irq_h
  logic set_irq;
  logic irq_h;
  logic in_irq;

  assign set_irq = irq_o | irq_h;
  assign in_irq  = ~irq_ret_i & set_irq;


  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      irq_h <= '0;
    end
    else begin
      irq_h <= in_irq;
    end
  end
  // daisy chain
  logic [15:0] masked_irq;
  logic        ready_i;
  logic [31:0] cause;
  logic        irq_out;

  assign irq_o       = irq_out;
  assign irq_cause_o = cause;
  assign ready_i     = ~(set_exc | irq_h);
  assign masked_irq  = (irq_req_i & mie_i);

  daisy_chain unit_chain (
      .clk_i       (clk_i),
      .rst_i       (rst_i),
      .masked_irq_i(masked_irq),
      .ready_i     (ready_i),
      .irq_ret_i   (irq_ret_i),
      .irq_ret_o   (irq_ret_out),
      .irq_cause_o (cause),
      .irq_o       (irq_out)

  );


endmodule
